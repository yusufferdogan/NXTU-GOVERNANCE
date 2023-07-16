// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IGovernanceError {
    error LessThanMinAmount();
    error ProjectDoesNotExist();
    error AlreadyVoted();
    error VoteEnded();
    error AlreadyApproved();
    error NotApproved();
    error DidNotApplied();

    event ProjectApplied(uint256 indexed id);
    event ProjectApproved(
        uint256 indexed id,
        string name,
        string description,
        string url,
        uint256 apr,
        uint256 lockedTime,
        uint256 voteEndDate,
        uint256 stakeEndDate
    );
    event ProjectVoted(
        uint256 indexed projectId,
        address indexed user,
        bool votedFor
    );
}
