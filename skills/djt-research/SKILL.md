---
name: research-to-strategy
description: Synthesizes high-density research into a strategic product document. Use when starting deep research for a specific domain or app feature.
---

# Research-to-Strategy Engine

## 1. Overview
This skill transforms broad research topics into a "Research-backed Strategy Document." It operates with high-density information, prioritizing mechanics and evidence over generalities.

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
Produce a single Markdown document with the following sections. Maintain a "Senior Applied Researcher" persona.

### Section I: The Success/Failure Matrix
* **Drop-off Points:** Identify 3-4 statistically common points of failure or "plateaus."
* **The High-Fluency Delta:** Contrast the specific behaviors of top 1% performers vs. "perpetual beginners."

### Section II: Domain-Specific Cognitive Load
* Analyze the primary mental "bottlenecks." 
* Focus on the shift from [State A] to [State B] (e.g., "Context-Heavy" to "Grammar-Heavy").

### Section III: The "Working" Stack
* Provide the top 3 evidence-based methodologies.
* Use a table to show: **Method | Theoretical Basis | Practical Implementation.**

### Section IV: Implementation & Retention
* Contrast "Engagement Theater" (low-value features) vs. "Active ROI" (high-retention mechanics).
* Define how the "Forgetting Curve" applies specifically to this domain.

### Section V: The 5 Inviolable Laws
* List 5 non-negotiable strategic mandates for the product's success.

## 4. Constraints
* **No conversational filler.**
* **High-density text.**
* **Strictly Markdown.**
* **Use tables and bullet points for scan-ability.**