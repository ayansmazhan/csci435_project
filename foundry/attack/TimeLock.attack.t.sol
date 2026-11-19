// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {TimeLock} from "../src/TimeLock.sol";

// Re-enters withdraw() every time it receives ETH, while the vault still has money.
contract Attacker {
    TimeLock target;
    uint256 amount;
    constructor(TimeLock t) { target = t; }
    function deposit() external payable {
        amount = msg.value;
        target.deposit{value: msg.value}(0);                   // unlocked immediately
    }
    function attack() external {
        target.withdraw();
    }
    receive() external payable {
        if (address(target).balance >= amount) {
            address(target).call(abi.encodeCall(TimeLock.withdraw, ()));
        }
    }
}

contract TimeLockAttackTest is Test {
    function test_ReentrancyCannotStealOthersFunds() public {
        TimeLock vault = new TimeLock();
        address victim = makeAddr("victim");
        vm.deal(victim, 5 ether);
        vm.prank(victim);
        vault.deposit{value: 5 ether}(0);

        Attacker a = new Attacker(vault);
        vm.deal(address(this), 1 ether);
        a.deposit{value: 1 ether}();
        vm.warp(block.timestamp + 1);
        try a.attack() {} catch {}

        assertLe(address(a).balance, 1 ether, "attacker stole funds");
    }
}
