// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MultiSig {
    address public owner1;
    address public owner2;
    address public owner3;

    struct Transaction {
        address to;
        uint256 value;
        bool executed;
        uint256 numConfirmations;
    }

    mapping(uint256 => Transaction) private transactions;
    uint256 public transactionCount;

    // Track if a specific owner has already confirmed a specific transaction to prevent duplicate confirmations
    mapping(uint256 => mapping(address => bool)) private txOwnerConfirmed;

    constructor(address _owner1, address _owner2, address _owner3) {
        require(_owner1 != address(0), "Owner1 cannot be zero address");
        require(_owner2 != address(0), "Owner2 cannot be zero address");
        require(_owner3 != address(0), "Owner3 cannot be zero address");
        require(_owner1 != _owner2, "Owner1 and Owner2 cannot be the same");
        require(_owner1 != _owner3, "Owner1 and Owner3 cannot be the same");
        require(_owner2 != _owner3, "Owner2 and Owner3 cannot be the same");

        owner1 = _owner1;
        owner2 = _owner2;
        owner3 = _owner3;
    }

    receive() external payable {
        // Accepts plain ETH transfers from anyone. 
        // The funds are managed via the submit/confirm/execute flow rather than a balance variable.
    }

    function isOwner(address account) external view returns (bool) {
        return account == owner1 || account == owner2 || account == owner3;
    }

    function transactionCount() external view returns (uint256) {
        return transactionCount;
    }

    function submit(address _to, uint256 _value) external returns (uint256 txId) {
        require(isOwner(msg.sender), "Only owners can submit");
        
        txId = transactionCount;
        transactions[txId] = Transaction({
            to: _to,
            value: _value,
            executed: false,
            numConfirmations: 0
        });
        transactionCount++;
    }

    function confirm(uint256 txId) external {
        require(isOwner(msg.sender), "Only owners can confirm");
        
        Transaction storage t = transactions[txId];
        require(t.numConfirmations < 3, "Transaction already has too many confirmations");
        require(!t.executed, "Transaction already executed");
        require(!txOwnerConfirmed[txId][msg.sender], "You have already confirmed this transaction");

        t.numConfirmations++;
        txOwnerConfirmed[txId][msg.sender] = true;
    }

    function execute(uint256 txId) external {
        require(isOwner(msg.sender), "Only owners can execute");
        
        Transaction storage t = transactions[txId];
        require(t.numConfirmations >= 2, "Transaction needs at least 2 confirmations");
        require(!t.executed, "Transaction already executed");

        t.executed = true;

        // Send ETH directly to the target
        (bool success,) = t.to.call{value: t.value}("");
        require(success, "Transfer failed");
    }

    function isConfirmed(uint256 txId, address owner) external view returns (bool) {
        return txOwnerConfirmed[txId][owner];
    }

    function getTransaction(uint256 txId) external view returns (address to, uint256 value, bool executed, uint256 numConfirmations) {
        Transaction storage t = transactions[txId];
        
        // Return default values if transaction doesn't exist to satisfy the interface without reverting on access
        return (t.to, t.value, t.executed, t.numConfirmations);
    }
}
