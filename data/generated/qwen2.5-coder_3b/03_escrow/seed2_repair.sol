pragma solidity ^0.8.24;

contract Escrow {
    address public buyer;
    address public seller;
    address public arbiter;
    bool public settled;

    constructor(address payable _seller, address payable _arbiter) payable {
        require(msg.value > 0, "Escrow requires an amount to be sent");
        require(_seller != address(0), "Seller address cannot be zero");
        require(_arbiter != address(0), "Arbiter address cannot be zero");

        buyer = msg.sender;
        seller = _seller;
        arbiter = _arbiter;
    }

    function buyer() external view returns (address) {
        return buyer;
    }

    function seller() external view returns (address) {
        return seller;
    }

    function arbiter() external view returns (address) {
        return arbiter;
    }

    function settled() external view returns (bool) {
        return settled;
    }

    function release() external {
        require(settled == false, "Escrow is already settled");
        require(msg.sender == buyer || msg.sender == arbiter, "Only buyer or arbiter can release");

        (bool success, ) = seller.call{value: address(this).balance}("");
        require(success, "Failed to release funds");
        settled = true;
    }

    function refund() external {
        require(settled == false, "Escrow is already settled");
        require(msg.sender == seller || msg.sender == arbiter, "Only seller or arbiter can refund");

        (bool success, ) = buyer.call{value: address(this).balance}("");
        require(success, "Failed to refund funds");
        settled = true;
    }
}
