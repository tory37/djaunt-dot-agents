# AmiraLearning/AmiraAnimalRescue — batch 2 of 3

Date range: 2022-10-19 to 2023-02-21 (50 commits, commits-API page 2)

## Stack (distinctive vs. rest of work history)

Unity / C# mobile AR game — "Wonderscope"/Superbloom codebase (`SuperbloomApp/Assets/...`), iOS-first. Confirmed by the diffs, not just the language stats:

- Unity `MonoBehaviour` lifecycle work throughout (`Awake`/`Start`/`Update`, coroutines, `DontDestroyOnLoad`, singletons)
- ARFoundation plane detection (`ARPlanePositioner`, `ARStartup`), haptics, particle systems, Timeline signals (`.signal` assets), TextMeshPro UI
- iOS-native build plumbing: `IPostprocessBuild` step editing `Info.plist` (encryption-exemption entry, `NSUserTrackingUsageDescription`), ATT via `Unity.Advertisement.IosSupport`
- Embedded webview bridge as the integration seam between the Unity game and Amira's web reading tutor

## Main body of work in this range

### 1. Unity ⇄ web reading-tutor integration (the load-bearing thread)

Tory owns the bridge between the Unity AR story app and Amira's web-based tutor rendered in an in-app webview. The bridge is a string-message protocol (`WonderscopeInterface.*`) plus injected JS.

- `AmiraStoryEventHandler` / `AmiraAuthWebviewEventHandler` parse inbound webview messages and re-emit them as C# `event Action`s — `onInternetDisconnect`, `triggerAttRequest`, `appVersion`, login-required, intervention-required/complete, toggle-webview.
- Outbound direction uses `webview.EvaluateJS` to call into `window.wonderscope` (e.g. `TriggerPostAppVersion`, AB-test group handoff).
- Passed device identity into the tutor URL as a query param (`?unityUserId=<deviceUniqueIdentifier>`) so the web side could join to the game session (`7a0f3a71`).

### 2. Offline / network-disruption handling end to end (`7bdef3b3`, `afcc3032`, `7afd2fb8`, `80c4f1e8`, `f6f34c1d` — ~2.4k and ~2.0k line diffs)

The largest single problem solved in this batch. An always-online reading tutor inside an AR game meant a dropped connection could strand the player mid-story. Tory built the whole path:

- Wrote `AmiraNetworkChecker`, a `DontDestroyOnLoad` singleton wrapping `UnityWebRequest` against a dedicated API Gateway health endpoint, with two modes: one-shot `TestNetwork(onSuccess, onFailure)` and `TestNetworkUntilSuccess` (coroutine that retries every 2s until online).
- Gated four separate entry points on it: app boot (`BootSequence` blocks the splash progress bar behind a connectivity check, with a spinner and a "Refresh" retry dialog), story play button, story start/resume in `StorySequencer`, and auth webview init (auth now waits for connectivity before loading the URL instead of failing silently).
- Added a deliberate minimum-visible-time on the failing check (500ms floor) so the loading spinner reads as a real check rather than a flicker — a UX detail, not a functional one.
- Handled mid-story drops: modal dialog, pause the sequencer, return to home screen, fire `onInternetInterrupted`.
- Moved `UIModalDialog` into the shared AR-StoryMaker layer so both the game and the Amira integration could reach it, and added a `SimpleSpinner`.
- Wired a new `Internet Interrupted During Story` analytics event through `SequencerFlowEvents` → `SBAnalytics`.
- Hardened teardown along the way: `OnDestroy` handlers were unsubscribing from event handlers that could be null after a failed init — added null guards in `AmiraStoryController` and `AmiraAuthWebviewController`.
- Refactored `AmiraAuthWebviewController` to a static `Instance` singleton so `AuthService` stopped depending on `FindObjectOfType` at `Awake` time (a real ordering bug, since the webview controller may not exist yet).

### 3. Amira intervention lead-in / HUD (`7fab3f95`, `1bb55580`)

When the tutor decides a reader needs help mid-story, the game has to hand off from AR gameplay to the tutor without a jarring cut.

