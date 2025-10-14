# Repository Guidelines

## Quick Start
- Open the project with `godot4 --path .`. If the main scene is unset, point `Project Settings > Application > Run > Main Scene` to `res://scenes/MainMenu.tscn` so `godot4 --path . --run` works reliably.
- For batch checks or CI, prefer `godot4 --headless --path . --run`.
- Export desktop builds with `godot4 --headless --path . --export-release "Linux/X11" build/snarkscissors.x86_64`; ensure presets live in `export_presets.cfg`.

## Project Structure & Docs
- Scenes live under `scenes/`; ensure each `.tscn` has a matching script in `scripts/` (e.g. `scenes/GameScene.tscn` ↔ `scripts/GameScene.gd`) per [Godot scene/script pairing](https://docs.godotengine.org/en/stable/tutorials/best_practices/node_tree_best_practices.html).
- UI fragments belong in `scenes/UI/` so they can be instanced across menus.
- Design and technical references reside in `docs/`: review `snarkscissors_gdd.md`, `snarkscissors_tech_study.md`, and `snarkscissors_project_roadmap.md` before altering gameplay, networking, or delivery scope.
- Shared art stays at the root (`icon.svg`). Mirror that structure for any new assets to avoid import path churn.

## Scene & Script Guidelines
- Follow the official [GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html): 4-space indentation, snake_case for variables and signals (`round_completed`), PascalCase for classes, and explicit types on exported and public members.
- Use `@onready var` for cached node references instead of repeated `get_node` calls. Prefer [node grouping and signals](https://docs.godotengine.org/en/stable/tutorials/best_practices/index.html) over tightly coupled lookups.
- Keep scenes focused: one root node per major responsibility, child nodes named descriptively (no default `Node2D`, `Control`). Clean up temporary nodes with `queue_free()` to prevent leaks.
- When adding multiplayer code, isolate RPCs in the relevant script (e.g. `NetworkManager.gd`), annotate with `@rpc` access policy, and validate remote data server-side where feasible.

## Resource & UID Management
- Keep `.tscn` and `.tres` files committed so resource UIDs resolve consistently. After renaming scenes, verify the UID cache updates before pushing.
- References in `project.godot` should use `res://` paths when possible to avoid UID drift, especially for the main scene and autoloads.

## Testing & QA
- Aim for deterministic gameplay logic to support automated tests. Add future unit or integration coverage under `tests/` using GUT or Godot’s native runner (headless command shown above).
- For new features, capture short clips of `GameScene.tscn` interactions to document expected behaviour until automated regression tests exist.
- Run smoke tests in headless mode before merging multiplayer changes to ensure RPC paths stay valid.

## Process & Collaboration
- Commits stay short and imperative (e.g. `Tweak round flow`). PR descriptions must state scope, evidence (commands run, screenshots, clips), and related docs/roadmap items. Flag networking changes that touch `scripts/NetworkManager.gd` or multiplayer flow.
- Align planning with `docs/snarkscissors_project_roadmap.md`: stabilise the player-hosted MVP first, then harden netcode, and plan for the dedicated server milestone.
- Reference Godot’s stable documentation for engine features, editor workflows, and best practices; link relevant sections in code comments only when behaviour deviates from defaults.
