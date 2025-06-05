# SnarkScissors Game Design Document

## 1. Executive Summary

SnarkScissors je inovativní PvP hra, která transformuje klasickou hru Rock-Paper-Scissors do moderního multiplayerového zážitku s komiksovou estetikou. Hra kombinuje jednoduchost známé mechaniky s přehnanými animacemi, plně customizovvatelnými avatary a vtipnými gesty, které vytváří intenzivní a zábavné souboje.

**Klíčové prvky:**
- Klasická RPS mechanika s možností rozšíření o Lizard-Spock variantu
- Plně přizpůsobitelné avatary s odemykatatelnými gesty
- Různorodé herní režimy od 1v1 po masivní Battle Hall
- Komiksová estetika s důrazem na humor a vizuální efekty

## 2. Cílová skupina

### Primární cílová skupina:
- Casual hráči 18-35 let hledající rychlou zábavu
- Fanoušci multiplayerových her s možností customizace
- Hráči, kteří oceňují humor a parodie ve hrách

### Sekundární cílová skupina:
- Mid-core hráči hledající společenský herní zážitek
- Streamers a content creatori díky zábavnému obsahu
- Příležitostní hráči využívající krátké herní session

## 3. Platformy a distribuce

### Primární platforma: Steam
- Hlavní kanál vydání a monetizace
- Využití Steam Workshop pro uživatelský obsah
- Integrace Steam achievement a cloud save
- Steam matchmaking pro online režimy
- Komunitní funkce (fóra, recenze, guides)

### Doplňkové platformy:
- **Cross-play webový klient:** Rychlý přístup bez instalace
- **Mobilní companion app:** Správa profilu a sledování statistik
- **Budoucí rozšíření:** Epic Games Store, konzole s cross-play podporou

## 4. Core Gameplay

### Herní mechanika:
- **Základní RPS:** Rock beats Scissors, Scissors beats Paper, Paper beats Rock
- **Rozšířená varianta:** Lizard-Spock pro pokročilé hráče
- **Timing system:** Synchronní odpočítávání 3...2...1... THROW!
- **Formát zápasu:** Best of 3, 5 nebo 7 podle režimu

### Herní režimy:

#### 1v1 Duels:
- **Local Hotseat:** Dva hráči na jednom PC
- **Online Ranked:** Matchmaking s ELO systémem
- **Private Matches:** Soukromé místnosti s přáteli
- **Practice Mode:** Trénink proti AI s různými obtížnostmi

#### Battle Hall (Masivní režim):
- **Kapacita:** 20-50 hráčů současně
- **Mechanika:** Všichni hází současně, postupují pouze vítězové
- **Formát:** Eliminační kola až do posledního přeživšího
- **Odměny:** Speciální kosmetika pro top 3 umístění

#### Team vs Team (TvT):
- **Týmy:** 3v3 a 8v8 hráčů
- **Mechanika:** Náhodná párování 1v1 soubojů mezi týmy
- **Vítězství:** Tým s více výhrami v kole postupuje
- **Speciální funkce:** Týmová gesta a koordinované animace

#### Turnajové režimy:
- **Formát:** Pavoukový systém pro 8, 16 nebo 32 hráčů
- **Sledování:** Spectate mode pro vyřazené hráče
- **Komentáře:** AI komentátor s vtipnými poznámkami
- **Odměny:** Exkluzivní tituly a kosmetické předměty

## 5. Klíčové funkce

### Avatar Customization System:
- **Vzhled:** Různé typy postavy, barvy, proporce
- **Oblečení:** Klobouky, brnění, kostýmy, tematické outfity
- **Zbraně/Předměty:** Meče, kladiva, magické hole, absurdní předměty
- **Pozadí:** Prostředí pro souboje (arény, fantasy lokace, sci-fi)
- **Animace:** Personalizované pózy a gesta pro každý tah

### Gesture System:
- **Základní gesta:** Klasické házení kamene, nůžek, papíru
- **Speciální gesta:** Odemykatelné dramatické animace
- **Tematické sety:** Ninja, pirát, čaroděj, robot styly
- **Rare gestures:** Epické animace s vizuálními efekty
- **Custom combos:** Možnost kombinovat různé prvky

### Victory & Defeat Animations:
- **Victory dances:** Různorodé taneční sekvence
- **Taunts:** Posměšná gesta a repliky
- **Komiksové bubliny:** Vtipné komentáře a urážky
- **Defeat animations:** Dramatické smrti a reakce na prohru
- **Environmental effects:** Exploze, ohňostroje, magické efekty

## 6. Technické specifikace

### Technologický stack:

**Option A: Web-based approach**
- **Frontend:** React + Phaser.js
- **Backend:** Node.js + Colyseus/Socket.io
- **Steam integrace:** Electron wrapper
- **Database:** MongoDB/PostgreSQL

**Option B: Native approach**
- **Engine:** Unity nebo Godot
- **Networking:** Mirror/Photon (Unity) nebo built-in (Godot)
- **Steam SDK:** Plná integrace
- **Cross-platform:** Jednoduchá portování

### Síťová architektura:
- **Server-client model:** Autoritativní server pro fair play
- **Real-time synchronizace:** Důraz na lag compensation
- **Anti-cheat:** Validace všech akcí na serveru
- **Scalability:** Horizontální škálování pro masivní režimy

