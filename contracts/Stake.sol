// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

import "./interfaces/IStake.sol";

contract Stake is IStake, Ownable {
    IERC20 public immutable token;
    uint256 public lockedTime = 365 days / 2;
    uint256 public baseApr = 24_000;
    uint256 public dominator = 100_000;
    uint256 public tokenAprReward;

    struct UserData {
        // queue structure
        uint256 front;
        Deposit[] deposits;
    }

    mapping(address => UserData) public userData;

    constructor(address _token) {
        token = IERC20(_token);
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

    function stake(uint256 amount) external {
        if (amount == 0) revert AmountCantBeZero();

        uint256 userReward = (amount * baseApr * lockedTime) /
            (dominator * 365 days);

        if (tokenAprReward < userReward) revert InsufficientReward();

        tokenAprReward -= userReward;

        userData[msg.sender].deposits.push(
            Deposit({
                // solhint-disable-next-line not-rely-on-time
                unlockTime: block.timestamp + lockedTime,
                amount: amount,
                reward: userReward
            })
        );

        emit Staked(msg.sender, amount);

        bool success = token.transferFrom(msg.sender, address(this), amount);
        if (!success) revert TransferError();
    }

    //unstake users stake, starts from users first stake to last stake
    function unstake() external {
        UserData storage user = userData[msg.sender];

        if (user.deposits.length - user.front == 0) revert NoDeposit();
        Deposit memory unstakedDeposit = user.deposits[user.front];

        // solhint-disable-next-line not-rely-on-time
        if (unstakedDeposit.unlockTime > block.timestamp)
            revert StakeIsLocked();

        uint256 withdrawAmount = unstakedDeposit.amount +
            unstakedDeposit.reward;

        delete user.deposits[user.front];
        user.front++;

        emit Unstaked(msg.sender, withdrawAmount);
        bool success = token.transfer(msg.sender, withdrawAmount);
        if (!success) revert TransferError();
    }

    function setLockedTime(uint256 _lockedTime) external onlyOwner {
        lockedTime = _lockedTime;
    }

    function setBaseApr(uint256 _baseApr) external onlyOwner {
        baseApr = _baseApr;
    }
}
