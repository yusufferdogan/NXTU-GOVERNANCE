// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./interfaces/IStake.sol";
import "./interfaces/IGovernance.sol";

contract Stake is IStake, Ownable, Pausable {
    IERC20 public immutable token;
    IGovernance public immutable governance;

    uint256 public constant DOMINATOR = 100_000;
    uint256 public tokenAprReward;

    struct UserData {
        // queue structure
        uint256 front;
        Deposit[] deposits;
    }

    //user => project => userData
    mapping(address => mapping(uint256 => UserData)) public userData;

    //projectId => total collectedAmount
    mapping(uint256 => uint256) public totalCollected;

    mapping(address => address) public referers;

    constructor(address _token, address _governance) {
        token = IERC20(_token);
        governance = IGovernance(_governance);
        //deployer has referer so peoples can referenced by deployer
        referers[msg.sender] = address(this);
    }

    function isProjectFailedToCollectAmount(uint256 projectId)
        public
        view
        returns (bool)
    {
        (uint256 timetampToCollectUntil, uint256 amountToBeCollect) = governance
            .getProjectCollectData(projectId);

        return ((block.timestamp > timetampToCollectUntil) &&
            (totalCollected[projectId] < amountToBeCollect));
    }

    //method for adding apr rewards for stakers
    function addAprReward(uint256 amount) external onlyOwner {
        tokenAprReward += amount;

        bool success = token.transferFrom(msg.sender, address(this), amount);
        if (!success) revert TransferError();
    }

    //this method can be used to take back unused reward tokens
    function takeBackRemainingRewards(uint256 amount) external onlyOwner {
        tokenAprReward -= amount;

        bool success = token.transfer(msg.sender, amount);
        if (!success) revert TransferError();
    }

    function stake(
        uint256 _projectId,
        uint256 _amount,
        address _referer
    ) external whenNotPaused {
        if (_amount == 0) revert AmountCantBeZero();

        uint256 refPercantage = governance.getProjectRefPercantage(_projectId);

        //project want ref and user does not have ref
        if (refPercantage != 0 && referers[msg.sender] == address(0)) {
            if (_referer == address(0)) revert CantStakeWithoutRef();
            if (_referer == msg.sender) revert CantRefToYourself();
            // if your referer has referer means your referer is valid
            if (referers[_referer] == address(0)) revert RefererIsNoStaker();
            //assign parameter as msg.sender's referer
            referers[msg.sender] = _referer;
        }

        if (!governance.isProjectPassedTheVoting(_projectId))
            revert ProjectIsNotPassedTheVoting();

        (
            uint256 apr,
            uint256 lockedTime,
            uint256 stakeEndDate,
            uint256 amountToBeCollect
        ) = governance.getProjectStakeData(_projectId);

        if (block.timestamp > stakeEndDate) revert StakeIsEnded();

        //if project ref pool is fulled
        if (_amount + totalCollected[_projectId] > amountToBeCollect)
            revert ProjectCollectCompleted();

        uint256 userReward = (_amount * apr * lockedTime) /
            (DOMINATOR * 365 days);

        uint256 refReward = (_amount * refPercantage) / DOMINATOR;

        uint256 totalReward = userReward + refReward;

        if (tokenAprReward < totalReward) revert InsufficientReward();

        tokenAprReward -= totalReward;

        userData[msg.sender][_projectId].deposits.push(
            Deposit({
                unlockTime: block.timestamp + lockedTime,
                amount: _amount,
                reward: userReward
            })
        );

        totalCollected[_projectId] += _amount;

        emit Staked(_projectId, msg.sender, _amount);

        if (refPercantage != 0) {
            bool _success = token.transfer(referers[msg.sender], refReward);
            if (!_success) revert TransferError();
        }

        bool success = token.transferFrom(msg.sender, address(this), _amount);
        if (!success) revert TransferError();
    }

    //unstake users stake, starts from users first stake to last stake
    function unstake(uint256 projectId) external {
        // if project failed you have to
        if (isProjectFailedToCollectAmount(projectId))
            revert ProjectIsFailedToCollectAmount();

        UserData storage user = userData[msg.sender][projectId];

        if (user.deposits.length - user.front == 0) revert NoDeposit();
        Deposit memory unstakedDeposit = user.deposits[user.front];

        if (unstakedDeposit.unlockTime > block.timestamp)
            revert StakeIsLocked();

        uint256 withdrawAmount = unstakedDeposit.amount +
            unstakedDeposit.reward;

        delete user.deposits[user.front];
        user.front++;

        emit Unstaked(projectId, msg.sender, withdrawAmount);
        bool success = token.transfer(msg.sender, withdrawAmount);
        if (!success) revert TransferError();
    }

    function refund(uint256 projectId) external {
        if (!isProjectFailedToCollectAmount(projectId))
            revert ProjectIsNotFailedToCollectAmount();

        UserData storage user = userData[msg.sender][projectId];

        if (user.deposits.length - user.front == 0) revert NoDeposit();
        Deposit memory unstakedDeposit = user.deposits[user.front];

        uint256 withdrawAmount = unstakedDeposit.amount;

        tokenAprReward += unstakedDeposit.reward;

        delete user.deposits[user.front];
        user.front++;

        emit Refund(projectId, msg.sender, withdrawAmount);
        bool success = token.transfer(msg.sender, withdrawAmount);
        if (!success) revert TransferError();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
