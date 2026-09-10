---
name: djt-test-plan
description: "Produce a tight, importance-ranked manual test plan scoped to a single change, with mitmweb fault-injection scripts generated per target environment. Posts the plan to the ticket or PR that owns the change; writes a local file only when no remote owner exists. /djt-test-plan [target]"
trigger: /djt-test-plan
---

# /djt-test-plan

Write a manual test plan that validates **one change** — usable unchanged for local pre-merge checks, QA on dev, and post-deploy production validation — and generate the mitmweb (mitmproxy) scripts needed to exercise the hard-to-reach cases.

This is the single entry point for **all manual-test-case authoring**. Any request to "write a test plan", "manual test steps", "QA steps", "how do I test this", or "doer test plan" routes through this skill.

## Usage

```
/djt-test-plan                       # infer the change from the current branch/diff
/djt-test-plan ASSMNT-1615           # work from a ticket
/djt-test-plan origin/develop..HEAD  # work from a diff range
/djt-test-plan @path/to/spec.md      # work from a spec/notes file
```

The skill is **input-agnostic**: it works on whatever it is given (diff, PR, ticket, prose, or just the current branch) and degrades gracefully — stating what it could not determine rather than guessing.

---

## Principles (non-negotiable)

1. **Tight, change-driven scope.** A case belongs in the plan only if its outcome *could change because of this change* — it hits a path the diff touched, a branch whose condition moved, or behavior the source explicitly claims. Everything else is out of scope. Do not list or explain what is out of scope — the plan's silence is the answer.
2. **Sequential efficiency first, importance second.** Order cases to minimize configuration changes — proxy script swaps, account switches, feature flag toggles. Group cases that share the same setup together and run them back-to-back. Within a setup group, order by `likelihood-of-breakage × impact`. **Never force the tester to return to a previous configuration to cover a higher-ranked case** — a test plan that requires backtracking is worse than one that doesn't, regardless of importance order. Importance informs which group runs first, not individual case position within the sequence.
3. **One case per behavior, not one case per environment.** Write test cases that describe the behavior being validated. Environment-specific details (URLs, mitmweb commands, config values) appear as **inline blocks inside the case**, not as separate cases. Never write "TC2: test X on dev2" and "TC3: test X on prod2" — that is always wrong. If two environments test the same thing, it is one case with two env config blocks.
4. **Real API when the contract changed; injection when the pathway is unchanged.** Ask first: *does this change touch how the app calls the API — a new operation, a new request field, a new expected response shape, or a newly consumed field?* If yes, a mitmproxy-injected response **cannot verify that contract** — it bypasses the real network entirely. Those cases must hit the live endpoint directly. Use fault injection only when the behavior under test uses **existing, verified API pathways** and the goal is to simulate a specific network condition or response variant that is hard to produce by clicking alone. Mislabeling an API-contract case as "use injection" hides real integration failures.
5. **See-it-or-ask URL resolution.** Bake in only values you can directly observe in the repo. If a target host is not discoverable, **ask the user** — never guess, synthesize, or pattern-match a production endpoint.
6. **Terse house style.** Setup stated once, never repeated per case. One line of intent + terse steps + inline expected result per case. Scripts referenced by filename.
7. **Honest about confidence.** Flag speculative cases vs. certain ones, and list gaps.

---

## Workflow

### Step 1 — Gather context

Determine **what changed** and **why**:

- If a diff/branch/PR is given (or inferable from the current branch), read the changed files. Identify the network responses, state branches, and edge conditions the change keys off — these are the candidate test points and fault-injection sites.
- If a ticket/spec/prose is given, read it for intent and acceptance criteria.
- Use both when both are available: the diff supplies the *mechanism* (where to inject faults), the ticket supplies the *intent* (what to assert).
- If you have neither a diff nor a description, say so and ask the user what changed before continuing.

### Step 2 — Derive the change-driven test cases

