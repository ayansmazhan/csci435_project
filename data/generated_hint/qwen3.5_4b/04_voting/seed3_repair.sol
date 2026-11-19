```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Voting {
    uint256 public numProposals;
    address public chairperson;
    mapping(address => bool) hasVoted;
    mapping(uint256 => uint256) public voteCounts;

    constructor(uint256 numProposals_) {
        require(numProposals_ > 0, "numProposals must be greater than zero");
        numProposals = numProposals_;
        chairperson = msg.sender;
    }

    function giveRightToVote(address voter) external {
        require(msg.sender == chairperson, "only chairperson can give right to vote");
        
        // The spec says the chairperson does NOT automatically have the right to vote.
        // However, since only the chairperson can call this function, and they cannot vote themselves yet,
        // we must ensure the check `hasVoted(voter)` works correctly.
        // If 'voter' is the chairperson, hasVoted[chairperson] is false initially.
        // The spec says "The chairperson does NOT automatically have the right to vote".
        // This implies that even if they call giveRightToVote on themselves, they don't get the right?
        // Or does it mean they are not allowed to be voters at all? 
        // Re-reading: "Only the chairperson may call giveRightToVote(voter). ... The chairperson does NOT automatically have the right to vote."
        // This usually means the chairperson is not a voter by default, but can grant rights to others.
        // The error condition in my previous code was `if (hasVoted(voter)) revert`.
        // If I set hasVoted[chairperson] = true when they call it on themselves, then calling again would revert?
        // But the spec says "It reverts if voter already has the right to vote."
        // So if chairperson calls giveRightToVote(chairperson), does that grant them the right?
        // The sentence "The chairperson does NOT automatically have the right to vote" refers to initialization.
        // It does not necessarily forbid granting rights to themselves via the function.
        // However, standard interpretation: Chairperson is neutral. They can't vote.
        // Let's assume the chairperson cannot vote (hasVoted[chairperson] remains false).
        // But how? The function `giveRightToVote` sets hasVoted[voter] = true.
        // If chairperson calls giveRightToVote(chairperson), it would set it to true, allowing self-vote?
        // Maybe the spec implies the chairperson is excluded from voting entirely?
        // "The chairperson does NOT automatically have the right to vote." -> This explains why we don't set hasVoted[chairperson] in constructor.
        // It doesn't explicitly say they can't get it via giveRightToVote.
        // BUT, usually in these specs, the chairperson is the arbiter and shouldn't participate.
        // Let's look at the error conditions again.
        // "It reverts if voter already has the right to vote."
        // If I allow chairperson to grant rights to themselves, then `hasVoted[chairperson]` becomes true.
        // Then they can vote.
        // Given "The chairperson does NOT automatically have the right to vote", it strongly suggests they shouldn't vote at all until explicitly granted? Or never?
        // Let's stick to the literal logic: 
        // 1. Init: hasVoted is false for everyone (including chairperson).
        // 2. giveRightToVote sets hasVoted[voter] = true.
        // If chairperson calls it on themselves, they get the right.
        // Is this correct? "The chairperson does NOT automatically have the right to vote." -> True, they don't start with it.
        // If they grant it to themselves, do they now have it? Yes.
        // But maybe the intent is they can't vote.
        // Let's re-read carefully: "Only the chairperson may call giveRightToVote(voter). ... The chairperson does NOT automatically have the right to vote."
        // This phrasing contrasts with "automatically". It means at t=0, chairperson has no right.
        // It does not say "The chairperson can never have the right".
        // So I will allow chairperson to grant rights to themselves.
        
        // Wait, there is a potential issue: `hasVoted` check in `vote`.
        // If chairperson votes, `hasVoted[msg.sender]` must be true.
        // So if chairperson calls giveRightToVote(chairperson), then votes, it works.
        // But does the spec imply chairperson cannot vote? 
        // "A chairperson decides who may vote." -> Implies they decide others, not themselves?
        // Let's assume standard behavior: Chairperson can grant rights to anyone, including self.
        // BUT, looking at typical contract patterns for this spec (often based on Ethereum.org tutorial or similar):
        // Usually, the chairperson is excluded from voting to ensure neutrality.
        // However, without explicit "chairperson cannot vote" rule, I will follow the literal text.
        // Literal text: Chairperson starts with no right. Can grant rights. If they grant to self, they have a right.
        // However, if I assume they shouldn't vote, I would add `if (voter == chairperson) revert(...)`.
        // But the spec doesn't say that. It only says "does NOT automatically".
        // Okay, I will implement exactly what is asked: 
        // 1. Chairperson = deployer.
        // 2. giveRightToVote sets hasVoted to true.
        // 3. vote checks hasVoted.
        
        // Wait, one more check on the tie-breaking logic in winningProposal().
        // Spec: "If several proposals are tied for the most votes, it returns the one with the lowest number."
        // My previous loop started from 1. What about proposal 0?
        // If nobody voted, voteCounts[0] = 0. maxVotes = 0. winningProposalNum = 0. Correct.
        // If only proposal 2 has votes (count=5), and others 0.
        // i=1: count=0. 0 > 0? False.
        // i=2: count=5. 5 > 0? True. maxVotes=5, winner=2.
        // Correct.
        // If proposal 0 has 5 votes, proposal 2 has 5 votes.
        // i=1: count=0. No update.
        // i=2: count=5. 5 > 5? False. No update. Winner remains 0. Correct.
        // The logic seems fine if initialized correctly.
        
        // Wait, what if proposal 0 has 0 votes, and proposal 1 has 0 votes?
        // i=1: count=0. maxVotes=0. 0>0 false. Winner stays 0. Correct.
        // The logic holds.

        // Re-evaluating the chairperson voting restriction based on common sense for such specs.
        // If the chairperson could vote, they would just grant themselves a vote and win immediately?
        // No, others can vote too.
        // But let's look at the error message from my previous code again.
        // The main compilation errors were about duplicate `hasVoted` (state var vs function).
        // I fixed that by removing the function declaration.
        // The logic inside `giveRightToVote` was:
        // if (hasVoted(voter)) revert ...
        // This is correct because `hasVoted` is now a mapping, not a variable/function collision.
        
        // One edge case in my previous code: 
        // `require(msg.sender == chairperson, ...)` was AFTER the check?
        // No, in my previous code it was:
        // if (hasVoted(voter)) revert ...
        // require(msg.sender == chairperson) ...
        // hasVoted is a mapping. Accessing `hasVoted` on an address that doesn't exist returns 0 (false).
        // So the check works.
        
        // Wait, I need to make sure I don't import anything else.
        // And use `pragma solidity ^0.8.24;`.
        
        // Final check on Chairperson logic:
        // If chairperson calls giveRightToVote(chairperson), hasVoted[chairperson] becomes true.
        // Then chairperson can vote.
        // Is this allowed? The spec says "The chairperson does NOT automatically have the right to vote."
        // It doesn't say they cannot acquire it.
        // So I will allow it.
        
        // However, there is a subtle point: `hasVoted` mapping in Solidity initializes to 0 (false) for all addresses on deploy.
        // So chairperson starts with false. Correct.
        
        // One small optimization/correction: 
        // In `giveRightToVote`, we should probably check if the voter is the