// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Crowdfunding} from "../src/Crowdfunding.sol";

// Re-enters refund() every time it receives ETH, while the campaign still has money.
contract Attacker {
    Crowdfunding target;
    uint256 amount;
    constructor(Crowdfunding t) { target = t; }
    function contribute() external payable {
        amount = msg.value;
        target.contribute{value: msg.value}();
    }
    function attack() external {
        target.refund();
    }
    receive() external payable {
        if (address(target).balance >= amount) {
            address(target).call(abi.encodeCall(Crowdfunding.refund, ()));
        }
    }
}

contract CrowdfundingAttackTest is Test {
    function test_ReentrancyCannotStealOthersFunds() public {
        Crowdfunding cf = new Crowdfunding(10 ether, 1 days);   // goal will be missed
        address victim = makeAddr("victim");
        vm.deal(victim, 5 ether);
        vm.prank(victim);
        cf.contribute{value: 5 ether}();

        Attacker a = new Attacker(cf);
        vm.deal(address(this), 1 ether);
        a.contribute{value: 1 ether}();

        vm.warp(block.timestamp + 1 days);                       // deadline passed, goal missed
        try a.attack() {} catch {}

        assertLe(address(a).balance, 1 ether, "attacker stole funds");
    }
}