Apply the scope discriminator (Principle 1). For each candidate behavior, decide **in-scope** (could break *because of this change*) or **out-of-scope regression** (pre-existing behavior the change doesn't touch). Keep only in-scope cases.

Apply two additional filters before finalizing the case list:

1. **Condition reachability gate.** When the fix is gated on a compound boolean condition (e.g. `A && B`), trace each candidate case's preconditions against that gate. If the proposed test conditions make one or more branches of the gate permanently false — meaning the new code path cannot fire regardless of what the tester does — discard the case. It is structurally unreachable and cannot validate the change.
2. **Setup-step deduplication.** Before keeping a pure happy-path case, check whether its core assertion is already an implicit checkpoint in the setup or early steps of a higher-priority in-scope case. If the happy path must succeed for another case to even begin, it is already covered. Discard the duplicate.

For each case capture: a one-line **intent**, terse **steps**, the **expected result**, and what setup it requires (proxy script, account state, feature flag, etc.).

Then sequence the cases (Principle 2): group by shared setup, order groups by importance, order within each group by importance. The final sequence must be executable top-to-bottom with no backtracking.

### Step 3 — Identify fault-injection points

**Before assigning injection to any case, apply Principle 4:** if the change alters the API contract (new operation called, new field sent or consumed, changed response shape expected), that case must hit the real API — label it `[real API]`, not a fault script. Injection is only valid when the pathway is established and you are simulating a condition that is hard to reach by clicking alone.

For each case that cannot be reached by clicks alone (network failure, empty/odd payloads, latency races), map it to the fault vocabulary:

| Fault | Reproduces | mitmweb mechanism |
|---|---|---|
| **Drop / fail** | "network blocked", request rejected, `undefined`/thrown responses | Python script intercepts the flow and overwrites `flow.response` with a non-2xx status + error body so the client's error path fires |
| **Empty / malformed** | no-data edges, parse failures, empty-state UI | Python script overwrites `flow.response.text` with an empty/garbled body |
| **Mutate** | "has X but not Y" permutations (e.g. assess but no evaluar) | Python script parses JSON response body, rewrites specific fields, and re-encodes |
| **Latency** | loading-state flashes, race conditions, debounce/cancel bugs | Python script calls `time.sleep()` before allowing the flow to continue |

Only the cases that earn a fault get a script. Most cases are plain interaction steps.

**If any case is marked for injection**: do not proceed to Step 5 or Step 6 until the Step 4 environment gate is satisfied. The gate is blocking.

### Step 4 — Resolve environments and target URLs (blocking gate when injection is in play)

**Gate trigger:** If zero cases require injection, skip this gate — no URLs are needed for a plain-interaction plan and you may proceed directly to Step 6.

**If any case requires injection**, stop and ask the user before writing anything further:

1. "Which environments do you need this tested against? (e.g. dev2, prod2, local)"
2. For each fault-injection case, list the specific host you need: "For TC{n} ({fault} `{OperationName}`), I need the GraphQL host for each environment above."
3. If you found a candidate URL in the repo (env config, build profiles, `process.env.*_URL`, etc.), present it for confirmation — do **not** silently assume it is correct: "I found `<URL>` in `<file>` — does that map to `<env>`?"

Do not generate scripts, READMEs, or the final plan until all needed hosts are confirmed by the user.

Once confirmed: map each environment's host values so they can be dropped as inline blocks into the single case that covers that behavior (Principle 3 — one case per behavior, not per environment).

### Step 5 — Generate the mitmweb scripts

See **mitmproxy script conventions** below. Generate host-agnostic, operation-matched Python scripts (so the fault logic is portable across environments), one per case, with each environment's host supplied for the CLI `--allow-hosts` scope and any URL-based cases.

Hold the scripts in memory until Step 7 decides where they go. Do **not** write them to disk yet — when a remote owner exists they are embedded in the comment as heredocs and never touch the repo.

### Step 6 — Write the test plan

Follow the **test plan format** below. Importance-ordered, terse, setup-once, each fault case referencing its Python file by name.

### Step 7 — Place the output (a remote owner wins over local files)

First decide **whether a remote place owns this change**. Check in this order:

1. **A ticket** — the input is a ticket key, the current branch matches a ticket pattern (e.g. `ASSMNT-####`), or a `djt-kanban` card sits in `.agents/.kanban/3_doing/`.
2. **An open PR** for the current branch (`gh pr view`).
3. **Any resource the user named** in the invocation (a ticket URL, a PR URL, a card).

If more than one candidate exists, ask which one. Post to exactly one place.

#### A remote owner exists → post there, write nothing locally

The comment is the **only** artifact. Do not write `doer-test-plan.html`. Do not write a local copy of the Python scripts. Do not create `.agents/output/` folders or READMEs.

The comment must be **fully self-contained** — the reader has no access to the repo. For every fault-injection case include:

1. A `mkdir -p ~/tc-scripts/<key>/` + heredoc block that writes the script file (`<key>` = the ticket key, else a short slug).
2. The full `mitmweb` command per environment, pointing at `~/tc-scripts/<key>/<script>.py`.
3. The proxy enable block and the proxy disable block.

No repo paths. No references to local files. If the post fails, then — and only then — fall back to the local file and say the post failed.

#### No remote owner → write locally

Write the plan to `.agents/output/<type>/<slug>/doer-test-plan.html` (`bugs/`, `features/`, or `techdebt/` per the change type), with the Python files alongside it. Use the standard HTML shell + stylesheet from the **HTML Output Convention** in AGENTS.md (`badge-bug`/`badge-feature`, bootstrap the stylesheet first).

### Step 8 — Present a summary

In the terminal: the change under test, count of in-scope cases by importance, which cases carry mitmproxy scripts, the environments covered, and where the plan landed — the ticket/PR comment link, or the file path when there was no remote owner. Restate any gaps or values you had to ask for.

---

## mitmproxy script conventions

The reproduction primitive is **operation-level fault injection on a shared GraphQL endpoint** using mitmproxy's Python API. Because every GraphQL call hits the same URL, matching must happen on the **request POST body** (the `operationName` / query name), not the URL.

- **Match on the operation, not the host.** This makes the fault logic identical across local/dev/prod. Example shape:

  ```python
  import json
  import re
  from mitmproxy import http

  # TC<n> — <fault> <OperationName>  (djt-test-plan)
  # Host-agnostic: matches the GraphQL operation in the request body.
  # Run via: mitmweb --allow-hosts <env host> -s <script_name>.py

  def request(flow: http.HTTPFlow):
      if "/graphql" in flow.request.path and flow.request.method == "POST":
          try:
              body = flow.request.json()
              # Extract operation name directly or fallback to regex on query
              op = body.get("operationName")
              if not op and body.get("query"):
                  match = re.search(r'\b(?:query|mutation)\s+(\w+)', body["query"])
                  if match:
                      op = match.group(1)
              
              if op == "<OperationName>":
                  # Drop/fail: client error path fires
                  flow.response = http.Response.make(
                      503,
                      json.dumps({ "errors": [{ "message": "Simulated failure (djt-test-plan TC<n>)" }] }),
                      {"Content-Type": "application/json"}
                  )
          except ValueError:
              pass # Ignore invalid JSON
  ```

- **Remote owner → inline heredocs, no files.** When the plan is posted to a ticket or PR, each script ships inside the comment as a `mkdir -p ~/tc-scripts/<key>/` + heredoc block that the reader pastes once. No per-environment folders, no README files, no repo copies. Name each file after its case (`tc7-fail-getamiralicenses.py`).
- **Local fallback → per-environment suite folder.** Only when no remote owner exists: one folder per environment (e.g. `mitmproxy/dev2/`, `mitmproxy/prod2/`), each containing the readable `.py` script per case named to the test case, plus a `README.md` with the exact copy-paste terminal sequence below. **Every command in a README must be fully populated with real values — no `<placeholders>`.** Each README is scoped to one environment; there is no reason to leave any variable for the reader to fill in.
- **Why the host still matters** even though scripts are host-agnostic: `--allow-hosts` prevents a prod fault from misfiring on local traffic and reduces mitmweb UI noise; any non-GraphQL/URL-based case needs the URL explicitly.
- **Paths must always be absolute or repo-root-relative** — never a bare filename. The reader opens the plan cold and does not know which folder to `cd` into. In a ticket or PR comment, use `~/tc-scripts/<key>/tc1-fail-x.py`. In a local README, use the repo-relative path (e.g. `.agents/output/bugs/slug/mitmproxy/dev2/tc1-fail-x.py`) so the command works from the repo root.
- **Every README must include the full run sequence** using these exact macOS commands (assume Wi-Fi; user can substitute their interface name):

  ```bash
  # 1. From the repo root — start mitmweb with the full script path
  # --listen-port 9090: proxy (avoids local dev servers on 8080)
  # --set web_port=19191: web UI on an uncommon port (8080-8083 are all commonly taken by local apps)
  mitmweb --listen-port 9090 --set web_port=19191 --allow-hosts <env-host> -s .agents/output/<type>/<slug>/mitmproxy/<env>/<script>.py
  # mitmweb UI is now visible at http://127.0.0.1:19191

  # 2. Enable system proxy (new terminal tab — leave mitmweb running)
  networksetup -setwebproxy "Wi-Fi" 127.0.0.1 9090
  networksetup -setsecurewebproxy "Wi-Fi" 127.0.0.1 9090
  networksetup -setwebproxystate "Wi-Fi" on
  networksetup -setsecurewebproxystate "Wi-Fi" on

  # --- run your test case now ---

  # 3. Disable proxy when done
  networksetup -setwebproxystate "Wi-Fi" off
  networksetup -setsecurewebproxystate "Wi-Fi" off
  # Then Ctrl+C in the mitmweb terminal to stop it
  ```

---

## Test plan format

**A table, not prose.** Same structure whether it lands as a ticket/PR comment or — no remote owner — an HTML file.

**Length budget, enforced:** the plan must be shorter than the change deserves, not longer. A small diff gets one heading, one setup line, one table, and a handful of notes. Nothing else. If it runs past that, compress — do not add sections.

- **Heading** — one line: the change under test, linked to the PR or ticket.
- **Setup** — **one sentence**, inline under the heading. Environment, whether a proxy is needed, and the account/data precondition. Not a section, not a bullet list, never repeated per case. When injection is in play, add only "mitmweb running with `<script>`, CA cert trusted" — the commands live in the Scripts section.
- **Cases** — a single markdown table, sequenced per Principle 2. Row order *is* run order, most important first within a setup group.

  | # | Do | Expect |
  |---|---|---|
  | 1 | `<terse imperative actions, one row per behavior>` | `<what the tester should see>` |

  Rules:
  - **One row per behavior, not per assertion.** Gestures of the same family collapse into one row — "click the edge, click the text, drag from text off the edge" is one row with a combined expectation, not three.
  - **No importance labels.** Row order carries it. `(highest)` / `(high)` on every row is noise.
  - **No per-case rationale.** Why a case exists belongs in the PR, not the plan. The tester needs the action and the expectation.
  - Merge no-regression checks into one row where they share a setup.
  - Fault-injection rows name their script inline (`TC3 Script below`) and state the real-data alternative in the same cell. Never embed script bodies or mitmweb commands in a row.
  - Env-specific values go in the Notes, not in rows.
- **Notes** — a short bullet list after the table, only for things that change what the tester does or how they read a result. Typical members, and nothing beyond them:
  - a target that is hard to hit or measure (exact pixel bands, timing windows),
  - **known-expected behavior that looks like a bug** — say "expected, tracked on `<TICKET>`, not a regression", so it does not get filed against this change,
  - collateral a tester will trip over (a dev tool that is unreachable in this state),
  - which rows need an account, flag, or physical device that may not exist, and that they are skippable.

  This list replaces a separate Gaps section for anything a note can carry.

### Worked example

A frontend fix to a modal's close button plus two new dismiss gestures — five changed files. The whole plan:

> ## Doer test plan — [PR 6009](https://example.invalid/pr/6009)
>
> dev2, no proxy. Need a student with a reading-comprehension passage that has a reference story — the story button appears once the questions start.
>
> | # | Do | Expect |
> |---|---|---|
> | 1 | Badge showing (ISIP-visibility license, forced assessment), Chrome font size **Very large**. Reopen the story mid-questions, tap the X. | X visible at the book's top-right, drawn over the ribbon. Closes to the same question, answers intact. |
> | 2 | Reopen the story, press Escape. | Closes. |
> | 3 | Reopen, click near the left screen edge. Reopen, click the passage text. Reopen, drag from the text off the book. | Edge click closes. Text click and drag do not. |
> | 4 | Story open, narrow the window (or rotate a tablet to portrait). | "Please rotate your device" sits **above** the book. |
> | 5 | Nonverbal student, first read: press Escape, click off the book, then tap the green arrow. | No X. Escape and off-book do nothing. Only the arrow closes it and starts the questions. |
> | 6 | On an iPad: story open, tap just inside the left screen edge. | Closes. If nothing happens, report it — the X and Escape still work. |
> | 7 | Badge with no story open. Then the excerpts view in live reading: Escape, click off the book. | Badge unchanged. Excerpts close only via the X. |
>
> Notes
>
> - The off-book band is narrow — roughly 41px left, 68px right at 1366 wide. Aim at the screen edge.
> - Nonverbal question 2+ still auto-opens the passage with the arrow and replays the intro audio. Expected, tracked on ASSMNT-2529 — not a regression.
> - The debug menu cannot be opened while the story is up.
> - Case 1 needs an ISIP-visibility account; skip it if none exists on dev2. Case 6 needs a physical iPad.

Note what it does *not* contain: no restatement of the bug, no root-cause summary, no list of what the unit tests already cover, no per-case importance label, no rationale paragraphs, and no Gaps section — the two genuine gaps are the last Notes bullet.

- **Scripts section (at the bottom, after all cases)** — one block per script, titled `TC{n} Script`. Contains: the full mitmweb command per environment and the Python script body. **Block granularity = one independently-run unit per block.** A unit is the set of commands the tester runs in one go without stopping — all four `networksetup` enable lines are one unit (one block), both disable lines are one unit (one block), and each per-environment mitmweb command is its own unit (one block each, since the tester picks exactly one). Jira renders a copy button per block; splitting commands that belong together is just as bad as grouping commands that must be chosen between. Example shape for two environments:

  **TC1 — dev2**
  ` ` `bash
  mitmweb --listen-port 9090 ...dev2-host... -s ~/tc-scripts/TICKET/tc1-fail-x.py
  ` ` `
  **TC1 — prod2**
  ` ` `bash
  mitmweb --listen-port 9090 ...prod2-host... -s ~/tc-scripts/TICKET/tc1-fail-x.py
  ` ` `
  **Enable proxy** (new tab; leave mitmweb running)
  ` ` `bash
  networksetup -setwebproxy "Wi-Fi" 127.0.0.1 9090
  networksetup -setsecurewebproxy "Wi-Fi" 127.0.0.1 9090
  networksetup -setwebproxystate "Wi-Fi" on
  networksetup -setsecurewebproxystate "Wi-Fi" on
  ` ` `
  **Disable proxy** when done
  ` ` `bash
  networksetup -setwebproxystate "Wi-Fi" off
  networksetup -setsecurewebproxystate "Wi-Fi" off
  ` ` `

  Never use `# --- TC1 — dev2 ---` comment lines inside a shared block. Keeping scripts out of the case list is what makes the cases scannable.
- **Gaps / confidence** — only for a case you could not write at all, or a value nobody could supply. Anything a Notes bullet can carry belongs there instead. Omit the section entirely otherwise, which is the common case.