# Spec 04: Voting

Write a Solidity contract named `Voting`.
Use `pragma solidity ^0.8.24;`. Do not import any other files.

A chairperson decides who may vote. Each allowed voter can vote once for one of several numbered proposals.

## Required interface
- `constructor(uint256 numProposals)`
- `function chairperson() external view returns (address)`
- `function giveRightToVote(address voter) external`
- `function vote(uint256 proposal) external`
- `function voteCount(uint256 proposal) external view returns (uint256)`
- `function hasVoted(address voter) external view returns (bool)`
- `function winningProposal() external view returns (uint256)`

## Behaviour
1. The deployer is the chairperson. Proposals are numbered `0` to `numProposals - 1`. The constructor reverts if `numProposals` is 0.
2. Only the chairperson may call `giveRightToVote(voter)`. It reverts if `voter` already has the right to vote. The chairperson does NOT automatically have the right to vote.
3. `vote(proposal)` adds one vote to `proposal`. It reverts if the caller has no right to vote, has already voted, or if `proposal` is not a valid proposal number.
4. `voteCount(proposal)` returns the number of votes for that proposal. `hasVoted(voter)` returns whether that address has voted.
5. `winningProposal()` returns the proposal with the most votes. If several proposals are tied for the most votes, it returns the one with the lowest number. If nobody has voted, it returns 0.
