# Resume Writing Guide (reference)

Static guidance for the synthesis stages of `PIPELINE.md`. Read this instead
of doing a live web search each run — keep it updated by hand if resume
best practices shift.

## The XYZ formula

Every bullet should compress to: **"Accomplished X, measured by Y, by doing
Z."** Drop any bullet that can't fill in a real X or Y — a bullet with no
outcome is just a task description.

- Weak: "Worked on the checkout service."
- Strong: "Cut checkout-flow error rate by 40% by rewriting the payment
  retry logic in the checkout service."

If a repo has no measurable outcome available (no issue counts, no scale
signal, no before/after), use a scope signal instead of inventing a number:
team size, request volume, user count, repo age/longevity, or "sole
maintainer of X for Y years."

## Consolidate, don't enumerate

This is the most important rule for this pipeline. A resume reader — human
or ATS — does not want one line per repo. If 5 repos are all "React +
TypeScript CRUD app," that's **one** bullet: "Built and maintained 5+
production React/TypeScript applications across [domain], covering
[shared theme — auth, data viz, internal tooling, etc.]."

Group repos by:
1. **Tech stack overlap** (same language/framework doing similar work)
2. **Role/domain overlap** (e.g. three unrelated-stack repos that are all
   "internal developer tooling")
3. **Genuine one-offs** — a repo doing something distinct enough (scale,
   novelty, leadership) earns its own bullet even if the stack overlaps
   with others.

Target 4-8 total experience bullets for the whole synthesized output,
regardless of how many repos were scoped in. If digests produce more
candidate bullets than that, merge or cut the weakest, not the newest.

## Action verbs

Lead every bullet with a strong, specific past-tense verb. Avoid "worked
on," "responsible for," "helped with," "involved in" — those describe
presence, not contribution.

Prefer: built, designed, shipped, led, migrated, optimized, automated,
reduced, scaled, architected, debugged, replaced, consolidated, launched.

## ATS / keyword considerations

- Use the plain, industry-standard name for a technology, not a stylized
  or internal name. "PostgreSQL" not "Postgres DB layer."
- Keep a dedicated skills/technologies line separate from the narrative
  bullets — ATS keyword matchers weight explicit skill lists heavily, and
  a reader skims it fast.
- No tables, no columns, no icons, no images in the skills line — plain
  comma-separated text parses reliably across every ATS in use.
- Don't keyword-stuff technologies that don't appear anywhere in the
  underlying repo data. Every skill listed must trace back to at least one
  scoped repo's actual language/dependency/commit evidence.

## Length discipline

The whole output is a resume *section*, not a portfolio. Total output
should read naturally in under a printed half-page: a skills line plus
4-8 bullets. If synthesis produces more, that's a signal to consolidate
further, not to keep everything.

## Quantify what's available

From the digests, pull whatever real numbers exist:
- Commit count / PR count / repo lifespan (longevity signal)
- Contributor count on the repo (scale/collaboration signal)
- Stars/forks if public and non-trivial (adoption signal)
- Anything in the README stating users, scale, or deployment context

Never fabricate a metric. If nothing quantifiable exists for a cluster,
fall back to a scope statement instead of inventing a number.
