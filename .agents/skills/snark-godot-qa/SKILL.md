---
name: snark-godot-qa
description: Run deterministic validation for the SnarkScissors Godot MVP, including project load, menu/settings smoke checks, injected computer-gameplay validation, and optional responsive UI screenshots.
---

# Snark Godot QA

Run all checks from the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .agents/skills/snark-godot-qa/scripts/run-tests.ps1
```

The runner discovers `godot4` or `godot` on `PATH`, then falls back to a Godot console executable in the sibling `Godot/` directory. Pass `-GodotPath <path>` to override discovery.

## Select Checks

```powershell
# UI, settings, audio, and deterministic RPS gameplay
powershell -ExecutionPolicy Bypass -File .agents/skills/snark-godot-qa/scripts/run-tests.ps1 -Suite ui

# Capture a responsive menu, settings overlay, or completed game round
powershell -ExecutionPolicy Bypass -File .agents/skills/snark-godot-qa/scripts/run-tests.ps1 -Suite ui -CaptureView game -CaptureSize 390x844 -CapturePath artifacts/game-portrait.png
```

## Interpret Results

- Require exit code `0` for every Godot process.
- Require `UI_SMOKE_OK` from `tests/UISmoke.tscn`, `AUDIO_SMOKE_OK` from
  `tests/AudioSmoke.tscn`, and `SNARK_QA_OK` from the runner.
- Treat `SCRIPT ERROR` or `Parse Error` output as failure even when Godot returns zero.
- When a `.tscn` hierarchy changes, update exact node paths in `tests/UISmoke.gd` in the same change.
- Keep the injected computer choice deterministic in tests and cover all nine RPS outcomes.

After automated checks, visually inspect the menu, settings overlay, and completed round. Test at least `1024x576`, `2560x1440`, `390x844` portrait, and `844x390` landscape when layout changes.
