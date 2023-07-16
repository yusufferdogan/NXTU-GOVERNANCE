// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IGovernance {
    function amountToApply() external view returns (uint256);

    function applyProject() external;

    function approveProject(
        uint256 projectId,
        string memory _name,
        string memory _description,
        string memory _url,
        uint256 _apr,
        uint256 _unstakeDate,
        uint256 _voteEndDate
    ) external;

    function getProjectStakeData(uint256 projectId)
        external
        view
        returns (
            uint256 apr,
            uint256 lockedTime,
            uint256 stakeEndDate
        );

    function isProjectApproved(uint256 projectId) external view returns (bool);

    function isVoted(address, uint256) external view returns (bool);

    function minAmountToVote() external view returns (uint256);

    function owner() external view returns (address);

    function projectCount() external view returns (uint256);

    function projects(uint256)
        external
        view
        returns (
            string memory name,
            string memory description,
            string memory url,
            uint256 apr,
            uint256 lockedTime,
            uint256 unstakeDate,
            uint256 voteEndDate,
            uint256 votedFor,
            uint256 votedAgainst,
            bool applied,
            bool approved
        );

    function renounceOwnership() external;

    function token() external view returns (address);

    function transferOwnership(address newOwner) external;

    function voteProject(
        uint256 projectId,
        bool voteFor,
        uint256 amount
    ) external;
}
