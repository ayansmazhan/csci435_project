pragma solidity ^0.8.24;

contract MultiSig {
    address[] public owners;
    mapping(uint256 => Transaction) public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmations;

    struct Transaction {
        address to;
        uint256 value;
        bool executed;
        uint256 numConfirmations;
    }

    constructor(address owner1, address owner2, address owner3) {
        require(owner1 != address(0) && owner2 != address(0) && owner3 != address(0), "Owner cannot be zero address");
        require(owner1 != owner2 && owner2 != owner3, "Two owners cannot be the same");
        owners = [owner1, owner2, owner3];
    }

    receive() external payable {}

    function isOwner(address account) public view returns (bool) {
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == account) {
                return true;
            }
        }
        return false;
    }

    function transactionCount() external view returns (uint256) {
        return transactions.length;
    }

    function submit(address to, uint256 value) external returns (uint256 txId) {
        require(isOwner(msg.sender), "Caller must be an owner");
        txId = transactions.length;
        transactions[txId] = Transaction({
            to: to,
            value: value,
            executed: false,
            numConfirmations: 0
        });
        return txId;
    }

    function confirm(uint256 txId) external {
        require(isOwner(msg.sender), "Caller must be an owner");
        require(txId < transactions.length, "Transaction does not exist");
        require(!transactions[txId].executed, "Transaction has already been executed");
        require(!confirmations[txId][msg.sender], "Already confirmed by caller");
        confirmations[txId][msg.sender] = true;
        transactions[txId].numConfirmations++;
        if (transactions[txId].numConfirmations >= 2) {
            execute(txId);
        }
    }

    function execute(uint256 txId) external {
        require(isOwner(msg.sender), "Caller must be an owner");
        require(txId < transactions.length, "Transaction does not exist");
        require(!transactions[txId].executed, "Transaction has already been executed");
        require(transactions[txId].numConfirmations >= 2, "Not enough confirmations");
        transactions[txId].executed = true;
        (bool success, ) = transactions[txId].to.call{value: transactions[txId].value}("");
        require(success, "Transfer failed");
    }

    function isConfirmed(uint256 txId, address owner) external view returns (bool) {
        return confirmations[txId][owner];
    }

    function getTransaction(uint256 txId) external view returns (address to, uint256 value, bool executed, uint256 numConfirmations) {
        require(txId < transactions.length, "Transaction does not exist");
        return (
            transactions[txId].to,
            transactions[txId].value,
            transactions[txId].executed,
            transactions[txId].numConfirmations
        );
    }
}
