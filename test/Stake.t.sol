// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../contracts/Stake.sol";
import "../contracts/NxtuToken.sol";
import "../contracts/Governance.sol";
import "../contracts/interfaces/IStake.sol";

//solhint-disable
import "forge-std/Test.sol";
import "forge-std/StdUtils.sol";
import "forge-std/console.sol";

contract StakeTest is Test {
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
    NxtuToken public t;
    Stake public s;
    Governance public g;
    address public token;
    address public stake;
    address public gov;
    address public deployer;
    uint256 public minAmountToVote = 1 * 10**8;
    uint256 public amountToApply = 500 * 10**8;

    // function prep(address user, string memory name) public {
    //     vm.label(user, name);
    //     vm.deal(user, 1 << 128);
    //     t.mint(user, 1000000 * 10**18);
    //     vm.prank(user);
    //     t.approve(stake, type(uint256).max);
    //     vm.prank(user);
    //     t.approve(gov, type(uint256).max);
    // }

    function setUp() public {
        t = new NxtuToken(500000000000000 * 10**8);
        s = new Stake(token, gov);
        g = new Governance(token);

        token = address(t);
        stake = address(s);
        gov = address(g);

        vm.label(token, "TOKEN");
        vm.label(stake, "STAKE");
        vm.label(gov, "GOVERNANCE");

        deployer = address(this);
        vm.label(deployer, "DEPLOYER");

        t.approve(stake, type(uint256).max);
        t.approve(gov, type(uint256).max);
    }

    function test_burnFrom() public {
        // console.log(
        //     "allowance",
        //     t.allowance(deployer, gov) == type(uint256).max
        // );
        g.testBurn(1);
    }

    function test_apply() public {
        vm.expectEmit();
        emit ProjectApplied(1);
        g.applyProject();
    }

    function test_vote() public {
        vm.expectEmit();
        emit ProjectApplied(1);
        g.applyProject();

        vm.expectEmit();
        emit ProjectApproved(
            1,
            "name",
            "desc",
            "url",
            24_000, //apr
            90 days, // lockedTime
            90, // vote end time
            30 days // stake end time
        );
        g.approveProject(
            1,
            "name",
            "desc",
            "url",
            24_000, //apr
            90 days, // lockedTime
            90, // vote end time
            30 days // stake end time
        );

        //solhint-disable
        (
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
        ) = g.projects(1);
        //solhint-enable

        assertEq(approved, true);
        assertEq(applied, true);

        vm.expectEmit();
        emit ProjectVoted(1, deployer, true);
        g.voteProject(1, true, minAmountToVote);
    }
}
