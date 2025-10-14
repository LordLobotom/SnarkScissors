# SnarkScissors 🪨📄✂️

An innovative PvP game transforming the classic Rock-Paper-Scissors game into a modern multiplayer experience with comic book aesthetics.

## About the Game
SnarkScissors combines the simplicity of familiar Rock-Paper-Scissors mechanics with exaggerated animations, fully customizable avatars, and witty gestures. Create your unique fighter and battle in intense matches against players from around the world.

## Key Features
- 🎮 Classic RPS mechanics with optional Lizard-Spock variant expansion
- 🎨 Fully customizable avatars with unlockable gestures
- 🏟️ Various game modes from 1v1 to massive Battle Hall (50 players)
- 🎭 Comic book aesthetics with emphasis on humor and visual effects
- 🏆 Tournament modes with organized competitions
- 👥 Team battles 3v3 and 8v8

## Current Status (MVP)
Currently working on MVP version with the following features.

### Implemented
- Basic RPS mechanics (rock, paper, scissors)
- Local multiplayer for 2 players (online via player-hosted sessions)
- Best of 5 rounds system (first to 3 wins)
- Basic UI with countdown and score tracking
- Main menu with lobby system

### In Development
- Extended animations and visual effects
- Avatar customization system
- Dedicated server architecture
- Steam integration

## Technical Specifications

### Engine and Tools
- Game Engine: Godot 4.x
- Language: GDScript
- Primary Platform: PC (Steam)
- Future Platforms: Web, mobile companion application

### System Requirements (Preliminary)
- OS: Windows 10/11, macOS 10.15+, Linux Ubuntu 18.04+
- Processor: Intel i5-4590 / AMD FX 8350 or better
- Memory: 4 GB RAM
- Graphics: DirectX 11 compatible GPU
- Network: Broadband internet connection
- Storage: 2 GB available space

## Installation and Setup

### Cloning the Repository
```bash
git clone https://github.com/LordLobotom/snarkscissors.git
cd snarkscissors
```

### Opening in Godot
1. Download Godot 4.x from [godotengine.org](https://godotengine.org).
2. Open the `project.godot` file in the editor.
3. Run the main scene `MainMenu.tscn` or use the Play button for quick testing.

### Running from Command Line
```bash
# Open in editor
godot4 --path . --editor

# Run directly
godot4 --path . --run

# Run headless (for testing)
godot4 --headless --path . --run
```

## Project Structure
```
/
├── scenes/          # Game scenes (.tscn files)
├── scripts/         # GDScript files (.gd)
├── ui/              # UI assets and resources
├── docs/            # Design documents and roadmaps
└── project.godot    # Godot project configuration
```

## Documentation
- [Game Design Document](docs/snarkscissors_gdd.md) - Complete game design and features
- [Technical Study](docs/snarkscissors_tech_study.md) - Technical implementation details
- [Competitive Analysis](docs/snarkscissors_competitive.md) - Market analysis
- [AI Art Pipeline](docs/snarkscissors_ai_pipeline.md) - Art asset creation workflow
- [Project Roadmap](docs/snarkscissors_project_roadmap.md) - Development phases and milestones

## Development Roadmap

### Phase 1: Stabilize (Weeks 0-4)
- Lock MVP experience
- Smoke-test player hosting
- Polish gameplay and UI

### Phase 2: Harden (Weeks 4-10)
- Improve resilience
- Add telemetry
- Prepare authoritative server flow

### Phase 3: Scale (Weeks 10+)
- Dedicated server tier
- Matchmaking queue
- Steam integration
- Live-service features

## Contributing
This is currently a solo indie development project. For questions or suggestions, please open an issue.

## License
All rights reserved. This project is not open source.
