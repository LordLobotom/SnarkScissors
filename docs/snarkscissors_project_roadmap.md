# SnarkScissors Project Roadmap

## Current product baseline

The active product is a deliberately small single-player MVP:

- Immediate Rock–Paper–Scissors against a computer opponent.
- Endless session scoring with deterministic rules.
- A short reveal animation and semantic sound feedback.
- A three-action main menu and reusable audio settings overlay.
- Responsive desktop, phone landscape, and phone portrait layouts.
- Automated project, UI, settings, and injected-gameplay smoke coverage.

The former player-hosted ENet lobby prototype is no longer part of the runtime. Networking remains a possible future direction, not a current dependency.

## Phase 1 — Stabilize the simple MVP

- Validate touch ergonomics and safe-area behavior on physical Android and iOS devices.
- Add Android and iOS export presets once the local SDK/toolchain is available.
- Confirm music and sound asset licensing and optimize package size.
- Add a compact pause/resume behavior for mobile lifecycle notifications.
- Keep captures clean at 390×844, 844×390, 1024×576, and 2560×1440.

## Phase 2 — Add replay value without complicating the flow

- Optional best-of-five match mode and a one-tap score reset.
- Small result streaks, haptics, and additional reveal polish.
- Lightweight computer personalities or difficulty patterns that never compromise clear rules.
- Local statistics saved on device.

## Phase 3 — Reassess multiplayer

Only revisit networking after the local game is polished and validated on target devices. Start with a written contract for authority, hidden choices, disconnect behavior, and deterministic tests before adding lobby or transport code.

The broader ambitions in `snarkscissors_gdd.md`, `snarkscissors_tech_study.md`, and `snarkscissors_competitive.md` remain concept references. They do not describe the current implementation.
