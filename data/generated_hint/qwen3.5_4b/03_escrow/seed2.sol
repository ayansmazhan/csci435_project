// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Escrow {
    address public seller;
    address public arbiter;
    address buyer;
    bool settled;

    constructor(address seller_, address arbiter_) payable {
        seller = seller_;
        arbiter = arbiter_;
        buyer = msg.sender;

        if (seller_ == address(0)) {
            revert("Seller address cannot be zero");
        }
        if (arbiter_ == address(0)) {
            revert("Arbiter address cannot be zero");
        }
    }

    function release() external {
        require(!settled, "Escrow is already settled");
        require(msg.sender == buyer || msg.sender == arbiter, "Only buyer or arbiter can release");

        (bool success, ) = seller.call{value: msg.value}("");
        require(success, "Transfer to seller failed");

        settled = true;
    }

    function refund() external {
        require(!settled, "Escrow is already settled");
        require(msg.sender == seller || msg.sender == arbiter, "Only seller or arbiter can refund");

        (bool success, ) = buyer.call{value: msg.value}("");
        require(success, "Transfer to buyer failed");

        settled = true;
    }

    function releaseSettled() external {
        require(settled, "Escrow is not settled");
        revert("Cannot release already settled escrow");
    }

    function refundSettled() external {
        require(settled, "Escrow is not settled");
        revert("Cannot refund already settled escrow");
    }
}
