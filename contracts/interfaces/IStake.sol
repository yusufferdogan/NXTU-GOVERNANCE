// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IStake {
    struct Deposit {
        uint256 unlockTime;
        uint256 amount;
        uint256 reward;
    }

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);

    error TransferError();
    error NoDeposit();
    error StakeIsLocked();
    error InsufficientReward();
    error AmountCantBeZero();
}
