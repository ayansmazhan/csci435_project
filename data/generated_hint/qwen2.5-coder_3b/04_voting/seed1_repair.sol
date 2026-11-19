pragma solidity ^0.8.24;

contract Voting {
    // State variables
    address public chairperson;
    mapping(address => bool) public hasVoted;
    uint256[] public proposals;
    mapping(uint256 => uint256) public voteCounts;

    // Constructor
    constructor(uint256 numProposals) {
        if (numProposals == 0) revert("Number of proposals must be greater than 0");
        chairperson = msg.sender;
        proposals = new uint256[](numProposals);
        for (uint256 i = 0; i < numProposals; i++) {
            proposals[i] = i;
        }
    }

    // Functions
    function chairperson() external view returns (address) {
        return chairperson;
    }

    function giveRightToVote(address voter) external {
        require(msg.sender == chairperson, "Only chairperson can grant voting rights");
        require(!hasVoted[voter], "Voter already has right to vote");
        hasVoted[voter] = true;
    }

    function vote(uint256 proposal) external {
        require(hasVoted[msg.sender], "Caller does not have right to vote");
        require(!voteCounts[proposal], "Caller has already voted");
        require(proposal < proposals.length, "Proposal does not exist");
        voteCounts[proposal]++;
        hasVoted[msg.sender] = true;
    }

    function voteCount(uint256 proposal) external view returns (uint256) {
        return voteCounts[proposal];
    }

    function hasVoted(address voter) external view returns (bool) {
        return hasVoted[voter];
    }

    function winningProposal() external view returns (uint256) {
        uint256 winningProposal = 0;
        for (uint256 i = 1; i < proposals.length; i++) {
            if (voteCounts[i] > voteCounts[winningProposal]) {
                winningProposal = i;
            }
        }
        return winningProposal;
    }
}
