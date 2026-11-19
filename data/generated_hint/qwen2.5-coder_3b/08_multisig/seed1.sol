pragma solidity ^0.8.24;

contract MultiSig {
    address public owner1;
    address public owner2;
    address public owner3;

    mapping(uint256 => Transaction) public transactions;
    uint256 public transactionCount;

    struct Transaction {
        address to;
        uint256 value;
        bool executed;
        uint256 numConfirmations;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "Caller is not an owner");
        _;
    }

    modifier onlyConfirmed(uint256 txId) {
        require(isConfirmed(txId, msg.sender), "Caller is not a confirmed owner");
        _;
    }

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

    function receive() external payable {}

    function isOwner(address account) external view returns (bool) {
        return account == owner1 || account == owner2 || account == owner3;
    }

    function transactionCount() external view returns (uint256) {
        return transactionCount;
    }

    function submit(address to, uint256 value) external onlyOwner returns (uint256 txId) {
        txId = transactionCount++;
        transactions[txId] = Transaction(to, value, false, 0);
    }

    function confirm(uint256 txId) external onlyConfirmed(txId) {
        Transaction storage t = transactions[txId];
        require(!t.executed, "Transaction is already executed");
        t.numConfirmations++;
        if (t.numConfirmations >= 2) {
            execute(txId);
        }
    }

    function execute(uint256 txId) external onlyConfirmed(txId) {
        Transaction storage t = transactions[txId];
        require(!t.executed, "Transaction is already executed");
        require(t.numConfirmations >= 2, "Not enough confirmations");

        t.executed = true;
        (bool success, ) = t.to.call{value: t.value}("");
        require(success, "Failed to send ether");
    }

    function isConfirmed(uint256 txId, address owner) external view returns (bool) {
        Transaction storage t = transactions[txId];
        return t.numConfirmations > 0 && t.numConfirmations <= 2 && t.executed == false;
    }

    function getTransaction(uint256 txId) external view returns (address to, uint256 value, bool executed, uint256 numConfirmations) {
        Transaction storage t = transactions[txId];
        return (t.to, t.value, t.executed, t.numConfirmations);
    }
}
