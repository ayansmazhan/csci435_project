// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Escrow {
    address public immutable buyer;
    address public immutable seller;
    address public immutable arbiter;
    bool public settled;

    constructor(address seller_, address arbiter_) payable {
        require(msg.value > 0, "no deposit");
        require(seller_ != address(0) && arbiter_ != address(0), "zero address");
        buyer = msg.sender;
        seller = seller_;
        arbiter = arbiter_;
    }

    function release() external {
        require(msg.sender == buyer || msg.sender == arbiter, "not allowed");
        require(!settled, "already settled");
        settled = true;
        (bool ok, ) = seller.call{value: address(this).balance}("");
        require(ok, "payment failed");
    }

    function refund() external {
        require(msg.sender == seller || msg.sender == arbiter, "not allowed");
        require(!settled, "already settled");
        settled = true;
        (bool ok, ) = buyer.call{value: address(this).balance}("");
        require(ok, "payment failed");
    }

    // No receive() or fallback(): plain ETH transfers to this contract revert automatically.
}