- Replaced a "wait 1 second and hope" hack (`TriggerInterventionAfterDelay`, carrying two TODOs admitting nobody knew why the delay was needed) with an explicit, event-driven lead-in: `AmiraInterventionLeadInHUD` sizes itself to the smaller screen dimension, plays a SFX then a randomly-chosen Amira VO clip, and fires `OnTransitionEnd` when audio actually finishes — then the intervention triggers.
- Added `AmiraStoryHUDController` plus Timeline `ShowAmiraHUD`/`HideAmiraHUD` signal assets so story timelines can show/hide Amira's dialogue HUD at authored beats.
- Wrote `ImageAlphaGlitcher`, a small utility that randomizes image alpha between bounds for a hologram-glitch look on the HUD.

### 4. Story-menu "Coming Soon" / preview-only stories (`c6ea43df`, `44464a05`)

- Added `IsPreviewOnly` plus per-device (`iPhone`/`iPad`) coming-soon artwork to the `IStoryData` interface, and implemented it across `EmbeddedStoryData` and `MockStoryData` — the test double was kept in lockstep with the interface.
- New `StoryMenuComingSoonCard` intercepts the play button for unreleased stories and shows a device-appropriate card instead of starting a download.
- Added a distinct `Story comingSoonPlayButtonClicked` analytics event so demand for unshipped episodes was measurable. Later used to ship "Episode 2 Coming Soon."

### 5. Analytics instrumentation (Segment + Bugsnag breadcrumbs)

- `SegmentAnalytics`: collapsed a dual user-id scheme (an app-local anonymous id joined to Adjust session params, plus an Amira user id) onto the device unique identifier as the single `Identify`/`Track` id, and moved `amiraUserId` into traits instead. Fixed a real identity-stitching problem where events landed under a different id than the tutor's user (`7a0f3a71`, `35b1c23c`).
- `SBAnalytics` additions across the batch: AR plane found/lost, coming-soon click, internet-interrupted. Notably moved `ARSetupPlaneFound` out of `ARStartup` (where a VO throttle timer suppressed it) into `ARPlanePositioner.EnableGridAndAudio`, so the analytics event fires every time a plane is found rather than only when the voiceover played — and added the matching plane-lost event (`1971d2b6`). That's an analytics-correctness bug found by reading the gating logic, not the event name.
- Every analytics method follows a `try { ... } catch { /* no-throw guarantee */ }` convention — telemetry can never crash gameplay.

### 6. iOS App Tracking Transparency (`3d216a70`, `7da3bdbf`)

Added the `ATTracking` wrapper (checks `NOT_DETERMINED` before prompting, so it can be called idempotently), triggered it from a webview message so the *web* side controls prompt timing, and added the required `NSUserTrackingUsageDescription` plist entry via the Unity build post-process step. App-Store-compliance work.

### 7. Smaller fixes and cleanups

- Rewrote the timeout-behaviour hierarchy: renamed `TimelineTimeoutBehaviour` → `ActivateAfterDelayBehaviour` and `OnActivate` → `OnTimeout` across four subclasses (audio/particle/renderer/activate), replaced a two-field `timerActive` + `currentTimer` state machine with a single countdown float, and stripped a pile of `Debug.LogWarning` noise that was shipping in every frame path (`d99d69a6`).
- Disabled chapter skipping across all stories by flag-gating `SetChapterSelectionPanelActive` rather than deleting the UI (`dc0fa68d`).
- Muted story-preview video audio when the webview toggles open, via a new webview-toggle Action (`35e0e464`, `fdced819`).
- Forced horizontal rotation during stories; showed the webview on play-button click so the web loading screen is visible during auth (`50ee708d`, `b9b8652b`).
- Swapped in corrected Amira intro videos and updated audio prefabs; fixed intro-video-2 pointing at the wrong asset (`0dd0f672`, `1f9d2931`, `2057dbba`).
- Maintained a git submodule pointer for the shared AR-StoryMaker/WithinTools layer.

## Signals for this batch

- 50 commits, 2022-10-19 → 2023-02-21 (~4 months)
- Work is ticket-driven (AE-####/AR-#### Jira keys) and PR-reviewed — several commits are "Addressed comments" follow-ups on his own PRs
- Two codebases in one repo: the licensed Within/Wonderscope AR engine (`AR-StoryMaker/WithinTools`, copyright Within Unlimited) and Amira's app layer (`SBApp`). Tory works in both, and repeatedly promotes shared pieces (`UIModalDialog`) from the app layer into the engine layer.
- Cross-boundary role: C# gameplay code, an embedded-webview JS bridge, iOS native build config, and analytics/telemetry — not a single-lane contributor.
