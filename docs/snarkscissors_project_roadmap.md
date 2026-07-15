# SnarkScissors – Project Improvements Roadmap

## Purpose
- Map the next iterations required to move from the current player-hosted prototype toward a resilient online experience.
- Align design, code, and infrastructure priorities with the ambitions outlined in `snarkscissors_gdd.md` and `snarkscissors_tech_study.md`.
- Highlight decision points around multiplayer hosting, including when to introduce a classic server-client backbone.

## Snapshot: Where We Are
- Core loop and UI live in `GameScene.tscn` / `MainMenu.tscn` with local hosting logic in `scripts/`.
- Multiplayer currently assumes a **player-hosted session** (the host instance acts as server/authority).
- Documentation covers gameplay vision and technical feasibility, but we lack sequencing for delivery, backend ownership, and live-ops tooling.

## Roadmap Overview
| Phase | Target Window | Focus | Key Deliverables |
| --- | --- | --- | --- |
| **Stabilise** | Weeks 0‑4 | Lock the MVP experience, smoke-test player hosting | Deterministic RPS resolution, lobby UX polish, networking smoke tests |
| **Harden** | Weeks 4‑10 | Improve resilience, instrument telemetry, prep authoritative flow | Host migration fallback, rollback-friendly state sync, elastic metrics |
| **Scale** | Weeks 10+ | Introduce dedicated server tier + live-service loops | Headless server build, matchmaking queue, session persistence, ops playbooks |

## Phase Details

### 1. Stabilise (Prototype → Closed Alpha)
- **Gameplay polish:** Finalise round flow, tie-break rules, and HUD feedback; verify animations/UI on 16:9 and 21:9 layouts.
- **Player-hosted networking:** Audit `NetworkManager` RPC usage for consistency; ensure inputs are validated and late joins gracefully rejected.
- **Testing cadence:** Script headless smoke runs (`godot --headless --path . --run`); capture manual playtest footage for regression tracking.
- **Docs & tooling:** Update README onboarding, add quickstart for local hosting, log open questions in `docs/snarkscissors_gdd.md`.

### 2. Harden (Closed Alpha → Beta)
- **Session reliability:** Implement host migration or reconnection timeout logic; add keep-alive pings and clear disconnect UX.
- **Security & fairness:** Move sensitive resolution logic server-side where possible (authoritative round evaluation); add anti-spam throttles.
- **Observability:** Instrument lightweight telemetry (match IDs, latency, disconnect reasons) and surface in a developer dashboard or logs.
- **Content pipeline:** Automate asset import checks, define animation naming conventions, and document the pipeline alongside `snarkscissors_ai_pipeline.md`.

### 3. Scale (Beta → Live)
- **Dedicated server tier:** Stand up a headless Godot build (or alternative like Nakama) to act as authoritative match coordinator; separate repo/deployment scripts.
- **Matchmaking & persistence:** Implement queueing, ELO tracking, and cloud persistence for player profiles; plan for GDPR-compliant storage.
- **Live ops:** Build release checklist, monitoring alerts, and rollback procedures; schedule seasonal content drops aligned with Battle Hall ambitions.
- **Platform integration:** Integrate Steam backend services (lobbies, achievements) and ensure cross-platform compatibility for future web/mobile clients.

## Networking Strategy: Player Host vs Classic Server-Client

### Short-Term: Player-Hosted Sessions
- **Rationale:** Minimal infrastructure, rapid iteration, aligns with current prototype.
- **Action Items:**
  - Formalise host responsibilities (authoritative round resolution, lobby ownership).
  - Add NAT traversal guidance (port forwarding, relay options) to player-facing docs.
  - Implement host-side sanity checks (input validation, flood protection).

### Mid-Term: Dedicated Relay / Authoritative Server
- **Trigger Conditions:** Match sizes beyond 1v1, high disconnect rates, need for ranked integrity, or platform compliance (Steam Deck, consoles).
- **Action Items:**
  - Prototype a headless Godot server scene that handles matchmaking, state replication, and replay storage.
  - Evaluate third-party backends (Nakama, Godot Multiplayer Relay, custom Node.js) for persistence, analytics, and moderation tooling.
  - Define communication contract (RPC schema, authentication tokens) and isolate netcode from UI logic for reuse across clients.
  - Plan deployment pipeline (container image, CI export command, staging environment) and cost envelope for always-on servers.

### Long-Term: Hybrid Model
- Combine dedicated regional servers for ranked/battle hall modes with peer-hosted private matches.
- Offer relay fallback for P2P when hosts fail NAT traversal.
- Build admin tooling to monitor sessions, ban offenders, and simulate load before seasonal events.

## Dependencies & Risks
- **Team bandwidth:** Solo/indie constraints demand automation (CI exports, linting) to maintain velocity.
- **Networking complexity:** Transitioning from player-hosted to authoritative requires reworking gameplay code to be deterministic and server-trust-first.
- **Cost management:** Dedicated servers introduce recurring costs—budget needs to be locked before committing to always-on infrastructure.
- **Compliance:** Storing user data (profiles, match history) brings GDPR/CCPA obligations; plan legal review early.

## Next Steps
1. Add short throw, impact, and result animations on top of the refreshed menu, lobby, arena, and functional audio/display settings overlay.
2. Expand the audio pass with match-intensity music transitions and review the unused prepared effects against future gestures and cosmetics.
3. Run an external-network friend test beyond the automated localhost ENet smoke check and document NAT/port-forwarding friction.
4. Kick off the headless authoritative server spike, recording findings in `docs/snarkscissors_tech_study.md` and updating NetworkManager assumptions.
5. Define success metrics (latency thresholds, crash-free sessions, ready-check timing) to govern phase transitions and revisit the roadmap quarterly.
