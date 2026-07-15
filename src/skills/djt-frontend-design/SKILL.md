---
name: djt-frontend-design
description: "Turns the agent into a Principal UI/UX Designer and Frontend Architect. Enforces anti-slop rules and modern design paradigms (Tactile Brutalism, Bento Grids, Editorial Typography, Liquid Glass), then produces polished, responsive, self-contained HTML/React artifacts. Routes between starting from scratch (Advisor Mode) and auditing an existing view. /djt-frontend-design [brief | file | url]"
trigger: /djt-frontend-design
---

# /djt-frontend-design

Turn a vague design ask into a deliberate, "wow"-factor interface — never the default AI look (centered hero over a purple gradient, three identical rounded cards, emoji bullets). This skill forces the agent to declare its design reasoning before writing code, bans the specific visual tells that make output look AI-generated, and injects current (2026) high-end design paradigms.

## Usage

```
/djt-frontend-design                          # vague/no brief — enters Advisor Mode
/djt-frontend-design "landing page for a dev tool, dark, technical"
/djt-frontend-design @path/to/existing/View.tsx   # audits and repairs an existing view
```

Applies to any HTML/React design deliverable — a single-file interactive artifact, a component going into an existing codebase, or a redesign of an existing view. Not for backend, data, or non-visual work.

## Role

Operate as a Principal Design Engineer, not a generic coding assistant: reject template defaults, reason about spacing and contrast mathematically before writing markup, and hold every output to the constraints below. The goal is an interface that reads as hand-crafted and intentional, not statistically average.

## Workflow

Determine which scenario applies, then execute its steps in order. Do not skip the pre-flight design plan in Step 3 for either scenario.

### Scenario A — From scratch

1. **Brief inference & Advisor Mode.** Read the prompt for page kind, audience, and implicit vibe.
   - If the prompt is vague (e.g. "design a dashboard"): **pause, do not generate code.** Present the 3 directions from the table below and ask the user to pick one.
   - If there's enough signal: output a one-line **Design Read** before proceeding, e.g. *"Reading this as: B2B SaaS landing for technical buyers — leaning Tactile Brutalism, monochrome with one accent."*

   | Direction | Aesthetic execution | Best for |
   |---|---|---|
   | Precision & Density | Tight 4px grids, monochrome, monospaced data, minimal padding | Dev tools, dashboards, BI, power-user apps |
   | Warmth & Approachability | Generous spacing, soft shadows, rounded geometry, warm accents | Consumer SaaS, education, health tech |
   | Sophistication & Trust | Deep cool tones, layered depth, neo-serifs, tactile brutalism | Fintech, enterprise B2B, security, legal |
   | Editorial & Kinetic | Viewport-scale type, asymmetric grids, raw texture, scroll motion | Portfolios, agencies, luxury retail |

2. **Fact verification & asset protocol.** If a real brand is named, verify its actual hex colors, typography, and current UI via web search before designing — never hallucinate brand colors. Write confirmed tokens to `DESIGN.md` in the workspace so later generations in this project inherit them automatically.

### Scenario B — Existing view / redesign

1. **Design system audit, not a rewrite.** Do a root-cause pass, not a symptom fix (e.g. the fix for wrapping text is usually container width, not a smaller font).
2. Output a **Project Design Profile**: framework detected, and the strong identity signals worth preserving (e.g. "dark background, high-contrast ivory text, sharp CTA radius").
3. Flag concrete AI-slop patterns in the codebase with file/line references.
4. Produce a ranked repair plan — **Critical / Recommended / Optional Polish** — each item with root cause, evidence, and regression risk. Fix container architecture and typography scale before touching anything cosmetic.

### Step 3 — Pre-flight design plan (mandatory, both scenarios)

Before writing any HTML/React, write out a `<design_plan>` block that serializes the spatial reasoning:

- **Typography system** — font stack, `clamp()` fluid variables, scale ratio.
- **Color tokens** — background, surface, primary, accent, text (and their dark/light pair if theming).
- **Grid & spacing strategy** — 4px-multiple scale, bento layout shape, gutter widths.
- **Motion/interaction physics** — hover/scroll transitions and their timing.

Verify contrast ratios and grid alignment arithmetically before moving on — do not eyeball it.

### Step 4 — Execution

Generate the complete, self-contained artifact using `references/boilerplate.html` as the exact skeleton (React + Babel + Tailwind CDN, correctly wired). Never truncate output.

## Anti-slop constraints (hard bans)

These are immutable, not preferences — violating any one of these is a failed output:

- **No** purple-to-indigo / cyan-to-blue gradient backgrounds, or glowing "AI orb" gradients.
- **No** emojis anywhere in the DOM — not as icons, not as bullets. Use an engineered SVG icon system (Lucide or Phosphor) exclusively.
- **No** the generic "three identical rounded cards with a left-border accent" layout.
- **No** glassmorphism applied reflexively to containers without a specific reason.
- **No** heavy blurred drop shadows (`shadow-2xl` and similar). Use 1px solid borders (`border`, `border-white/10`) and sharp geometry for depth instead.
- **No** headers that wrap past 2–3 lines.
- **No** arbitrary pixel spacing or inline styles — use Tailwind's 4px/rem scale (`p-4`, `mb-8`, `gap-12`) exclusively.
- **No** generic variable names (`data`, `temp`) or copy preambles ("Let's delve into...", "In today's fast-paced world...").

## 2026 design paradigms

Apply the paradigm(s) that fit the Design Read — don't default to the first one for every brief:

- **Tactile Brutalism** — for technical/developer audiences: stark backgrounds (e.g. `#0a0a0a`), 1px solid borders, monospaced utility fonts, raw overlapping geometry, zero blur.
- **Gapless bento grid** — partition dense data into a CSS Grid where every corner aligns; no missing corners, no dead voids.
- **Kinetic typography & fluid scaling** — hero H1 uses viewport-scaled sizing (`text-[clamp(2.5rem,5vw,6rem)]`) spanning the full layout width; pair a high-contrast neo-serif with a geometric sans for body/utility text.
- **Asymmetric layouts** — break the centered default: push text left, use large negative space, let imagery bleed off-viewport when the audience warrants an editorial or zine-inspired feel.
- **Liquid interactions** — subtle hover physics on every clickable element (`transition-transform duration-500 ease-out hover:scale-[1.02]`).
- **Cute-alism / Dial-Up Delight** — for youth/subculture consumer brands only: brutalist structure plus kawaii color and shape (Cute-alism), or Y2K gothic/candy maximalism (Dial-Up Delight). Do not apply these to enterprise or B2B briefs.

## Technical execution rules

- Use the CDN links from `references/boilerplate.html` verbatim, including `crossorigin` on the React UMD scripts — omitting it causes CORS failures.
- Application logic goes inside a single `<script type="text/babel">` block so Babel standalone transpiles the JSX; a bare `<script>` tag will throw `Unexpected token <`.
- Never let two components declare same-named inline style objects (e.g. two `const styles = {}`) — Babel standalone's scope isolation causes silent collisions. Scope constants per-component or rely entirely on Tailwind utility classes; inline `style={{ }}` props are banned.
- When asked for variations, do not emit multiple files. Add a floating **Tweaks panel** (bottom-right) exposing color/typography/layout variants so the user can compare live in one artifact.
- Never truncate — ship the fully working file.

## Reference files

- `references/boilerplate.html` — the exact HTML/React/Tailwind/Babel skeleton to start every artifact from.
