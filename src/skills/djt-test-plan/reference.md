# /djt-test-plan — Reference

Full rules for `SKILL.md`. Read this before Step 1. Section numbers match `SKILL.md`.

## Principles (non-negotiable)

1. **Tight, change-driven scope.** A case belongs in the plan only if its outcome *could change because of this change* — it hits a path the diff touched, a branch whose condition moved, or behavior the source explicitly claims. Everything else is out of scope. Do not list or explain what is out of scope — the plan's silence is the answer.
2. **Sequential efficiency first, importance second.** Order cases to minimize configuration changes — proxy script swaps, account switches, feature flag toggles. Group cases that share the same setup together and run them back-to-back. Within a setup group, order by `likelihood-of-breakage × impact`. **Never force the tester to return to a previous configuration to cover a higher-ranked case** — a test plan that requires backtracking is worse than one that doesn't, regardless of importance order. Importance informs which group runs first, not individual case position within the sequence.
3. **One case per behavior, not one case per environment.** Write test cases that describe the behavior being validated. Environment-specific details (URLs, mitmweb commands, config values) live in the Scripts section and Notes, not as separate cases. Never write "TC2: test X on dev2" and "TC3: test X on prod2" — that is always wrong. If two environments test the same thing, it is one case with two env command blocks.
4. **Real API when the contract changed; injection when the pathway is unchanged.** Ask first: *does this change touch how the app calls the API — a new operation, a new request field, a new expected response shape, or a newly consumed field?* If yes, a mitmproxy-injected response **cannot verify that contract** — it bypasses the real network entirely. Those cases must hit the live endpoint directly. Use fault injection only when the behavior under test uses **existing, verified API pathways** and the goal is to simulate a specific network condition or response variant that is hard to produce by clicking alone. Mislabeling an API-contract case as "use injection" hides real integration failures.
5. **See-it-or-ask URL resolution.** Bake in only values you can directly observe in the repo or the source. If a target host or link is not discoverable, **ask the user** — never guess, synthesize, or pattern-match a production endpoint.
6. **Terse case rows.** One line of intent + terse steps + inline expected result per case. Setup stated once, never repeated per case. Scripts referenced by name, never embedded in a row.
7. **Honest about confidence.** Flag speculative cases vs. certain ones, and list gaps.
8. **Executable as written.** Anything the reader must type, paste, or run has a **copy button** (doer artifact) or sits in its **own code block** (posted plan — Jira and GitHub render a copy button per block). Anything the reader must open is a **link**. The reader should never retype a value or hunt for a URL.
9. **No secrets.** Never put passwords, tokens, or API keys in either plan. Test account emails and student/org IDs are fine. For credentials, say where to find them.

---

## Workflow

### Step 1 — Gather context, and spot the source

Determine **what changed**, **why**, and **where the request came from**.

- If a diff/branch/PR is given (or inferable from the current branch), read the changed files. Identify the network responses, state branches, and edge conditions the change keys off — these are the candidate test points and fault-injection sites.
- If a ticket/spec/prose is given, read it for intent and acceptance criteria.
- Use both when both are available: the diff supplies the *mechanism* (where to inject faults), the ticket supplies the *intent* (what to assert).
- If you have neither a diff nor a description, say so and ask the user what changed before continuing.
- **Resolve the plan destination now** (see Step 8) and collect the links the doer will need: ticket, PR, app URLs per environment, log/dashboard links, design links. Only collect what you can see (Principle 5).

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
| **Mutate** | "has X but not Y" permutations (e.g. assess but no spanish) | Python script parses JSON response body, rewrites specific fields, and re-encodes |
| **Latency** | loading-state flashes, race conditions, debounce/cancel bugs | Python script calls `time.sleep()` before allowing the flow to continue |

Only the cases that earn a fault get a script. Most cases are plain interaction steps.

**If any case is marked for injection**: do not proceed to Step 5 or Step 6 until the Step 4 environment gate is satisfied. The gate is blocking.

