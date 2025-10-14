# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SnarkScissors is a PvP Rock-Paper-Scissors game built with Godot 4.x and GDScript. It features multiplayer functionality with a comic art style, transforming the classic game into an engaging online experience with customizable avatars and exaggerated animations.

**Current Status:** MVP phase with local split-screen and online multiplayer via player-hosted sessions. Actively developing toward a dedicated server architecture.

## Development Commands

### Running the Game

```bash
# Open project in Godot Editor
godot4 --path . --editor

# Run the game directly (requires main scene set in Project Settings)
godot4 --path . --run

# Run headless (for testing networking and CI)
godot4 --headless --path . --run
```

**Note:** If the main scene is unset, configure it in `Project Settings > Application > Run > Main Scene` to `res://scenes/MainMenu.tscn`.

### Exporting Builds

Export configurations are defined in `export_presets.cfg` for:
- Windows Desktop
- Linux/X11
- Web (HTML5)

```bash
# Export desktop builds headlessly
godot4 --headless --path . --export-release "Linux/X11" build/snarkscissors.x86_64
```

### Testing

The project currently lacks automated tests but plans to add them under `tests/` using GUT or Godot's native test runner.

**Manual Testing:**
- Local split-screen mode (2 players, same PC)
- Network hosting (one player hosts, another connects via IP)
- Run smoke tests in headless mode before merging multiplayer changes to verify RPC paths remain valid

**Testing Best Practices:**
- Aim for deterministic gameplay logic to support future automated tests
- Capture short clips of `GameScene.tscn` interactions to document expected behaviour
- Test both host and client perspectives when modifying network flow

## Architecture

### Networking Model

**Player-Hosted Sessions (Current):**
- One player acts as both server and authority using `ENetMultiplayerPeer`
- Host manages game state, round resolution, and synchronization
- Maximum 2 players for MVP (1v1 duels)
- Plans exist for dedicated server migration (see `docs/snarkscissors_project_roadmap.md`)

**Network Flow:**
1. Host creates server via `NetworkManager.create_server()`
2. Client connects via `NetworkManager.join_server(ip, port)`
3. Players ready up in `MainMenu` lobby
4. Host initiates `start_game.rpc()` to transition to `GameScene`
5. Host drives all game phases via RPC calls to synchronize state

### Core Components

**NetworkManager (Autoload Singleton)**
- Location: `scripts/NetworkManager.gd`
- Singleton managing all multiplayer connections and RPC synchronization
- Exposes signals: `player_connected`, `player_disconnected`, `connection_established`, `connection_failed`, `server_created`
- Key responsibilities:
  - Create/join servers
  - Track connected peers and ready states
  - Synchronize game state through RPC methods
  - Bridge between UI scenes and multiplayer backend

**Main Scenes:**
- `scenes/MainMenu.tscn` - Entry point, connection panel, and lobby (script: `scripts/MainMenu.gd`)
- `scenes/GameScene.tscn` - Arena for Rock-Paper-Scissors duels (script: `scripts/GameScene.gd`)
- `scenes/UI/PlayerListItem.tscn` - Reusable lobby player item (script: `scripts/PlayerListItem.gd`)

**Game Flow:**
1. **MainMenu.gd** - Handles hosting/joining, lobby management, ready checks
2. **NetworkManager** - Coordinates RPC calls when all players are ready
3. **GameScene.gd** - Orchestrates round phases:
   - `waiting` → `countdown` (3s) → `choosing` (10s) → `results`
   - Host is authoritative: evaluates RPS outcomes, broadcasts results
   - First to 3 wins (best of 5 rounds)

### RPC Synchronization Pattern

**Authority Model:**
- Host (`NetworkManager.is_host == true`) drives state transitions
- Host uses `@rpc("authority", "call_local", "reliable")` to broadcast phases
- Clients use `@rpc("any_peer", "call_remote", "reliable")` to send choices

**Key Synchronized Events:**
- `sync_round_start(round_number)` - Initiates new round for all peers
- `sync_countdown_phase(time)` - Starts countdown timer
- `sync_choice_phase(time)` - Opens choice buttons, starts selection timer
- `sync_player_choice(player_id, choice)` - Broadcasts player's throw
- `sync_round_end(winner_id, results)` - Displays results and updates scores

### Scene References

NetworkManager maintains weak references to active scenes:
- `main_menu_ref` - Set when MainMenu is active
- `game_scene_ref` - Set when GameScene is active

These references allow RPC handlers to invoke methods on the active scene (e.g., `game_scene_ref.receive_player_choice()`).

## Code Conventions

Follow the official [GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html):

- **Language:** GDScript (Godot 4.x syntax with typed variables)
- **Indentation:** 4 spaces (no tabs)
- **Naming:**
  - snake_case for variables, functions, and signals (e.g., `round_completed`)
  - PascalCase for classes and scene files
  - Use explicit types on exported and public members
