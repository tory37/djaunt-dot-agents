# AmiraLearning/cordova-plugin-googleplus

**Verdict: NOT resume-worthy. Exclude from synthesis.**

## What it is
Company fork of `EddyVerbruggen/cordova-plugin-googleplus`, a third-party Cordova
plugin wrapping native Google Sign-In (Android/Java, iOS/Objective-C, JS bridge).
Forked 2022-07-13, last push 2022-07-14 — a two-day-lived vendor fork, created only
to unblock a dependency bump for Amira's Cordova app.

- Languages: Java (19KB), JavaScript (13.5KB), Objective-C (7.8KB) — all upstream code.
- Stars 0, forks 1. No original project.

## Tory's contribution
Exactly one commit, `1347ea0` (2022-07-13, "Updated google sigin version"),
authored as `tory.hebert@amiralearning.com`. Zero PRs.

The full diff is **1 line changed in `plugin.xml`**:
`GoogleSignIn` CocoaPods spec `~> 5.0.2` → `~> 6.0.2`.

That is the entire contribution. No source files touched — no Java, no Objective-C,
no JS. The actual work of making the plugin compatible with Google Sign-In SDK 6
(the iOS API surface changed substantially between 5.x and 6.x) was done the next
day by a different engineer (Pete Simpson, `ed4cf23`, "Updates iOS files for Google
SDK >=6").

## Assessment
This is a dependency-version bump on a vendored fork — a fork-setup artifact, not
original engineering. It carries no design decisions, no problem solved, and no
transferable technical signal beyond "worked on a Cordova mobile app that used
Google Sign-In," which any other repo covering that app would establish better.

**Recommendation:** drop entirely. Do not generate a bullet. At most, it is weak
corroborating evidence for Cordova/hybrid-mobile exposure if some other digest
already claims it — do not let it introduce Java or Objective-C into the skills
line, since Tory wrote neither here.
