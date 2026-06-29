---
name: djt-test-plan
description: "Produce a tight, importance-ranked manual test plan scoped to a single change, with mitmweb fault-injection scripts generated per target environment. Places the plan on the active ticket or on disk. /djt-test-plan [target]"
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

Once confirmed: map each environment's host values so they can be dropped as inline blocks into the single case that covers that behavior. **Do not emit one case per environment** — env-specific values live inside the case, not as separate cases.

### Step 5 — Generate the mitmweb scripts

See **mitmproxy script conventions** below. Generate host-agnostic, operation-matched Python scripts (so the fault logic is portable across environments), grouped into one folder per environment that also carries that environment's host for the CLI `--allow-hosts` scope and any URL-based cases.

### Step 6 — Write the test plan

Follow the **test plan format** below. Importance-ordered, terse, setup-once, each fault case referencing its Python file by name.

### Step 7 — Place the output

- **Active ticket in play** (the input is a ticket key, or the current branch matches a ticket pattern such as `ASSMNT-####`): post the plan as a **comment on the ticket** (via the available Jira tooling). The Jira comment **must be fully self-contained** — a tester reading it has no access to the local repo or `.agents/output/`. For every fault-injection case, include: (1) a copy-pasteable `mkdir` + heredoc block to create the script file at `~/tc-scripts/<TICKET>/`, (2) the full `mitmweb` command referencing that path, and (3) the proxy enable/disable commands. No repo paths, no external file references. Also write the Python files to `.agents/output/` as the implementer's local reference copy.
- **No ticket**: write the plan to `.agents/output/bugs/<slug>/doer-test-plan.html` (or `features/`/`techdebt/` per the change type), with Python files alongside it. Use the standard HTML shell + stylesheet from the **HTML Output Convention** in AGENTS.md (`badge-bug`/`badge-feature`, bootstrap the stylesheet first).

### Step 8 — Present a summary

In the terminal: the change under test, count of in-scope cases by importance, which cases carry mitmproxy scripts, the environments covered, and the path/ticket where the plan landed. Restate any gaps or values you had to ask for.

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

- **Per-environment suite folder.** One folder per environment (e.g. `mitmproxy/dev2/`, `mitmproxy/prod2/`), each containing the readable `.py` script per case named to the test case (`tc7-fail-getamiralicenses.py`), plus a `README.md` with the exact copy-paste terminal sequence below. **Every command in a README must be fully populated with real values — no `<placeholders>`.** Each README is scoped to one environment; there is no reason to leave any variable for the reader to fill in.
- **Why the host still matters** even though scripts are host-agnostic: `--allow-hosts` prevents a prod fault from misfiring on local traffic and reduces mitmweb UI noise; any non-GraphQL/URL-based case needs the URL explicitly.
- **READMEs must use the full repo-relative path in the mitmweb `-s` flag** — never a bare filename. The reader opens a README cold; they don't know which folder to `cd` into. Using the full path (e.g. `.agents/output/bugs/slug/mitmproxy/dev2/tc1-fail-x.py`) means the command works from the repo root with zero navigation. Ticket comments are different — see Step 7.
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

Terse and importance-ordered. Suggested structure (HTML doc or ticket comment):

- **Header** — the change under test, source (ticket/diff), environments covered.
- **Setup (once)** — preconditions, accounts, flags, how to start `mitmweb` with the scripts + verify the mitmproxy CA cert is trusted. Never repeat per case.
- **Cases (sequenced per Principle 2)** — each a minimal block. Use this exact shape:

  ```
  TC1 — <intent> (<importance: highest / high / medium / low>)

  <real-data alternative when a fault script exists>
  Use fault injection (TC1 Script below) or: <what real state to find/use instead>.

  1. <step>
  2. <step>
  ✓ <expected result>
  ```

  Rules:
  - Every case that has a fault script **must also state the real-data alternative** — the tester chooses their path; do not assume injection is required.
  - Cases that need no injection just have steps + expected, no injection line.
  - Do not embed script content or mitmweb commands in the case body — reference by name only (`TC1 Script below`). Scripts live at the bottom.
  - Env-specific values (URLs, hosts) appear as a compact inline block only when they differ by environment; otherwise omit.

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
- **Gaps / confidence** — speculative cases and anything that couldn't be determined (e.g. a value that needed to be asked for but wasn't provided). Omit this section entirely if there are no genuine gaps.