### Step 4 — Resolve environments and target URLs (blocking gate when injection is in play)

**Gate trigger:** If zero cases require injection, skip this gate — no URLs are needed for a plain-interaction plan and you may proceed directly to Step 6.

**If any case requires injection**, stop and ask the user before writing anything further:

1. "Which environments do you need this tested against? (e.g. dev2, prod2, local)"
2. For each fault-injection case, list the specific host you need: "For TC{n} ({fault} `{OperationName}`), I need the GraphQL host for each environment above."
3. If you found a candidate URL in the repo (env config, build profiles, `process.env.*_URL`, etc.), present it for confirmation — do **not** silently assume it is correct: "I found `<URL>` in `<file>` — does that map to `<env>`?"

Do not generate scripts or the final plan until all needed hosts are confirmed by the user.

Once confirmed, map each environment's host to its mitmweb command in the Scripts section (Principle 3).

### Step 5 — Generate the mitmweb scripts

See **mitmproxy script conventions** below. Generate host-agnostic, operation-matched Python scripts (so the fault logic is portable across environments), one per case, with each environment's host supplied for the CLI `--allow-hosts` scope and any URL-based cases.

Scripts always ship as **heredoc blocks inside the plan** — never as files in the repo. Hold them in memory until the plan is written.

### Step 6 — Write the plan

One plan. QA runs it as written, so write every row for a tester with no repo access: what they see and do. No repo paths, function names, stack traces, or root cause. Environment-specific values (local vs deployed) go in Setup and Notes (Principle 3). Follow the **Doer plan artifact** spec below. Publish it, give the user the link, then **stop**.

### Step 7 — Wait for the doer's result

The user runs the plan and reports back. Handle each outcome:

- **Failures found** — the change needs fixing. Fix, then update the same artifact (the case list may change).
- **All pass / local validation done** — proceed to Step 8.
- **Rows skipped** (no account, no device, no flag) — keep them in the plan and mark them skipped. QA picks them up.

If the user pasted the artifact's **Copy results** output, use it. Otherwise ask for a one-line outcome per row.

### Step 8 — Post the plan to the ticket's Doer Test Plan field

Only after the doer confirms local validation. Post the same plan, converted to markdown per the **Ticket plan format** below. Never write a separate QA plan. Never offer one.

Find the destination. The source of the request wins. Signals, strongest first:

1. **A resource the user named** — a ticket URL, PR URL, card, or Slack thread.
2. **A ticket** — the input is a ticket key, the current branch matches a ticket pattern (e.g. `PROJ-####`).
3. **An open PR** for the current branch (`gh pr view`).
4. **Where the request originated in this conversation** — a pasted ticket, thread, or link.

Typical cases:

- **Ticket in current work** — the common case. Set the ticket's **Doer Test Plan** field. A PR for the same change does not change this.
- **PR only, no ticket** — post a PR comment.
- **Request started in a thread, doc, or other tool** — post there if you can write to it. Otherwise ask.

**When the destination is clear**, say it in one line, then post: "Plan going to PROJ-1615, Doer Test Plan field."

**When it is unclear, ask before posting.** Unclear means: two candidates that disagree (different tickets), none found, or a destination you cannot write to. Post to exactly one place.

Mechanics:

- **Jira** — look up the Doer Test Plan field by name in the issue metadata, then set it with the Jira tool available (MCP or CLI). If the field already has content, show it and ask before replacing.
- **PR** — `gh pr comment`.
- **Anywhere else** — use that tool if it exists; otherwise ask.
- **If the post fails, or no remote place exists** — write `.agents/output/<type>/<slug>/test-plan.md` and say why. Do not retry silently or suggest another host.

The posted plan is the only markdown copy. No local copy unless the post failed.

### Step 9 — Present a summary

In the terminal, short:

- **After the artifact:** the change under test, count of cases, which carry scripts, environments covered, the artifact link, and the line "Plan will go to `<destination>` — say so if wrong." Restate any gaps or values you had to ask for.
- **After the post:** where it landed (field, comment link, or file path), and which rows are marked skipped.

