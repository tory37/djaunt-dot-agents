# djt-code-reviewer — Checklist and Sources

Run every item that applies to the diff. Each item names its source. Items marked "internal lesson, unsourced" have no outside source.

## Standard of review

- [ ] The bar is "improves code health", not perfection. Source: Google, "The Standard of Code Review" — "definitely improves the overall code health of the system". https://google.github.io/eng-practices/review/reviewer/standard.html
- [ ] Mark polish as a nit. The author may ignore it. Source: same page — "Prefix it with something like 'Nit: '".
- [ ] Only findings the change introduced count toward the verdict. Tag the rest pre-existing. Source: Anthropic, "Severity levels" — "A bug that exists in the codebase but wasn't introduced by this PR". https://code.claude.com/docs/en/code-review-pull-requests
- [ ] Mark each finding blocking or non-blocking. Source: Conventional Comments, "decorations". https://conventionalcomments.org/

## Dimensions

Source for this section: Google, "What to look for in a code review". https://google.github.io/eng-practices/review/reviewer/looking-for.html

- [ ] **Design** (#design). "Does this change belong in your codebase?" Do the pieces fit together?
- [ ] **Functionality** (#functionality). Does it do what the author intended? Is that good for its users? Check edge cases and concurrency.
- [ ] **Complexity** (#complexity). "Too complex" means a reader cannot understand it quickly. Flag over-generality and speculative features.
- [ ] **Tests** (#tests). Unit, integration, or end-to-end as fits the change. Tests must fail when the code breaks.
- [ ] **Naming** (#naming). Long enough to say what it is or does. Not so long it is hard to read.
- [ ] **Comments** (#comments). Explain why code exists, not what it does.
- [ ] **Style** (#style). The repo's style guide and linter are the authority. Do not report what CI enforces.
- [ ] **Documentation** (#documentation). A change to how people build, test, use, or release code updates the docs.
- [ ] **Every line** (#every-line). Read every line in scope. Do not skim.
- [ ] **Context** (#context). Read the whole function and file, not only the hunk.
- [ ] **Good things** (#good-things). Tell the author about something done well. Conventional Comments: leave at least one praise per review.

## Claims and tracing

- [ ] State the core claim. Verify it against source. Every behavior claim cites `file:line`, "not an inference from naming". https://code.claude.com/docs/en/code-review-customize
- [ ] Contract and shape. Compare the serialized field set before and after. Check computed members, ignored fields, and inherited members before trusting reflection over a type. Confirm receivers still accept the shape. Source: internal reviewer practice, supported by the evidence rule above.
- [ ] Downstream. Open the real consumer of changed data.
- [ ] Upstream. List the real callers. Check present-to-absent transitions (clears, removals, resets). Show the search behind "no caller relies on this". Supported by Google #context and the evidence rule.

## Security

Source: OWASP Secure Code Review Cheat Sheet. https://cheatsheetseries.owasp.org/cheatsheets/Secure_Code_Review_Cheat_Sheet.html

- [ ] Input: "All inputs validated on server regardless of client-side checks". Allowlists over blocklists.
- [ ] Queries: "Parameterized queries or safely implemented stored procedures". Encode output for its context.
- [ ] Authn and session: strong salted hashes. Tokens with at least 128 bits of entropy. Sessions end on logout and timeout. Cookies HttpOnly, Secure, SameSite.
- [ ] Authz: "All access controls enforced server-side". "Default deny access policy". No horizontal or vertical privilege escalation.
- [ ] Crypto: modern algorithms. Secure random numbers. Keys stored and rotated. Hostnames verified.
- [ ] Secrets and config: "No hardcoded secrets". No internal detail in error messages. "Sensitive data not logged".
- [ ] Libraries: "Up-to-date libraries without known vulnerabilities". Apply any repo or org dependency rule from the base-branch rules files.
- [ ] Monitoring: auth failures and authz violations are logged. Logs are protected.

## Tests

- [ ] Test behavior, not implementation. "the actual test itself typically shouldn't need to change if the code's user-facing behavior doesn't change." A changed setup is fine. A changed assertion for unchanged behavior is the smell. https://testing.googleblog.com/2013/08/testing-on-toilet-test-behavior-not.html
- [ ] Mock coupling. "Changing the nature of calls to collaborators usually cause a mockist test to break." Flag interaction assertions that pin internal calls when an outcome could be asserted. https://martinfowler.com/articles/mocksArentStubs.html
- [ ] Prefer state checks (return value, stored row, emitted write) over call checks. Same Fowler article.
- [ ] Private-internals coupling: assertions on private helpers or call counts. Same sources.
- [ ] Tautological mirror: the test restates source structure, such as asserting a map holds the constant it was built from. Same sources.
- [ ] Magic-number assertion: a test asserts a tunable constant equals a literal. It breaks on a valid retune and proves no behavior. Derive inputs from the code's own constants. **Internal lesson, unsourced.**
- [ ] Config re-assertion: a test patches env or config and re-asserts wiring the module already states. **Internal lesson, unsourced.**
- [ ] Ask of each test: what production bug makes this fail? "None" is a finding.

## Noise control

Source: Anthropic, "Customize Code Review". https://code.claude.com/docs/en/code-review-customize

- [ ] Do not report CI-enforced lint, format, or type errors. Skip generated files and lockfiles.
- [ ] "Report at most five Nits per review."
- [ ] In one-off scripts and test-only code, report only near-certain, severe problems. The source example is a `scripts/` folder; a script that is the product gets the full review.
- [ ] Reserve high severity for changes that "break behavior, leak data, or block a rollback". Style, naming, and refactors are Nit at most.
- [ ] Review rules come from the base branch, "never from the pull request's own changes".

## Size

- [ ] Review at most 200 to 400 changed lines per pass. Split larger diffs across finders. Source: SmartBear — "no more than 200 to 400 lines of code (LOC) at a time". Cisco study, vendor-published: treat as a heuristic. https://smartbear.com/learn/code-review/best-practices-for-peer-code-review/
- [ ] Use the PR description to orient. Verify against source. Same SmartBear page, "author annotations".

## Limits

- [ ] Say the review did not build or run the code.
- [ ] "A review with no findings doesn't mean your code is error-free or secure." https://code.claude.com/docs/en/code-review

## Non-mutating review

- [ ] Never `git stash`. Use a temp `git worktree` for a clean baseline. Remove it after. Source: internal practice. Consistent with Anthropic's read-only review ("a review doesn't push commits"), https://code.claude.com/docs/en/code-review
