// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IGovernanceError.sol";

interface INXTU is IERC20 {
    function burnFrom(address account, uint256 amount) external;

    function burn(uint256 amount) external;
}

contract Governance is AccessControl, IGovernanceError, Pausable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant APPROVER_ROLE = keccak256("APPROVER_ROLE");

    INXTU public immutable token;
    //shows all applied or approved projects count
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
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(APPROVER_ROLE, msg.sender);
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

    // apply your project via burning tokens
    function applyProject() external {
        projects[++projectCount].applied = true;
        token.burnFrom(msg.sender, amountToApply);
        emit ProjectApplied(projectCount);
    }

    //owner approves the applied projects
    function approveProject(
        uint256 projectId,
        string calldata _name,
        string calldata _description,
        string calldata _url,
        uint256 _apr,
        uint256 _lockedTime,
        uint256 _voteEndDate,
        uint256 _stakeEndDate
    ) external onlyRole(APPROVER_ROLE) {
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

    // users can vote projects , if they want that this project should pass the voting
    // voteFor = true else false
    // projectId specifies the projectID
    // amount can be any amount which is more than or equal to minVoteAmount
    function voteProject(
        uint256 projectId,
        bool voteFor,
        uint256 amount
    ) external whenNotPaused {
        if (amount < minAmountToVote) revert LessThanMinAmount();
        if (isVoted[msg.sender][projectId]) revert AlreadyVoted();
        if (!projects[projectId].approved) revert NotApproved();
        if (block.timestamp > projects[projectId].voteEndDate)
            revert VoteEnded();

        isVoted[msg.sender][projectId] = true;

        Project storage project = projects[projectId];
        if (voteFor) project.votedFor++;
        else project.votedAgainst++;

        emit ProjectVoted(projectId, msg.sender, voteFor);

        token.burnFrom(msg.sender, amount);
    }

    function setMinAmountToVote(uint256 amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        minAmountToVote = amount;
    }

    function setAmountToApply(uint256 amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        amountToApply = amount;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }
}
