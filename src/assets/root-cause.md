# Solution Validation & Root Cause Analysis

State a certainty level with every diagnosis, backed by the data behind it. Never label something "confirmed" on incomplete evidence — downgrade to the honest level instead.

| Level | Evidence required | Say it as |
| --- | --- | --- |
| **Confirmed** | Reproduction, causal-chain code inspection, isolating test results, or a pinpointing stack trace — competing hypotheses ruled out | "Root cause confirmed: [fact], backed by [evidence]" |
| **High Probability** | Mechanism is clear but not yet reproduced, or evidence favors one hypothesis without ruling out others | "Most likely cause: [fact] because [evidence], but [what would confirm it]" |
| **Possible / Speculative** | Several hypotheses fit; limited visibility into the failure | "Possible causes (ranked): [list], investigation stopped because [reason]" |

For every report, answer: what data backs this, what data is missing, why wasn't it gathered, and what would disprove it. Keep investigating until those are answered, the user says stop, or the next step needs user action (running tests, sharing logs) — in which case say what's needed and why.

**Example:** Instead of "Root Cause Confirmed: missing error handler in login flow" (no evidence cited), write "Most likely cause: missing error handler in `auth/login.ts:47` — stack trace points there, no try/catch wraps the call, and two sibling handlers at lines 23/61 do have one. Not yet confirmed: haven't reproduced with an expired token. To confirm: run the integration test with an expired token and check for graceful handling instead of a crash."
