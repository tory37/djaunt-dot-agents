---
name: djt-test-plan
description: "Produce a tight, importance-ranked manual test plan scoped to a single change, with Proxyman fault-injection configs generated per target environment. Places the plan on the active ticket or on disk. /djt-test-plan [target]"
trigger: /djt-test-plan
---

# /djt-test-plan

Write a manual test plan that validates **one change** — usable unchanged for local pre-merge checks, QA on dev, and post-deploy production validation — and generate the Proxyman configs needed to exercise the hard-to-reach cases.

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

1. **Tight, change-driven scope.** A case belongs in the plan only if its outcome *could change because of this change* — it hits a path the diff touched, a branch whose condition moved, or behavior the source explicitly claims. Everything else is normal regression and is **excluded**. Name the exclusions in a short "Not covered" note so the reader trusts the tightness.
2. **Importance ranking, not time budgeting.** Order cases by `likelihood-of-breakage × impact`. Acceptance criteria and the riskiest changed path float to the top. No time estimates, no budget input.
3. **One plan, three environments.** The same cases validate local → dev → prod. A case names an environment only when behavior legitimately differs there.
4. **See-it-or-ask URL resolution.** Bake in only values you can directly observe in the repo. If a target host is not discoverable, **ask the user** — never guess, synthesize, or pattern-match a production endpoint.
5. **Terse house style.** Setup stated once, never repeated per case. One line of intent + terse steps + inline expected result per case. Configs referenced by filename.
6. **Honest about confidence.** Flag speculative cases vs. certain ones, and list gaps.

---

## Workflow

### Step 1 — Gather context

Determine **what changed** and **why**:

- If a diff/branch/PR is given (or inferable from the current branch), read the changed files. Identify the network responses, state branches, and edge conditions the change keys off — these are the candidate test points and fault-injection sites.
- If a ticket/spec/prose is given, read it for intent and acceptance criteria.
- Use both when both are available: the diff supplies the *mechanism* (where to inject faults), the ticket supplies the *intent* (what to assert).
- If you have neither a diff nor a description, say so and ask the user what changed before continuing.

### Step 2 — Derive the change-driven test cases

