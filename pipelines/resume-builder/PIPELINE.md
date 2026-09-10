# Resume Builder Pipeline

Pulls the user's real GitHub activity across their repos and synthesizes
one consolidated, copy-paste-ready resume section — optimized for both a
human reader and an ATS/LLM resume screener.

Follow the stages below in order. Each stage writes its result to disk
under `pipelines/resume-builder/output/<run-id>/` before the next stage
starts. Per-repo raw pulls and diff reads happen inside dedicated
subagents (stage 3) — that keeps this conversation's context bounded to
digests only, no matter how deep the per-repo analysis goes. Later stages
read only the small digests, never the raw pulls.

Pick `<run-id>` once, the first time this pipeline is ever run for real
(e.g. `full-history-2026-09-10`), and reuse the same `<run-id>` across
every session until the run finishes — this is one long-running pass
across the user's whole GitHub history, not a new run per day. `dryrun/`
is reserved for throwaway test runs and is gitignored; a real run's
`<run-id>` directory is not.

Requires `gh` (GitHub CLI), authenticated. If `gh auth status` fails, stop
and tell the user to run `gh auth login` first.

## Session management and resuming across sessions

This pipeline is expected to span multiple sessions and token-limit
resets — a full GitHub history pass is not a one-sitting job. **Do not**
keep one conversation alive across hours-long gaps or repeated
idle-wakeups waiting to continue; that drags accumulated chat history
forward and burns context for no benefit. Instead:

- The **ledger** (`output/<run-id>/ledger.md`) is the single source of
  truth for what's done. It is committed to git, human-readable, and
  cheap for a brand-new agent (or a brand-new session) to read cold.
- End the session freely once a batch of work lands and the ledger is
  updated. To resume — same session, new session, or a totally different
  agent with no memory of this one — just point it at this file
  (`PIPELINE.md`) and say which `<run-id>` to continue.
- **Stage 0 below is what makes that safe.** Always run it before doing
  any other stage's work, even if you think you already know the state.

## Stage 0 — Resume check (run this first, every time)

1. Look for an existing ledger: `output/<run-id>/ledger.md` (if the user
   didn't name a `<run-id>`, check `output/` for the most recent
   non-`dryrun` directory with a ledger and confirm with the user before
   continuing it).
2. If no ledger exists: this is a new run. Create
   `output/<run-id>/ledger.md` from the template below with stage 1
   marked pending, then proceed to stage 1.
3. If a ledger exists: read it in full. It tells you exactly which
   stages/repos are done, which are pending, and any resume notes a prior
   session left behind. **Do not redo a step the ledger marks done** —
   trust the disk state over any assumption. Resume at the first pending
   item. Do not re-run stage 3 for a repo whose digest file already
   exists and is marked done, even if you can't recall doing it.

### Ledger template

```markdown
# Resume Builder Run Ledger — <run-id>

Status: IN PROGRESS
Started: <date>
Login: <login>

## Stage 1 — Discovery
- [ ] repos.json written

## Stage 2 — Scoping
- [ ] selected-repos.json written (N repos selected)

## Stage 3 — Per-repo digests
<one checklist line per selected repo, added once selection is known.
small repos get one line; repos over ~60 commits get a nested checklist
per batch instead — see "Large repos" in Stage 3 of PIPELINE.md>
- [ ] <small-repo-name>
- [ ] <big-repo-name> (chunked, N batches)
  - [ ] batch 1 (<date range>)
  - [ ] batch 2 (<date range>)
  - [ ] merged into digest

## Stage 4 — Synthesis
- [ ] done

## Stage 5 — Final output
- [ ] resume-summary.md written

## Resume notes
<free text — anything a cold agent should know before continuing:
API quirks hit, repos that needed special handling, decisions made
mid-run, etc.>
```

Update the ledger **immediately** after each unit of work completes, not
batched at the end of a stage — if stage 3 spawns 5 repo subagents and
the session ends after 3 return, the ledger must show exactly those 3 as
done so the next session doesn't redo them or lose track of the other 2.
Commit the ledger (and any newly written digests) after each meaningful
update, since this is a private project and durability against a lost
chat matters more than clean commit history here — small, frequent
commits are correct for this pipeline's output.

## Stage 1 — Discover

1. `gh api user --jq '.login'` → the authenticated username.
2. `gh repo list <login> --json name,owner,description,isPrivate,isFork,pushedAt,primaryLanguage,url --limit 200`
   for personal repos.
3. `gh api user/orgs --jq '.[].login'` → list orgs the user belongs to.
4. Confirm with the user which orgs to include (a work org may span
   multiple GitHub orgs — e.g. an acquired company's separate org — and
   some orgs in the list may not apply at all). Don't assume; ask.

