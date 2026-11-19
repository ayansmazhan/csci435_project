// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Escrow {
    address public buyer;
    address public seller;
    address public arbiter;
    bool public settled;

    constructor(address seller_, address arbiter_) payable {
        require(msg.value > 0, "ETH must be sent");
        require(seller_ != address(0), "Invalid seller");
        require(arbiter_ != address(0), "Invalid arbiter");
        buyer = msg.sender;
        seller = seller_;
        arbiter = arbiter_;
    }

    function release() external {
        require(!settled, "Deal already settled");
        require(msg.sender == buyer || msg.sender == arbiter, "Unauthorized");
        payable(seller).transfer(address(this).balance);
        settled = true;
    }

    function refund() external {
        require(!settled, "Deal already settled");
        require(msg.sender == seller || msg.sender == arbiter, "Unauthorized");
        payable(buyer).transfer(address(this).balance);
        settled = true;
    }
}
