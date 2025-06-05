# SnarkScissors - Technical Feasibility Study
## Solo Indie Developer - Shake Fidget Inspired UI

### Engine Recommendation: Godot 4.x

#### Proč Godot pro solo indie dev:
- **Bezplatný a open-source** - žádné licenční poplatky
- **Lightweight** - rychlý development cycle
- **Excellent 2D support** - perfektní pro Shake Fidget styl
- **Built-in networking** - MultiplayerAPI pro online funkcionalita
- **Steam integration** - Steamworks SDK addon dostupný
- **Jednoduchý deployment** - export do Windows/Linux/Mac jedním klikem
- **GDScript** - Python-like jazyk, rychlý na učení
- **Malá community** ale kvalitní documentation

#### Alternativy (proč ne):
- **Unity:** Komplexnější, subscription model, overkill pro 2D
- **GameMaker:** Drahý, uzavřený
- **Construct 3:** Web-based, omezené pro Steam integraci

### UI Design Architecture - Shake Fidget Style

#### Core UI Elements:
```
┌─────────────────────────────────────────────────────────────┐
│ SNARKSCISSORS                                               │
│ ┌─────────────┐ GAME AREA                ┌─────────────┐     │
│ │   PLAYER1   │                         │   PLAYER2   │     │
│ │             │                         │             │     │
│ │ CHAR AVATAR │                         │ CHAR AVATAR │     │
│ │    HAT      │        POSE             │    HAT      │     │
│ │    WEPS     │       READY!            │    WEPS     │     │
│ │    GEAR     │                         │    GEAR     │     │
│ │             │  ROCK PAPER SCISSORS    │             │     │
│ │   STATS     │                         │   STATS     │     │
│ └─────────────┘                         └─────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

#### Technical Implementation:
- **UI Framework:** Godot's built-in UI system (Control nodes)
- **Character Display:** AnimatedSprite2D s frame-based animacemi
- **Customization:** Modular sprite system (base + overlays)
- **Responsive Design:** Anchor-based layout pro různá rozlišení

### Networking Architecture

#### Multiplayer Options:

**Option 1: Godot MultiplayerAPI (Doporučeno)**
```gdscript
# Příklad synchronizace RPS výběru
@rpc("any_peer", "call_local", "reliable")
func player_choice(choice: String):
    players_ready += 1
    player_choices[multiplayer.get_remote_sender_id()] = choice
    if players_ready == 2:
        evaluate_round()
```

**Výhody:**
- Built-in do Godotu
- Easy setup pro P2P i dedicated server
- Automatic synchronization
- Low latency pro RPS timing

**Option 2: External Service (Pro scalability)**
- **Nakama:** Open-source game server
- **Firebase:** Pro jednoduchý start
- **Custom Node.js:** Když potřebujeme full control

#### Recommended Flow:
1. Start s Godot MultiplayerAPI (MVP)
2. Scale na dedicated server když potřebujeme Battle Hall

### Art Pipeline - Shake Fidget Style

#### Asset Creation Workflow:
1. **Base Characters:** Vector art v Inkscape/Illustrator
2. **Modular System:** Separate layers pro customization
3. **Animation:** Simple tweening, no complex rigging
4. **Export:** PNG sprite sheets, optimized for Godot

#### Character Customization System:
```gdscript
# Modular character system
class_name Character
extends Node2D

@export var base_sprite: Texture2D
@export var hat_sprite: Texture2D  
@export var weapon_sprite: Texture2D

func update_appearance():
    $Base.texture = base_sprite
    $Hat.texture = hat_sprite
    $Weapon.texture = weapon_sprite
```

#### Animation Style:
- **Tweening-based:** Simple scale/rotation effects
- **Frame-based:** Pour gesture animations
- **Particle effects:** Pro victory/defeat animations
- **Juice effects:** Screen shake, color flashes

### Steam Integration

#### Required Features:
- **Steamworks SDK:** Community-maintained Godot addon
- **Achievements:** Easy integration s Godot signals
- **Cloud Save:** JSON save files
- **Multiplayer:** Steam P2P networking
- **Workshop:** Pro user-generated content (budoucnost)

#### Implementation:
```gdscript
# Steam achievement unlock
func unlock_achievement(achievement_id: String):
    if Steam.is_init():
        Steam.set_achievement(achievement_id)
        Steam.store_stats()
```

### MVP Technical Roadmap

#### Sprint 1 (1-2 týdny): Basic RPS Logic
- Godot project setup
- Basic UI layout (2 player boxes)
- RPS game logic implementation
- Local multiplayer (hotseat)
- Simple victory/defeat states

#### Sprint 2 (1-2 týdny): Character System
- Modular character sprites
- Basic customization menu
- Character animation system
- Save/load character configs

#### Sprint 3 (2-3 týdny): Online Multiplayer
- Godot MultiplayerAPI setup
- Matchmaking lobby
- Synchronous RPS gameplay
- Connection handling/reconnect

#### Sprint 4 (1-2 týdny): Steam Integration
- Steamworks addon integration
- Basic achievements
- Cloud save functionality
- Steam overlay compatibility

#### Sprint 5 (2-3 týdny): Polish MVP
- Victory animations
- Sound effects
- UI polish/tweening
- Performance optimization

### Development Environment Setup

#### Tools Stack:
- **Engine:** Godot 4.2+
- **Art:** Inkscape (free) + GIMP
- **Audio:** Audacity + freesound.org
- **Version Control:** Git + GitHub
- **Project Management:** GitHub Issues/Projects

#### Asset Resources:
- **Free Art:** OpenGameArt.org, Kenney.nl
- **Placeholder Audio:** Zapsplat, freesound.org
- **Fonts:** Google Fonts (podobné Shake Fidget)

### Technical Risks & Mitigation

#### High Risk:
- **Network Synchronization:** RPS musí být perfectly timed
- **Mitigation:** Prototyp networking ASAP, použít reliable RPCs

#### Medium Risk:
- **Steam Integration:** Komplexita - První Steam hra může být tricky
- **Mitigation:** Steamworks addon má good documentation

#### Low Risk:
- **Performance:** s Godot 2D RPS game nebude performance intensive
- **Cross-platform:** Godot export je reliable

### Cost Breakdown - Solo Dev

#### Development Costs:
- **Engine:** $0 (Godot free)
- **Art Tools:** $0 (open-source alternativy)
- **Steam Direct Fee:** $100 (one-time)
- **Server Costs:** $0-50/month (start s Godot P2P)

#### Time Investment:
- **MVP:** 8-12 týdnů (part-time)
- **Steam Ready:** 4-6 týdnů
- **Full Feature Set:** 8-12 týdnů

#### Revenue Share:
- **Steam:** 30% (po $1M), 25% (po $10M), 20% (po $50M)
- **Godot:** 0% (free engine)

### Next Steps This Week

1. **Install Godot 4.2+** a vytvořit nový projekt
2. **Mockup základní UI** (jednoduchý gray-box)
3. **Implement basic RPS logic** (single player vs AI)
4. **Test Steamworks addon** compatibility
5. **Create art pipeline workflow** (base character + 1 hat)

### Ready to Start?

Máme kompletní technický plán pro SnarkScissors! Vše je realizovatelné pro solo indie developera s Godot enginem.

**Chcete začít s konkrétním kódem nebo se nejdříve podíváme na setup Godot projektu a základní UI mockup?**