### Org repos — filter by authorship before presenting

A work org can hold hundreds of repos; most were never touched by the
user. Listing all of them for manual scoping in Stage 2 doesn't scale, and
GitHub's Search API (`search/commits`, `search/issues`) routinely 404s on
orgs that restrict search indexing for private repos — so authorship
filtering has to go through the plain (non-search) commits endpoint,
per repo.

This step is bulk, mechanical API traffic (hundreds of repos × one
commits check each) — never do it inline. Spawn **one subagent per
selected org**, in parallel:

1. `gh repo list <org> --json name,owner,pushedAt,primaryLanguage,url,isFork --limit 1000`.
2. For each repo, check authorship without Search:
   `gh api repos/<org>/<repo>/commits -f author=<login> -f per_page=1`
   (non-empty array → touched). If empty, retry without the `author`
   filter and grep the first page's `commit.author.name`/`commit.author.email`
   against the user's known local git identities — same null-`login`
   linkage gap as personal repos (see Stage 3 note below) — before
   concluding the repo is untouched.
3. Keep only repos where authorship is confirmed. Write the filtered
   list to `output/<run-id>/discovery/org-<org-name>.json`.
4. Return only a one-line confirmation to the orchestrator: org name,
   repos scanned, repos kept.

Merge all org fragments plus the personal-repo list from steps 1-2 into
`output/<run-id>/discovery/repos.json`. Check off each org's scan in the
ledger as its subagent returns, not batched at the end.

5. Present a condensed table in chat: name, org/owner, primary language,
   last pushed, fork y/n. Batch in groups of ~20 if the list is long —
   don't dump 100+ repos in one wall of text.
6. Check off "repos.json written" in the ledger and commit.

## Stage 2 — Scope with the user

Ask the user which repos are actually relevant to a resume (exclude dead
experiments, forks with no real contribution, sandbox/tutorial repos,
anything private-and-irrelevant). This is a plain back-and-forth in chat —
repo counts routinely exceed what a 4-option multiple-choice tool supports,
so just ask them to list names or say "all except X, Y."

Write the confirmed subset to `output/<run-id>/selected-repos.json`. Check
off "selected-repos.json written" in the ledger, add one pending checklist
line per selected repo under Stage 3, and commit.

Stop here and wait for the user's answer before continuing — do not guess
which repos matter.

## Stage 3 — Per-repo deep analysis (one subagent per repo)

Raw `gh` pulls and commit diffs are large. Doing this inline would load all
of it into this conversation's context, permanently — nothing removes prior
tool output except compaction, and that's lossy and manual. Instead, spawn
one fresh subagent (`general-purpose`, no shared context) per repo. Its raw
pulls and diff reads live entirely inside its own context; only a short
digest crosses back. This is what actually keeps this conversation's
context low regardless of how deep each repo's analysis goes — not a
discipline of "don't re-read it," but structural isolation.

Run a few repos at a time (parallel `Agent` calls), not strictly one at a
time — the sequencing in earlier versions of this plan existed only to
protect this conversation's context, which a subagent already does on its
own. Skip any repo whose ledger checklist line is already checked — its
digest file already exists from a prior session.

As each subagent's confirmation comes back, immediately check off that
repo's line in the ledger and commit — do not wait for the whole batch to
finish before updating the ledger. This is what makes a mid-batch session
end safe to resume: the ledger always reflects exactly which digests
exist on disk, never "the whole batch, probably."

### Large repos — checkpoint within the repo, not just across repos

A repo worked on for years can have hundreds of commits — too much for one
subagent call to responsibly cover in one pass, and if that single call
fails or runs long, a resume would have to redo the whole repo from
scratch. Before spawning a repo's subagent(s), check its size cheaply:

```
gh api search/commits -f q="repo:{owner}/{repo} author:<login>" --jq '.total_count'
```

- **At or below ~60 commits:** proceed as a single subagent per repo,
  per the steps below.
