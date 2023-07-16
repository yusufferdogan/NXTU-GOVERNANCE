// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IGovernanceError.sol";

interface INXTU is IERC20 {
    function burnFrom(address account, uint256 amount) external;

    function burn(uint256 amount) external;
}

contract Governance is Ownable, IGovernanceError {
    INXTU public immutable token;
    uint256 public projectCount;
    uint256 public minAmountToVote = 1 * 10**8;
    uint256 public amountToApply = 500 * 10**8;

    struct Project {
        string name;
        string description;
        string url;
        uint256 apr;
        //unstakeTimeStamp = voteEndDate + lockedTime
        uint256 lockedTime;
        uint256 voteEndDate;
        uint256 votedFor;
        uint256 votedAgainst;
        uint256 stakeEndDate;
        bool applied;
        bool approved;
    }

    constructor(address _token) {
        token = INXTU(_token);
    }

    mapping(uint256 => Project) public projects;
    mapping(address => mapping(uint256 => bool)) public isVoted;

    // function that returns true if the project is passed the vote
    function isProjectPassedTheVoting(uint256 projectId)
        external
        view
        returns (bool)
    {
        Project memory project = projects[projectId];
        // invalid project
        if (project.lockedTime == 0) return false;
        //check voting ends
        if (block.timestamp < project.voteEndDate) return false;
        //which vote is bigger
        if (project.votedFor > project.votedAgainst) return true;
        else return false;
    }

    function getProjectStakeData(uint256 projectId)
        external
        view
        returns (
            uint256 apr,
            uint256 lockedTime,
            uint256 stakeEndDate
        )
    {
        Project memory project = projects[projectId];
        apr = project.apr;
        lockedTime = project.lockedTime;
        stakeEndDate = project.stakeEndDate;
    }

    function applyProject() external {
        projects[++projectCount].applied = true;
        token.burnFrom(msg.sender, amountToApply);
        emit ProjectApplied(projectCount);
    }

    function approveProject(
        uint256 projectId,
        string calldata _name,
        string calldata _description,
        string calldata _url,
        uint256 _apr,
        uint256 _lockedTime,
        uint256 _voteEndDate,
        uint256 _stakeEndDate
    ) external onlyOwner {
        if (!projects[projectId].applied) revert DidNotApplied();
        if (projects[projectId].approved) revert AlreadyApproved();

        projects[projectId] = Project({
            name: _name,
            description: _description,
            url: _url,
            apr: _apr,
            lockedTime: _lockedTime,
            votedFor: 0,
            votedAgainst: 0,
            applied: true,
            approved: true,
            stakeEndDate: _stakeEndDate,
            voteEndDate: _voteEndDate
        });
        emit ProjectApproved(
            projectId,
            _name,
            _description,
            _url,
            _apr,
            _lockedTime,
            _voteEndDate,
            _stakeEndDate
        );
    }

    function voteProject(
        uint256 projectId,
        bool voteFor,
        uint256 amount
    ) external {
        if (amount < minAmountToVote) revert LessThanMinAmount();
        if (isVoted[msg.sender][projectId]) revert AlreadyVoted();
        if (!projects[projectId].approved) revert NotApproved();
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp > projects[projectId].voteEndDate)
            revert VoteEnded();

        isVoted[msg.sender][projectId] = true;

        Project storage project = projects[projectId];
        if (voteFor) project.votedFor++;
        else project.votedAgainst++;

        emit ProjectVoted(projectId, msg.sender, voteFor);

        token.burnFrom(msg.sender, amount);
    }
}
