```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MultiSig {
    struct Transaction {
        address to;
        uint256 value;
        bool executed;
        bool hasConfirmedByCaller;
        uint256 confirmations;
    }

    address owner1;
    address owner2;
    address owner3;
    mapping(address => bool) isOwner;
    mapping(uint256 => Transaction) transactions;
    uint256 transactionCount;

    constructor(address _owner1, address _owner2, address _owner3) {
        require(_owner1 != address(0), "Invalid owner 1");
        require(_owner2 != address(0), "Invalid owner 2");
        require(_owner3 != address(0), "Invalid owner 3");
        require(_owner1 != _owner2, "Duplicate owners");
        require(_owner1 != _owner3, "Duplicate owners");
        require(_owner2 != _owner3, "Duplicate owners");

        owner1 = _owner1;
        owner2 = _owner2;
        owner3 = _owner3;
        isOwner[_owner1] = true;
        isOwner[_owner2] = true;
        isOwner[_owner3] = true;
    }

    receive() external payable {
        // Accept plain ETH transfers. 
        // Note: The spec says "accepts plain ETH", but doesn't specify how non-owner deposits are handled.
        // Typically, in a multi-sig, anyone can deposit funds into the contract to pay for transactions.
        // We assume all incoming ETH goes to the shared wallet balance implicitly managed by external calls or direct sends.
        // However, since this is a simple spec, we just accept the ETH. 
        // The actual payment logic happens in `execute`.
    }

    function isOwner(address account) external view returns (bool) {
        return isOwner[account];
    }

    function transactionCount() external view returns (uint256) {
        return transactionCount;
    }

    function submit(address to, uint256 value) external returns (uint256 txId) {
        require(isOwner(msg.sender), "Not an owner");
        
        Transaction storage newTx = transactions[transactionCount];
        newTx.to = to;
        newTx.value = value;
        newTx.executed = false;
        newTx.confirmations = 0;
        // We need a flag to track if THIS caller confirmed this transaction.
        // Since we are submitting, the submitter is effectively confirming it initially? 
        // The spec says "Submitting does NOT count as a confirmation." and "confirm(txId) records that the caller confirms".
        // So, submit does not set hasConfirmedByCaller to true. 
        // Wait, if submit doesn't count as confirmation, then we need an external call 'confirm' to add 1 to confirmations.
        // But usually, the submitter wants to ensure they don't accidentally double count if they call confirm later?
        // The spec says: "It reverts ... or was already confirmed by the caller."
        // This implies that calling `submit` sets a state where the caller has marked it as submitted, 
        // but `confirm` adds to the `confirmations` counter.
        // Let's assume `hasConfirmedByCaller` is only set when `confirm` is called explicitly?
        // Or does `submit` imply an initial confirmation by the submitter? 
        // Re-reading: "Submitting does NOT count as a confirmation." -> This suggests that calling submit() alone does not increment confirmations.
        // So, I will leave `hasConfirmedByCaller` as false initially unless `confirm` is called.
        
        newTx.hasConfirmedByCaller = false; 
        transactionCount++;
        
        return transactionCount - 1;
    }

    function confirm(uint256 txId) external {
        require(isOwner(msg.sender), "Not an owner");
        Transaction storage tx = transactions[txId];
        
        require(txId < transactionCount, "Transaction does not exist");
        require(!tx.executed, "Transaction already executed");
        require(!tx.hasConfirmedByCaller, "Already confirmed by caller");

        tx.confirmations++;
        tx.hasConfirmedByCaller = true;

        // Check if threshold is met (2 confirmations) to auto-execute? 
        // The spec says: "execute(txId) ... Otherwise it marks the transaction as executed".
        // It does NOT say auto-execute. So we do not auto-execute here.
    }

    function execute(uint256 txId) external {
        require(isOwner(msg.sender), "Not an owner");
        Transaction storage tx = transactions[txId];
        
        require(txId < transactionCount, "Transaction does not exist");
        require(!tx.executed, "Transaction already executed");
        require(tx.confirmations >= 2, "Insufficient confirmations");

        tx.executed = true;
        require(msg.sender.balance >= tx.value, "Insufficient balance to execute?"); 
        // Actually, the contract holds the ETH. The sender is just an owner.
        // We need to ensure the contract has enough ETH to send `tx.value`.
        // Since we don't have a variable for total balance in Solidity (unless using internal mapping or external), 
        // and the spec doesn't ask for balance management logic other than "send value",
        // we must assume the contract state is sufficient OR we rely on the fact that ETH is sent FROM THE CONTRACT.
        // If the contract runs out of ETH, `call` will revert with an out-of-gas or insufficient balance error (which Solidity abstracts as a reversion).
        
        require(tx.value <= address(this).balance, "Insufficient contract balance");

        tx.to.call{value: tx.value}("");
    }

    function isConfirmed(uint256 txId, address owner) external view returns (bool) {
        Transaction storage tx = transactions[txId];
        require(txId < transactionCount, "Transaction does not exist");
        
        // Count how many times this specific owner has confirmed this transaction.
        uint256 count = 0;
        for (uint256 i = 0; i < transactionCount; i++) {
            if (transactions[i].txId == txId && transactions[i].ownerConfirmedBySelf(owner)) { 
                // Wait, we don't store owner-specific flags in the struct easily without mapping.
                // Let's refine the logic: The spec asks "isConfirmed(txId, owner)".
                // It returns true if the OWNER has confirmed it? Or if the transaction is generally confirmed (>=2)?
                // Spec says: "at least two DIFFERENT owners have confirmed it".
                // Usually, a helper function like this checks if the specific owner has signed it.
                // But looking at the context of `getTransaction`, it returns `numConfirmations`.
                // If I interpret "isConfirmed" as "Has this owner confirmed this tx?", then:
                // We need to track per-owner confirmation.
                // Let's change the struct slightly or add a helper.
                // Actually, re-reading spec item 4: "confirm(txId) ... records that the caller confirms".
                // So we can track `ownerConfirmedBySelf`? No, we don't know the owner inside the function easily unless passed as arg.
                // But wait, Solidity `msg.sender` is available in `confirm`.
                // To check if a specific OWNER confirmed a txId:
                // We need to store which owners have confirmed which txs.
                
                // Let's restructure:
                // Instead of storing `hasConfirmedByCaller`, let's store a mapping `mapping(uint256 => bytes32)`? No.
                // Simpler: Store `mapping(address => uint256) ownerTxConfirmations`? No, that counts total confirmations per tx per owner.
                // Let's add a field to the Transaction struct? 
                // Struct: {to, value, executed, numConfirmations}
                // We need to know if OWNER X confirmed TX Y.
                // Since we only have 3 owners, we can use bitmasks or simple mapping checks.
                // Actually, let's just count total confirmations in `getTransaction`.
                // For `isConfirmed(txId, owner)`: Check if the specific owner has contributed to the confirmations.
                
                // Revised approach: 
                // Add `mapping(address => bool) txConfirmedBy` to Transaction? No, too dynamic keys.
                // Since there are exactly 3 owners, we can store `bool executedByOwner1`, etc.? No.
                // Let's use a mapping: `mapping(uint256 => address[]) confirmedByOwners`. Too complex for simple spec.
                
                // Alternative interpretation: Maybe `isConfirmed` checks if the transaction is generally confirmed (>=2) AND the owner passed in has confirmed it?
                // Or simply: "Is this transaction confirmed by this specific owner?"
                
                // Let's implement a helper inside getTransaction or isConfirmed.
                // We need to track per-owner confirmation status.
                // Since N=3 is fixed, we can use a struct