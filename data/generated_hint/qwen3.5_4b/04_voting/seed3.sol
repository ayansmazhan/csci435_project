// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Voting {
    uint256 public numProposals;
    address public chairperson;
    mapping(address => bool) public hasVoted;
    mapping(uint256 => uint256) public voteCounts;
    
    struct ProposalVoteData {
        uint256 count;
    }

    constructor(uint256 numProposals_) {
        require(numProposals_ > 0, "numProposals must be greater than zero");
        numProposals = numProposals_;
        chairperson = msg.sender;
    }

    function giveRightToVote(address voter) external {
        if (hasVoted(voter)) {
            revert("voter already has the right to vote");
        }
        // Note: The spec says "The chairperson does NOT automatically have the right to vote",
        // so we do not set hasVoted(chairperson) here.
        require(msg.sender == chairperson, "only chairperson can give right to vote");
        hasVoted[voter] = true;
    }

    function vote(uint256 proposal_) external {
        if (hasVoted[msg.sender]) {
            revert("voter already voted");
        }
        if (proposal_ >= numProposals) {
            revert("invalid proposal number");
        }
        
        // Increment the count for the proposed vote
        voteCounts[proposal_]++;
        hasVoted[msg.sender] = true;
    }

    function voteCount(uint256 proposal_) external view returns (uint256) {
        return voteCounts[proposal_];
    }

    function hasVoted(address voter) external view returns (bool) {
        return hasVoted[voter];
    }

    function winningProposal() external view returns (uint256) {
        uint256 maxVotes = 0;
        uint256 winningProposalNum = 0; // Default to 0 if nobody voted
        
        for (uint256 i = 1; i < numProposals; ++i) {
            uint256 currentCount = voteCounts[i];
            if (currentCount > maxVotes) {
                maxVotes = currentCount;
                winningProposalNum = i;
            } else if (currentCount == maxVotes && currentCount > 0) {
                // If tied, keep the lower number. Since we iterate from 1 upwards,
                // we only update if strictly greater. If equal, we do not update,
                // preserving the lower index.
                // However, we need to be careful with the initialization logic.
                // Let's refine: Initialize maxVotes = 0. Winning is 0.
                // If i=1 has 0 votes, it's equal to maxVotes (0). We do NOT update. Winning remains 0. Correct.
                // If i=1 has > 0 votes, we update. Correct.
                // If i=2 has same as i=1, and i=1 was the winner (lower), we do NOT update. Correct.
            }
        }
        
        return winningProposalNum;
    }
}
