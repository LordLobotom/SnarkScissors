# CLAUDE.md

## Current project

SnarkScissors is a Godot 4 single-player Rock–Paper–Scissors MVP. The current runtime deliberately has no lobby, networking, accounts, or matchmaker.

Runtime flow:

1. `scenes/MainMenu.tscn` opens with Play, Settings, and Quit.
2. Play changes directly to `scenes/GameScene.tscn`.
3. `scripts/GameScene.gd` chooses a random computer throw, locks input during a short reveal, resolves the round, updates the session score, and immediately enables the next round.
4. `scenes/UI/SettingsOverlay.tscn` can be opened from either main scene and persists bus volumes through `SettingsManager`.

## Commands

```powershell
# Run
godot4 --path .

# Non-interactive project load
godot4 --headless --editor --path . --quit

# Complete deterministic QA
powershell -ExecutionPolicy Bypass -File .agents/skills/snark-godot-qa/scripts/run-tests.ps1

# Windows export
godot4 --headless --path . --export-release "Windows Desktop" ../snarkscissors_export/snarkscissors.exe
```

## Architecture

- `scripts/MainMenu.gd`: direct scene navigation and quit handling.
- `scripts/GameScene.gd`: local round state, random computer selection, pure outcome mapping, reveal animation, and score display.
- `scripts/SettingsManager.gd`: the persisted audio source of truth at `user://snarkscissors_settings.cfg`.
- `scripts/SettingsOverlay.gd`: pausing modal, live audio preview, reset, and save.
- `scripts/AudioManager.gd`: looping music and a small semantic SFX pool routed through Music and SFX buses.
- `scripts/Backdrop.gd`: shared resize-aware decorative background.
- `tests/UISmoke.gd`: menu/settings assertions, all nine RPS outcomes, and one deterministic animated round.

The game uses a square 390×390 stretch reference with `canvas_items` and `expand`, then reflows the arena by orientation. In portrait, the computer is above the player; in landscape, the player is left and the computer is right.

## Change rules

- Keep `MainMenu.tscn`, `GameScene.tscn`, and `SettingsOverlay.tscn` paired with their scripts.
- Keep the three choice names as `StringName` values: `rock`, `paper`, `scissors`.
- Preserve the phase guard so repeated input cannot overlap reveal animations.
- Keep computer-choice injection available to deterministic tests.
- Use containers and the existing orientation breakpoint rather than fixed screen coordinates.
- Keep audio values clamped to `0.0..1.0` and routed through Master, Music, and SFX.
- Update `tests/UISmoke.gd` whenever scene node paths or interaction contracts change.
