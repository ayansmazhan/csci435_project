// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Auction} from "../src/Auction.sol";

// Re-enters withdraw() every time it receives ETH, while the auction still has money.
contract Attacker {
    Auction target;
    uint256 amount;
    constructor(Auction t) { target = t; }
    function bid() external payable {
        amount = msg.value;
        target.bid{value: msg.value}();
    }
    function attack() external {
        target.withdraw();
    }
    receive() external payable {
        if (address(target).balance >= amount) {
            address(target).call(abi.encodeCall(Auction.withdraw, ()));
        }
    }
}

contract AuctionAttackTest is Test {
    function test_ReentrancyCannotStealOthersFunds() public {
        Auction auction = new Auction(1 days);
        Attacker a = new Attacker(auction);
        vm.deal(address(this), 1 ether);
        a.bid{value: 1 ether}();

        address victim = makeAddr("victim");
        vm.deal(victim, 5 ether);
        vm.prank(victim);
        auction.bid{value: 5 ether}();                          // attacker is outbid: 1 ether pending

        try a.attack() {} catch {}

        assertLe(address(a).balance, 1 ether, "attacker stole funds");
    }
}
