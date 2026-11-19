pragma solidity ^0.8.24;

contract Voting {
    address public chairperson;
    uint256 public numProposals;
    mapping(address => bool) public voters;
    mapping(uint256 => uint256) public voteCounts;

    constructor(uint256 _numProposals) {
        require(_numProposals > 0, "Number of proposals must be greater than zero");
        chairperson = msg.sender;
        numProposals = _numProposals;
    }

    function chairperson() external view returns (address) {
        return chairperson;
    }

    function giveRightToVote(address voter) external {
        require(voters[voter] == false, "Voter already has the right to vote");
        require(msg.sender == chairperson, "Only the chairperson can give right to vote");
        voters[voter] = true;
    }

    function vote(uint256 proposal) external {
        require(voters[msg.sender] == true, "Caller does not have the right to vote");
        require(voteCounts[proposal] == 0, "Caller has already voted");
        require(proposal < numProposals, "Proposal is not a valid proposal number");

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
