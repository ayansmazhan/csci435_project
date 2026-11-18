// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {TimeLock} from "../src/TimeLock.sol";

contract TimeLockTest is Test {
    TimeLock lock;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    uint256 start;

    function setUp() public {
        start = block.timestamp;
        lock = new TimeLock();
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
    }

    // rule 1
    function test_DepositRecordsBalanceAndUnlockTime() public {
        vm.prank(alice);
        lock.deposit{value: 1 ether}(1 days);
        assertEq(lock.balanceOf(alice), 1 ether);
        assertEq(lock.unlockTime(alice), start + 1 days);
    }

    function test_ZeroDepositReverts() public {
        vm.prank(alice);
        vm.expectRevert();
        lock.deposit{value: 0}(1 days);
    }

    function test_ShorterDepositKeepsLaterUnlock() public {
        vm.startPrank(alice);
        lock.deposit{value: 1 ether}(7 days);
        lock.deposit{value: 1 ether}(1 days);    // must not shorten the lock
        vm.stopPrank();
        assertEq(lock.unlockTime(alice), start + 7 days);
        assertEq(lock.balanceOf(alice), 2 ether);
    }

    function test_LongerDepositExtendsUnlock() public {
        vm.startPrank(alice);
        lock.deposit{value: 1 ether}(1 days);
        lock.deposit{value: 1 ether}(7 days);
        vm.stopPrank();
        assertEq(lock.unlockTime(alice), start + 7 days);
    }

    // rule 2
    function test_IncreaseLockTimeAdds() public {
        vm.startPrank(alice);
        lock.deposit{value: 1 ether}(1 days);
        lock.increaseLockTime(2 days);
        vm.stopPrank();
        assertEq(lock.unlockTime(alice), start + 3 days);
    }

    function test_IncreaseLockTimeWithoutBalanceReverts() public {
        vm.prank(alice);
        vm.expectRevert();
        lock.increaseLockTime(1 days);
    }

    function test_HugeIncreaseCannotUnlockEarly() public {
        vm.startPrank(alice);
        lock.deposit{value: 1 ether}(7 days);
        uint256 before = lock.unlockTime(alice);
        // Try to wrap the unlock time around to a small number (an overflow attack).
        // The call may revert or succeed; either is fine as long as the lock is not shortened.
        uint256 extra = type(uint256).max - before + 1;
        (bool ok, ) = address(lock).call(abi.encodeCall(TimeLock.increaseLockTime, (extra)));
        ok;                                       // result deliberately ignored
        assertGe(lock.unlockTime(alice), before);
        vm.expectRevert();
        lock.withdraw();                          // still locked
        vm.stopPrank();
    }

    // rule 3
    function test_WithdrawBeforeUnlockReverts() public {
        vm.prank(alice);
        lock.deposit{value: 1 ether}(1 days);
        vm.warp(start + 1 days - 1);
        vm.prank(alice);
        vm.expectRevert();
        lock.withdraw();
    }

    function test_WithdrawAtUnlockTime() public {
        vm.prank(alice);
        lock.deposit{value: 1 ether}(1 days);
        vm.warp(start + 1 days);
        vm.prank(alice);
        lock.withdraw();
        assertEq(alice.balance, 10 ether);
        assertEq(lock.balanceOf(alice), 0);
    }

    function test_WithdrawWithNoBalanceReverts() public {
        vm.prank(alice);
        vm.expectRevert();
        lock.withdraw();
    }

    // rule 4
    function test_UsersOnlyWithdrawOwnFunds() public {
        vm.prank(alice);
        lock.deposit{value: 1 ether}(1 days);
        vm.prank(bob);
        lock.deposit{value: 3 ether}(1 days);
        vm.warp(start + 1 days);
        vm.prank(alice);
        lock.withdraw();
        assertEq(alice.balance, 10 ether);
        assertEq(address(lock).balance, 3 ether);   // bob's ETH untouched
        vm.prank(alice);
        vm.expectRevert();
        lock.withdraw();                            // alice has nothing left
    }
}
