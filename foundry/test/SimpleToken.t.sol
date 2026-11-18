// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {SimpleToken} from "../src/SimpleToken.sol";

contract SimpleTokenTest is Test {
    // Declared here so the test can check that the right events are emitted
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    SimpleToken token;
    address owner = makeAddr("owner");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    uint256 constant SUPPLY = 1000;

    function setUp() public {
        vm.prank(owner);                       // owner deploys the token
        token = new SimpleToken(SUPPLY);
    }

    // rule 1
    function test_ConstructorGivesSupplyToDeployer() public view {
        assertEq(token.totalSupply(), SUPPLY);
        assertEq(token.balanceOf(owner), SUPPLY);
    }

    // rule 2
    function test_TransferMovesTokens() public {
        vm.prank(owner);
        bool ok = token.transfer(alice, 100);
        assertTrue(ok);
        assertEq(token.balanceOf(owner), SUPPLY - 100);
        assertEq(token.balanceOf(alice), 100);
    }

    function test_TransferEmitsEvent() public {
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, alice, 100);
        vm.prank(owner);
        token.transfer(alice, 100);
    }

    function test_TransferMoreThanBalanceReverts() public {
        vm.prank(alice);                       // alice has 0 tokens
        vm.expectRevert();
        token.transfer(bob, 1);
    }

    function test_TransferToZeroAddressReverts() public {
        vm.prank(owner);
        vm.expectRevert();
        token.transfer(address(0), 1);
    }

    function test_TransferZeroTokensAllowed() public {
        vm.prank(alice);
        assertTrue(token.transfer(bob, 0));
    }

    // rule 3
    function test_ApproveSetsAndReplacesAllowance() public {
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, alice, 50);
        assertTrue(token.approve(alice, 50));
        token.approve(alice, 20);              // replaces, does not add
        vm.stopPrank();
        assertEq(token.allowance(owner, alice), 20);
    }

    // rule 4
    function test_TransferFromUsesAllowance() public {
        vm.prank(owner);
        token.approve(alice, 50);
        vm.prank(alice);
        assertTrue(token.transferFrom(owner, bob, 30));
        assertEq(token.balanceOf(bob), 30);
        assertEq(token.balanceOf(owner), SUPPLY - 30);
        assertEq(token.allowance(owner, alice), 20);
    }

    function test_TransferFromWithoutAllowanceReverts() public {
        vm.prank(alice);                       // owner never approved alice
        vm.expectRevert();
        token.transferFrom(owner, bob, 1);
    }

    function test_TransferFromAboveAllowanceReverts() public {
        vm.prank(owner);
        token.approve(alice, 10);
        vm.prank(alice);
        vm.expectRevert();
        token.transferFrom(owner, bob, 11);
    }

    function test_TransferFromAboveBalanceReverts() public {
        vm.prank(alice);
        token.approve(bob, 100);               // alice approves bob, but alice has 0 tokens
        vm.prank(bob);
        vm.expectRevert();
        token.transferFrom(alice, bob, 1);
    }

    // rule 5
    function test_TotalSupplyNeverChanges() public {
        vm.prank(owner);
        token.transfer(alice, 300);
        vm.prank(alice);
        token.approve(bob, 100);
        vm.prank(bob);
        token.transferFrom(alice, bob, 100);
        assertEq(token.totalSupply(), SUPPLY);
        assertEq(token.balanceOf(owner) + token.balanceOf(alice) + token.balanceOf(bob), SUPPLY);
    }
}
