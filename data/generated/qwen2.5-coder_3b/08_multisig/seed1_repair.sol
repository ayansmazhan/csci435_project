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

    mapping(uint256 => Transaction) public transactions;
    uint256 public transactionCount;

    constructor(address _owner1, address _owner2, address _owner3) {
        require(_owner1 != address(0) && _owner2 != address(0) && _owner3 != address(0), "Owner addresses cannot be zero");
        require(_owner1 != _owner2 && _owner2 != _owner3 && _owner1 != _owner3, "Owners must be distinct");
        owner1 = _owner1;
        owner2 = _owner2;
        owner3 = _owner3;
    }

    function receive() external payable {}

    function isOwner(address account) public view returns (bool) {
        return account == owner1 || account == owner2 || account == owner3;
    }

    function transactionCount() public view returns (uint256) {
        return transactionCount;
    }

    function submit(address to, uint256 value) external returns (uint256 txId) {
        require(isOwner(msg.sender), "Only owners can submit transactions");
        txId = transactionCount++;
        transactions[txId] = Transaction(to, value, false, 0);
    }

    function confirm(uint256 txId) external {
        require(isOwner(msg.sender), "Only owners can confirm transactions");
        Transaction storage t = transactions[txId];
        require(t.to != address(0) && t.value > 0, "Transaction does not exist");
        require(!t.executed, "Transaction has already been executed");
        require(t.numConfirmations < 2, "Transaction already confirmed by the caller");
        t.numConfirmations++;
    }

    function execute(uint256 txId) external {
        require(isOwner(msg.sender), "Only owners can execute transactions");
        Transaction storage t = transactions[txId];
        require(t.to != address(0) && t.value > 0, "Transaction does not exist");
        require(!t.executed, "Transaction has already been executed");
        require(t.numConfirmations >= 2, "Not enough confirmations");
        t.executed = true;
        (bool success, ) = payable(t.to).call{value: t.value}("");
        require(success, "Failed to send ETH");
    }

    function isConfirmed(uint256 txId, address owner) public view returns (bool) {
        Transaction storage t = transactions[txId];
        return t.numConfirmations > 0 && (owner == owner1 || owner == owner2 || owner == owner3);
    }

    function getTransaction(uint256 txId) public view returns (address to, uint256 value, bool executed, uint256 numConfirmations) {
        Transaction storage t = transactions[txId];
        return (t.to, t.value, t.executed, t.numConfirmations);
    }
}
