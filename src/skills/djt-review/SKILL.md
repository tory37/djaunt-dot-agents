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

Write a detailed review report to `.agents/output/reviews/<name>-<timestamp>.html`. Use the standard HTML shell from the **HTML Output Convention** in AGENTS.md (`badge-review`, depth-1 stylesheet path `../assets/style.css`). Bootstrap the stylesheet first if not present.

Structure the report with these sections:

**Summary** (`<h2>`) — High-level overview of the changes and overall quality. Include a `.meta-block` with key facts (files changed, overall verdict badge).

**Critical Findings** (`<h2>`) — For each finding: a `.finding-card.critical` with `.badge-critical` badge, `.finding-title`, `.finding-body` explanation, and `.finding-file` chip(s) for affected files.

**Suggested Improvements** (`<h2>`) — Each as `.finding-card.warning` with `.badge-warning`.

**Positive Notes** (`<h2>`) — Each as `.finding-card.positive` with `.badge-suggestion`.

**Test Coverage** (`<h2>`) — Summary paragraph, then a `.checklist` of what's covered and what's missing.

**Files Reviewed** (`<h2>`) — Render file paths as `.file-chip` elements inside a `.files-list` div.

### 5. Present Summary

Provide a concise summary of the review in the terminal, including a link to the full report.