- **Node References:** Use `@onready var` for cached node references instead of repeated `get_node()` calls
- **Scene Organization:**
  - One root node per major responsibility
  - Descriptive node names (avoid default names like `Node2D`, `Control`)
  - Clean up temporary nodes with `queue_free()` to prevent leaks
- **Signals:** Declared at top of scripts, prefer [node grouping and signals](https://docs.godotengine.org/en/stable/tutorials/best_practices/index.html) over tightly coupled lookups
- **Comments:** Czech language inline comments for implementation notes, English for architectural explanations
- **RPC Annotations:** Always specify authority, delivery mode, and reliability explicitly; isolate RPCs in relevant scripts and validate remote data server-side where feasible

## File Organization

```
/
├── scenes/           # .tscn scene files
│   ├── MainMenu.tscn
│   ├── GameScene.tscn
│   └── UI/          # Reusable UI components (instanced across menus)
├── scripts/         # .gd GDScript files
│   ├── NetworkManager.gd (autoload)
│   ├── MainMenu.gd
│   ├── GameScene.gd
│   └── PlayerListItem.gd
├── ui/              # UI assets and resources
├── docs/            # Design documents and roadmaps
├── tests/           # Planned: Unit/integration tests (GUT or native runner)
├── icon.svg         # Shared art at root level
├── project.godot    # Godot project configuration
├── export_presets.cfg  # Export configurations
└── README.md
```

**Organization Principles:**
- Each `.tscn` file has a matching script in `scripts/` (e.g., `scenes/GameScene.tscn` ↔ `scripts/GameScene.gd`) per [Godot scene/script pairing](https://docs.godotengine.org/en/stable/tutorials/best_practices/node_tree_best_practices.html)
- UI fragments belong in `scenes/UI/` for reusability
- Design and technical references in `docs/` should be reviewed before altering gameplay, networking, or delivery scope
- Shared assets stay at root level to avoid import path churn

## Important Context

### Multiplayer State Management

- **Determinism:** Round resolution must be deterministic across all peers
- **Host Migration:** Not yet implemented; disconnected host ends the match
- **Reconnection:** Not yet implemented; dropped connections terminate the game
- **Input Validation:** Currently minimal; planned for Harden phase

### Current Limitations

- Only supports 2-player matches (1v1)
- No NAT traversal or relay fallback (players must configure port forwarding)
- No persistent player profiles or match history
- No anti-cheat or input validation beyond basic checks
- Settings panel is not yet implemented

### Future Roadmap Phases

1. **Stabilise** (Weeks 0-4): Polish MVP, smoke test player hosting
2. **Harden** (Weeks 4-10): Host migration, telemetry, authoritative server prep
3. **Scale** (Weeks 10+): Dedicated servers, matchmaking, Steam integration

See `docs/snarkscissors_project_roadmap.md` for full details.

## Working with This Codebase

### Adding New Game Modes

1. Extend `GameScene.gd` with mode-specific logic
2. Update `NetworkManager` RPC methods if new synchronization is needed
3. Consider host authority implications (who evaluates outcomes?)
4. Align changes with `docs/snarkscissors_project_roadmap.md` phases

### Modifying Network Flow

1. Changes to RPC signatures require updates on both host and client code paths
2. Test with both host and client perspectives
3. Always use `call_local` to ensure host sees the same state as clients
4. Verify `NetworkManager.is_host` checks before authoritative actions
5. **Flag all networking changes that touch `scripts/NetworkManager.gd` or multiplayer flow in PRs**
6. Run smoke tests in headless mode before merging

### UI Development

- Scenes use Godot's Control nodes with custom themes
- Node references use `@onready` for scene tree queries
- Signals connect in `_ready()` via `_connect_ui_signals()` helper
- UI text is primarily in English, with some Czech in code comments
- UI fragments in `scenes/UI/` should be reusable across menus

### Resource & UID Management

- Keep `.tscn` and `.tres` files committed so resource UIDs resolve consistently
- After renaming scenes, verify the UID cache updates before pushing
- References in `project.godot` should use `res://` paths to avoid UID drift (especially for main scene and autoloads)

### Git & Collaboration

- **Commit messages:** Short and imperative (e.g., "Tweak round flow")
- **PR descriptions:** State scope, evidence (commands run, screenshots, clips), and related docs/roadmap items
- Reference Godot's [stable documentation](https://docs.godotengine.org/en/stable/) for engine features and link relevant sections in code comments only when behaviour deviates from defaults

## Resources

- Game Design Document: `docs/snarkscissors_gdd.md`
- Technical Study: `docs/snarkscissors_tech_study.md`
- Project Roadmap: `docs/snarkscissors_project_roadmap.md`
- AI Pipeline: `docs/snarkscissors_ai_pipeline.md`
- Godot 4 Multiplayer Docs: https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html
