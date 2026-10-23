// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {PiggyBank} from "../src/PiggyBank.sol";

contract PiggyBankTest is Test {
    PiggyBank bank;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        bank = new PiggyBank();
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
    }

    function test_DepositIncreasesBalance() public {          // rule 1
        vm.prank(alice);
        bank.deposit{value: 1 ether}();
        assertEq(bank.balanceOf(alice), 1 ether);
    }

    function test_DepositZeroReverts() public {               // rule 1
        vm.prank(alice);
        vm.expectRevert();
        bank.deposit{value: 0}();
    }

    function test_WithdrawSendsEth() public {                 // rules 2, 3
        vm.startPrank(alice);
        bank.deposit{value: 2 ether}();
        bank.withdraw(0.5 ether);
        vm.stopPrank();
        assertEq(bank.balanceOf(alice), 1.5 ether);
        assertEq(alice.balance, 8.5 ether);
    }

    function test_CannotWithdrawMoreThanBalance() public {    // rule 2
        vm.startPrank(alice);
        bank.deposit{value: 1 ether}();
        vm.expectRevert();
        bank.withdraw(2 ether);
        vm.stopPrank();
    }

    function test_CannotWithdrawOthersFunds() public {        // rule 4
        vm.prank(alice);
        bank.deposit{value: 1 ether}();
        vm.prank(bob);
        vm.expectRevert();
        bank.withdraw(1 ether);
    }
}
