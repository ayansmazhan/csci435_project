// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Auction} from "../src/Auction.sol";

// A bidder contract with no receive() function: any ETH sent to it is rejected.
contract RejectingBidder {
    function placeBid(Auction a) external payable {
        a.bid{value: msg.value}();
    }
}

contract AuctionTest is Test {
    Auction auction;
    address seller = makeAddr("seller");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    uint256 constant DURATION = 1 days;
    uint256 start;

    function setUp() public {
        start = block.timestamp;
        vm.prank(seller);
        auction = new Auction(DURATION);
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
    }

    // rule 1
    function test_ConstructorSetsSellerAndEndTime() public view {
        assertEq(auction.seller(), seller);
        assertEq(auction.endTime(), start + DURATION);
    }

    // rule 2
    function test_FirstBidBecomesHighest() public {
        vm.prank(alice);
        auction.bid{value: 1 ether}();
        assertEq(auction.highestBidder(), alice);
        assertEq(auction.highestBid(), 1 ether);
    }

    function test_ZeroBidReverts() public {
        vm.prank(alice);
        vm.expectRevert();
        auction.bid{value: 0}();
    }

    function test_EqualBidReverts() public {
        vm.prank(alice);
        auction.bid{value: 1 ether}();
        vm.prank(bob);
        vm.expectRevert();
        auction.bid{value: 1 ether}();
    }

    function test_BidAfterEndTimeReverts() public {
        vm.warp(start + DURATION);              // jump forward in time
        vm.prank(alice);
        vm.expectRevert();
        auction.bid{value: 1 ether}();
    }

    function test_OutbidIsRecordedNotSent() public {
        vm.prank(alice);
        auction.bid{value: 1 ether}();
        vm.prank(bob);
        auction.bid{value: 2 ether}();
        assertEq(auction.pendingReturns(alice), 1 ether);
        assertEq(alice.balance, 9 ether);       // not refunded automatically
        assertEq(auction.highestBidder(), bob);
    }

    function test_OutbiddingYourselfAddsToPendingReturns() public {
        vm.startPrank(alice);
        auction.bid{value: 1 ether}();
        auction.bid{value: 3 ether}();
        vm.stopPrank();
        assertEq(auction.pendingReturns(alice), 1 ether);
        assertEq(auction.highestBid(), 3 ether);
    }

    function test_PendingReturnsAccumulate() public {
        vm.prank(alice);
        auction.bid{value: 1 ether}();
        vm.prank(bob);
        auction.bid{value: 2 ether}();          // alice: 1 pending
        vm.prank(alice);
        auction.bid{value: 3 ether}();          // bob: 2 pending
        vm.prank(bob);
        auction.bid{value: 4 ether}();          // alice: 1 + 3 = 4 pending
        assertEq(auction.pendingReturns(alice), 4 ether);
        assertEq(auction.pendingReturns(bob), 2 ether);
    }

    // rule 3
    function test_WithdrawReturnsFunds() public {
        vm.prank(alice);
        auction.bid{value: 1 ether}();
        vm.prank(bob);
        auction.bid{value: 2 ether}();
        vm.prank(alice);
        auction.withdraw();
        assertEq(alice.balance, 10 ether);
        assertEq(auction.pendingReturns(alice), 0);
    }

    function test_WithdrawWithNothingDoesNotRevert() public {
        vm.prank(alice);
        auction.withdraw();
        assertEq(alice.balance, 10 ether);
    }

    function test_HighestBidderCannotWithdrawCurrentBid() public {
        vm.prank(alice);
        auction.bid{value: 1 ether}();
        vm.prank(alice);
        auction.withdraw();
        assertEq(alice.balance, 9 ether);
        assertEq(address(auction).balance, 1 ether);
    }

    // rule 4
    function test_EndBeforeTimeReverts() public {
        vm.expectRevert();
        auction.end();
    }

    function test_EndPaysSeller() public {
        vm.prank(alice);
        auction.bid{value: 1 ether}();
        vm.prank(bob);
        auction.bid{value: 2 ether}();
        vm.warp(start + DURATION);
        auction.end();
        assertTrue(auction.ended());
        assertEq(seller.balance, 2 ether);
        assertEq(address(auction).balance, 1 ether);   // alice's refund is still waiting
    }

    function test_EndTwiceReverts() public {
        vm.warp(start + DURATION);
        auction.end();
        vm.expectRevert();
        auction.end();
    }

    function test_EndWithNoBids() public {
        vm.warp(start + DURATION);
        auction.end();
        assertTrue(auction.ended());
        assertEq(seller.balance, 0);
    }

    // rule 5
    function test_RejectingBidderCannotBlockBids() public {
        RejectingBidder bad = new RejectingBidder();
        bad.placeBid{value: 1 ether}(auction);
        vm.prank(alice);
        auction.bid{value: 2 ether}();          // must still work
        assertEq(auction.highestBidder(), alice);
    }
}
