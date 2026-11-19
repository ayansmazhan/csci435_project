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

    Transaction[] public transactions;
    uint256 public transactionCount;

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

    function isOwner(address account) public view returns (bool) {
        return account == owner1 || account == owner2 || account == owner3;
    }

    function transactionCount() public view returns (uint256) {
        return transactions.length;
    }

    function submit(address to, uint256 value) public onlyOwner returns (uint256 txId) {
        txId = transactionCount++;
        transactions.push(Transaction(to, value, false, 0));
    }

    function confirm(uint256 txId) public onlyConfirmed(txId) {
        require(transactions[txId].numConfirmations < 2, "Transaction already confirmed");
        transactions[txId].numConfirmations++;
        if (transactions[txId].numConfirmations == 2) {
            execute(txId);
        }
    }

    function execute(uint256 txId) public onlyConfirmed(txId) {
        require(!transactions[txId].executed, "Transaction already executed");
        require(transactions[txId].numConfirmations >= 2, "Not enough confirmations");

        transactions[txId].executed = true;
        (bool success, ) = transactions[txId].to.call{value: transactions[txId].value}("");
        require(success, "Failed to send ether");
    }

    function isConfirmed(uint256 txId, address owner) public view returns (bool) {
        return transactions[txId].numConfirmations > 0 && transactions[txId].numConfirmations <= 2 && transactions[txId].executed == false;
    }

    function getTransaction(uint256 txId) public view returns (address to, uint256 value, bool executed, uint256 numConfirmations) {
        return (transactions[txId].to, transactions[txId].value, transactions[txId].executed, transactions[txId].numConfirmations);
    }
}
