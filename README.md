# SnarkScissors

SnarkScissors is a small, playable Rock–Paper–Scissors game built with Godot 4. Open it, press **Play**, and immediately face the computer.

## MVP features

- A centered main menu with only Play, Settings, and Quit.
- Endless player-versus-computer rounds with a persistent session score.
- Large Rock, Paper, and Scissors controls with original SVG pictograms.
- A short locked-input reveal animation and clear win, loss, or draw feedback.
- Responsive landscape and portrait layouts. Portrait places the computer above the player and keeps choices at the bottom.
- Persistent master, music, and effects volume controls.
- Keyboard focus plus `1`, `2`, and `3` shortcuts for the three choices.

## Run

```powershell
godot4 --path .
```

If Godot is not on `PATH`, open `project.godot` from the Godot Project Manager. The main scene is already set to `res://scenes/MainMenu.tscn`.

## Test

Run the complete deterministic project, UI, settings, and gameplay check:

```powershell
powershell -ExecutionPolicy Bypass -File .agents/skills/snark-godot-qa/scripts/run-tests.ps1
```

Capture responsive views by selecting a screen and window size:

```powershell
powershell -ExecutionPolicy Bypass -File .agents/skills/snark-godot-qa/scripts/run-tests.ps1 `
  -Suite ui -CaptureView game -CaptureSize 390x844 `
  -CapturePath artifacts/game-portrait.png
```

The smoke test injects a deterministic computer choice for a complete animated round and checks all nine Rock–Paper–Scissors outcomes.

## Export

The repository includes a Windows Desktop preset:

```powershell
godot4 --headless --path . --export-release "Windows Desktop" ../snarkscissors_export/snarkscissors.exe
```

The runtime UI and renderer are mobile-friendly, but Android and iOS export presets and SDK configuration are not included yet.

## Structure

```text
scenes/
  MainMenu.tscn
  GameScene.tscn
  UI/SettingsOverlay.tscn
scripts/
  MainMenu.gd
  GameScene.gd
  SettingsManager.gd
  SettingsOverlay.gd
  AudioManager.gd
ui/
  theme.tres
  throw_rock.svg
  throw_paper.svg
  throw_scissors.svg
tests/
  UISmoke.tscn
  UISmoke.gd
```

The older multiplayer and lobby implementation has been removed from the MVP. The broader design documents under `docs/` remain long-term product references rather than descriptions of the current runtime.
