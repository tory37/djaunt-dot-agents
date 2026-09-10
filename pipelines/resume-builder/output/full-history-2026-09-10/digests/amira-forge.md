# amira-forge (amira-rnd/amira-forge)

Private. Created 2026-05-13, last pushed 2026-09-10. 1 star, 0 forks.
Languages: TypeScript (2.15 MB), Python (1.27 MB), HTML (804 KB), SCSS (178 KB),
Jinja, Dockerfile, JavaScript.

## Role and contribution

Founder/originator of the repo. Authored the initial commit and the project's
first architectural passes, then handed a working foundation to a team that has
since grown it substantially (repo now includes a separate teacher-facing
Next.js app, a FastAPI generate service, StoryWorks integration, and an AppSync
curriculum sync — none of which are his commits).

6 commits by `tory37`, all on `main`, all via merged PRs (4 merged PRs: #1, #5,
#9, #10). Active window: 2026-05-13 to 2026-06-09.

Product context: Amira Forge is a Payload CMS 3 application for Amira Learning —
a guided, LLM-powered authoring tool for AIT (Assessment, Instruction, and
Tutoring) content.

## Specific technical work (verified against diffs, not commit messages)

### 1. Project bootstrap and stack selection (`b316367`, +10,268 / 42 files)

Raw diff size is inflated by `pnpm-lock.yaml` (8,720 lines) and Payload's
generated `src/payload-types.ts` (339 lines) — real hand-authored work is ~1,200
lines. Stood up the whole project skeleton:

- Payload CMS 3 on Next.js App Router, with the `(payload)` / `(frontend)` route
  group split, admin catch-all route, REST + GraphQL route handlers.
- Multi-stage `Dockerfile` (node:22-alpine, deps/builder/runner stages, non-root
  `nextjs` user, Next standalone output) and `docker-compose.yml`.
- Full test harness on day one: Playwright e2e config plus specs for admin and
  frontend, Vitest integration config and spec, and reusable `tests/helpers/`
  for login and user seeding.
- ESLint flat config, Prettier, TS config with path aliases.

### 2. Postgres migration off the template's MongoDB default (`3e188ce`)

Swapped the Payload blank template's MongoDB assumption for Postgres
(`@payloadcms/db-postgres`), added `pnpm db` / `pnpm db:stop` Docker Compose
scripts for a local database container, and rewrote the README from template
boilerplate into a real project README (setup steps, script table, env-var
table, stack description).

### 3. Auth.js (NextAuth v5) + AWS Cognito authentication (`903c4a5`, PR #9)

Replaced Payload's native email/password auth with Auth.js as the sole auth
layer. Notable decisions visible in the diff:

- Cognito OIDC provider is **conditionally registered** — the provider array is
  spread only when `COGNITO_CLIENT_ID` / `COGNITO_ISSUER` are present, so local
  dev runs with no live AWS. A `Credentials` stub provider is spread in only
  under `NODE_ENV === 'development'`. Both are environment-gated at config time
  rather than branched at request time.
- Route protection via `src/proxy.ts` (Next.js 16's middleware convention),
  wrapping the `auth()` handler with a `PUBLIC_PATHS` allowlist (`/login`,
  `/api/auth`, Payload's REST API) and a matcher that excludes static assets.
- Extended the `Users` collection with `cognitoSub`, `googleId`, `firstName`,
  `lastName`, and a `userType` select (author / reviewer / admin) — the identity
  model the later authorization work builds on.
- Wrote `src/lib/kinesis-credentials.ts` as a deliberate typed stub that
  *throws* with a message naming the exact blockers
  (`COGNITO_IDENTITY_POOL_ID`, `KINESIS_IAM_ROLE_ARN`) instead of silently
  failing — the Cognito Identity Pool → STS AssumeRoleWithWebIdentity → Kinesis
  path was designed but blocked on DevOps.
- Documented the DevOps handoff in the PR body as a var/source table
  (which Cognito console screen each value comes from), and mirrored it into
  `.env.example`.

### 4. Authorization model: admin elevation and group-shared ownership (`2e3bb16`, PR #10, ticket ASF-4)

Built the repo's access-control layer:

- `src/lib/access.ts` with shared Payload access helpers `authenticated`,
  `isAdmin`, `isAdminOrSelf`; centralized an `authenticated` helper that had
  been duplicated inline in `ConversationSkills.ts`.
- Closed a privilege-escalation hole: put field-level `access: { update: isAdmin }`
  on `Users.userType` so a user cannot promote themselves to admin even though
  they can update their own record (`isAdminOrSelf` at the collection level).
- New `Groups` collection (name + `members` relationship), admin-write-only.
- Replaced per-document `ownerOnly` access with an async `ownerOrGroupMember`
  query-constraint function across `Conversations`, `GeneratedMedia`, and
  `ConversationSkills` — it resolves the caller's group memberships via
  `payload.find` and returns a Payload `Where` clause (OR over owner-is-me /
  group-in-my-groups), so filtering happens in the database query rather than
  post-fetch. Admins short-circuit to `true`.
- Added a `beforeChange` hook that stamps `owner: req.user.id` on create, and
  marked `owner` `readOnly` + indexed so ownership can't be spoofed by the
  client.
- Extended NextAuth `Session` / `JWT` types with `userType`.

### 5. Repo hygiene (`3a4d0a8`, `361c0dc`, PR #5)

Added `AGENTS.md` (AI-agent working instructions for the repo), and untracked
`.vscode/` — small, but the `.gitignore`/untrack pair shows the diff was a real
`git rm --cached`, not just an ignore line.

## Notable patterns

- **Ships blocked work as explicit, typed failure, not TODO comments.** The
  Kinesis stub throws a message naming the missing infra inputs.
- **Environment-conditional wiring** so the app is runnable locally with zero
  cloud credentials.
- **Security-first defaults on an internal tool** — role escalation closed at the
  field level, ownership stamped server-side, access enforced as DB query
  constraints.
- **PR descriptions carry explicit test plans** as checkbox lists, plus
  cross-team dependency tables when another team must supply values.

## Quantifiable signals

- 6 commits, 4 merged PRs, 100% of commits merged through PR review.
- Founded the repo; contribution window 2026-05-13 → 2026-06-09 (~4 weeks).
- Repo has since grown to a 4-language, multi-app monorepo (Next.js Payload
  server, standalone teacher UI, FastAPI generate service) on the foundation and
  auth/authz layer laid here.
- Stack introduced by his commits: TypeScript, Next.js 16, React 19, Payload CMS
  3, PostgreSQL, Auth.js/NextAuth v5, AWS Cognito (OIDC), AWS STS/Kinesis
  (designed), Docker / Docker Compose, pnpm, Playwright, Vitest, ESLint,
  Prettier.
