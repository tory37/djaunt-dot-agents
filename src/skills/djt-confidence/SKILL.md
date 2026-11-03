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

## Out of scope — never report these

- Who can approve, merge rules, code owners, CI gates, branch protection.
- Code style, naming, refactors. That is review, not requirements.
- New ideas for the ticket.

If it doesn't change whether a requirement is met, leave it out.

## Workflow

Read-only throughout. No ticket writes, no PR comments, no Slack, no commits.

1. **Gather the requirements.** Read the whole ticket: description, acceptance criteria, test plan, the Doer Test Plan field, and every comment. Follow links the ticket uses to define scope: a parent epic section, a design thread, a spec. Later comments and answered questions override the description. Note which.
2. **Gather the change.** Diff against the default branch. PR body, every review, every inline thread and its replies. Read the code. Never trust a PR body, commit message, or reply without checking the code or the recorded result.
3. **List each requirement.** One row per description requirement, acceptance criterion, and numbered test-plan item. Quote it short.
4. **Grade each row.**
   - **Met**: evidence is a `file:line`, a test name that asserts it, or a result recorded on the ticket or PR.
   - **Partly met**: some of it has evidence. Say what's missing.
   - **Not met**: the code does something else, or nothing.
   - **Unverified**: claimed but no evidence you can see. A test-plan item with no recorded result is Unverified.
   - **Blocked**: can't be done yet. Name the blocker.
5. **List open questions on the requirements.**
   - Questions in the ticket or comments nobody answered.
   - Places the code departs from the ticket text without a recorded decision.
   - Review threads, human or bot, with no reply and no fix in code. Check the code before calling one open.
   - Each one names who would answer it.
6. **Give the verdict.** Yes only if every row is Met, or Blocked with the block agreed on the ticket or PR, and no open question remains.

Delegate steps 1–5 to one subagent (inherit model) when the ticket or diff is large. Keep step 6. Verify any row the subagent marks Met that has no evidence.

## Output

Chat, in this order, under ~15 lines:

1. `Complete confidence: yes|no` plus one line why.
2. The rows that aren't Met: status, requirement, the gap.
3. Open questions, numbered, each with who answers it.
4. The count: `N requirements: X met, Y partly, Z not, W unverified, V blocked`.

The full table goes to `.agents/output/reviews/<TICKET>/confidence.html` under the repo root. Requirement | status | evidence. Point to it in one line.

Certainty labels from the root-cause rules apply to any claim about behavior: Confirmed, High Probability, Possible.
