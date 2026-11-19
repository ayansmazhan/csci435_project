// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MultiSig {
    address owner1;
    address owner2;
    address owner3;
    
    uint256 transactionCount;
    
    struct Transaction {
        address to;
        uint256 value;
        bool executed;
        mapping(address => bool) confirmedBy;
    }

    Transaction[] transactions;

    constructor(address owner1_, address owner2_, address owner3_) {
        require(owner1_ != address(0), "Owner cannot be zero address");
        require(owner2_ != address(0), "Owner cannot be zero address");
        require(owner3_ != address(0), "Owner cannot be zero address");
        require(owner1_ != owner2_, "Owners must be different");
        require(owner1_ != owner3_, "Owners must be different");
        require(owner2_ != owner3_, "Owners must be different");
        
        owner1 = owner1_;
        owner2 = owner2_;
        owner3 = owner3_;
    }

    receive() external payable {}

    function isOwner(address account) external view returns (bool) {
        return account == owner1 || account == owner2 || account == owner3;
    }

    function transactionCount() external view returns (uint256) {
        return transactionCount;
    }

    function submit(address to, uint256 value) external returns (uint256 txId) {
        require(isOwner(msg.sender), "Caller must be an owner");
        
        Transaction storage newTx = transactions[transactionCount];
        newTx.to = to;
        newTx.value = value;
        newTx.executed = false;
        delete newTx.confirmedBy[msg.sender];
        
        transactions[transactionCount] = newTx;
        return transactionCount++;
    }

    function confirm(uint256 txId) external {
        require(txId < transactionCount, "Transaction does not exist");
        Transaction storage tx = transactions[txId];
        
        require(!tx.executed, "Transaction has already been executed");
        require(!tx.confirmedBy[msg.sender], "Already confirmed by current owner");

        tx.confirmations++;
        tx.confirmedBy[msg.sender] = true;
    }

    function execute(uint256 txId) external {
        require(txId < transactionCount, "Transaction does not exist");
        Transaction storage tx = transactions[txId];
        
        require(!tx.executed, "Transaction has already been executed");
        require(tx.confirmations >= 2, "Insufficient confirmations");

        tx.executed = true;
        payable(tx.to).transfer(tx.value);
    }

    function isConfirmed(uint256 txId, address owner) external view returns (bool) {
        require(txId < transactionCount, "Transaction does not exist");
        return transactions[txId].confirmedBy[owner];
    }

    function getTransaction(uint256 txId) external view returns (address to, uint256 value, bool executed, uint256 numConfirmations) {
        require(txId < transactionCount, "Transaction does not exist");
        Transaction storage tx = transactions[txId];
        return (tx.to, tx.value, tx.executed, tx.confirmations);
    }
}
