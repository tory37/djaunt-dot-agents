---
name: djt-research
description: Synthesizes high-density research into a strategic product document. Use when starting deep research for a specific domain or app feature.
trigger: /djt-research
---

# Research-to-Strategy Engine

## 1. Overview

This skill transforms broad research topics into a "Research-backed Strategy Document." It operates with high-density information, prioritizing mechanics, grounded evidence, and transparent sourcing over generalities.

### Core Mandates

- **Grounded Truth**: ZERO hallucination. Every claim, data point, or technical assertion MUST be backed by a source and cited inline.
- **File-First Delivery**: All reports MUST be written to `.agents/research/<domain>-<timestamp>.md`. Do NOT print the report to the terminal.
- **Concise Reporting**: After writing the file, provide only a high-level summary of the research effort in the terminal.

## 2. Intake Protocol (CRITICAL)

Before acting, Claude must evaluate the provided information.

- **IF** the user provides a topic but no data: Provide the **Input Template** below and ask the user to fill it out.
- **IF** the user provides data but it is thin: Ask 3-5 targeted clarifying questions to ensure the "Success/Failure Matrix" can be populated with high-density facts.
- **IF** the user provides a full context: Proceed directly to **Step 3**.

### [Input Template]

Please provide the following to begin:

1. **Domain:** (e.g., Japanese SLA, Fintech Security, Sustainable Urbanism)
2. **Target Output/Product:** (e.g., dekigo.app, a technical whitepaper, a new SaaS feature)
3. **Core Conflict:** (e.g., "The SOV vs SVO mental shift," "Scaling speed vs data integrity")
4. **Specific Constraints:** (e.g., "Focus on adult learners," "Must be applicable to mobile-first UX")

## 3. Execution Phase

Produce a single Markdown document with the following sections. Maintain a "Senior Applied Researcher" persona. Every claim must be followed by an inline citation: `[Source Name](URL)`.

### Section I: The Success/Failure Matrix

- **Drop-off Points**: Identify 3-4 statistically common points of failure or "plateaus."
- **The High-Fluency Delta**: Contrast the specific behaviors of top 1% performers vs. "perpetual beginners."

### Section II: Domain-Specific Cognitive Load

- Analyze the primary mental "bottlenecks."
- Focus on the shift from [State A] to [State B].

### Section III: The "Working" Stack

- Provide the top 3 evidence-based methodologies.
- Use a table to show: **Method | Theoretical Basis | Practical Implementation.**

### Section IV: Implementation & Retention

- Contrast "Engagement Theater" (low-value features) vs. "Active ROI" (high-retention mechanics).
- Define how the "Forgetting Curve" applies specifically to this domain.

### Section V: The 5 Inviolable Laws

- List 5 non-negotiable strategic mandates for the product's success.

### Section VI: Sources & Bibliography

- List all sources used in the research, including titles and URLs.

## 4. Final Delivery & Constraints

### Terminal Output Protocol

Once the report is written to disk, output ONLY the following summary to the user:

> Research complete.
>
> - **Sources searched**: [X]
> - **Sources cited**: [Y]
> - **Report location**: `.agents/output/research/<filename>.md`

### Constraints

- **Mandatory Citations**: Any claim lacking a citation must be removed or marked explicitly as an "Unverified Hypothesis."
- **No Terminal Bloat**: Do NOT print the report content to the console.
- **High-Density Text**: Prioritize facts and mechanics over flowery prose.
- **Strictly Markdown**: The report file must follow clean Markdown formatting.
tting.
