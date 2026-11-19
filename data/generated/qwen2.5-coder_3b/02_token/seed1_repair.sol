pragma solidity ^0.8.24;

contract SimpleToken {
    // Event to emit when a transfer occurs
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Event to emit when an approval occurs
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // Mapping from address to their balance
    mapping(address => uint256) public balances;

    // Mapping from address to their allowance
    mapping(address => mapping(address => uint256)) public allowances;

    // Total supply of tokens
    uint256 public totalSupply;

    // Constructor to initialize the token with a given total supply
    constructor(uint256 initialSupply) {
        totalSupply = initialSupply;
        balances[msg.sender] = initialSupply;
    }

    // Function to get the total supply of tokens
    function totalSupply() external view returns (uint256) {
        return totalSupply;
    }

    // Function to get the balance of a given account
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    // Function to transfer tokens to a given address
    function transfer(address to, uint256 amount) external returns (bool) {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        require(to != address(0), "Recipient address cannot be zero");

        balances[msg.sender] -= amount;
        balances[to] += amount;

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    // Function to approve a spender to transfer tokens on behalf of the caller
    function approve(address spender, uint256 amount) external returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // Function to get the allowance of a spender for a given owner
    function allowance(address owner, address spender) external view returns (uint256) {
        return allowances[owner][spender];
    }

    // Function to transfer tokens on behalf of a given account
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(allowances[from][msg.sender] >= amount, "Insufficient allowance");
        require(balances[from] >= amount, "Insufficient balance");
        require(to != address(0), "Recipient address cannot be zero");

        balances[from] -= amount;
        balances[to] += amount;
        allowances[from][msg.sender] -= amount;

        emit Transfer(from, to, amount);
        return true;
    }
}
