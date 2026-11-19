// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MultiSig {
    struct Transaction {
        address to;
        uint256 value;
        bool executed;
        bool isConfirmedBySender; // Used to prevent double confirmation by same owner
        uint256 confirmations;
    }

    address public owner1;
    address public owner2;
    address public owner3;

    mapping(uint256 => Transaction) internal transactions;
    uint256 internal nextTxId;

    constructor(address _owner1, address _owner2, address _owner3) {
        if (_owner1 == address(0)) revert("Owner1 cannot be zero address");
        if (_owner2 == address(0)) revert("Owner2 cannot be zero address");
        if (_owner3 == address(0)) revert("Owner3 cannot be zero address");
        
        if (_owner1 == _owner2 || _owner1 == _owner3 || _owner2 == _owner3) {
            revert("Owners cannot be the same");
        }

        owner1 = _owner1;
        owner2 = _owner2;
        owner3 = _owner3;
    }

    receive() external payable {}

    function isOwner(address account) external view returns (bool) {
        return account == owner1 || account == owner2 || account == owner3;
    }

    function transactionCount() external view returns (uint256) {
        return nextTxId;
    }

    function submit(address to, uint256 value) external returns (uint256 txId) {
        require(isOwner(msg.sender), "Only owners can submit");
        
        transactions[txId] = Transaction({
            to: to,
            value: value,
            executed: false,
            isConfirmedBySender: false,
            confirmations: 0
        });

        txId++; // Increment count after storing
    }

    function confirm(uint256 txId) external {
        require(txId < nextTxId, "Invalid transaction ID");
        
        Transaction storage tx = transactions[txId];
        require(!tx.executed, "Transaction already executed");
        require(!tx.isConfirmedBySender, "Already confirmed by sender");

        // Check if the current owner has already confirmed this transaction (prevents double count)
        bool isOwner1 = msg.sender == owner1;
        bool isOwner2 = msg.sender == owner2;
        bool isOwner3 = msg.sender == owner3;

        if (isOwner1 && tx.isConfirmedBySender) {
            revert("Owner1 has already confirmed this transaction");
        }
        if (isOwner2 && tx.isConfirmedBySender) {
            revert("Owner2 has already confirmed this transaction");
        }
        if (isOwner3 && tx.isConfirmedBySender) {
            revert("Owner3 has already confirmed this transaction");
        }

        tx.isConfirmedBySender = true;
        tx.confirmations++;

        // Check if execution threshold is met
        if (tx.confirmations >= 2) {
            execute(txId);
        }
    }

    function execute(uint256 txId) external {
        require(txId < nextTxId, "Invalid transaction ID");
        
        Transaction storage tx = transactions[txId];
        require(!tx.executed, "Transaction already executed");
        require(tx.confirmations >= 2, "Insufficient confirmations");

        tx.executed = true;

        (bool success, ) = tx.to.call{value: tx.value}("");
        require(success, "Transfer failed");
    }

    function isConfirmed(uint256 txId, address owner) external view returns (bool) {
        require(txId < nextTxId, "Invalid transaction ID");
        
        Transaction storage tx = transactions[txId];
        bool isOwner1 = owner == owner1;
        bool isOwner2 = owner == owner2;
        bool isOwner3 = owner == owner3;

        return (isOwner1 && tx.isConfirmedBySender) || 
               (isOwner2 && tx.isConfirmedBySender) || 
               (isOwner3 && tx.isConfirmedBySender);
    }

    function getTransaction(uint256 txId) external view returns (address, uint256, bool, uint256) {
        require(txId < nextTxId, "Invalid transaction ID");
        
        Transaction storage tx = transactions[txId];
        return (tx.to, tx.value, tx.executed, tx.confirmations);
    }
}