---

## Doer plan artifact

Publish as an **Artifact** (private by default). Before writing it, load the `artifact-design` skill and follow its page contract. Write the source file to `.agents/output/<type>/<slug>/doer-test-plan.html` (`bugs/`, `features/`, or `techdebt/` per change type), then publish that path. Re-publish the same path to update.

If no Artifact tool exists, produce the same page as a self-contained styled HTML file per the **HTML Output Convention** in AGENTS.md (inline JS for copy buttons) and give the user the file path.

The page contains, in this order:

1. **Header** — the change under test, linked to the PR or ticket. Chips for environment and ticket key.
2. **Links** — everything the doer will open: ticket, PR, app URL per environment, the mitmweb UI (`http://127.0.0.1:19191`) when a proxy is in play, log or dashboard links, design links. Only links you can see or the user supplied (Principle 5). No broken or guessed links.
3. **Setup** — a short checklist, one line per item, each with a copy button on anything runnable or pasteable: branch checkout, local run command, test account email, student/org ID, flag name. Not repeated per case. When injection is in play, add the proxy-start step and point at the Scripts section.
4. **Cases** — one table, sequenced per Principle 2. Row order *is* run order. Each row has:
   - the `Do` and `Expect` text,
   - a **Pass / Fail / Skip** control and an optional note field.
   - Any value a row tells the tester to type or paste gets its own copy button.
5. **Notes** — the short bullet list (see **Test plan table rules**).
6. **Scripts** — every script, per the block granularity rule below. Each block has a copy button. Each script ships with its `mkdir -p ~/tc-scripts/<key>/` + heredoc install block.
7. **Copy results** — a button that copies the pass/fail/skip state and notes as markdown, for pasting back to the agent.

Copy-button rules:

- One button per independently-run unit. Never one button for a whole page of commands.
- The button copies the exact text shown. No hidden prefixes.
- Button gives visible feedback ("Copied") and degrades if the clipboard API is blocked (select the text).

Result state may persist in `localStorage` as a per-viewer convenience. Wrap every read and write in `try/catch`. The page must render without it.

Keep the length budget from the table rules. The artifact adds links, buttons, and result controls — not prose.

---

## Ticket plan format

A **handoff document**: markdown, never HTML. It is the same plan as the artifact, not a second plan. Written in Tory's voice (blunt, plain, no fluff), pitched at the tester.

Structure — nothing else:

- **Heading** — one line: the change under test, linked to the PR or ticket.
- **What changed** — one or two plain sentences on what the tester will notice. No root cause.
- **Dev-verified** — one line: what the author already confirmed locally, and which rows were skipped.
- **Setup** — one sentence. Environment, account/data precondition, whether a proxy is needed.
- **Cases** — the table from the rules below.
- **Notes** — the bullet list from the rules below.
- **Scripts** — only when a row needs injection. Fully self-contained, since the tester has no repo.

No local paths other than `~/tc-scripts/<key>/`. No repo references. Every runnable thing is in its own fenced code block, so it gets a copy button.

---

## Test plan table rules

Applies to the case table in both plans. **A table, not prose.**

**Length budget, enforced:** the plan must be shorter than the change deserves, not longer. A small diff gets one heading, one setup line, one table, and a handful of notes. Nothing else. If it runs past that, compress — do not add sections.

- **Cases** — a single table, sequenced per Principle 2. Row order *is* run order, most important first within a setup group.

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
- **Gaps / confidence** — only for a case you could not write at all, or a value nobody could supply. Anything a Notes bullet can carry belongs there instead. Omit the section entirely otherwise, which is the common case.

### Worked example

A frontend fix to a modal's close button plus two new dismiss gestures — five changed files. The case table and notes for the whole plan:

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
> - Nonverbal question 2+ still auto-opens the passage with the arrow and replays the intro audio. Expected, tracked on PROJ-2529 — not a regression.
> - The debug menu cannot be opened while the story is up.
> - Case 1 needs an ISIP-visibility account; skip it if none exists on dev2. Case 6 needs a physical iPad.

