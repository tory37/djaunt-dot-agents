---
name: djt-review
description: "Perform a comprehensive code review of a branch, diff, or specific files. /djt-review [target]"
trigger: /djt-review
---

# /djt-review

Perform a comprehensive code review.

## Usage

```
/djt-review                     # review current unstaged changes
/djt-review origin/main..HEAD   # review changes between main and current branch
/djt-review path/to/file.ts     # review a specific file
```

## Steps

### 1. Gather Context

Identify the scope of the review. If a diff or branch is specified, list the changed files. Read the relevant files to understand the intent and implementation.

### 2. Analyze

Evaluate the code against the following criteria:

- **Correctness & Logic**: Does it do what it's supposed to? Are there edge cases?
- **Security**: Any vulnerabilities (XSS, injection, sensitive data leaks)?
- **Performance**: Inefficient loops, unnecessary allocations?
- **Maintainability**: Clear naming, modularity, adherence to project patterns?
- **Standards**: Does it follow the engineering standards defined in the project (e.g., `GEMINI.md`, `CLAUDE.md`, or `README.md`)?

### 3. Check Tests

Verify that the changes are accompanied by appropriate tests (unit, integration). If tests are missing or insufficient, note this as a high-priority finding.

### 4. Generate Report
Write a detailed review report to `.agents/output/reviews/<name>-<timestamp>.md`.

The report must follow this structure:

# Code Review Report

## Summary
<!-- High-level overview of the changes and overall quality. -->

## Critical Findings
<!-- Bugs, security issues, or major architectural concerns. -->
- [FINDING 1]: [EXPLANATION]

## Suggested Improvements
<!-- Non-critical but valuable refactors or optimizations. -->
- [IMPROVEMENT 1]: [RATIONALE]

## Positive Notes
<!-- What was done well. -->
- [NOTE 1]

## Test Coverage
<!-- Summary of existing tests and what might be missing. -->

## Files Reviewed
- [FILE 1]


### 5. Present Summary

Provide a concise summary of the review in the terminal, including a link to the full report.
