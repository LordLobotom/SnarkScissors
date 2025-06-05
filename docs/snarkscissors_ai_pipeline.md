# SnarkScissors - AI Art Pipeline & UI/UX Design
## Shake Fidget + Darkest Dungeon Style Consistency

### Doporučené AI Nástroje (Ranked)

#### 1. Midjourney V6 (TOP Choice)
- Pro nejlepší projekt - Character Reference --cref parameter umožňuje consistent characters napříč obrázky
- Kombinace --sref style reference a --cref pro consistent style i charaktery
- Výborné pro cartoon/fantasy style podobný Shake Fidget

**Setup pro konzistenci:**
```
/imagine [character description] --cref [reference_image_URL] --sref [style_reference_URL] --cw 100 --ar 1:1
```

**Pricing:** $10/měsíc Basic plan = 200 generací

#### 2. Consistent Character AI
- Specializovaný nástroj pro consistent characters bez prompt engineering
- Perfektní pro začátečníky
- Jednodušší než Midjourney, ale menší kreativní kontrola

#### 3. Layer.ai Pro Game Development
- Specializovaný na game assets, rychlé iterations pro indie vývoj
- Expensive, ale worth it pokud potřebujeme volume

#### 4. CGDream Free Alternative
- Free consistent character generator s professional výsledky
- Dobrý pro experimenty a prototyping

### Art Style Definition

#### Shake Fidget Elements:
- **Proporce:** Chibi-style s velkými hlavami
- **Barvy:** Sýté, kontrastní paleta
- **Lineart:** Thick outlines, hand-drawn feel
- **Textures:** Soft shading, minimal detail
- **Humor:** Exaggerated expressions, cartoonish

#### Darkest Dungeon Elements:
- **Atmosféra:** Dramatic lighting, shadows
- **Character Design:** Distinctive silhouettes
- **Color Grading:** Rich, saturated tones
- **Composition:** Dynamic poses, action-oriented

#### Combined Style for SnarkScissors:
```
Art Style Prompt: cartoon character, thick black outlines, chibi proportions, vibrant colors, dramatic lighting, fantasy RPG style, hand-drawn illustration, expressive face, action pose, similar to Shake and Fidget mixed with Darkest Dungeon, colorful but moody, --style raw --stylize 750
```

### Character Reference Sheet Creation

#### Step 1: Master Reference (Midjourney)
```
Prompt Template: character sheet of [CHARACTER_TYPE], multiple poses and expressions, front view, side view, back view, action poses, cartoon style, thick outlines, vibrant colors, fantasy RPG character, chibi proportions, white background, reference sheet layout, --ar 16:9 --style raw

Examples:
- character sheet of brave knight, multiple poses...
- character sheet of sneaky rogue, multiple poses...
- character sheet of wise wizard, multiple poses...
```

#### Step 2: Consistent Variations using --cref

**Action Poses:**
```
/imagine brave knight throwing rock paper scissors gesture, dynamic action pose, cartoon style --cref [reference_sheet_URL] --cw 100
```

**Expressions:**
```
/imagine brave knight victory celebration dance, happy expression, arms raised --cref [reference_sheet_URL] --cw 100
```

**Customization Parts:**
```
/imagine medieval helmet variations, fantasy armor pieces, colorful designs --sref [style_reference_URL]
```

### UI/UX Mockup Design

