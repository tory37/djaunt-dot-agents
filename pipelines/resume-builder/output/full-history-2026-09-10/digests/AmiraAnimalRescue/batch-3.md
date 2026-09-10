# AmiraAnimalRescue — batch 3 of 3 (oldest)

Date range: 2022-10-05 to 2022-10-19
Commits in batch: 2 (of 102 total by tory37)

## What this batch covers

The tail end of the commits API pagination — the two earliest commits attributed to
tory37 in the repo. Both are small, targeted fixes in the Unity AR client
(`SuperbloomApp`), not feature work. Treat this batch as a start-date marker for the
project rather than a source of resume-grade accomplishments.

## Technical work

- **Screen-orientation handling in the AR story flow.** Set the device orientation to
  landscape at the moment a story finishes loading, in the AR carousel's enabler
  (`SuperbloomApp/Assets/SBApp/Scripts/Carousel/AREnabler.cs`, in `OnStoryLoaded`).
  The same commit bumped the `AR-StoryMaker` git submodule pointer, so the change was
  coordinated across the app repo and its vendored AR story-authoring module.
- **Retired the scene-level orientation enforcer.** Deactivated the enforcer GameObject
  via a prefab override in the AR experience scene
  (`SuperbloomApp/Assets/AR-StoryMaker/WithinTools/Scenes/ARExperienceUI.unity`).
  Paired with the commit above, this moves orientation control out of a scene object and
  into script, at the story-load lifecycle hook.

## Notable signals

- Distinctive stack for this history: Unity / C#, AR (ARFoundation-style controller +
  startup components), ShaderLab/HLSL in the repo at large, Fingers gesture library,
  git submodules for a shared AR story-authoring toolchain.
- Architecture visible even in this small slice: a story-driven AR app where a carousel
  selects an `IStoryData`, which then enables AR controller input and AR startup —
  i.e. story content and AR runtime are decoupled behind an interface.

## Noise excluded

- The scene-file commit is nominally 439 additions / 439 deletions, but nearly all of
  that is Unity YAML prefab-override reordering. The only semantic change is one
  `m_IsActive: 0`. Do not count its raw diff size as scale.
