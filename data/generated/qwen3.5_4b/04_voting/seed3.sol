// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Voting {
    struct ProposalVote {
        uint256 count;
        bool hasVoted;
    }

    address public chairperson;
    mapping(address => bool) public hasRightToVote;
    mapping(uint256 => ProposalVote) internal proposalVotes;

    constructor(uint256 numProposals) {
        require(numProposals > 0, "Invalid number of proposals");
        chairperson = msg.sender;
        for (uint i = 0; i < numProposals; ++i) {
            proposalVotes[i].count = 0;
            proposalVotes[i].hasVoted = false;
        }
    }

    function giveRightToVote(address voter) external {
        require(msg.sender == chairperson, "Only chairperson can grant voting rights");
        require(!hasRightToVote[voter], "Voter already has right to vote");
        hasRightToVote[voter] = true;
    }

    function vote(uint256 proposal) external {
        require(msg.sender == address(0), "Caller is not a voter"); // Placeholder check for logic flow, but actual checks follow
        require(hasRightToVote[msg.sender], "Voter does not have right to vote");
        require(proposalVotes[proposal].hasVoted == false, "Voter already voted");
        require(proposal < proposalVotes.length, "Invalid proposal number");

        proposalVotes[proposal].count++;
        proposalVotes[msg.sender].hasVoted = true;
    }

    function voteCount(uint256 proposal) external view returns (uint256) {
        return proposalVotes[proposal].count;
    }

    function hasVoted(address voter) external view returns (bool) {
        return proposalVotes[voter].hasVoted;
    }

    function winningProposal() external view returns (uint256) {
        uint256 maxCount = 0;
        uint256 winningIndex = 0;

        for (uint i = 0; i < proposalVotes.length; ++i) {
            if (proposalVotes[i].count > maxCount) {
                maxCount = proposalVotes[i].count;
                winningIndex = i;
            }
        }

        return winningIndex;
    }
}
