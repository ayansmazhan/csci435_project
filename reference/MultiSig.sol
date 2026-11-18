// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MultiSig {
    struct Transaction {
        address to;
        uint256 value;
        bool executed;
        uint256 numConfirmations;
    }

    uint256 public constant REQUIRED = 2;
    mapping(address => bool) public isOwner;
    Transaction[] private _txs;
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not an owner");
        _;
    }

    modifier txExists(uint256 txId) {
        require(txId < _txs.length, "no such transaction");
        _;
    }

    constructor(address owner1, address owner2, address owner3) {
        require(owner1 != address(0) && owner2 != address(0) && owner3 != address(0), "zero address");
        require(owner1 != owner2 && owner1 != owner3 && owner2 != owner3, "duplicate owner");
        isOwner[owner1] = true;
        isOwner[owner2] = true;
        isOwner[owner3] = true;
    }

    receive() external payable {}

    function transactionCount() external view returns (uint256) {
        return _txs.length;
    }

    function submit(address to, uint256 value) external onlyOwner returns (uint256 txId) {
        txId = _txs.length;
        _txs.push(Transaction({to: to, value: value, executed: false, numConfirmations: 0}));
    }

    function confirm(uint256 txId) external onlyOwner txExists(txId) {
        require(!_txs[txId].executed, "already executed");
        require(!isConfirmed[txId][msg.sender], "already confirmed");
        isConfirmed[txId][msg.sender] = true;
        _txs[txId].numConfirmations += 1;
    }

    function execute(uint256 txId) external onlyOwner txExists(txId) {
        Transaction storage t = _txs[txId];
        require(!t.executed, "already executed");
        require(t.numConfirmations >= REQUIRED, "not enough confirmations");
        t.executed = true;                                  // effect before interaction
        (bool ok, ) = t.to.call{value: t.value}("");
        require(ok, "payment failed");
    }

    function getTransaction(uint256 txId)
        external
        view
        txExists(txId)
        returns (address to, uint256 value, bool executed, uint256 numConfirmations)
    {
        Transaction storage t = _txs[txId];
        return (t.to, t.value, t.executed, t.numConfirmations);
    }
}
