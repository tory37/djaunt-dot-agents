# djt-godot-review

A code review skill that enforces Godot 4 official best practices and project architectural mandates across GDScript, scenes, and resources.

## What it checks

Eleven categories pulled directly from the Godot documentation and project CLAUDE.md:

- **A** GDScript standards (static typing, naming, private prefix, exports, no God Scripts)
- **B** `request_*` / `_apply_*` Autoload seam for future networking readiness
- **C** Signal direction (downward = method calls, upward = emit, cross-system = bus)
- **D** Scene coupling and dependency injection
- **E** Lifecycle callbacks (`_process` vs `_physics_process`, input location, init order)
- **F** Node vs RefCounted vs Resource vs Object base class selection
- **G** Scenes vs Scripts (when to use each)
- **H** Data structure and algorithm selection
- **I** `preload()` vs `load()` correctness
- **J** Composition/component architecture and feature folder layout
- **K** GUT unit test coverage

## Install

```bash
bash tools/djt-godot-review/install.sh --target /path/to/your/godot/project
```

## Usage

```
/djt-godot-review                    # review unstaged changes
/djt-godot-review origin/main..HEAD  # review branch diff
/djt-godot-review path/to/file.gd    # review a specific file
```

Reports are written to `.agents/output/reviews/<name>-<timestamp>.md` with findings labeled `[CRITICAL]`, `[WARNING]`, or `[SUGGESTION]` per category.
