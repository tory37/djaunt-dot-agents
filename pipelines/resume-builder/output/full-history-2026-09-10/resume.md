# Tory Hebert
Senior Frontend Engineer · Lafayette, LA · (337) 380-0038 · tory37@gmail.com · toryh.dev · github.com/tory37 · linkedin.com/in/toryhebert

Senior frontend engineer with 10 years building production React/TypeScript applications, including 4+ years on the core client of a K-5 reading and assessment platform serving 5.5M+ students. Goes full-stack when the work needs it (Node.js, Python, PostgreSQL, AWS Lambda/AppSync/DynamoDB). Works almost entirely through a self-designed agentic workflow — setting direction, architecture, and review while agents implement — and uses it to build the tools that remove friction for the team: a component workbench in 4 days, a partner-facing authoring platform in 3, and 11 browser extensions in 15.

## Skills

**Languages:** JavaScript, TypeScript, Python, Java, C#, SQL
**Frameworks/Libraries:** React, Next.js, Redux, Angular, RxJS, Node.js
**Cloud/Infra:** AWS (Lambda, AppSync, DynamoDB, API Gateway, S3, Cognito, SNS, SQS, CloudWatch, CloudFormation), Terraform, Docker
**APIs/Data:** GraphQL, REST, PostgreSQL, Drizzle ORM, OpenAI API
**Testing:** Jest, Vitest, Playwright, pytest, JUnit, Gatling
**CI/CD & Tools:** GitHub Actions, Jenkins, Git, Datadog
**AI/Agentic Engineering:** Claude Code, multi-agent orchestration, agentic pipeline design, MCP integration, prompt engineering, LLM API integration
**Other:** Unity/WebGL, Chrome/Firefox extensions (Manifest V3)

## Experience

### Senior Software Engineer — Amira Learning
*Lafayette, LA (remote) · 2022 – Present*

- Owned Amira's core K-5 reading and assessment client (React/TypeScript) for 3+ years, serving 5.5M+ students across 4,000+ districts. Migrated its real-time assessment engine to a server-orchestrated architecture that now runs every English-language assessment.
- Shipped an LLM-powered conversational comprehension feature end-to-end (inference pipeline, timeout safeguards, teacher-facing transcript report), a WebGL animated tutor avatar, and a 6-brand white-label platform for partners including NWEA and HMH.
- Cut every assessment UI check from a 3+ minute assignment run to instant by building a component workbench that renders real screens with live item-bank data and production text-to-speech. Used it that week to ship 5 layout fixes, each verified across up to 16 cases and 4 viewport sizes.
- Built a partner-facing assessment authoring platform solo in ~3 days with an agentic workflow (Next.js, PostgreSQL): one type registry drives 12 item types through editing, CSV import, LLM prompt generation, and live preview in the real student app. Now extending it to open PRs for engineer approval.
- Built internal tools wherever friction repeated: a GPT-4 pipeline that fixed homonym meanings across the story corpus, After Effects automation that generated hundreds of instructional videos, a one-command item-bank reviewer for content specialists, and daily-use browser extensions for test environments.
- Led frontend on the teacher/admin web app for 16 months, building the district-facing bilingual assessment configuration and screening-window scheduling system from scratch, plus a client-side Word generator that turns live report components into per-student intervention plans.
- Worked across the stack when it was the fastest path to ship: a parent portal (Cognito, AppSync), a license-configuration grid, GraphQL schema changes serving ~12 downstream services, a Lambda + DynamoDB microservice, and 18 months of Angular work during the Istation merger.
- Took the lead as the team's only Unity/C# engineer on an acquired AR mobile game (Wonderscope): taught Unity to coworkers, built a branching-path timeline extension, and owned 5 production releases plus an in-house A/B testing framework.

### Senior Software Engineer (Fullstack) — Marqeta
*Oakland, CA · 2020 – 2022*

- Helped launch Marqeta's in-house 3D Secure service in 2020 — one of the first verified on Visa's 3DS 2.2 standard — and owned its admin configuration panel and customer-facing authentication forms (React, Node.js), on a card platform that processed $111B across 122M active cards in 2021.
- Built on the 3DS backend (Java) and its Terraform-managed AWS infrastructure (Lambda, API Gateway, SNS, SQS, S3, DynamoDB), and wrote its unit, integration, and Gatling load tests.
- Wrote 3DS design docs, ran knowledge-sharing sessions, supported compliance audits, and mentored a summer intern plus two new hires through onboarding.

### Senior Software Engineer (Frontend) — Waitr, Inc.
*Lafayette, LA · 2017 – 2020*

- Built Waitr's customer-facing web ordering app (React, Redux) for a food-delivery platform that grew to 2.4M active diners and ~24,000 restaurants by 2019.
- Introduced Jest to the codebase and migrated the existing Chai test suites.
- Owned an in-house AngularJS order-management product used by staff and restaurant partners, advising a small group of engineers from requirements through deployment.

### Associate Technical Consultant (Frontend) — Perficient, Inc.
*Lafayette, LA · 2016 – 2017*

- Built a single-page application for the Kaiser Permanente healthcare website (AngularJS, Angular 2, TypeScript, SASS) against an existing styleguide, with Karma/Jasmine unit tests.

## Personal Projects

**djaunt-dot-agents** — the agentic workflow behind the work above. github.com/tory37/djaunt-dot-agents
- One instruction set and skill library synced across Claude Code, Gemini CLI, and Cursor, so every workflow runs the same on any machine and any tool.
- Designed resumable multi-agent pipelines: disk-backed ledger state, parallel subagents with isolated context per unit of work, and safe recovery mid-run. One of them built this resume from 30+ repos of git history.

**djaunt-browser-tools** — 11 Manifest V3 extensions for Chrome and Firefox, built in 15 days with an agentic workflow and used daily for Amira testing: rerouting launch URLs to temporary test environments, mocking APIs, and editing headers and query flags. 502 test assertions, CI-built releases. github.com/tory37/djaunt-browser-tools

**Mealeo** — meal-planning and pantry app (Next.js, TypeScript) with Gemini built in for macro estimation and AI-merged shopping lists. github.com/tory37/djaunt-cooking

**Dekigo** — Japanese reading and spaced-repetition vocabulary tool (Next.js, Supabase, Kuromoji), tested with Vitest and Playwright. github.com/tory37/dekigo

## Education

**Bachelor of Science, Computer Science** — University of Louisiana at Lafayette, 2012 – 2016
