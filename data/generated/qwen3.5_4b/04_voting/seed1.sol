// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Voting {
    address public chairperson;
    uint256 private numProposals;
    mapping(address => bool) private votingRights;
    mapping(address => bool) private votedFor;
    mapping(uint256 => uint256) private voteCounts;

    constructor(uint256 _numProposals) {
        require(_numProposals > 0, "Voting: numProposals must be greater than 0");
        chairperson = msg.sender;
        numProposals = _numProposals;
        // Initialize vote counts to 0 for all proposals
        for (uint256 i = 0; i < numProposals; ++i) {
            voteCounts[i] = 0;
        }
    }

    function chairperson() external view returns (address) {
        return chairperson;
    }

    function giveRightToVote(address voter) external {
        require(msg.sender == chairperson, "Voting: only chairperson can grant voting rights");
        require(!votingRights[voter], "Voting: voter already has the right to vote");
        votingRights[voter] = true;
    }

    function vote(uint256 proposal) external {
        require(msg.sender == chairperson || votingRights[msg.sender], "Voting: no voting rights");
        require(proposal < numProposals, "Voting: invalid proposal");
        require(!votedFor[msg.sender], "Voting: already voted");

        voteCounts[proposal]++;
        votedFor[msg.sender] = true;
    }

    function voteCount(uint256 proposal) external view returns (uint256) {
        require(proposal < numProposals, "Voting: invalid proposal");
        return voteCounts[proposal];
    }

    function hasVoted(address voter) external view returns (bool) {
        require(votingRights[voter], "Voting: voter does not have the right to vote");
        return votedFor[voter];
    }

    function winningProposal() external view returns (uint256) {
        uint256 maxVotes = 0;
        uint256 winningProposalNum = 0;

        for (uint256 i = 0; i < numProposals; ++i) {
            if (voteCounts[i] > maxVotes) {
                maxVotes = voteCounts[i];
                winningProposalNum = i;
            }
        }

        return winningProposalNum;
    }
}
