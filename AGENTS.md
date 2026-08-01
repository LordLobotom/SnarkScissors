# Repository Guidelines

## Product Contract

- The active product is a small single-player Rock-Paper-Scissors MVP against the computer.
- Keep the main menu limited to `Play`, `Settings`, and `Quit`.
- Keep settings in the main menu; the game screen exposes only `Menu` navigation.
- In phone portrait, place the computer above the player and keep throw buttons at the bottom.
- Networking, lobbies, RPCs, and multiplayer tests are not current runtime dependencies.

## Quick Start

- Open or run the project with `godot4 --path .`.
- Run all automated checks with
  `powershell -ExecutionPolicy Bypass -File .agents/skills/snark-godot-qa/scripts/run-tests.ps1`.
- Export Windows with
  `godot4 --headless --path . --export-release "Windows Desktop" ../snarkscissors_export/snarkscissors.exe`.
- Keep `res://scenes/MainMenu.tscn` as the main scene.

## Project Structure

- Major scenes live in `scenes/` and reusable fragments in `scenes/UI/`.
- Pair major scenes with scripts under `scripts/`, for example
  `scenes/GameScene.tscn` and `scripts/GameScene.gd`.
- Shared visual resources live in `ui/`, music in `audio/`, and used effects in `sfx/`.
- Keep automated smoke scenes and scripts under `tests/`.
- Treat `docs/snarkscissors_project_roadmap.md` as the current delivery scope. Broader design
  documents are concept references only.

## Code and Resource Guidelines

- Follow the official GDScript style guide: four-space indentation, snake_case names,
  PascalCase classes, and explicit types on public or exported members.
- Cache scene nodes with `@onready var`, communicate with signals where useful, and free
  temporary nodes when their work is complete.
- Keep `.tscn`, `.tres`, `.gd.uid`, source assets, import metadata, and required licenses in Git.
- Use `res://` paths for project resources and update scene/script references together.
- Preserve the `Master`, `Music`, and `SFX` audio bus contract and persist settings through
  `SettingsManager`.

## Testing and Delivery

- Keep RPS outcome logic deterministic and cover all nine choice combinations.
- Validate menu actions, settings pause/resume, audio playback, reveal input locking, scoring,
  and neutral choice focus in smoke tests.
- For layout changes, inspect at least 390x844 portrait and 1024x576 desktop; also check
  844x390 and 2560x1440 for broader responsive changes.
- Run `$snark-godot-qa` after implementation and before committing, pushing, or exporting.
- Use short imperative commit subjects and include scope, user impact, and validation evidence
  in pull-request descriptions.
