// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Crowdfunding} from "../src/Crowdfunding.sol";

contract CrowdfundingTest is Test {
    Crowdfunding cf;
    address creator = makeAddr("creator");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    uint256 constant GOAL = 5 ether;
    uint256 constant DURATION = 7 days;
    uint256 start;

    function setUp() public {
        start = block.timestamp;
        vm.prank(creator);
        cf = new Crowdfunding(GOAL, DURATION);
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
    }

    function _give(address who, uint256 amount) internal {
        vm.prank(who);
        cf.contribute{value: amount}();
    }

    function _afterDeadline() internal {
        vm.warp(start + DURATION);
    }

    // rule 1
    function test_ConstructorSetsFields() public view {
        assertEq(cf.creator(), creator);
        assertEq(cf.goal(), GOAL);
        assertEq(cf.deadline(), start + DURATION);
    }

    function test_ZeroGoalReverts() public {
        vm.expectRevert();
        new Crowdfunding(0, DURATION);
    }

    // rule 2
    function test_ContributeRecords() public {
        _give(alice, 1 ether);
        _give(alice, 2 ether);
        _give(bob, 1 ether);
        assertEq(cf.contributions(alice), 3 ether);
        assertEq(cf.totalRaised(), 4 ether);
    }

    function test_ZeroContributionReverts() public {
        vm.prank(alice);
        vm.expectRevert();
        cf.contribute{value: 0}();
    }

    function test_ContributeAtDeadlineReverts() public {
        _afterDeadline();
        vm.prank(alice);
        vm.expectRevert();
        cf.contribute{value: 1 ether}();
    }

    function test_ContributeAfterGoalBeforeDeadline() public {
        _give(alice, 5 ether);
        _give(bob, 1 ether);                   // still allowed
        assertEq(cf.totalRaised(), 6 ether);
    }

    // rules 3 and 4
    function test_ClaimWhenGoalExactlyReached() public {
        _give(alice, 3 ether);
        _give(bob, 2 ether);                   // exactly 5 ether = goal
        _afterDeadline();
        vm.prank(creator);
        cf.claim();
        assertEq(creator.balance, 5 ether);
        assertTrue(cf.claimed());
    }

    function test_ClaimBeforeDeadlineReverts() public {
        _give(alice, 6 ether);
        vm.prank(creator);
        vm.expectRevert();
        cf.claim();
    }

    function test_ClaimByOtherReverts() public {
        _give(alice, 6 ether);
        _afterDeadline();
        vm.prank(alice);
        vm.expectRevert();
        cf.claim();
    }

    function test_ClaimGoalNotReachedReverts() public {
        _give(alice, 1 ether);
        _afterDeadline();
        vm.prank(creator);
        vm.expectRevert();
        cf.claim();
    }

    function test_ClaimTwiceReverts() public {
        _give(alice, 6 ether);
        _afterDeadline();
        vm.startPrank(creator);
        cf.claim();
        vm.expectRevert();
        cf.claim();
        vm.stopPrank();
    }

    // rules 5 and 6
    function test_RefundWhenGoalMissed() public {
        _give(alice, 2 ether);
        _give(bob, 1 ether);
        _afterDeadline();
        vm.prank(alice);
        cf.refund();
        assertEq(alice.balance, 10 ether);
        assertEq(cf.contributions(alice), 0);
        assertEq(cf.totalRaised(), 3 ether);    // rule 6: does not decrease
    }

    function test_RefundBeforeDeadlineReverts() public {
        _give(alice, 1 ether);
        vm.prank(alice);
        vm.expectRevert();
        cf.refund();
    }

    function test_RefundWhenGoalReachedReverts() public {
        _give(alice, 6 ether);
        _afterDeadline();
        vm.prank(alice);
        vm.expectRevert();
        cf.refund();
    }

    function test_RefundTwiceReverts() public {
        _give(alice, 1 ether);
        _give(bob, 1 ether);                   // bob's ETH must stay safe
        _afterDeadline();
        vm.startPrank(alice);
        cf.refund();
        vm.expectRevert();
        cf.refund();
        vm.stopPrank();
        assertEq(address(cf).balance, 1 ether);
    }

    function test_RefundWithoutContributionReverts() public {
        _give(alice, 1 ether);
        _afterDeadline();
        vm.prank(bob);
        vm.expectRevert();
        cf.refund();
    }
}