Apply the scope discriminator (Principle 1). For each candidate behavior, decide **in-scope** (could break *because of this change*) or **out-of-scope regression** (pre-existing behavior the change doesn't touch). Keep only in-scope cases. Rank the survivors by importance.

For each case capture: a one-line **intent**, terse **steps**, the **expected result**, and whether it needs network fault injection.

### Step 3 — Identify fault-injection points

For each case that cannot be reached by clicks alone (network failure, empty/odd payloads, latency races), map it to the fault vocabulary:

| Fault | Reproduces | Proxyman mechanism |
|---|---|---|
| **Drop / fail** | "network blocked", request rejected, `undefined`/thrown responses | Script matches the operation → overwrite response with a non-2xx status + error body so the client's error path fires |
| **Empty / malformed** | no-data edges, parse failures, empty-state UI | Script or Map Local returns an empty/garbled body |
| **Mutate** | "has X but not Y" permutations (e.g. assess but no evaluar) | Script rewrites specific response fields |
| **Latency** | loading-state flashes, race conditions, debounce/cancel bugs | Throttle/delay the matched operation |

Only the cases that earn a fault get a config. Most cases are plain interaction steps.

### Step 4 — Resolve environments and target URLs

- Determine which environments the user is validating. **If not explicit, ask** (e.g. "dev2 + prod2?") before generating configs.
- Resolve each environment's host/base URL on the **see-it-or-ask** rule:
  - **Directly discoverable** in repo config/env (e.g. `configs/exports.*.js`, `process.env.*_URL`, build profiles) → bake it in, no questions.
  - **Not discoverable** (e.g. a production endpoint that isn't embedded locally) → **ask the user for the exact URL(s).** Do not invent one.
- Produce **one fully-populated suite per environment**, values hardcoded — favor ready-to-go over parameterized scripts so prod-deploy validation needs zero edits.

### Step 5 — Generate the Proxyman configs

See **Proxyman config conventions** below. Generate host-agnostic, operation-matched scripts (so the fault logic is portable across environments), grouped into one folder per environment that also carries that environment's host for SSL-proxying scope and any URL-based cases.

### Step 6 — Write the test plan

Follow the **test plan format** below. Importance-ordered, terse, setup-once, each fault case referencing its config file by name.

### Step 7 — Place the output

- **Active ticket in play** (the input is a ticket key, or the current branch matches a ticket pattern such as `ASSMNT-####`): post the plan as a **comment on the ticket** (via the available Jira tooling). Write the config files into the repo output folder and reference their paths in the comment; also inline each short script in a fenced block so it can be pasted directly.
- **No ticket**: write the plan to `.agents/output/bugs/<slug>/doer-test-plan.html` (or `features/`/`techdebt/` per the change type), with config files alongside it. Use the standard HTML shell + stylesheet from the **HTML Output Convention** in AGENTS.md (`badge-bug`/`badge-feature`, bootstrap the stylesheet first).

### Step 8 — Present a summary

In the terminal: the change under test, count of in-scope cases by importance, which cases carry Proxyman configs, the environments covered, and the path/ticket where the plan landed. Restate any gaps or values you had to ask for.

---

## Proxyman config conventions

The reproduction primitive is **operation-level fault injection on a shared GraphQL endpoint**. Because every GraphQL call hits the same URL, matching must happen on the **request POST body** (the `operationName` / query name), not the URL. Proxyman's **Scripting** tool reads the body and can return a custom status/body — verified capability.

- **Match on the operation, not the host.** This makes the fault logic identical across local/dev/prod. Example shape (confirm the exact scripting API against `https://docs.proxyman.com/scripting` for the installed version):

  ```js
  // TC<n> — <fault> <OperationName>  (djt-test-plan)
  // Host-agnostic: matches the GraphQL operation in the request body.
  // Enable Proxyman SSL proxying for <env host> so this only fires on <env>.
  async function onResponse(context, url, request, response) {
    const body = request.body; // JSON dict for application/json
    const op = body && (body.operationName
      || (typeof body.query === "string" && (body.query.match(/\b(?:query|mutation)\s+(\w+)/) || [])[1]));
    if (op === "<OperationName>") {
      response.statusCode = 503;                 // drop/fail: client error path fires
      response.body = { errors: [{ message: "Simulated failure (djt-test-plan TC<n>)" }] };
    }
    return response;
  }
  ```

- **Per-environment suite folder.** One folder per environment (e.g. `proxyman/dev2/`, `proxyman/prod2/`), each containing the readable `.js` script per case, named to the test case (`tc7-fail-getamiralicenses.js`), plus a short `README.md` with: the environment host, the SSL-proxying domain(s) to enable, and how to load + toggle each script as you walk the cases.
- **Why the host still matters** even though scripts are host-agnostic: Proxyman needs the domain in its SSL-proxying allow-list to intercept HTTPS at all; scoping to the host prevents a prod fault from misfiring on local traffic; and any non-GraphQL/URL-based case needs the URL.
- **Import format caveat (verify on first real use).** Proxyman supports per-tool export/import of Scripting rules, but the exact bundle file format/extension is not pinned down in the docs. Emit the readable `.js` sources (always paste-able into the Scripting tool) and import instructions now; once the installed Proxyman's export format is confirmed, upgrade the skill to also emit a single one-click importable bundle. Do not fabricate a bundle format.

---

## Test plan format

Terse and importance-ordered. Suggested structure (HTML doc or ticket comment):

- **Header** — the change under test, source (ticket/diff), environments covered.
- **Setup (once)** — preconditions, accounts, flags, how to attach Proxyman + enable SSL proxying for the environment host. Never repeat per case.
- **Cases (ranked, most important first)** — each a single block:
  - *Intent* — one line.
  - *Steps* — terse, imperative.
  - *Expected* — inline checkpoint.
  - *Config* — filename reference when the case needs a fault (`→ proxyman/<env>/tcN-*.js`).
  - *Env* — note only if behavior differs by environment.
- **Not covered** — one line listing the adjacent regression surface deliberately excluded (so tightness is a choice, not an oversight).
- **Gaps / confidence** — speculative cases and anything that couldn't be determined.