#### Main Game Interface (Shake Fidget Layout)
```
┌─────────────────────────────────────────────────────────────┐
│ SNARKSCISSORS                                               │
│ ┌─────────────┐ CHARACTER BATTLE ARENA ┌─────────────┐      │
│ │   PLAYER    │                        │    ENEMY    │      │
│ │             │                        │             │      │
│ │ CHAR AVATAR │        FULL            │ CHAR AVATAR │      │
│ │             │                        │             │      │
│ │   READY!    │       READY!           │   READY!    │      │
│ │             │                        │             │      │
│ │ RENDER      │     COUNTDOWN: 3       │    RENDER   │      │
│ │ EQUIPMENT   │                        │ EQUIPMENT   │      │
│ │ HAT         │   ROCK PAPER SCISSORS  │ HAT         │      │
│ │ WEAPON      │                        │ WEAPON      │      │
│ │ ARMOR       │     SCORE: 2 - 1       │ ARMOR       │      │
│ │ OUTFIT      │                        │ OUTFIT      │      │
│ │ GESTURE     │     NEXT ROUND         │ GESTURE     │      │
│ │             │                        │             │      │
│ │ STATS       │                        │ STATS       │      │
│ │ WINS        │                        │ WINS        │      │
│ │ RANK        │                        │ RANK        │      │
│ │ COINS       │                        │ COINS       │      │
│ └─────────────┘                        └─────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

#### Character Customization Screen
```
┌─────────────────────────────────────────────────────────────┐
│ CHARACTER CUSTOMIZATION                              [SAVE] │
│                                                      [X]    │
│ ┌─────────────┐ LIVE                 CATEGORY TABS          │
│ │   PREVIEW   │ CHAR ┌──┬──┬──┬──┬──┬──┬──┬──┬──┬──┐       │
│ │             │      │  │  │  │  │  │  │  │  │  │  │       │
│ │    HAT      │      │  │  │  │  │  │  │  │  │  │  │       │
│ │   CROWN     │ BODY │  │  │  │  │  │  │  │  │  │  │       │
│ │    HELM     │      │  │  │  │  │  │  │  │  │  │  │       │
│ │    CAP      │ WEAPONS │  │  │  │  │  │  │  │  │  │       │
│ │    MASK     │      │  │  │  │  │  │  │  │  │  │  │       │
│ │             │ GESTURES │  │  │  │  │  │  │  │  │       │
│ │ ROTATE VIEW │      └──┴──┴──┴──┴──┴──┴──┴──┴──┴──┘       │
│ │             │                                            │
│ │ Cool        │ COLOR PICKER              RARITY           │
│ │ Funny       │ ┌─────────────┐          ┌─────────────┐    │
│ │ Scary       │ │    Hue      │ Bright   │   Common    │    │
│ │             │ │    Sat      │ Dark     │    Rare     │    │
│ │ RANDOMIZE   │ └─────────────┘          │    Epic     │    │
│ │             │                          │   Legend    │    │
│ │             │                          └─────────────┘    │
│ │ PREVIEW     │                                            │
│ │ GESTURE     │                                            │
│ └─────────────┘                                            │
│ Knight throws dramatic rock gesture!                       │
└─────────────────────────────────────────────────────────────┘
```

### Gesture Animation System Design

#### Gesture Categories

**Basic Gestures (Free):**
- Rock: Simple fist pump
- Paper: Flat hand wave  
- Scissors: Peace sign with attitude

**Themed Gesture Sets (Premium):**

**Knight Set:**
- Rock: Shield bash motion
- Paper: Banner wave
- Scissors: Sword slash

**Archer Set:**
- Rock: Boulder throw
- Paper: Map unfold
- Scissors: Arrow nocking

**Mage Set:**
- Rock: Earth spell casting
- Paper: Scroll reading
- Scissors: Lightning bolt

**Pirate Set:**
- Rock: Cannonball throw
- Paper: Treasure map
- Scissors: Cutlass swing

#### Victory/Defeat Animations

**Victory Celebrations:**
- Dance moves based on character theme
- Environmental effects (confetti, sparkles)
- Taunting gestures with speech bubbles

**Defeat Reactions:**
- Dramatic death falls
- Comical over-reactions
- Character-specific defeat poses

### Art Production Pipeline

#### Phase 1: Style Guide Creation (Week 1)
1. **Master Style Reference:** Generate 5-10 style reference images
2. **Character Archetypes:** Create base templates for each class
3. **Color Palette:** Define primary/secondary color schemes
4. **UI Elements:** Basic buttons, frames, backgrounds

#### Phase 2: Character Asset Creation (Week 2-3)
1. **Base Characters:** 5-8 starting character types
2. **Modular Parts:** Hats, weapons, armor (20 pieces each)
3. **Gesture Animations:** Basic set + 2-3 premium sets
4. **Expression Sheets:** Happy, angry, surprised, etc

#### Phase 3: Environment & UI (Week 4)
1. **Battle Arenas:** 3-5 different backgrounds
2. **UI Frames:** Consistent styling across all screens
3. **Icons & Buttons:** Complete UI element set
4. **Effects:** Particle systems, hit effects, transitions

#### Phase 4: Polish & Consistency (Week 5)
1. **Quality Check:** Ensure all assets match style guide
2. **Animation Polish:** Smooth transitions, timing
3. **Color Grading:** Consistent mood across all assets
4. **Export & Optimization:** Proper formats for Godot

### Specific Prompts for Our Game

#### Character Reference Creation:
```
character reference sheet of brave cartoon knight, multiple expressions (happy, angry, surprised, confident), multiple poses (idle, action, victory, defeat), thick black outlines, vibrant colors, chibi proportions, fantasy RPG style, white background, turnaround views, --ar 16:9 --style raw --stylize 750
```

#### UI Element Generation:
```
fantasy game UI button, medieval wooden frame, golden accents, thick outlines, cartoon style, ornate design, game interface element, --ar 3:1 --style raw

game inventory slot, empty item frame, medieval fantasy style, thick borders, subtle glow effect, UI element, --ar 1:1 --style raw
```

#### Battle Arena Backgrounds:
```
medieval tournament arena background, cartoon style, vibrant colors, cheering crowd, fantasy setting, thick outlines, game background, atmospheric perspective, --ar 16:9 --style raw
```

#### Gesture Animation Keyframes:
```
cartoon knight character throwing rock gesture, dynamic action pose, thick outlines, vibrant colors, dramatic motion lines, exaggerated expression, game animation keyframe, --cref [character_reference_URL]
```

### Technical Implementation Notes

#### Godot Integration:
- **Sprite Sheets:** Export animations as PNG sequences
- **Modular System:** Separate layers for customization parts
- **Resolution:** 256x256 for characters, 128x128 for items
- **Format:** PNG with alpha for transparency

#### Performance Optimization:
- **Texture Atlases:** Combine related sprites
- **LOD System:** Lower detail for distant/small characters
- **Animation Culling:** Stop animations off-screen
- **Memory Management:** Load/unload assets as needed

### Next Steps This Week

#### Day 1-2: Setup & Style Guide
1. **Subscribe to Midjourney** ($10)
2. **Create master style reference images**
3. **Generate character archetype sheets**
4. **Test consistency with --cref parameter**

#### Day 3-4: Character Assets
1. **Create 3-5 base character designs**
2. **Generate modular customization parts**
3. **Test color variations and combinations**
4. **Export for Godot testing**

#### Day 5-7: UI & Mockups
1. **Create main game interface mockup**
2. **Design customization screen**
3. **Generate UI elements (buttons, frames)**
4. **Prepare assets for prototype**

### Success Metrics

**Quality Benchmarks:**
- Consistent character appearance across all images
- Clear Shake Fidget + Darkest Dungeon style blend
- Modular customization system working
- Professional-looking UI mockups ready

**Ready for next phase:** Technical prototype with actual art assets!

---

**SnarkScissors Art Pipeline je kompletně připravený pro realizaci!** 🎨✂️