// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract SimpleToken {
    address public owner;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) public allowance;
    uint256 public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 initialSupply) {
        owner = msg.sender;
        balances[msg.sender] = initialSupply;
        totalSupply = initialSupply;
    }

    function totalSupply() external view returns (uint256) {
        return totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(to != address(0), "transfer: invalid recipient");
        require(msg.sender == owner || allowance[msg.sender][msg.sender] >= amount, "SimpleToken: insufficient funds");
        
        balances[msg.sender] -= amount;
        balances[to] += amount;

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        require(msg.sender == owner || allowance[msg.sender][msg.sender] >= amount, "SimpleToken: insufficient funds");
        
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(to != address(0), "transfer: invalid recipient");
        require(from.balance >= amount, "SimpleToken: insufficient balance of sender");
        require(allowance[from][msg.sender] >= amount, "SimpleToken: insufficient allowance");

        balances[from] -= amount;
        balances[to] += amount;
        allowance[from][msg.sender] -= amount;

        emit Transfer(from, to, amount);
        return true;
    }
}
