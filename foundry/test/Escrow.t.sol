// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Escrow} from "../src/Escrow.sol";

contract EscrowTest is Test {
    Escrow escrow;
    address buyer = makeAddr("buyer");
    address seller = makeAddr("seller");
    address arbiter = makeAddr("arbiter");
    address stranger = makeAddr("stranger");

    function setUp() public {
        vm.deal(buyer, 10 ether);
        vm.prank(buyer);
        escrow = new Escrow{value: 1 ether}(seller, arbiter);
    }

    // rule 1
    function test_ConstructorSetsParties() public view {
        assertEq(escrow.buyer(), buyer);
        assertEq(escrow.seller(), seller);
        assertEq(escrow.arbiter(), arbiter);
        assertEq(address(escrow).balance, 1 ether);
        assertFalse(escrow.settled());
    }

    function test_ConstructorWithoutEthReverts() public {
        vm.prank(buyer);
        vm.expectRevert();
        new Escrow(seller, arbiter);
    }

    function test_ConstructorZeroSellerReverts() public {
        vm.prank(buyer);
        vm.expectRevert();
        new Escrow{value: 1 ether}(address(0), arbiter);
    }

    function test_ConstructorZeroArbiterReverts() public {
        vm.prank(buyer);
        vm.expectRevert();
        new Escrow{value: 1 ether}(seller, address(0));
    }

    // rule 2
    function test_BuyerCanRelease() public {
        vm.prank(buyer);
        escrow.release();
        assertEq(seller.balance, 1 ether);
        assertEq(address(escrow).balance, 0);
        assertTrue(escrow.settled());
    }

    function test_ArbiterCanRelease() public {
        vm.prank(arbiter);
        escrow.release();
        assertEq(seller.balance, 1 ether);
    }

    function test_SellerCannotRelease() public {
        vm.prank(seller);
        vm.expectRevert();
        escrow.release();
    }

    function test_StrangerCannotRelease() public {
        vm.prank(stranger);
        vm.expectRevert();
        escrow.release();
    }

    // rule 3
    function test_SellerCanRefund() public {
        vm.prank(seller);
        escrow.refund();
        assertEq(buyer.balance, 10 ether);        // 9 left after deposit + 1 back
        assertTrue(escrow.settled());
    }

    function test_ArbiterCanRefund() public {
        vm.prank(arbiter);
        escrow.refund();
        assertEq(buyer.balance, 10 ether);
    }

    function test_BuyerCannotRefund() public {
        vm.prank(buyer);
        vm.expectRevert();
        escrow.refund();
    }

    function test_StrangerCannotRefund() public {
        vm.prank(stranger);
        vm.expectRevert();
        escrow.refund();
    }

    // rule 4
    function test_CannotReleaseTwice() public {
        vm.prank(buyer);
        escrow.release();
        vm.prank(arbiter);
        vm.expectRevert();
        escrow.release();
    }

    function test_CannotRefundAfterRelease() public {
        vm.prank(buyer);
        escrow.release();
        vm.prank(arbiter);
        vm.expectRevert();
        escrow.refund();
    }

    // rule 5
    function test_RejectsPlainEth() public {
        vm.deal(stranger, 1 ether);
        vm.prank(stranger);
        (bool ok, ) = address(escrow).call{value: 1 ether}("");
        assertFalse(ok);
    }
}
