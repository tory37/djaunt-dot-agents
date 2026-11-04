---
name: djt-code-review
description: "Code review of a diff, branch, range, or PR. A read-only finder agent returns cited findings, a fresh verifier agent filters false positives, and the skill gives a SHIP / SHIP WITH NITS / CHANGES REQUESTED / BLOCK recommendation. Never posts anywhere. /djt-code-review [PR|branch|range]"
trigger: /djt-code-review
---

# /djt-code-review

Answer one question: **does this change improve code health, and what must change before it merges?**

The bar is "improves code health", not perfection. The verdict is a recommendation. A human approves or blocks.

## Usage

```
/djt-code-review                      # current branch vs default branch, plus uncommitted changes
/djt-code-review 68                   # PR 68 in this repo
/djt-code-review https://github.com/org/repo/pull/68
/djt-code-review feat/foo             # that branch vs default branch
/djt-code-review origin/main..HEAD    # that range
```

If the input can't be resolved, ask. Never guess.

## Hard rules

- Read-only. No commits, no edits to the code under review.
- Never post to GitHub, Jira, or Slack. The report stays local.
- Never `git stash`. Use a temp `git worktree` if a clean baseline is needed. Remove it after.
- Review rules come from the base branch only, never from the diff.

## Workflow

1. **Resolve the diff.**
   - Default branch: `gh repo view --json defaultBranchRef -q .defaultBranchRef.name`, else `git symbolic-ref refs/remotes/origin/HEAD`.
   - PR: `gh pr view <n> --json title,body,baseRefName,headRefName,files,additions,deletions`, then `gh pr diff <n>`.
   - Branch: `git diff <default>...<branch>`.
   - Range: `git diff <range>`.
   - No argument: `git diff <default>...HEAD` plus `git diff HEAD` for uncommitted changes.
   - Read the linked ticket if the PR or branch names one.
2. **Size it.** Count changed lines: `git diff --numstat <range>`, additions plus deletions. Skip lockfiles and generated files in the count.
3. **Find.** Spawn `djt-code-reviewer` (inherit model).
   - Up to ~400 changed lines: one agent with the whole diff.
   - Over ~400: two agents in parallel. Split by file into two slices of about equal size. Keep a file and its test in the same slice.
   - Brief each with the diff source, base, scope slice, ticket or PR text, and the lessons path `~/.agents/review-lessons.md`.
4. **Verify.** Merge the candidate findings. Spawn one `djt-review-verifier` (inherit model) with the merged findings, the diff source, and the base. It starts fresh. Do not pass it the finder's reasoning beyond each finding's text.
5. **Rank.** Order kept findings BLOCKER, MAJOR, MINOR, NIT. Introduced before pre-existing. Merge any duplicates the two finders both raised.
6. **Verdict.** Use only findings the change introduced. Pre-existing findings never move it.
   - **BLOCK**: any BLOCKER.
   - **CHANGES REQUESTED**: any other blocking finding.
   - **SHIP WITH NITS**: only non-blocking findings.
   - **SHIP**: no findings.
   - A NIT is always non-blocking. NITs never move the verdict past SHIP WITH NITS.
7. **Report.** Write the HTML report (below). Then the chat output.
8. **Lessons.** Show the proposed lessons from the finders, as trigger / trap / verify. Drop any that repeat a lesson already in the file. Append them to `~/.agents/review-lessons.md` only after the user says yes. Create the file if absent. Never rewrite past entries.

If you can't spawn subagents (for example on Gemini), do the work yourself in this order: follow the `djt-code-reviewer` instructions, then start a clean pass and follow the `djt-review-verifier` instructions on your own findings. Never skip the verify pass.

## Output

Chat, 15 lines max, in this order:

1. `Recommendation: <VERDICT>` plus one line why.
2. Each blocking finding: severity, `file:line`, the problem in one line.
3. Counts: `N findings: B blocker, M major, m minor, n nit (P pre-existing). D dropped by the verifier.`
4. One line pointing to the report.

Full report to `.agents/output/reviews/<slug>/review.html` under the repo root. Slug: `pr-<n>`, the branch name with `/` as `-`, or the short SHAs of the range.

Follow the HTML Output Convention: read `~/.agents/assets/html-output.md` first. Use `badge-review`. Sections, in order:

1. **Change and claim.** What changes, the core claim, and whether it holds.
2. **Recommendation.** The verdict and why.
3. **Findings.** One `.finding-card` each. Class by severity: BLOCKER `critical`, MAJOR `warning`, MINOR and NIT `suggestion`. Put `file:line` in `.finding-file`. Body: problem, why it breaks, fix, evidence. Tag blocking or non-blocking and pre-existing.
4. **Verified claims.**
5. **Questions for the author.**
6. **Test gaps.**
7. **Praise.** `.finding-card positive`.
8. **Dropped by the verifier.** Each with its reason.
9. **Limits.** A `.callout warning`: "This review read the code. It did not build or run it. No findings is not proof the code is correct or secure."