Note what it does *not* contain: no restatement of the bug, no root-cause summary, no list of what the unit tests already cover, no per-case importance label, no rationale paragraphs, and no Gaps section — the two genuine gaps are the last Notes bullet. In the doer artifact, this same table also carries links, copy buttons, and result controls. In the posted plan, it is converted to markdown per Step 8.

---

## Scripts section

At the bottom of both plans, after all cases. One block per script, titled `TC{n} Script`. Contains: the full mitmweb command per environment and the Python script body.

**Block granularity = one independently-run unit per block.** A unit is the set of commands the tester runs in one go without stopping:

- All four `networksetup` enable lines are one unit (one block).
- Both disable lines are one unit (one block).
- Each per-environment mitmweb command is its own unit (one block each, since the tester picks exactly one).
- Each script's `mkdir -p` + heredoc install is one unit.

Every block gets a copy button (doer artifact) or its own fenced block (posted plan). Splitting commands that belong together is just as bad as grouping commands that must be chosen between.

Example shape for two environments:

**TC1 — install script**
` ` `bash
mkdir -p ~/tc-scripts/TICKET && cat > ~/tc-scripts/TICKET/tc1-fail-x.py <<'EOF'
<script body>
EOF
` ` `
**TC1 — dev2**
` ` `bash
mitmweb --listen-port 9090 --set web_port=19191 --allow-hosts <dev2-host> -s ~/tc-scripts/TICKET/tc1-fail-x.py
` ` `
**TC1 — prod2**
` ` `bash
mitmweb --listen-port 9090 --set web_port=19191 --allow-hosts <prod2-host> -s ~/tc-scripts/TICKET/tc1-fail-x.py
` ` `
**Enable proxy** (new tab; leave mitmweb running)
` ` `bash
networksetup -setwebproxy "Wi-Fi" 127.0.0.1 9090
networksetup -setsecurewebproxy "Wi-Fi" 127.0.0.1 9090
networksetup -setwebproxystate "Wi-Fi" on
networksetup -setsecurewebproxystate "Wi-Fi" on
` ` `
**Disable proxy** when done, then Ctrl+C in the mitmweb tab
` ` `bash
networksetup -setwebproxystate "Wi-Fi" off
networksetup -setsecurewebproxystate "Wi-Fi" off
` ` `

Never use `# --- TC1 — dev2 ---` comment lines inside a shared block. Keeping scripts out of the case list is what makes the cases scannable.

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

- **Heredocs, no repo files.** Both plans ship each script as a `mkdir -p ~/tc-scripts/<key>/` + heredoc block the reader pastes once (`<key>` = the ticket key, else a short slug). No per-environment folders, no README files, no repo copies. Name each file after its case (`tc7-fail-getlicenses.py`).
- **Why the host still matters** even though scripts are host-agnostic: `--allow-hosts` prevents a prod fault from misfiring on local traffic and reduces mitmweb UI noise; any non-GraphQL/URL-based case needs the URL explicitly.
- **Every command is fully populated with real values — no `<placeholders>`** in the shipped plan. Each environment gets its own command block; there is no reason to leave any variable for the reader to fill in.
- **Paths are always absolute or home-relative** — never a bare filename. The reader opens the plan cold and does not know which folder to `cd` into. Use `~/tc-scripts/<key>/tc1-fail-x.py`.
- **Use these exact macOS commands** for the proxy (assume Wi-Fi; user can substitute their interface name):
  - `--listen-port 9090`: proxy port (avoids local dev servers on 8080).
  - `--set web_port=19191`: web UI on an uncommon port (8080-8083 are all commonly taken by local apps). The UI is at `http://127.0.0.1:19191`.
  - Enable and disable blocks are as shown in the **Scripts section** example.
