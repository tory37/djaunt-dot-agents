# istation-hydra/olp-html-practice

**Istation HTML Practice Engine ("Micro Lessons")** — the student-facing single-page app for Istation's data-driven Math and Reading practice experience.

## Scale signals
- Repo created 2022-06-23, still active (last push 2026-09-08); 3 stars, 2 forks (internal org repo).
- Large codebase: ~5.1M bytes TypeScript, ~400K SCSS, ~349K HTML.
- Tory's contribution here is **small and late**: 6 commits (incl. 2 merge commits), 2 merged PRs, all in Feb 2025. This is a drive-by/polish contribution to a repo owned by another team, not a primary ownership repo.

## Tech stack observed
Angular (README says 14.1.2 at time of writing; `package.json` now on Angular 21), TypeScript, SCSS, Apollo GraphQL client, AWS Amplify + Cognito auth, Microsoft SignalR (realtime), Lexical rich-text editor, Spine/Lottie animation players, Docker, GitFlow branching, AWS-backed dev credentials tooling.

## Role / contribution
Front-end UI polish and branding work on the student experience, delivered as two ticketed, reviewed PRs (Jira SC-213, SC-278):

- **PR #944 — "Rotate logout logo on profile popup"** (merged 2025-02-10). Fixed the orientation of the logout icon in the header's profile popup via a scoped SCSS transform on the footer `svg` (`rotate(180deg)` + 1px optical nudge) in `profile-popup.component.scss`. Also toggled dev-environment feature flags (`enableArbitraryLaunching`, `returnToReferrer`, `devHomePage`) in `configuration-dev/configuration.json` to reach the logout flow locally — then reverted them in a follow-up commit before merge (evidence of catching a config leak in own PR).
- **PR #947 — "Update logout screen image to a generic handwave"** (merged 2025-02-12). Replaced the branded full-wordmark logo on the logout page with a new generic `handwave.svg` component icon in the `htc-logout-page` Angular component (`OnPush` change detection, inline template), and re-tuned the surrounding `auth.scss` figure sizing (removed a hardcoded `left: -1.5rem` offset, scaled the image to 65% width) so the new asset centered correctly.

## Notable details
- Both PRs included a visual validation screenshot in the description and linked the owning Jira ticket — consistent, evidence-backed PR hygiene.
- Work touched an auth/logout flow that branches on referrer origin (`istation.applaunch`), i.e. an embedded-launch integration with the wider Istation platform.

## Resume value
Low-weight. Useful only as a supporting data point for "contributed across teams/repos in an Angular + AWS ed-tech platform"; not strong enough for its own bullet.
