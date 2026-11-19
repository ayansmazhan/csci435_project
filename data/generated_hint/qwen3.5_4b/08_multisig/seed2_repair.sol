// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MultiSig {
    address private owner1;
    address private owner2;
    address private owner3;

    uint256 public transactionCount;

    struct Transaction {
        address to;
        uint256 value;
        bool executed;
        bool confirmedByOwner1;
        bool confirmedByOwner2;
        bool confirmedByOwner3;
    }

    mapping(uint256 => Transaction) private transactions;

    function isOwner(address account) external view returns (bool) {
        return account == owner1 || account == owner2 || account == owner3;
    }

    constructor(address owner1, address owner2, address owner3) {
        require(owner1 != address(0), "Owner1 cannot be zero address");
        require(owner2 != address(0), "Owner2 cannot be zero address");
        require(owner3 != address(0), "Owner3 cannot be zero address");
        require(owner1 != owner2, "Owner1 and Owner2 must be different");
        require(owner1 != owner3, "Owner1 and Owner3 must be different");
        require(owner2 != owner3, "Owner2 and Owner3 must be different");

        owner1 = owner1;
        owner2 = owner2;
        owner3 = owner3;
    }

    receive() external payable {}

    function submit(address to, uint256 value) external returns (uint256 txId) {
        require(isOwner(msg.sender), "Not an owner");
        
        txId = transactionCount;
        transactions[txId] = Transaction({
            to: to,
            value: value,
            executed: false,
            confirmedByOwner1: false,
            confirmedByOwner2: false,
            confirmedByOwner3: false
        });

        // Increment transaction count for next submission
        transactionCount++;
        
        return txId;
    }

    function confirm(uint256 txId) external {
        require(isOwner(msg.sender), "Not an owner");
        
        Transaction storage tx = transactions[txId];

        require(tx.to != address(0), "Invalid transaction");
        require(!tx.executed, "Transaction already executed");
        
        // Check if this owner has already confirmed this transaction
        bool isThisOwner1 = msg.sender == owner1;
        bool isThisOwner2 = msg.sender == owner2;
        bool isThisOwner3 = msg.sender == owner3;

        require(!tx.confirmedByOwner1 && isThisOwner1, "Already confirmed by Owner1");
        require(!tx.confirmedByOwner2 && isThisOwner2, "Already confirmed by Owner2");
        require(!tx.confirmedByOwner3 && isThisOwner3, "Already confirmed by Owner3");

        if (isThisOwner1) {
            tx.confirmedByOwner1 = true;
        } else if (isThisOwner2) {
            tx.confirmedByOwner2 = true;
        } else if (isThisOwner3) {
            tx.confirmedByOwner3 = true;
        }
    }

    function execute(uint256 txId) external {
        require(isOwner(msg.sender), "Not an owner");
        
        Transaction storage tx = transactions[txId];

        require(tx.to != address(0), "Invalid transaction");
        require(!tx.executed, "Transaction already executed");
        
        // Must have at least 2 confirmations from the 3 owners
        uint256 confirmations = 0;
        if (tx.confirmedByOwner1) confirmations++;
        if (tx.confirmedByOwner2) confirmations++;
        if (tx.confirmedByOwner3) confirmations++;

        require(confirmations >= 2, "Insufficient confirmations");

        // Mark as executed
        tx.executed = true;

        // Send ETH
        payable(tx.to).transfer(tx.value);
    }

    function isConfirmed(uint256 txId, address owner) external view returns (bool) {
        Transaction storage tx = transactions[txId];
        
        if (owner == owner1) return tx.confirmedByOwner1;
        if (owner == owner2) return tx.confirmedByOwner2;
        if (owner == owner3) return tx.confirmedByOwner3;
        
        return false; 
    }

    function getTransaction(uint256 txId) external view returns (address to, uint256 value, bool executed, uint256 numConfirmations) {
        require(txId <= transactionCount, "Invalid transaction ID");
        
        Transaction storage tx = transactions[txId];
        
        address _to = tx.to;
        uint256 _value = tx.value;
        bool _executed = tx.executed;
        
        // Count confirmations
        if (tx.confirmedByOwner1) numConfirmations++;
        else if (tx.confirmedByOwner2) numConfirmations++;
        else if (tx.confirmedByOwner3) numConfirmations++;
    }
}
