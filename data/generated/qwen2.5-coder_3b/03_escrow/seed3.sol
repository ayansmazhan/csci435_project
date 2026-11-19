pragma solidity ^0.8.24;

contract Escrow {
    address public buyer;
    address public seller;
    address public arbiter;
    bool public settled;

    constructor(address seller_, address arbiter_) payable {
        require(msg.value > 0, "No ETH sent");
        require(seller_ != address(0), "Seller cannot be zero address");
        require(arbiter_ != address(0), "Arbiter cannot be zero address");

        buyer = msg.sender;
        seller = seller_;
        arbiter = arbiter_;
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
        require(msg.sender == buyer || msg.sender == arbiter, "Only buyer or arbiter can release");
        require(!settled, "Escrow is already settled");

        payable(seller).transfer(address(this).balance);
        settled = true;
    }

    function refund() external {
        require(msg.sender == seller || msg.sender == arbiter, "Only seller or arbiter can refund");
        require(!settled, "Escrow is already settled");

        payable(buyer).transfer(address(this).balance);
        settled = true;
    }
}
