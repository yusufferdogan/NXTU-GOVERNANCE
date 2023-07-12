// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

interface INXTU is IERC20 {
    function burnFrom(address account, uint256 amount) external;
}

contract Governance is Ownable {
    error LessThanMinAmount();
    error ProjectDoesNotExist();
    error AlreadyVoted();
    error VoteEnded();

    event ProjectCreated(
        uint256 indexed id,
        string name,
        string description,
        string url,
        uint256 voteEndDate,
        uint256 unstakeDate,
        uint256 apr
    );
    event ProjectVoted(
        uint256 indexed projectId,
        address indexed user,
        bool votedFor
    );

    INXTU public immutable token;
    uint256 public projectCount;
    uint256 public minAmountToVote = 1 * 10**8;

    struct Project {
        string name;
        string description;
        string url;
        uint256 apr;
        uint256 unstakeDate;
        uint256 voteEndDate;
        uint256 votedFor;
        uint256 votedAgainst;
    }

    constructor(address _token) {
        token = INXTU(_token);
    }

    mapping(uint256 => Project) public projects;
    mapping(address => mapping(uint256 => bool)) public isVoted;

    function addProject(
        string calldata _name,
        string calldata _description,
        string calldata _url,
        uint256 _apr,
        uint256 _unstakeDate,
        uint256 _voteEndDate
    ) external onlyOwner {
        projects[++projectCount] = Project({
            name: _name,
            description: _description,
            url: _url,
            apr: _apr,
            unstakeDate: _unstakeDate,
            voteEndDate: _voteEndDate,
            votedFor: 0,
            votedAgainst: 0
        });
        emit ProjectCreated(
            projectCount,
            _name,
            _description,
            _url,
            _voteEndDate,
            _unstakeDate,
            _apr
        );
    }

    function voteProject(
        uint256 projectId,
        bool voteFor,
        uint256 amount
    ) external {
        if (amount < minAmountToVote) revert LessThanMinAmount();
        if (projectId > projectCount) revert ProjectDoesNotExist();
        if (isVoted[msg.sender][projectId]) revert AlreadyVoted();
        // solhint-disable-next-line not-rely-on-time
        if (projects[projectId].voteEndDate > block.timestamp)
            revert VoteEnded();

        isVoted[msg.sender][projectId] = true;

        Project storage project = projects[projectId];
        if (voteFor) project.votedFor++;
        else project.votedAgainst++;

        token.burnFrom(msg.sender, amount);
    }
}
