// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

import "./interfaces/IStake.sol";
import "./interfaces/IGovernance.sol";

contract Stake is IStake, Ownable {
    IERC20 public immutable token;
    IGovernance public immutable governance;

    uint256 public dominator = 100_000;
    uint256 public tokenAprReward;

    struct UserData {
        // queue structure
        uint256 front;
        Deposit[] deposits;
    }

    //user => project => userData
    mapping(address => mapping(uint256 => UserData)) public userData;

    constructor(address _token, address _governance) {
        token = IERC20(_token);
        governance = IGovernance(_governance);
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

    function stake(uint256 projectId, uint256 amount) external {
        if (amount == 0) revert AmountCantBeZero();

        if (!governance.isProjectPassedTheVoting(projectId))
            revert ProjectIsNotPassedTheVoting();

        (uint256 apr, uint256 lockedTime, uint256 stakeEndDate) = governance
            .getProjectStakeData(projectId);

        if (block.timestamp > stakeEndDate) revert StakeIsEnded();

        uint256 userReward = (amount * apr * lockedTime) /
            (dominator * 365 days);

        if (tokenAprReward < userReward) revert InsufficientReward();

        tokenAprReward -= userReward;

        userData[msg.sender][projectId].deposits.push(
            Deposit({
                // solhint-disable-next-line not-rely-on-time
                unlockTime: block.timestamp + lockedTime,
                amount: amount,
                reward: userReward
            })
        );

        emit Staked(projectId, msg.sender, amount);

        bool success = token.transferFrom(msg.sender, address(this), amount);
        if (!success) revert TransferError();
    }

    //unstake users stake, starts from users first stake to last stake
    function unstake(uint256 projectId) external {
        UserData storage user = userData[msg.sender][projectId];

        if (user.deposits.length - user.front == 0) revert NoDeposit();
        Deposit memory unstakedDeposit = user.deposits[user.front];

        // solhint-disable-next-line not-rely-on-time
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
}
