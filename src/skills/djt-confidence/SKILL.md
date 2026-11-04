---
name: djt-confidence
description: "Verdict on whether a change meets its ticket. Maps every ticket requirement to evidence in the code or a recorded result, and lists open questions on the requirements. Answers 'do we believe in this change', nothing else. /djt-confidence [TICKET] [PR|branch|range]"
trigger: /djt-confidence
---

# /djt-confidence

Answer one question: **does this change meet every requirement of its ticket, and is any requirement still open?**

The answer is a verdict: **Complete confidence: yes** or **no**. Never "mostly". One gap makes it no.

## Usage

```
/djt-confidence                        # ticket from the branch name, change = current branch vs default branch
/djt-confidence PROJ-123               # that ticket, current branch
/djt-confidence PROJ-123 68            # that ticket, PR 68 in this repo
/djt-confidence PROJ-123 origin/main..HEAD
```

If the ticket or the change can't be resolved, ask. Never guess.

## Out of scope

Approval, merge rules, CI gates, code style, and new ideas for the ticket. The auditor's list is the full rule. If it doesn't change whether a requirement is met, leave it out.

## Workflow

Read-only throughout. No ticket writes, no PR comments, no Slack, no commits.

1. **Resolve the input.** The ticket key and the change: a PR, a branch, or a range. Ask if either is unresolved.
2. **Audit.** Spawn `djt-confidence-auditor` (inherit model). Brief it with the ticket and the change. It gathers, lists, grades, and returns open questions.
3. **Verify.** Check every row it marks Met. A Met row with no `file:line`, test name, or recorded result drops to Unverified. Open the cited code for any row that looks wrong.
4. **Give the verdict.** Yes only if every row is Met, or Blocked with the block agreed on the ticket or PR, and no open question remains.

If you can't spawn subagents (for example on Gemini), follow the `djt-confidence-auditor` instructions yourself, then run steps 3 and 4.

## Output

Chat, in this order, under ~15 lines:

1. `Complete confidence: yes|no` plus one line why.
2. The rows that aren't Met: status, requirement, the gap.
3. Open questions, numbered, each with who answers it.
4. The count: `N requirements: X met, Y partly, Z not, W unverified, V blocked`.

The full table goes to `.agents/output/reviews/<TICKET>/confidence.html` under the repo root. Requirement | status | evidence. Point to it in one line.

Certainty labels from the root-cause rules apply to any claim about behavior: Confirmed, High Probability, Possible.
