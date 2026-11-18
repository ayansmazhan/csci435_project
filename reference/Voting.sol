// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Voting {
    address public immutable chairperson;
    uint256[] private _votes;                         // _votes[i] = votes for proposal i
    mapping(address => bool) private _canVote;
    mapping(address => bool) private _hasVoted;

    constructor(uint256 numProposals) {
        require(numProposals > 0, "no proposals");
        chairperson = msg.sender;
        _votes = new uint256[](numProposals);         // all counts start at 0
    }

    function giveRightToVote(address voter) external {
        require(msg.sender == chairperson, "only chairperson");
        require(!_canVote[voter], "already has the right");
        _canVote[voter] = true;
    }

    function vote(uint256 proposal) external {
        require(_canVote[msg.sender], "no right to vote");
        require(!_hasVoted[msg.sender], "already voted");
        require(proposal < _votes.length, "invalid proposal");
        _hasVoted[msg.sender] = true;
        _votes[proposal] += 1;
    }

    function voteCount(uint256 proposal) external view returns (uint256) {
        return _votes[proposal];
    }

    function hasVoted(address voter) external view returns (bool) {
        return _hasVoted[voter];
    }

    function winningProposal() external view returns (uint256 winner) {
        // Strictly greater (>) keeps the lowest number when there is a tie.
        for (uint256 i = 1; i < _votes.length; i++) {
            if (_votes[i] > _votes[winner]) {
                winner = i;
            }
        }
    }
}
