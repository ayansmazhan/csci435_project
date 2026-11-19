pragma solidity ^0.8.24;

contract Voting {
    address private chairperson;
    mapping(address => bool) private voters;
    mapping(uint256 => uint256) private voteCounts;
    uint256 private numProposals;

    constructor(uint256 _numProposals) {
        require(_numProposals > 0, "Number of proposals must be greater than 0.");
        chairperson = msg.sender;
        numProposals = _numProposals;
        for (uint256 i = 0; i < _numProposals; i++) {
            voteCounts[i] = 0;
        }
    }

    function chairperson() external view returns (address) {
        return chairperson;
    }

    function giveRightToVote(address voter) external {
        require(msg.sender == chairperson, "Only the chairperson can give right to vote.");
        require(!voters[voter], "The voter already has the right to vote.");
        voters[voter] = true;
    }

    function vote(uint256 proposal) external {
        require(msg.sender != chairperson, "The chairperson cannot vote.");
        require(voters[msg.sender], "The voter has no right to vote.");
        require(proposal < numProposals, "Invalid proposal number.");
        require(voteCounts[proposal] == 0, "The proposal has already been voted for.");
        voteCounts[proposal]++;
    }

    function voteCount(uint256 proposal) external view returns (uint256) {
        return voteCounts[proposal];
    }

    function hasVoted(address voter) external view returns (bool) {
        return voters[voter];
    }

    function winningProposal() external view returns (uint256) {
        uint256 winningProposal = 0;
        uint256 maxVotes = 0;
        for (uint256 i = 0; i < numProposals; i++) {
            if (voteCounts[i] > maxVotes) {
                maxVotes = voteCounts[i];
                winningProposal = i;
            }
        }
        return winningProposal;
    }
}
