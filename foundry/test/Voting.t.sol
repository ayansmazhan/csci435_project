// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Voting} from "../src/Voting.sol";

contract VotingTest is Test {
    Voting voting;
    address chair = makeAddr("chair");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address carol = makeAddr("carol");

    function setUp() public {
        vm.prank(chair);
        voting = new Voting(3);                // proposals 0, 1, 2
    }

    // helper: chair gives the right to vote, then the voter votes
    function _allowAndVote(address voter, uint256 proposal) internal {
        vm.prank(chair);
        voting.giveRightToVote(voter);
        vm.prank(voter);
        voting.vote(proposal);
    }

    // rule 1
    function test_DeployerIsChairperson() public view {
        assertEq(voting.chairperson(), chair);
    }

    function test_ZeroProposalsReverts() public {
        vm.expectRevert();
        new Voting(0);
    }

    // rule 2
    function test_OnlyChairpersonGivesRight() public {
        vm.prank(alice);
        vm.expectRevert();
        voting.giveRightToVote(bob);
    }

    function test_GivingRightTwiceReverts() public {
        vm.startPrank(chair);
        voting.giveRightToVote(alice);
        vm.expectRevert();
        voting.giveRightToVote(alice);
        vm.stopPrank();
    }

    function test_ChairpersonCannotVoteWithoutRight() public {
        vm.prank(chair);
        vm.expectRevert();
        voting.vote(0);
    }

    function test_ChairpersonCanVoteAfterGivingSelfRight() public {
        _allowAndVote(chair, 1);
        assertEq(voting.voteCount(1), 1);
    }

    // rule 3
    function test_VoteCountsOnce() public {
        _allowAndVote(alice, 2);
        assertEq(voting.voteCount(2), 1);
        assertEq(voting.voteCount(0), 0);
    }

    function test_VoteWithoutRightReverts() public {
        vm.prank(alice);
        vm.expectRevert();
        voting.vote(0);
    }

    function test_DoubleVoteReverts() public {
        _allowAndVote(alice, 0);
        vm.prank(alice);
        vm.expectRevert();
        voting.vote(1);
    }

    function test_InvalidProposalReverts() public {
        vm.prank(chair);
        voting.giveRightToVote(alice);
        vm.prank(alice);
        vm.expectRevert();
        voting.vote(3);                        // only 0, 1, 2 exist
    }

    // rule 4
    function test_HasVoted() public {
        assertFalse(voting.hasVoted(alice));
        _allowAndVote(alice, 0);
        assertTrue(voting.hasVoted(alice));
    }

    // rule 5
    function test_WinningProposalMajority() public {
        _allowAndVote(alice, 2);
        _allowAndVote(bob, 2);
        _allowAndVote(carol, 1);
        assertEq(voting.winningProposal(), 2);
    }

    function test_WinningProposalTieGoesToLowest() public {
        _allowAndVote(alice, 2);
        _allowAndVote(bob, 1);
        assertEq(voting.winningProposal(), 1);
    }

    function test_WinningProposalNoVotes() public view {
        assertEq(voting.winningProposal(), 0);
    }
}