## 7. UI/UX Design

### Split-Screen Interface (1v1):
```
Player 1         |  Player 2
Avatar 3D        |  Avatar 3D
Rock Paper       |  Paper Rock
Scissors         |  Scissors
Countdown: 3     |  Countdown: 3
READY!          |  READY!
------------------------------------
Score: 2-1      |  Next Round
---------------------------------
```

### Battle Hall Interface:
- **Main view:** Grid zobrazení všech hráčů
- **Mini-map:** Přehled postupujících hráčů
- **Chat:** Rychlá komunikace
- **Leaderboard:** Aktuální pořadí
- **Spectate controls:** Pro vyřazené hráče

### Customization Menu:
- **3D preview:** Rotační model avatara
- **Category tabs:** Oblečení, zbraně, gesta, pozadí
- **Filter system:** Podle rarity, tématu, ceny
- **Preview animations:** Ukázka gest v akci

## 8. Development Roadmap

### Phase 1: MVP (3-4 měsíce)
1. **Core mechanics:** Základní RPS logika
2. **Local multiplayer:** Split-screen pro 2 hráče
3. **Basic UI:** Funkční rozhraní
4. **Simple avatars:** Základní customizace
5. **Victory animations:** Jednoduché celebrace

### Phase 2: Online Features (2-3 měsíce)
1. **Online matchmaking:** 1v1 ranked matches
2. **Steam integration:** Achievementy, cloud save
3. **Extended gestures:** Více animací a efektů
4. **Profile system:** Statistiky a progression

### Phase 3: Massive Modes (3-4 měsíce)
1. **Battle Hall:** Masivní multiplayer
2. **Team vs Team:** Týmové režimy
3. **Tournament system:** Organizované turnaje
4. **Spectate mode:** Sledování zápasů

### Phase 4: Content & Polish (2-3 měsíce)
1. **Advanced customization:** Více kosmetických předmětů
2. **Seasonal events:** Speciální režimy a odměny
3. **Community features:** Guilds, chat, friends
4. **Performance optimization:** Podpora více hráčů

## 9. Monetizace strategie

### Základní model: Freemium/Premium
- **Base game:** Jednorázová platba na Steamu ($9.99-14.99)
- **Kosmetické DLC:** Tematické balíčky ($2.99-4.99)
- **Season Pass:** Kvartální content ($9.99)

### Mikrotransakce (post-launch):
- **Premium gestures:** Epické animace ($0.99-2.99)
- **Exclusive avatars:** Limitovaná edice ($1.99-3.99)
- **Battle Pass:** Sezónní progression systém ($9.99)
- **Guild features:** Prémiové týmové funkce

### Community monetizace:
- **Steam Workshop:** Podíl z uživatelského obsahu
- **Tournament entries:** Malé vstupné pro velké turnaje
- **Merchandise:** Fyzické produkty s herními motivy

## 10. Vizuální styl a audio

### Art Direction:
- **Styl:** Komiksová 3D grafika s cel-shading efekty
- **Barevnost:** Sytá, kontrastní paleta
- **Animace:** Přehnané, expresivní pohyby
- **Inspirace:** Shake Fidget, Team Fortress 2, Overwatch

### Audio Design:
- **Soundtrack:** Energická, komiksová hudba
- **Sound effects:** Přehnané zvukové efekty
- **Voice acting:** Charakteristické hlasy pro avatary
- **Dynamic audio:** Hudba reagující na intenzitu zápasu

## 11. Marketing a komunita

### Launch strategie:
- **Steam Next Fest:** Demo během festivalu
- **Influencer marketing:** Spolupráce se streamery
- **Gaming conventions:** Prezentace na indie game show
- **Social media:** TikTok, Twitter, YouTube shorts

### Komunitní podpora:
- **Official Discord:** Centrální hub pro hráče
- **Regular events:** Týdenní turnaje a challenges
- **Community contests:** Soutěže v designu avatarů
- **Developer streams:** Pravidelné streamy s vývojem

## 12. Rizika a mitigace

### Technická rizika:
- **Latency issues:** Důkladné testování networking kódu
- **Scalability:** Postupné navyšování kapacity serverů
- **Cross-platform compatibility:** Extensive QA testing

### Business rizika:
- **Market saturation:** Diferenciace skrze humor a customizaci
- **Low retention:** Regular content updates a events
- **Monetization balance:** Fair pricing bez pay-to-win prvků

## 13. Success Metrics

### Launch metrics (první 3 měsíce):
- **Player base:** 10,000 aktivních hráčů
- **Steam rating:** 80% pozitivní recenze
- **Retention:** 30% D7 retention rate
- **Revenue:** Break-even do 6 měsíců

### Long-term goals (12 měsíců):
- **Active players:** 50,000 MAU
- **Tournament participation:** 1,000 hráčů v měsíčních turnajích
- **Community content:** 100+ workshop items
- **Platform expansion:** Úspěšný launch druhé platformy

---

Tento dokument slouží jako živý průvodce vývojem hry SnarkScissors a bude průběžně aktualizován podle potřeb projektu a zpětné vazby od komunity.