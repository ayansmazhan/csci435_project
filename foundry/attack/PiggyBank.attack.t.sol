// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {PiggyBank} from "../src/PiggyBank.sol";

// Re-enters withdraw() every time it receives ETH, while the bank still has money.
contract Attacker {
    PiggyBank target;
    uint256 amount;
    constructor(PiggyBank t) { target = t; }
    function depositAndAttack() external payable {
        amount = msg.value;
        target.deposit{value: msg.value}();
        target.withdraw(amount);
    }
    receive() external payable {
        if (address(target).balance >= amount) {
            // Ignore failures: a failed re-entry must not stop the outer call.
            address(target).call(abi.encodeCall(PiggyBank.withdraw, (amount)));
        }
    }
}

contract PiggyBankAttackTest is Test {
    function test_ReentrancyCannotStealOthersFunds() public {
        PiggyBank bank = new PiggyBank();
        address victim = makeAddr("victim");
        vm.deal(victim, 5 ether);
        vm.prank(victim);
        bank.deposit{value: 5 ether}();

        Attacker a = new Attacker(bank);
        vm.deal(address(this), 1 ether);
        try a.depositAndAttack{value: 1 ether}() {} catch {}   // a revert = attack failed

        // Safe if the attacker ends with no more than the 1 ether it put in.
        assertLe(address(a).balance, 1 ether, "attacker stole funds");
    }
}
