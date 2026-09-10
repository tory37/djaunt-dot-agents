# AmiraAnimalRescue

**Repo:** `AmiraLearning/AmiraAnimalRescue` — "Amira Animal Rescue," a Unity/C# iOS AR mobile game
built on the acquired Within/Wonderscope "SuperbloomApp" AR-StoryMaker codebase (5.8MB C#, private).
**Created:** 2022-12-05 · **Last push:** 2023-06-05 · **PRs by tory37:** 48 · **Commits by tory37:** 102
(2022-10-05 → 2023-06-05, ~8 months).

## Role and contribution

Sole-or-primary app engineer on the Unity client — the distinctive outlier stack in this whole
work history: Unity `ScriptableObject`/`MonoBehaviour` patterns, ARFoundation plane tracking,
Timeline authoring, custom Unity `EditorWindow` tooling, and native Objective-C++ iOS plugin code.
Work spans gameplay systems, the Unity↔web-tutor integration bridge, native iOS plugin patching,
growth/experimentation infrastructure, analytics, release management, and internal developer
tooling. Owned 5 release cut/merge-back cycles (1.0.1 → 1.0.5-6), not just feature work — PRs
landed across two trackers (`AAR-*` game team, `AE-*` Amira platform), indicating cross-team work
spanning the game client and the parent learning platform.

## What was actually built

### Unity ⇄ web reading-tutor integration bridge
Owned the bridge between the Unity AR story app and Amira's web-based reading tutor rendered in
an in-app webview — a string-message protocol plus injected JS in both directions
(`WonderscopeInterface.*` inbound, `EvaluateJS` calls outbound). Passed device identity into the
tutor URL so the web side could join the game session to Amira's platform-side user record.

### Offline/network-disruption handling, built end to end
The largest single problem solved in the repo: an always-online reading tutor embedded in an
offline-capable AR game meant a dropped connection could strand a child mid-story. Built a
`DontDestroyOnLoad` network-checker singleton with one-shot and retry-until-success modes, gated
four separate entry points on it (app boot, story play button, story start/resume, auth webview
init), added mid-story-drop handling (pause, modal, return home, fire an analytics event), and
fixed a startup ordering bug where a webview controller was accessed via `FindObjectOfType` before
it necessarily existed.

### In-house A/B experimentation framework, built from scratch
`ScriptableObject`-based experiment/case/instance model with weighted variant assignment and
sticky per-user assignment. Pushed variant selection down into the content model itself — an
experiment case could swap the entire story variant, and later the entire branch within a page —
rippling the interface change through the story-loading stack. Built a QA test-group switcher
into an in-app dev-tools overlay so testers could force any variant on device.

### Story branching content pipeline + custom Unity editor tooling
Reworked the story data model from a flat page list to a branching list where each page holds
multiple variants, optionally bound to an A/B experiment. Extended the in-house Unity editor
window with a branch-authoring UI and an experiment-object field per branch, so content designers
(not just engineers) could author branching narrative tied to experiments.

### Native iOS webview orientation patch
The embedded webview and the AR scene disagreed on device orientation. Fixed it across three
layers in one change: Objective-C++ (`CGAffineTransformRotate` on the native webview plugin),
a new C# P/Invoke binding, and a Unity-side orientation-faker singleton that kept AR-anchored UI
upright when landscape was faked.

### Remote config with a force-upgrade gate
Boot-time fetch of a remote config with retry, parsed `minVersion` compared against the running
build, blocking play with an update-required dialog when too old — with a deliberate fail-open
design (a parse error doesn't block boot, only a fetch failure retries) so a bad config file could
never brick the installed base.

### Story progress persistence, in-app dev tools, analytics correctness
Rewrote a hardcoded-lookup-table story ID system into a serialized singleton with real persisted
completion state, retiring two competing content-ID schemes. Built an in-app developer-tools
overlay (runtime command registry, categorized UI) usable directly on a physical device. Found and
fixed an analytics-correctness bug where a plane-found event only fired when a voiceover-throttle
timer allowed it, undercounting a real user action.

## Problems solved

- A network dependency inside an app that otherwise plays fully offline — solved with a dedicated
  connectivity-check singleton gating every entry point that needs the web tutor.
- A "wait 1 second and hope" intervention hand-off hack (with two unresolved TODOs in the original
  code) replaced with an explicit, event-driven lead-in keyed to actual audio completion.
- A dual user-identity scheme in analytics (app-local anonymous ID vs. platform user ID) that was
  landing events under the wrong ID — collapsed onto a single device identifier.
- iOS App Tracking Transparency compliance, with idempotent prompt-triggering controlled by the
  web side.

## Design decisions worth naming

- Every analytics/telemetry call wrapped in a documented no-throw guarantee — instrumentation
  can never crash gameplay.
- Shared UI/dialog components deliberately promoted from the app layer into the licensed
  AR-StoryMaker engine layer as reuse needs emerged, rather than duplicated.
- Config-gated document/feature assembly pattern reused from the resume for incremental delivery.

## Quantifiable signals

| Signal | Value |
|---|---|
| Commits (tory37) | 102 |
| PRs (tory37) | 48 |
| Active span | 2022-10-05 → 2023-06-05 (~8 months) |
| Releases owned | 5 cut/merge-back cycles (1.0.1-1.0.5-6) |
| Stack | Unity, C#, ARFoundation, Objective-C++ (iOS native), embedded webview bridge |

## Recommended resume use

Strong, distinctive bullet: the only game/AR/mobile-native work in the whole history, with two
concrete, quantifiable engineering stories (offline-resilience system; cross-language native
orientation fix) plus release ownership. Good for demonstrating range beyond web/backend work,
if the resume has room for a distinct "mobile/game client" line.
