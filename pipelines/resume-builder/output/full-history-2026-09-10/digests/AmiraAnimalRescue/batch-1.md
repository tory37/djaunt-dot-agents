# AmiraAnimalRescue — batch 1 of 3

**Date range:** 2023-02-22 → 2023-06-05 (50 commits by tory37, commits-API page 1 — the most recent batch)

**Stack note (distinctive vs. rest of history):** This is a **Unity / C# iOS AR mobile game** — "Amira Animal Rescue", built on the acquired Within/Wonderscope "SuperbloomApp" AR-StoryMaker codebase. Confirmed by the diffs: Unity `ScriptableObject`/`MonoBehaviour` patterns, Timeline `PlayableAsset`/`Track` authoring, ARFoundation plane tracking, custom `EditorWindow` tooling, and native Objective-C++ (`.mm`) iOS plugin code. Nothing else in the work history is game/AR/Unity — this is the outlier stack.

## Role / contribution in this batch
Sole-or-primary app engineer on the Unity client. Work spans gameplay systems, native iOS plugin patching, growth/experimentation infrastructure, analytics instrumentation, release management, and internal developer tooling. Commits land through PRs (#83 → #276 in this window) including cutting and merging back releases 1.0.1 through 1.0.5-6 — so he owned the release train, not just feature work.

## Notable technical work (from diffs, not commit messages)

### 1. Built an in-house A/B experimentation framework from scratch (#219, #241, #229, #260)
- `ABTestCase` / `ABTestExperiment` / `ABTestInstance` as Unity `ScriptableObject`s, with **weighted variant assignment** (`ABTestCasesToWeight`) and sticky per-user case assignment (`GetOrAssignCaseForExperiment`).
- Wired variant selection into content itself: refactored `EmbeddedStoryData.StoryData` (a plain property) into `GetStoryData()` that resolves an experiment case → a different `StoryData` asset, so an experiment could swap the entire story variant a user sees. Interface change rippled through `IStoryData`, `StoryLoadFlow`, `LocalStoryResourceManager`, and mocks.
- Emitted an `Experiment Started` analytics event (name/id + variation name/id) so variants were measurable downstream.
- Later pushed experiment selection down to the **per-page/per-branch** level in the story data model (see #4).

### 2. Story branching in the content pipeline + custom Unity editor tooling (#229, "Portal mech tutorial with branching", 142 files)
- Reworked the story data model from a flat `List<StoryPageData>` to `List<BranchList>` (`dataPages2`), where each page holds multiple branch variants, each optionally bound to an `ExperimentToTestCase` pair — branching narrative and A/B variants share one mechanism.
- Extended the in-house `StoryEditor` `EditorWindow` (Select / Edit / CreatePage sections) with branch selection, an "Add Branch To This Page" foldout, and an AB-experiment object field per branch — content designers got the branching UI, not just engineers.
- Added Timeline authoring support: custom `ResetLoopSkipCountPlayable` / `PlayableAsset` / `Track` so timeline signals could reset a loop-skip counter mid-scene.

### 3. Patched the native iOS webview plugin to fake device orientation (#141, AE-10301)
The reading experience is an embedded Amira webview inside a Unity AR scene. The webview and the AR scene disagreed on orientation. Fix crossed three layers:
- **Objective-C++**: added `setRotation:` to both `WebView.mm` and `WebViewWithUIWebView.mm` (`CGAffineTransformRotate`), plus the `_CWebViewPlugin_SetRotation` C entry point.
- **C# interop**: new `[DllImport("__Internal")] _CWebViewPlugin_SetRotation` binding in `WebViewObject.cs`, with a margin re-apply to force a frame refresh after rotating.
- **Unity side**: new `OrientationFaker` singleton that rotates a registered set of transforms, plus a `Billboard` fix that swaps the LookAt up-vector to `right` when landscape is faked so AR-anchored UI stays upright.

### 4. Fixed a webview race condition and added a network/init timeout path (#156, #174)
- `webviewInitialized` handshake: added an `OnWebviewInitialized` event and `IsWebviewInitialized` flag, plus `webviewInitializeStarted` / `webviewInitializeSucceeded` analytics so init failure rate was observable in production.
- Added `OnWebviewInitializeTimeout` handling that clears the webview cache and hides it rather than hanging the app.
- Built an `AARModalManager` singleton + modal hierarchy (`BasicModal`, `SlowNetworkModal`, `AppReviewPromptModal`, `SendFeedbackPromptModal`, `AuthFailureModal`, `ResumeRestartStoryModal`) to surface these failure states to kids instead of a dead screen.
- Allowed the webview to fire passage-complete events directly, removing the race that "periodically broke the webview".

### 5. Remote config with force-upgrade gate (#83, AE-10394)
- New `AppConfigFetch` boot step: fetches `config.json` from S3 during boot, retries up to 3×, parses `minVersion`, compares component-wise against `Application.version`, and blocks play with a no-button "update required" dialog when the build is too old.
- Deliberate failure design: a **parse** error does not block boot (`HasFinished = true`) while a fetch failure retries — a deliberate fail-open decision documented against the ticket, so a bad config file could never brick the installed base.
- Emitted `Config Fetch Failed` / `Config Parse Error` / `App Version Below Min Detected` events to measure it.
- Also fixed a real boot-sequence bug in the same commit: `AnalyticsInit` never set `HasFinished`, so the boot chain could stall.

### 6. Story progress persistence and resume (#226, #230, #103)
- `StoryProgressService.GetStoryProgress(episodeId)` returns a `(unityPageIndex, webviewPageIndex)` pair, passed into the webview's `selectStory(...)` call so the Unity scene and the web reading experience resume at the same point.
- Rewrote `AmiraStoryTracker` (+175/-131) from a static class with hardcoded placeholder episode-ID lookup tables (`wonderscopeStoryIdToAmiraStoryId`, `cmsStrToBundleId`) into a serialized-instance singleton driven by `EmbeddedStoryData` assets and persisted completion state — removing three hand-maintained ID mapping dictionaries.
- Retired `CmsStrId` in favor of `AmiraStoryId` across the load flow and analytics, unifying two competing content-ID schemes.
- Product iteration on top: shipped a resume/restart modal, then replaced it with "resume for everyone, show RESUME on the play button" after the modal tested poorly.

### 7. Built an in-app developer tools overlay (#190, #203, #210)
- `AARDevTools` singleton: runtime command registry rendered as on-screen buttons with a scrolling history log — usable on a physical device where a console isn't available.
- Grew it into a categorized, collapsible UI (`AARDevToolCategory`) with listener cleanup on destroy to avoid duplicate-invocation bugs.
- Added a **test-group switcher** so QA could force any A/B variant on device, and commands to clear webview cache/cookies for auth debugging.

### 8. Orientation, AR, and analytics hardening (assorted)
- `UIDeviceRotationPrompt` + `DeviceOrientationEventChannel` / `VoidEventChannel` (ScriptableObject event-channel pattern) to prompt the tutoring cohort to rotate to landscape mid-story; portrait-lock with scaling adjustments for the control cohort (AE-10883/AE-10963).
- ARFoundation: ignored the spurious initial `plane lost` event, gated plane-lost events to fire only during a story, added new AR plane events and an AR camera error notification controller (AE-10867, AE-11131).
- Analytics discipline throughout — every new event handler wraps in `try/catch` with an explicit `// no-throw guarantee`, so instrumentation can never crash gameplay. De-duped `Session Started` to once per launch using local storage (AE-10470).
- Intervention HUD: extracted `AmiraInterventionHUDCanvas` as a persistent (`DontDestroyOnLoad`) canvas and removed per-enable manual `sizeDelta` math in favor of layout-driven sizing.

## Quantifiable signals (this batch)
- 50 commits, 2023-02-22 → 2023-06-05 (~3.5 months), essentially all via reviewed PRs (#83–#276).
- Owned 5 release cut/merge-back cycles in this window: 1.0.1, 1.0.2, 1.0.3, 1.0.4, 1.0.5-6.
- Largest real (non-generated) changesets: story branching + editor tooling (~142 files), boxed-clueball AB test, dev-tools overlay (+3,095), app-review/feedback modal system (+2,959), modal + webview-timeout system (+2,073).
- Ticket traffic spans two trackers — `AAR-*` (game team) and `AE-*` (Amira platform) — indicating he worked across the game client and the parent learning platform's requirements.

## Noise excluded
Unity `.meta`, `.asset`, `.unity`, `.prefab`, shader/material/animation, and art/video binaries were excluded before ranking — several commits show 20k–97k added lines that are almost entirely generated Unity scene/prefab YAML and imported assets (e.g. `4121351c1` at +96,984 has only ~120 lines of real C#). Merge/mergeback commits were read only for release-cadence signal, not as feature work.
