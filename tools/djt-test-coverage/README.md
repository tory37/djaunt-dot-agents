# djt-test-coverage

A two-phase test coverage audit and implementation skill. It scans your codebase, identifies coverage gaps by category, produces a prioritized checkbox report, and then implements only the tests you approve — on a dedicated branch.

## How it works

**Phase 1 — Audit:** The skill detects your testing framework(s), maps every source file to its test file, and evaluates coverage depth across seven categories. Results are written to a markdown report with checkboxes.

**Phase 2 — Apply:** You check the boxes for the gaps you want fixed, then re-invoke with `--apply`. The skill creates a branch, implements only the checked tests, and waits for you to confirm they pass before committing.

## What it checks

Seven coverage categories, scoped to what your framework can actually test:

- **A** Public API — every exported function/class has at least one test
- **B** Error paths — every `try/catch`, guard, and validation failure is exercised
- **C** Boundary and edge cases — zero, null, empty, max/min, single-element
- **D** State mutations — writes to stores, databases, or caches assert the resulting state
- **E** Integration seams — HTTP/DB/file calls have a stub or integration test
- **F** Async correctness — async functions are tested with proper await/resolution assertions
- **G** Branch coverage — every branch of a conditional is exercised by at least one test

## Framework awareness

The skill detects your framework(s) from config files and manifests before evaluating anything. Its boundaries (what it cannot test) are documented in the report so you know exactly what was excluded and why.

Supported frameworks include: Jest, Vitest, Mocha, Jasmine, pytest, Go test, RSpec, GUT (Godot), PHPUnit, and others detected from config.

## Install

```bash
bash tools/djt-test-coverage/install.sh --target /path/to/your/project
```

## Usage

```
/djt-test-coverage                    # audit entire project
/djt-test-coverage src/               # audit a specific directory
/djt-test-coverage src/auth/login.ts  # audit a specific file

# After checking boxes in the report:
/djt-test-coverage --apply .agents/output/coverage/<report>.md
```

Reports are written to `.agents/output/coverage/<scope>-<date>.md` with findings labeled by priority (Critical / High / Medium / Low) and category (A–G).
