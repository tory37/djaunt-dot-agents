# Handling Interjectory Requests

When the user makes a request that is outside the scope of the current feature or story (an "interjectory request"):

1. **Identify Scope:** Explicitly ask yourself: "Is this part of the current feature, or is it an 'oh this would be nice' addition?"
2. **Isolate Changes:** If it is out-of-scope, do NOT implement it on the current feature branch.
3. **Branch Off Master:** Create a new branch specifically for this request, starting from `master` (or the project's default branch).
4. **Switch Back:** Once the interjectory task is reviewed/completed, switch back to the original feature branch to continue the primary work.