- **Above ~60 commits:** this repo needs chunking. Pull just the ordered
  list of commit SHAs + dates (metadata only, cheap, fine to do inline —
  it's a short list, not diffs) and split it into contiguous batches of
  ~50 commits each, labeled by date range (e.g. `2021-01 to 2021-09`).
  Add a nested checklist under this repo's ledger line, one item per
  batch, plus a final "merged" item:

  ```markdown
  - [ ] big-repo (chunked, 4 batches)
    - [ ] batch 1 (2019-03 to 2019-11)
    - [ ] batch 2 (2019-11 to 2020-08)
    - [ ] batch 3 (2020-08 to 2021-05)
    - [ ] batch 4 (2021-05 to 2023-02)
    - [ ] merged into digest
  ```

  Spawn one subagent per batch (steps 1-6 below, but scoped only to that
  batch's commit range — pass the batch's SHA list or date range in the
  prompt), each writing a partial fragment to
  `output/<run-id>/digests/<repo-name>/batch-N.md` covering just that
  batch's role/contribution, notable technical work, and diffs sampled
  from *that batch's* commits. PRs, languages, metadata, and README only
  need pulling once for the whole repo — do that in batch 1's subagent (or
  a separate small subagent) and pass it forward, not re-pulled per batch.
  Check off each batch's ledger line as its fragment lands, same as any
  other unit of work — a session can end mid-repo and resume at the next
  unfinished batch.

  Once every batch for a repo is checked off, do the merge: read that
  repo's fragment files (small, already digested — safe to read directly,
  no subagent needed) and combine them into one
  `output/<run-id>/digests/<repo-name>.md` covering the repo's full span.
  Check off "merged into digest" and the repo's own top-level line, then
  commit.

For each repo (or each batch, if chunked) in `selected-repos.json`, spawn
a subagent with a self-contained prompt (it has no memory of this
conversation, so include the repo's `owner/name`, the user's `<login>`,
the output path, and — for a batch — the commit range it's scoped to)
instructing it to:

1. Pull commits authored by the user:
   `gh api repos/{owner}/{repo}/commits --jq '[.[] | select(.author.login=="<login>")]'`
   (paginate with `--paginate` for long-lived repos).
2. Pull PRs authored by the user:
   `gh pr list --repo {owner}/{repo} --author <login> --state all --json title,number,mergedAt,body --limit 100`
3. Pull language breakdown: `gh api repos/{owner}/{repo}/languages`
4. Pull repo metadata for scale signals:
   `gh api repos/{owner}/{repo} --jq '{stars: .stargazers_count, forks: .forks_count, created_at, pushed_at}'`
5. Read README and manifest files for tech-stack/purpose signal —
   whichever exist: `README.md`, `package.json`, `pyproject.toml`,
   `go.mod`, `Cargo.toml`, `requirements.txt`.
6. Identify the user's most substantial commits by diff size and read
   their actual diffs via `gh api repos/{owner}/{repo}/commits/{sha}` to
   see what was really built, not just what the commit message claims.
   Commit messages are often sparse or unhelpful — the diff is the source
   of truth for what the user actually did. Do this unconditionally, even
   when messages look informative — bad messages don't reliably predict
   trivial diffs, and vice versa. Before ranking by size, exclude noise
   that inflates diff size without reflecting real work: lockfiles
   (`package-lock.json`, `yarn.lock`, `poetry.lock`, `Cargo.lock`, etc.),
   generated/vendored files, pure reformat/lint-only commits, and merge
   commits.
7. Write one digest — role/contribution, specific technical work and
   problems solved (not just a tech-stack list), notable design
   decisions, and quantifiable signals (commit count, merged PR count,
   repo lifespan, stars/forks if meaningfully non-zero) — to
   `output/<run-id>/digests/<repo-name>.md`.
8. Return only a one-line confirmation as final output (e.g. "digest
   written for <repo-name>") — not the digest content. The digest lives on
   disk; there's no need to also pass it back through the subagent's
   return value into this conversation's context.

No raw data from any repo needs to land in `output/<run-id>/raw/` — the
subagent's own context is the scratch space, and it exits once its digest
is written.

## Stage 4 — Cross-repo synthesis

Once every selected repo has a digest, read the full digest set (small,
bounded — this is the only cross-repo read in the whole pipeline) from
`output/<run-id>/digests/`.

Apply `references/resume-writing-guide.md`:

- Cluster repos by tech-stack and role/domain overlap.
- Collapse each cluster into one bullet using the XYZ formula.
- Let genuinely distinct repos (different scale, novel domain, leadership
  role) keep their own bullet.
- Build a separate, plain-text skills/technologies line from the union of
  what actually showed up across digests — no invented skills.
- Target 4-8 total bullets regardless of how many repos went in.

Only start this stage once every line under Stage 3 in the ledger is
checked. Once synthesis is done, check off Stage 4 in the ledger and
commit.

## Stage 5 — Final output

Write exactly one file: `output/<run-id>/resume-summary.md`. Markdown,
copy-paste ready, containing:

1. A skills/technologies line (plain comma-separated, ATS-safe).
2. 4-8 experience bullets, each following the XYZ formula.

This is resume-register prose (strong past-tense action verb + tech +
quantified impact) — not casual chat voice. Resumes follow their own
established convention; this is a deliberate exception to any general
"write like the user talks" guidance elsewhere in this repo.

Print only a short chat summary pointing at the file path — do not paste
the full resume section into chat.

Check off Stage 5 in the ledger, set the ledger's Status to `DONE`, and
commit.
