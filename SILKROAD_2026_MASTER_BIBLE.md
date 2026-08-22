# SILKROAD 2026 MASTER BIBLE

**Phase 10.3 — Master Design Vision for the Silkroad 2026 Project**

This document is the single source of truth for the art, camera, combat presentation, HUD, lighting, audio, and production standards of the Silkroad 2026 project. It is a **design specification only**. It does not modify code, scenes, gameplay, networking, combat logic, or server code.

## How to read this document

Every claim about the project is grounded in the actual repository (`/workspace`, branch `master`). The document separates three layers:

| Layer | Meaning |
|---|---|
| **CURRENT REALITY** | What the repository actually contains today, verified against source files |
| **TARGET VISION** | What Silkroad 2026 must look, feel, and play like |
| **IMPLEMENTATION ROADMAP** | Strict, phased steps toward the vision |

System status vocabulary used throughout:

- **EXISTS NOW** — implemented and working in the repository today.
- **PARTIALLY IMPLEMENTED** — real foundation exists, but incomplete or not wired end-to-end.
- **NOT IMPLEMENTED** — absent from the repository.
- **FUTURE TARGET** — explicitly planned future work; not to be built in this phase.

Repository anchors referenced constantly below:

- Client: `MobileClient/` — Godot 4.4 (`gl_compatibility`), GDScript.
  - `main.gd` (state machine + offline demo boot), `boot.gd` (threaded preload of 5 GLBs, `UI_SCALE := 2.5`), `sro_protocol.gd` / `blowfish.gd` (packet layer), `player_controller.gd` (`MobilePlayer`, SpringArm camera, FOV 58), `mobile_hud.gd` (`MobileHUD`), `starter_world.gd` (`StarterWorld`, procedural world + offline combat loop), `character_select.gd` (`CharacterSelect`), `skill_system.gd` (2 builds, 6 skills), `skill_tree_ui.gd`, `inventory_ui.gd`, `monster_mob.gd` (`MonsterMob`, procedural Mangyang), `combat_vfx.gd` (`CombatVFX`), `floating_damage.gd`, `drop_item.gd` (`DropItem3D`), `minimap.gd` (`MinimapView`), `virtual_joystick.gd` (`VirtualJoystick`).
  - Phase 10.2 visual asset pipeline: `visual_asset_loader.gd` (`VisualAssetLoader`), `character_visual_adapter.gd` (`CharacterVisualAdapter`), `monster_visual_adapter.gd` (`MonsterVisualAdapter`), `humanoid_model.gd` (`HumanoidModel`), `animal_mob_model.gd` (`AnimalMobModel`), `asset_loader.gd` (facade), `assets/visual_asset_manifest.json` (5 legacy entries).
- Server: C# solution `SilkroadProject.sln`.
  - `GatewayServer/` (login, patch, launcher, shard list), `SR_GameServer/` (`SRGame`, `GObj`/`GObjChar`/`GObjMob`/`GObjNPC`/`GObjItem`, `Formula`, `PacketProcessor`, `GameWorld/AIManager` + `GObjUtils` + NavMesh `JmxNavmesh`, `Services/UniqueID`, `SQLTableMapping`), `SCommon/` (`TCPServer`, `Blowfish`, `Packet`, `MSSQL`, `Opcode`), `SCore/` (C++ support library).
- Protocol anchors: `0x5000`/`0x9000` handshake, `0x2001` identity, `0x6102`/`0xA102` gateway login, `0x6103`/`0xA103` agent login, `0x7007`/`0xB007` character screen, `0x7001`/`0xB001` select, `0x3012` enter world, `0x3015`/`0x3016`/`0x3019` spawn/despawn, `0xB021` movement, `0x7045`/`0xB045` select object, `0x7074`/`0xB074` action, `0x7099`/`0xB099` pickup, `0x7034`/`0xB034` inventory, `0x304D` drop item.

---

# PART A — THE VISION

---

# 1. EXECUTIVE VISION

## 1.1 What a Silkroad player must recognize

A Silkroad player stepping into Silkroad 2026 must instantly recognize three things:

1. **The world is the ancient trade route.** The design identity is built on the Silkroad: Eastern cities with tiered eaves and moon gates, Central Asian desert trade roads, walled oases, caravanserai, stone markets, mountain passes, and the sense of a vast land connected by one road. This is not a generic fantasy map.
2. **The character is a martial-civilization hero.** Player characters read as East Asian robes, scholar-warrior silhouettes, spears, talismans, and layered regalia — not generic fantasy leather-and-chain.
3. **The signature loop is present.** The trader-hunter-thief triad, level-based mastery builds, physical/magical balance, and party-scale monster encounters remain the heart of the game loop.

## 1.2 What feels modern in 2026

- **Presentation quality**: semi-realistic PBR materials, physically-based lighting, depth-of-field-ready staging, readable damage feedback, weighty animation, modern camera work.
- **Mobile-first ergonomics**: one-thumb input, minimal occlusion of the world by UI, aggressive performance tiers for low/mid/high-end Android.
- **Live-service cleanliness**: an asset pipeline (manifest + loader + adapters) that allows content to be swapped without touching gameplay logic.

## 1.3 Project ambition

Silkroad 2026 is a **premium semi-realistic mobile MMORPG** that preserves the network architecture, gameplay formulas, and skill/stat contracts of the existing C# server and Godot client, and rebuilds the **presentation layer** to a professional 2026 standard. The visual identity is original and not a Silkroad Online clone; it is *inspired by* the historical Silkroad and delivered through original geometry, materials, and rigs.

## 1.4 Status vocabulary applied to the vision

- **EXISTS NOW**: the networking stack, the stat/formula core, movement, combat result handling, inventory/loot, the procedural world, the character select flow, the visual asset pipeline.
- **PARTIALLY IMPLEMENTED**: build/skill presentation (client-side only, no server skill casting), monster presentation, world composition, HUD readability, camera depth.
- **NOT IMPLEMENTED**: skill casting server path, trader/hunter/thief gameplay, authored world content, premium character and environment assets, audio, day/night, mobile quality tiers.
- **FUTURE TARGET**: the Golden Vertical Slice and everything it establishes.

---

# 2. DESIGN PILLARS

## 2.1 The eight non-negotiable pillars

These are the laws of the project. Any future feature, asset, or change must satisfy all of them. Anything failing them must not be integrated.

### P1 — The Silkroad world is the identity
Every region must read as a place on the historical trade route: Eastern walled cities, desert trade roads, oases, caravanserai, markets, mountain passes, and a Western counterpart. The world is the product. A zone that reads as "generic fantasy meadow" is a design failure regardless of its beauty.

### P2 — Semi-realistic premium presentation
The quality bar is a premium 2026 mobile MMORPG. Not low-poly, not cartoon, not cell-shaded. Materials, proportions, cloth behavior, and lighting must read as believable and cinematic. Prototype geometry is temporary scaffolding, never a destination.

### P3 — Gameplay logic is sacred
The networking stack (`sro_protocol.gd`, `blowfish.gd`), the state machine (`main.gd`), skill definitions and formulas (`skill_system.gd`), combat result handling (`starter_world.gd`, server `Action`), and inventory/loot behavior are locked contracts. Presentation layers must adapt to them, never the reverse. Protected contracts are recorded in `PHASE9_LOGIC_LOCK.md`.

### P4 — The player is physically present
The camera must make the player feel inside a large world, not orbiting a diorama. Player and enemy visibility, target lock, obstacle handling, and camera smoothing are core features, not polish.

### P5 — Combat reads through presentation only
Combat logic is unchanged. Presentation carries the weight: anticipation, impact, reaction, damage readability. On a phone screen the player must always understand what happened, who is targeting them, and how much they hit for — without particle spam.

### P6 — The HUD recedes; the world leads
UI exists to serve the world. No giant casual cards, no oversized generic buttons that hide gameplay, no unrelated celestial decorations on functional UI. Information hierarchy, transparency, density, and touch ergonomics are designed, not accumulated.

### P7 — One coherent asset standard
Every external asset is gated (Section 19) and every internal piece of visual content must look coherent beside future content. No random asset dumping, no low-poly placeholder simply because it is free. Coherence is a quality gate, not a hope.

### P8 — Migration is phased and never regressive
Visual migration happens in strict phases (Section 17), each with a goal, files, assets, non-negotiable constraints, success criteria, and regression risks. The first real implementation is a single Golden Vertical Slice (Section 18) that establishes the quality standard for all future production.

## 2.2 What must never change

- Packet parsing/serialization, the security handshake, opcodes.
- The login/character/world state machine.
- Skill ids, mana/cooldown/progression formulas, damage resolution.
- Combat result handling, EXP, gold, inventory, loot.
- Server `Action`/`PickupItem`/`SelectGObj` behaviors and their packet contracts.
- CI artifact contracts.

---

# 3. EASTERN CIVILIZATION IDENTITY

## 3.1 Position

The East is the anchor civilization: a walled, river-and-mountain realm of formal architecture, scholars, martial artists, and ritual order. It sets the premium standard every other civilization is measured against.

## 3.2 Architecture language

- **Cities**: walled settlements with crenellated perimeter walls, drum/gate towers, tiered curved eaves, moon gates, ceremonial plazas, stone bridges over water, and axial main avenues that frame a palace or sanctum at the far end.
- **Structure grammar**: wooden-frame implied mass with stone bases, heavy curved tile roofs (dark slate with ridge ornaments), red-lacquered columns and brackets, paper-lantern warm glow at night, carved stone lions and guardian statues.
- **Palace/sanctum tier**: stepped stone platforms, marble balustrades, ceremonial gates, ornamental gables, and vertical stacking that reads as authority.
- **Vernacular tier**: courtyard houses, timber-and-tile two-story shopfronts along market streets, drying-lantern rows, stone-lined alleyways.

## 3.3 Roads, deserts, and the trade route

- The main road is a paved, wheel-worn trade artery (the existing ambientCG `PavingStones` PBR road in `starter_world.gd` is the correct material seed to build on, not to replace).
- Beyond the city gates: dust roads, stone-paved passes, and long desert stretches where the road visibly continues to the horizon — the player must always feel the road leads somewhere.
- Way markers, milestone stones, rest pavilions, and occasional roadside shrines give the road rhythm and scale.

## 3.4 Deserts and oases

- The desert is a major identity: sand dunes with believable rolling forms, wind-carved ripples, dust haze, dry grass tufts, and sparse rock outcrops.
- Oases are life: palm clusters, walled reservoirs, small gardens, caravanserai buildings where caravans rest.
- Climate language: high-key daylight, low-horizon heat haze, warm sand tones with cool shadow bias, and dramatic dusk.

## 3.5 Markets

- Dense stall composition: awnings, hanging goods, crates, stacked jars, lantern strings, stone paving, crowd-generating clusters of vendors (shops backed by the existing `RefShop`/NPC system).
- Markets must feel active even when empty of players: environmental animation (awning sway, dust, lantern flicker) carries life.

## 3.6 Temples and sanctums

- The existing celestial sanctum in `starter_world.gd` (sanctum dais, stepped altar, moon gate, floating crystal islands, ceremonial rings) is the temple grammar: elevated, symmetrical, luminous, and quiet.
- Temple identity: incense smoke, stone lanterns, engraved tablets, guardian statues, and a deliberate vertical axis.
- This is the language the celestial visual identity (Section 15.5) must be reconnected to.

## 3.7 Armor, weapons, and archetypes

- **Mage archetype (Celestial Mage)**: layered scholar robes with flowing over-sleeves, sash, talismanic ornaments, emissive chest crest, floating focus; weapon is a staff/talisman. Existing `humanoid_model.gd` mage regalia and `weapon_staff.glb` are the seed.
- **Warrior archetype (Dragon Warrior)**: padded armor over silk, pauldron/tassets, spear or polearm, dragon-motif sash; weapon is the spear. Existing spear build and `weapon_spear.glb` are the seed.
- **Material language**: lacquered wood, dark slate, aged brass and bronze, jade accents, silk and brocade, paper and bamboo. Gold is reserved for ritual/authority surfaces; it must not be sprayed everywhere.

## 3.8 Monster regions

- Near-city: foxes, wolves, boar, bandit men — low-tier, familiar.
- Deeper: spectral guardians and elemental beasts (the existing jade-and-amethyst Mangyang language in `animal_mob_model.gd`), shamanic spirits, armored war-beasts.
- High tiers: mythic beasts, guardian colossi, celestial dragons — rare, named, spawn-clear events.
- Every region's monster palette must match the region's material language; a jade spectral beast belongs in the sanctum mountains, not a farm field.

## 3.9 Color and material language (East)

Midnight indigo, jade teal, ceremonial gold, stone grey, ink black, paper white, silk red. Saturation is concentrated in ritual objects and enemy accents, not in base materials. This palette is the continuity anchor of the whole project.

---

# 4. WESTERN CIVILIZATION IDENTITY

## 4.1 Position

The West is the counterpart civilization of the trade route: a land of walled caravanserai, desert fortresses, bazaars, and pragmatic mercantile power. Where the East is formal and ritual, the West is layered, sun-beaten, and trade-hardened. The two civilizations meet on the trade road.

## 4.2 Architecture language

- **Cities**: mud-brick and stone fortresses with thick curtain walls, angular towers, crenellated parapets, arched gates, and stepped citadels.
- **Grammar**: flat roofs and domes, pointed and horseshoe arches, perforated lattice screens, deep shade loggias, courtyard caravanserai with a central well.
- **Market tier**: covered bazaar streets with arched vaults, hanging textiles, spice stalls, carpet displays — dense, colorful, tactile.
- **Caravanserai**: the emblematic structure — a fortified rectangle with a single gate, stable arcades around a courtyard, the place where caravans stop. It is the Western counterpart to the Eastern sanctum.

## 4.3 Material and color language (West)

Sun-baked ochre, sandstone, dusty rose, aged bronze, indigo trade-dye textiles, camel and leather tones. Light is hotter and lower-keyed than the East; shadow is deep and blue-biased. The palette must stay inside the master palette (P7) while reading clearly distinct from the East.

## 4.4 Weapons and archetypes

- Blade-heavy archetypes: curved sabers, scimitars, heavy hammers — a pragmatic, weapon-first silhouette versus the Eastern robe-and-polearm language.
- Armor: mail and plate over padded cloth, layered scarves, bazaar leathers.
- Monster language: desert predators, dust elementals, brigand camps, and eventually a caravan-raid threat layer.

## 4.5 Relationship to the East

The West exists so the trade route has two poles. The road, the caravans, and the desert between them are where the signature gameplay (trade, escort, ambush — the trader/hunter/thief triad) lives. Neither civilization is decorative; each is a full production region.

---

# 5. WORLD REGIONS AND BIOMES

## 5.1 Target world layout

A contiguous world stitched by one main road:

1. **Eastern capital** (walled city, palace axis, sanctum quarter) — the first-playable cradle.
2. **Eastern farmland and river valley** (villages, bridges, low monsters).
3. **Mountain pass** (paved switchbacks, guard posts, high-tier guardians).
4. **Desert trade road** (long open stretches, way stations, ambush points).
5. **Oasis cluster** (caravanserai, palm gardens, trade hub).
6. **Western fortress/bazaar** (secondary civilization hub).
7. **Frontier regions** (future: snow passes, lake country, sealed zones).

## 5.2 Current reality

`starter_world.gd` builds a single procedural zone with houses, trees, lanterns, a gate, a bridge, a market cluster, a celestial sanctum, water, and the PBR road. It is a **single showcase node**, not a region system. There is no region streaming, no region metadata beyond the server's `Formula` sector math (`REGION_HEIGHT`/`REGION_WIDTH` 192, `X_START_SECTOR`/`Z_START_SECTOR` 46), and no authored geography.

## 5.3 Migration direction

Keep `StarterWorld` as the *cradle* (the Golden Vertical Slice zone, Section 18). Introduce a `RegionInstance` concept (FUTURE TARGET) that can host authored geometry per server region, driven by `RefRegion` data the server already loads. The road must remain the connective spine in every region.

---

# 6. CHARACTER ARCHETYPES AND IDENTITY

## 6.1 Current reality

- Two builds exist client-side in `skill_system.gd`: **Wizard** (Celestial Mage) and **Spear** (Dragon Warrior), each with 3 skills:
  - Wizard: `arcane_bolt` (1.35x, 12 mana, 0.9s cd, cyan), `frost_nova` (2.1x, 30 mana, 4.5s cd, ice-blue), `meteor_lance` (3.4x, 52 mana, 7.0s cd, amber).
  - Spear: `piercing_thrust` (1.45x, 8 mana, 0.8s cd, gold), `whirlwind_sweep` (2.25x, 24 mana, 3.5s cd, pale-gold), `dragon_impale` (3.6x, 44 mana, 6.0s cd, ember-red).
  - Base mana 100; stats driven by `CharacterSelect` selection and the `MobilePlayer`/server `GObjChar` stat fields (STR/INT, physical/magical attack ranges, defense, hit/parry, block, crit).
- `character_select.gd` exposes `MODEL_IDS [1907, 1908, 1473]`, `WEAPON_IDS [3630, 3631, 3632]`, `OUTFIT_IDS [1035, 1036, 1037]` with race/weapon/build/outfit selectors and a scale slider. These must match server `_RefCharGen` (verified flow in `SR_GameServer/PacketProcessor.cs` `case 1` create).
- Server `GObjChar` already models the full stat surface and `_trijob` (Trader/Hunter/Thief levels), and `_Char` SQL maps `TraderLvl/HunterLvl/ThiefLvl` — the triad contract **EXISTS NOW as data**, gameplay is FUTURE TARGET.

## 6.2 Target vision

Archetypes are defined by **silhouette, material, and combat posture**, not by stat numbers. The Celestial Mage reads as scholar-robed ranged caster; the Dragon Warrior reads as armored polearm melee. Future archetypes (Western saber, bowman, healer) must fit the pillar rules and the civilization they belong to.

## 6.3 Migration direction

The build/stat/skill data model is correct and preserved. The visual gap is that `humanoid_model.gd` builds the character from primitives. The Golden Vertical Slice replaces the player character presentation with a premium rig (Section 18) while the adapter layer (`character_visual_adapter.gd`) keeps weapon sockets and attack-origin contracts intact.

---

# 7. MONSTERS AND ENCOUNTER DESIGN

## 7.1 Current reality

- Client `monster_mob.gd` (`MonsterMob`, Area3D) presents the procedural **Mangyang** with rarity (normal/champion/giant/unique), an AI phase state machine (idle/aggro/attack), a target ring, and a health bar.
- Server `GObjMob` implements rarity multipliers (`Champion` 10x HP / 2x stats, `Giant` and `Unique` 20x / 5x / 4x), nest/hive spawning in `AIManager`, and `AttackType`.
- Server `Action` (`0x7074`) resolves a flat physical hit (`Max(1, TotalMinPhyAtk)`) and returns `damage`, `hp`, `dead` in `0xB074`. Server skills (`RefSkill`) are loaded but **not used for casting** — NOT IMPLEMENTED.
- Phase 10.2 `monster_visual_adapter.gd` + `animal_mob_model.gd` present spectral jade/amethyst guardians and can attach a manifest scene.

## 7.2 Target vision

- **Monster language per region** (Section 3.8): every monster is drawn from its region's material palette.
- **Readability rules**: distinct silhouette, clear aggro state (posture + eye color, not a label), visible target ring for the active target only, and a health bar that appears on selection or damage, not permanently.
- **Weight**: hit reactions, brief anticipation before big attacks, and telegraphed AOEs. Encounter presentation must not spam particles.

## 7.3 Migration direction

The rarity/AI data model is preserved. Presentation work (FUTURE TARGET, Section 18): replace procedural Mangyang geometry in the showcase with premium rigged monsters driven through `monster_visual_adapter.gd`, keep `MonsterMob`'s AI/target/health behavior untouched.

---

# 8. ECONOMY, TRADE, AND CARAVANS

## 8.1 Current reality

- Gold, inventory, and shop systems **EXIST NOW**: server `GObjChar.OperateInventory` (move/drop/split/merge/equip/unequip via `0x7034`), `UpdateGold`, shop buy/sell (`0x7046`/`0x704B`, backed by `RefShop`), item pickup (`0x7099`), drop item (`0x304D`), and the `_Items`/`_Inventory` SQL mapping with 45 inventory slots (13 equip + 32 bag).
- The trader/hunter/thief triad is **NOT IMPLEMENTED as gameplay**; only the data fields exist (`_Char.TraderLvl/HunterLvl/ThiefLvl`, `GObjChar.m_triJob`).

## 8.2 Target vision

The trade loop is the signature: players move goods along the road, escort caravans, and are exposed to hunter/brigand interception. Gold is the reward of the road. This is FUTURE TARGET; the current systems already provide the currency and inventory substrate it needs.

## 8.3 Migration direction

Do not build trade gameplay in the visual phase. Preserve gold/inventory/shop contracts. When the triad is built (future), it must use the existing `0x7034`/gold/pickup machinery and the region/road architecture from Section 5.

---

# 9. CONTENT AND PROGRESSION TARGETS

## 9.1 Naming

The project currently uses serviceable working names (`Celestial Mage`, `Dragon Warrior`, `Mangyang`). Target: diegetic East/West naming consistent with the civilization language, applied to regions, monsters, skills, and items. Naming is a FUTURE TARGET sweep, coordinated with content so nothing ships with conflicting identities.

## 9.2 Progression

- **EXISTS NOW**: level, EXP (`ExpOffset`/`SExpOffset`), skill points, stat points, mastery rows (`_CharSkillMastery`), skill list (`_CharSkill`), HP/MP, gold.
- **EXISTS NOW**: `RefLevel` and `RefSkill` reference tables loaded server-side; client `skill_system.gd` computes damage multipliers per rank.
- **PARTIALLY IMPLEMENTED**: client skill tree UI (`skill_tree_ui.gd`) exists; server skill casting/validation is NOT IMPLEMENTED.
- **FUTURE TARGET**: server-authoritative skill casting via `0x7074` with damage/cooldown validation, mastery-gated skill unlock parity between client and server.

## 9.3 Presentation of progression

Progression UI must be dense, readable, and diegetic (Section 12): level/EXP is a compact read, mastery is a focused tree, not a screen of generic fantasy icons. Any new icons must pass the asset gate (Section 19) and the quality gate (Section 20).

---

# PART B — PRESENTATION TARGETS

---

# 10. CAMERA AND PLAYER PRESENCE

## 10.1 Current reality

`player_controller.gd` (`MobilePlayer`, CharacterBody3D) drives a `SpringArm3D` third-person rig at FOV 58, with virtual joystick input and `get_attack_style()`/`get_attack_origin()` (a hard-coded offset) feeding combat. There is no zoom, no target lock, no explicit obstacle handling beyond the spring arm's native collision, and no sensitivity/damping tuning.

## 10.2 Target vision

The player must feel physically present inside a large MMORPG world.

- **Exploration camera**: shoulder-height third person, slightly behind and above the character; a subtle default offset that keeps the silhouette and destination visible. Default pitch low enough to feel grounded, high enough to see the road ahead.
- **Combat camera**: on engagement, a short, smooth pull-back widens context; on target lock, the camera re-centers the target and the player in frame (both visible). No jarring snaps; all transitions are time-damped.
- **Target lock**: a soft lock (direction-sensitive) that keeps the current target framed near a screen anchor point; manual re-acquire via the existing `starter_world.gd` auto-acquire logic (currently wizard 16.0 / spear 4.6 range) with a tap-to-override.
- **Smoothing**: exponential damping for position and rotation; decoupled look and move latencies; optional camera-shake budget reserved for impacts (Section 11), kept small.
- **Zoom**: a single pinch-zoom band (e.g. 2.5 to 6.0 world units) that persists per profile; zoom is a player comfort tool, not a tactical exploit.
- **Obstacle handling**: the camera must never leave the player invisible; nearest-surface push-out with soft blend-back, walls fade or occlude, and the character remains readable through foliage (transparency/outline affordance on occluders, not world transparency).
- **Player visibility**: the character is always on-screen during normal play; idle breathing, ambient cloth sway, and a soft ground-contact shadow keep the body present even while standing.
- **Enemy visibility**: the active target ring exists (Section 7.2); off-screen aggro indicators (screen-edge chevron) are FUTURE TARGET but specified here so the camera and HUD reserve the space.

## 10.3 Constraints

- Camera work must not touch `MobilePlayer` physics, movement packets, or `get_attack_origin` contracts; it lives in a camera-controller layer that reads the existing rig.

---

# 11. COMBAT PRESENTATION

Combat **logic is unchanged** (Section 2.2). This section defines only the presentation layer wrapping the existing `combat_vfx.gd` calls and `starter_world.gd` combat flow.

## 11.1 Presentation language

- **Anticipation**: a short, readable wind-up before each strike/skill (posture + weapon pull-back + a focused energy gather). The existing `CombatVFX.spawn_skill_vfx`/`spawn_magic_projectile` calls fire on resolution; anticipation precedes them without delaying damage.
- **Attack animation**: one clear attack motion per build — spear: linear thrust/sweep; wizard: staff cast with talisman flash. Motion is directional toward the target, with follow-through that sells weight.
- **Weapon trails**: thin, additive, edge-defined trails during the active frames only; spear gold, staff cyan. Trails must not persist after resolution.
- **Hit effects**: compact impact burst at the contact point oriented to the surface; a single bright core with a small, short-lived ring. One effect, not a fireworks spawn.
- **Impact feedback**: screen-space kill of the moment — 2-3 frames of camera micro-punch scaled to damage tier, plus a timed hit-stop (freeze) of at most 50-80 ms on heavy hits.
- **Hit reactions**: enemies flinch along the attack direction; heavy skills knock back slightly; reactions are animation-state-based and must not desync `MonsterMob` AI or server HP state.
- **Critical hit feedback**: distinct but restrained — brighter core, one short vertical flash, and the damage number enlarged once (Section 11.3). No confetti.
- **Skill VFX**: skill-specific language mapped to existing ids (`arcane_bolt` cyan bolt, `frost_nova` ice ring, `meteor_lance` falling amber star, `piercing_thrust` gold line, `whirlwind_sweep` circular sweep, `dragon_impale` ember lance). Each skill has one signature effect plus minimal supporting layers.
- **Enemy targeting**: the ring/outline is the single source of "this is your target"; everything else (VFX, damage) points at it.
- **Damage readability**: numbers are the primary read — short rise, slight scale pulse on crit, quick fade; color coded (physical white/gold, magic cyan, crit amber). Never more than a handful on screen.

## 11.2 Anti-patterns

No random particle spam. No persistent screen shake. No overlapping opaque VFX that hide the world or the enemy silhouette. No "flashy every second" — visual budget concentrates on the active action and its resolution.

## 11.3 Readability on mobile

- Damage numbers sized for a phone (not a monitor), with outlines for contrast against any background.
- Hit-stop and camera punch are scaled by device tier (Section 13) so low-end devices skip the micro-effects, never the hit result.

---

# 12. UI / HUD DESIGN DIRECTION

## 12.1 Current reality (honest evaluation)

`MobileHUD` and `CharacterSelect` currently use dark-stone panels, gold filigree borders, and celestial labels — a functional premium theme. The critical problems are the ones Section 15.5/15.6 names: the celestial gold filigree is applied to **functional** HUD chrome (where it reads as decorative noise), `UI_SCALE := 2.5` inflates every control, and the layout competes with the world instead of receding behind it.

## 12.2 Target vision — a premium modern mobile MMORPG HUD

- **Information hierarchy** (first to last): your character state (HP/MP/EXP), your target, your active combat state (skills/cooldowns), world awareness (minimap, aggro), social (chat/party), meta (inventory/menu).
- **HP/MP/EXP**: one compact top-left cluster; HP is the largest single read, MP secondary, EXP a thin bar; values as compact text. High contrast on all backgrounds; no animated flourishes.
- **Target frame**: small frame above the world near the target (or top-center on lock) with name, level, HP bar, and aggro state — appears on selection, never persistent.
- **Skill hotbar**: bottom-right, 3-6 slots sized for thumb reach; cooldown as a crisp radial sweep on the icon plus a single digit; active build highlighted. Not a generic fantasy skill-grid.
- **Joystick**: bottom-left floating thumbstick; the existing `virtual_joystick.gd` behavior is preserved; visual is a subtle, semi-transparent base + thumb, not a giant pad.
- **Action buttons**: only what the moment needs (attack, skill, pickup) — compact, contextual, placed within thumb arc; auto-hide when not relevant.
- **Minimap**: top-right compact square; the existing `minimap.gd` landmarks/player-dot model is preserved; north-up by default with subtle rotation.
- **Quest tracking**: right edge compact tracker (FUTURE TARGET), 2-3 lines max, tappable to navigate.
- **Chat**: collapsible bottom-left ribbon above the joystick, hidden by default, one-tap expand; semi-transparent scrim.
- **Inventory access**: one small button toggling `inventory_ui.gd`; the panel is a dense grid, not full-screen cards.
- **Menus**: settings/profile accessible from a top-corner glyph; menus are compact overlays with the world still faintly visible behind.

## 12.3 Design rules

- **Transparency**: HUD chrome is at most ~40-60% fill with soft outlines; the world is never fully occluded.
- **Density**: information per pixel is high; spacing is deliberate, not ballooned by `UI_SCALE`.
- **Touch ergonomics**: all thumb controls inside the reach zone; hotbar/action buttons sized to the 44px+ guideline scaled to device DPI, not to `UI_SCALE := 2.5`.
- **Combat readability**: when in combat, HP/MP, target frame, and hotbar are the only strongly-lit elements; everything else dims.
- **No generic fantasy labels**: every label, icon, and panel must pass the civilization identity (Section 3/4) or be invisible; functional chrome uses neutral stone/ink, and celestial gold is reserved for ritual surfaces (sanctum UI moments), not everyday HUD.

## 12.4 Migration direction

`MobileHUD` signals and function names are preserved (locked contracts). The change is a visual/scale pass over `mobile_hud.gd` and `character_select.gd` controls (FUTURE TARGET, coordinated with the Golden Vertical Slice), never a re-skin that breaks bindings.

---

# 13. LIGHTING AND RENDERING TARGET

## 13.1 Current reality

The client uses Godot 4.4 `gl_compatibility`, a `ProceduralSkyMaterial` sky, directional key/rim lights and a fill omni (seen in `character_select.gd` setup), PBR `StandardMaterial3D` surfaces, and the ambientCG PBR road. Lighting is dynamic and un-baked; there are no baked lightmaps, no fog rig, no color grading, no day/night, and no quality tiers.

## 13.2 Target strategy (practical, Godot 4 mobile)

- **PBR materials**: keep `StandardMaterial3D` as the single material path; use roughness/metalness/specular maps from the ambientCG class of sources; cap texture budgets per tier (Section 13.4).
- **Baked lighting**: for static world geometry (buildings, terrain, static props), bake lightmaps per region into textures; dynamic objects (characters, monsters, dropped loot) use lit/unlit dynamic passes. Baking is the mobile perf lever — it must be introduced early in region production.
- **Dynamic character lighting**: characters get key+rim from the region's direction light plus a cheap per-character fill; emissive accents (talismans, eyes, skill cores) carry identity without expensive lights.
- **Shadows**: one directional shadow (1024/2048 by tier) covering the player area; static geometry can use baked contact/ambient occlusion; no shadow-casting dynamic lights in the hot path.
- **Ambient lighting**: baked irradiance from lightmaps; sky contribution from the procedural sky is acceptable as the ambient base at the Golden Slice scale.
- **Fog**: distance fog is the main depth and mood tool (dust haze in the desert, incense in temples); fog color keyed per region to the palette (Section 3.9/4.3). A subtle height fog keeps distant terrain silhouettes readable.
- **Color grading**: one global grade (contrast + slight teal/amber split per region type) applied via a cheap post pass or per-material response; avoid full-screen expensive effects on low tiers.
- **Day/night readiness**: author light states as a small LUT/timing table (day/dusk/night) driving directional key color/intensity, fog, emissive boost, and lantern flicker. FUTURE TARGET; the Golden Slice ships a fixed high-quality day state with dusk-ready data.
- **Performance**: object culling (distance + frustum), mesh LOD levels (3 per hero asset), baked lightmaps, merged static geometry, and a particle budget enforced per tier.

## 13.3 Quality tiers (Android)

| Tier | Device class | Directional shadows | Lightmaps | Dynamic lights | Post | Texture budget | Particles |
|---|---|---|---|---|---|---|---|
| **Low** | 2-3 GB RAM, mid-2018 GPU | 1024, off for others | Baked, low res | Player area only | None (or flat grade) | 1024 hero / 512 world | Halved, no hit-stop micro |
| **Mid** | 4-6 GB RAM, 2020+ GPU | 2048 | Baked, standard | +1 local fill | LUT grade | 1024 hero / 1024 world | Standard |
| **High** | 8+ GB RAM, 2022+ GPU | 2048 + soft shadows | Baked + probe accents | + rim dynamic | LUT + subtle bloom/vignette | 2048 hero / 1024 world | Full |

The tier is selected at boot from device profile and persisted; the same scene graph runs on all tiers — only budgets and toggles change. This guarantees the Golden Vertical Slice is never a "high-end only" demo.

## 13.4 Constraints

Lighting work must not alter gameplay scenes' node contracts; it is introduced through the region/scene presentation layer and the light rig used by `starter_world.gd`/`character_select.gd` environments.

---

# 14. AUDIO DIRECTION

Audio is **future work** (not implemented). This section fixes the philosophy so production knows what sounds like what.

- **City ambience**: layered crowd murmur, distant hawkers, lantern creak, water features, temple bells at intervals; low-freq city bed with sparse high accents.
- **Desert wind**: continuous filtered wind, sand hiss, occasional gust swells; slow LFO — never white-noise shout.
- **Forests**: canopy rustle, bird chirps panned by time-of-day, stream/brook beds, branch snaps underfoot.
- **Monsters**: per-family vocal identity (fox yips, spectral howls, guardian drones); aggro = short alert call; death = breath out, not explosion.
- **Weapons**: material-based — spear whoosh + cloth layer, staff hum + talisman chime; swing pitch scales with attack size.
- **Impacts**: weight-scaled thuds (leather/wood/stone response) with a single sharp transient; crit adds a short bright overtone, not more noise.
- **Skills**: each skill id gets one signature — `arcane_bolt` rising zap, `frost_nova` glass-ring, `meteor_lance` descending boom, `piercing_thrust` quick steel cut, `whirlwind_sweep` rotating sweep, `dragon_impale` ember roar. Skills never drown the hit feedback.
- **Marketplaces**: stall barker loops, coin and goods clutter, fabric rustle, animal calls; busy but never cacophonous.
- **Caravans**: creaking axles, bells on pack animals, hooves on road types, distant horn at way stations.

Principles: diegetic placement over abstract stingers; volume layering so the player always hears the *interaction* over the *ambience*; everything ducked under combat resolution; music reserved for cities/temples/triumph — silence is a feature on the open road.

---

# PART C — CURRENT REALITY, HONEST ASSESSMENT

---

# 15. WHAT THE CURRENT PROJECT GETS WRONG

For each problem: **CURRENT STATE**, **WHY IT FAILS THE SILKROAD 2026 VISION**, **MIGRATION DIRECTION**. All items are grounded in the actual repository.

## 15.1 Prototype appearance

- **CURRENT STATE**: `humanoid_model.gd` and `animal_mob_model.gd` build characters from primitives (capsules/cylinders/boxes) with procedural materials; `starter_world.gd` builds houses/trees/lanterns procedurally; the preloaded GLBs are `humanoid_wizard.glb`, `humanoid_spear.glb`, `monster_mangyang.glb`, `weapon_staff.glb`, `weapon_spear.glb`.
- **WHY IT FAILS**: primitives and procedural facades read as a prototype, not a product. The vision (P2) demands semi-realistic premium presentation; geometry built from capsules cannot achieve the proportions, silhouette complexity, or cloth/armor language the identity requires.
- **MIGRATION DIRECTION**: this is the accepted scaffolding, not a defect to mourn. The Golden Vertical Slice (Section 18) replaces the hero character, one weapon, and 1-2 monsters with premium rigs while `humanoid_model.gd`/`animal_mob_model.gd` and the adapters keep their contracts.

## 15.2 Procedural appearance

- **CURRENT STATE**: environment, water, sky, and road are procedural (`starter_world.gd` water shader, `ProceduralSkyMaterial`, ambientCG `PavingStones` road, procedural structures).
- **WHY IT FAILS**: procedural geometry is visually repetitive and reads as generated; premium worlds need authored silhouettes, bespoke rooflines, hand-placed density, and varied materials. Repetition is the enemy of a premium read.
- **MIGRATION DIRECTION**: keep the procedural systems as *fallback and test scaffolding* and as the source of the *layout logic* (market clusters, road spine, sanctum). Replace presentation with authored geometry per region over time, starting with the Golden Slice zone.

## 15.3 Low-poly appearance

- **CURRENT STATE**: geometry is uniformly low-detail and un-lodged; silhouettes are simple.
- **WHY IT FAILS**: low-poly is the single fastest tell of a prototype in 2026; the vision is explicit about NOT low-poly and NOT cartoon (P2).
- **MIGRATION DIRECTION**: the asset gate (Section 19) refuses low-poly and generic free packs outright; every hero asset ships 3 LODs (Section 13.2).

## 15.4 Generic fantasy identity

- **CURRENT STATE**: the *gameplay* systems are original, but several names and icon directions lean generic fantasy ("Celestial Mage", "Dragon Warrior", "Mangyang"); the celestial rebrand (Section 15.5) drifted toward abstract floating crystals rather than the Silkroad civilizations.
- **WHY IT FAILS**: generic fantasy dilutes the unique selling point — the Silkroad world itself (P1). If a player cannot tell this is a Silkroad game, the identity has failed.
- **MIGRATION DIRECTION**: naming sweep (Section 9.1) and re-grounding every visual motif in the Eastern/Western material language (Sections 3/4).

## 15.5 Celestial identity

- **CURRENT STATE**: Phase 9 rebrand introduced a "Mythical Celestial Asian" direction (midnight blue, jade teal, ceremonial gold, astral cyan, floating sanctum architecture, moon gates, suspended crystal islands) documented in `PHASE9_VISUAL_REBRAND.md`.
- **WHY IT FAILS**: taken to the extreme, "celestial" reads as floating-crystal fantasy (and risks contradicting the Silkroad identity). The gold filigree and crystal motifs are applied as a coating rather than as an architecture language, and it was partly justified by rejecting low-poly CC0 packs rather than by a coherent positive vision.
- **MIGRATION DIRECTION**: keep the *palette* (Section 3.9) and the sanctum grammar, but re-ground the identity in the Silkroad civilizations: sanctum architecture becomes temple architecture (Section 3.6), crystals become ritual/luminous accents, and the celestial register is reserved for high-tier content (dragons, guardians, sanctums), never everyday UI.

## 15.6 Oversized UI

- **CURRENT STATE**: `UI_SCALE := 2.5` is applied globally in `boot.gd` and `character_select.gd`; `character_select.gd` builds large option-button panels, bars, and a big stage; `mobile_hud.gd` chrome competes with the world.
- **WHY IT FAILS**: oversized UI hides the world, contradicts P6, and reads as casual-game rather than premium MMORPG. A `2.5` multiplier on every control is a blunt instrument that cannot produce good touch ergonomics by itself.
- **MIGRATION DIRECTION**: replace the blanket scale with per-control, DPI-aware sizing; verify thumb-reach zones on an actual phone profile; reserve the current scale only as an accessibility fallback (Section 12.3/12.4).

## 15.7 World composition

- **CURRENT STATE**: `starter_world.gd` composes a single procedural plaza (gate, bridge, market, sanctum, road, water) with no region structure, no authored geography, no vertical interest beyond the sanctum dais, and no long sightlines along the trade road.
- **WHY IT FAILS**: an MMORPG world is a *place* with scale and routes; a single plaza reads as a tech demo, not a world. The road must lead somewhere and each region must read as its own place (Section 5).
- **MIGRATION DIRECTION**: region-based world production (FUTURE TARGET) with the road as spine; the Golden Slice zone is the first authored region and must establish scale.

## 15.8 Environment density

- **CURRENT STATE**: the procedural zone has sparse, evenly spaced props; no clusters, no layering, no story-telling clutter.
- **WHY IT FAILS**: density sells believability. Empty, regular spacing reads as generated; real places have accumulation, decay, and rhythm (awning piles, market clutter, road-worn stones, shade pockets).
- **MIGRATION DIRECTION**: density budgets per prop class, hand-tuned clusters in authored regions, and environmental animation (Section 3.5) to keep spaces alive.

## 15.9 Character quality

- **CURRENT STATE**: characters are primitive-built with procedural materials; the adapter layer (`character_visual_adapter.gd`) already provides weapon sockets, animation map, and `get_attack_origin`.
- **WHY IT FAILS**: the player character is the most-seen object in the game; primitive geometry cannot carry the robe/armor identity, and silhouettes must distinguish archetypes at a glance (Section 6.2).
- **MIGRATION DIRECTION**: the Golden Vertical Slice replaces the hero with a premium rig and materials; the adapters and animation map are the integration point and must be preserved.

## 15.10 Visual hierarchy

- **CURRENT STATE**: everything is lit and saturated roughly equally; emissive accents (talismans, crystals, gold) are not budgeted, so nothing leads the eye.
- **WHY IT FAILS**: visual hierarchy is what makes premium games feel composed; without it the scene reads flat and noisy, and gameplay readability (target, hit, state) is lost.
- **MIGRATION DIRECTION**: an explicit read hierarchy per region (Section 13): focal architecture brightest, interactive elements emissive-graded, background recedes through fog/depth, and the player/target always the two brightest dynamic objects.

---

# 16. WHAT MUST BE PRESERVED

## 16.1 Server / networking (EXISTS NOW — protect first)

- `SCommon` packet, Blowfish, security-bytes, MSSQL, and opcode contracts (`sro_protocol.gd` mirrors these exactly; both sides of the handshake flow `0x5000/0x9000/0x2001/0x6102/0xA102/0x6103/0xA103`).
- The full agent flow: character screen/create/select, enter world, spawn/despawn (`0x3015/0x3016/0x3019`), movement (`0xB021`), select (`0x7045/0xB045`), action (`0x7074/0xB074`), pickup (`0x7099/0xB099`), inventory (`0x7034`), drop (`0x304D`), shop, chat, teleport.
- Server stat/formula core (`Formula.cs`, `GObjChar` stat surface, `GObjMob` rarity multipliers), navmesh (`JmxNavmesh`), AI spawning (`AIManager`), sight lists, and SQL mappings (`SQLTableMapping.cs`, `_Char`/`_Inventory`/`_Items`/`_CharSkillMastery`/`_CharSkill`).
- **Why**: this is the game's identity as a Silkroad-class network game; every visual change sits on top of it.

## 16.2 Gameplay (EXISTS NOW — protect)

- `skill_system.gd` build/skill definitions, mana/cooldown/damage formulas (wizard and spear trees, six skills).
- `main.gd` state machine and offline-demo boot.
- `starter_world.gd` combat/skill/EXP/inventory/loot handlers and the movement loop.
- `monster_mob.gd` AI phases, rarity, target ring, health bar.
- Gold/inventory/loot behavior in `GObjChar`/`GObjItem`.
- **Why**: these are locked contracts per P3 and `PHASE9_LOGIC_LOCK.md`; the presentation layers were deliberately built to adapt to them.

## 16.3 Visual architecture (EXISTS NOW — protect)

- The Phase 10.2 pipeline: `visual_asset_loader.gd` (manifest-driven `VisualAssetLoader` with `resolve_chain`/`resolve`/`instantiate`, `preload_assets`, shims), `assets/visual_asset_manifest.json`, `character_visual_adapter.gd` / `monster_visual_adapter.gd` (sockets, animation map, weapon attach, `get_attack_origin`), `humanoid_model.gd` / `animal_mob_model.gd` wrappers, `asset_loader.gd` facade.
- `combat_vfx.gd` public functions and skill-id mapping; `floating_damage.gd`; `drop_item.gd`; `minimap.gd`; `virtual_joystick.gd` behaviors.
- **Why**: the adapter/loader pattern is the seam that lets premium assets replace primitives without touching gameplay, networking, or scene contracts. It is the strategic asset of the whole visual migration.

## 16.4 Mobile infrastructure (EXISTS NOW — protect)

- The offline-demo mode that boots straight to `CharacterSelect`/`StarterWorld` — the fastest iteration loop and the demo surface for the Golden Vertical Slice.
- Threaded preload in `boot.gd` (5 GLBs) and the `gl_compatibility` renderer choice (broadest Android support).
- The C# server build, `.sln`, and the `SCore` native layer.
- **Why**: the demo loop and renderer choice are what make rapid, deterministic, mobile-verified iteration possible.

---

# PART D — IMPLEMENTATION ROADMAP

---

# 17. VISUAL MIGRATION ROADMAP

Strict phases. Do not do everything at once. Every phase preserves the contracts listed in Section 16 and passes the quality gate (Section 20) before it is accepted.

## Phase M0 — Golden Vertical Slice (first actual visual implementation)

- **GOAL**: one playable showcase proving the final quality direction end-to-end (Section 18).
- **FILES LIKELY INVOLVED**: `starter_world.gd` (zone placement only), `humanoid_model.gd` / `animal_mob_model.gd` (asset attachment through existing adapters), `character_visual_adapter.gd` / `monster_visual_adapter.gd` (sockets/weapon attach), `visual_asset_loader.gd` + `assets/visual_asset_manifest.json` (new manifest entries), `player_controller.gd` (camera smoothing/zoom in the camera layer only), `combat_vfx.gd` (presentation polish), new showcase assets.
- **ASSETS REQUIRED**: one premium player character rig, one premium weapon, one or two premium monsters, one small authored environment zone (with baked lighting, fog, density).
- **WHAT MUST NOT CHANGE**: skill definitions/formulas, combat resolution, movement packets, HUD bindings, adapters' public API, manifest format.
- **SUCCESS CRITERIA**: runs on low/mid/high Android tiers (Section 13.3) at target framerate; player+weapon+monster read premium; combat feedback readable; camera smooth; all existing gameplay still passes its checks.
- **REGRESSION RISKS**: adapter API drift, manifest parsing breakage, lighting budget overshoot, `get_attack_origin` misalignment.

## Phase M1 — Player character presentation

- **GOAL**: hero character premium rig across both builds (mage robes, warrior armor) with the weapon attach pipeline; archetype silhouettes final.
- **FILES**: adapters, loader/manifest, `humanoid_model.gd` integration, materials.
- **ASSETS**: rig + textures (2 archetypes, 3 LODs each).
- **WHAT MUST NOT CHANGE**: `get_attack_style`/`get_attack_origin`, animation map keys, build selectors.
- **SUCCESS**: both builds read as distinct premium archetypes; weapon swap correct; animation transitions clean.

## Phase M2 — Monster presentation

- **GOAL**: premium monster rigs replacing procedural Mangyang across rarities; regional monster language begins.
- **FILES**: `monster_visual_adapter.gd`, `animal_mob_model.gd` integration, `monster_mob.gd` untouched.
- **ASSETS**: 1-2 monster families, 3 LODs, animation set (idle/aggro/attack/hit/death).
- **WHAT MUST NOT CHANGE**: rarity multipliers, AI phases, target ring, health bar, HP handling.

## Phase M3 — Authored environment (first region)

- **GOAL**: replace the procedural zone with an authored Eastern cradle region (city gate, market, sanctum, road, river) with baked lighting, fog, and density.
- **FILES**: `starter_world.gd` layout/placement, new region scene, lighting rig.
- **ASSETS**: modular architecture kit, road/terrain materials, props.
- **WHAT MUST NOT CHANGE**: world layout logic used by gameplay (spawns, pathing), monster/player placement, road connectivity.

## Phase M4 — HUD rework

- **GOAL**: premium dense HUD per Section 12; remove blanket `UI_SCALE := 2.5`; introduce per-control sizing.
- **FILES**: `mobile_hud.gd`, `character_select.gd`, `inventory_ui.gd`, `skill_tree_ui.gd`, `virtual_joystick.gd` visuals.
- **WHAT MUST NOT CHANGE**: all signals, function names, bindings.
- **SUCCESS**: world-occluding UI gone; thumb ergonomics verified on-device; combat readability improved.

## Phase M5 — Presentation polish (camera/combat/VFX)

- **GOAL**: target lock, camera smoothing/zoom/obstacle handling (Section 10), combat presentation pass (Section 11).
- **FILES**: camera controller layer, `combat_vfx.gd` polish.
- **WHAT MUST NOT CHANGE**: combat logic, damage numbers contract, movement.

## Phase M6 — Second region + day/night + audio scaffold

- **GOAL**: Western/desert region, day/dusk/night LUT, audio philosophy scaffolding.
- **FILES**: new region, light state table, audio hooks.
- **ASSETS**: desert kit, West architecture kit, audio placeholders.

## Phase M7 — Server skill casting parity (gameplay, out of visual scope, listed for sequencing)

- **GOAL**: server-authoritative skill casting via `0x7074` matching `skill_system.gd` definitions; mastery gating.
- **WHAT MUST NOT CHANGE**: opcodes, skill ids, formulas.

---

# 18. GOLDEN VERTICAL SLICE

## 18.1 Definition

The first complete playable visual showcase. It proves the final quality direction using only a tightly scoped set:

- **One premium player character** (Celestial Mage or Dragon Warrior), fully rigged with the premium material treatment.
- **One premium weapon** (staff or spear), attached through `character_visual_adapter.gd` at the existing weapon socket.
- **One or two monsters** (one low-tier melee, optionally one spectral guardian), driven through `monster_visual_adapter.gd` with the premium monster treatment.
- **One small authored environment zone** (a slice of the Eastern cradle: road segment, gate or market edge, sanctum glimpse, river, skyline) with baked lighting, fog, and hand-placed density.
- **Modern camera**: smoothing, zoom, soft lock (Section 10).
- **Modern HUD section**: the HP/MP/EXP cluster, target frame, and skill hotbar in the premium dense style (Section 12) — a *section*, not a full reskin.
- **Movement, attack, hit feedback**: existing gameplay drive the new presentation — anticipation, impact, hit reaction, damage number (Section 11).

## 18.2 What the slice must prove

1. The final quality standard is achievable on mobile tiers (runs on low/mid/high per Section 13.3).
2. The adapter/loader pipeline cleanly swaps primitive scaffolds for premium assets **without touching gameplay, networking, or scene contracts**.
3. Combat presentation reads weighty, responsive, and readable on a phone (P5).
4. The camera makes the player feel physically present (P4).
5. The HUD recedes and the world leads (P6).
6. The slice looks coherent — as if one art director shipped it (P7).

## 18.3 Constraints

- Do **not** import dozens of unrelated assets first. If the slice cannot be made with the scoped set, the scope is wrong, not the asset count.
- The slice is the *quality standard*: every future phase (M1-M7) is measured against it.

---

# 19. ASSET ACQUISITION RULES

Every future external asset must be evaluated for:

- **Visual quality** — meets the semi-realistic premium bar (P2); screenshots and in-engine test, not storefront renders.
- **Art-direction match** — belongs to the Eastern or Western civilization language (Sections 3/4) or the celestial high-tier register; rejects generic fantasy.
- **Rig quality** — deformers, weighting, cloth/armor joints behave; no collapsing topology in motion.
- **Animation compatibility** — animation set covers idle/walk/run/attack/hit/death (and cast for casters) in the skeleton's native space.
- **Skeleton structure** — named bones map to the adapter's socket/animation map; retargeting cost is estimated before purchase.
- **Mobile optimization** — draw calls, material count, and vertex count fit the tier budget (Section 13.3).
- **Licensing** — CC0 or explicit commercial-use license with redistribution rights; no "non-commercial" or "attribution-only confusing" packs.
- **Commercial-use suitability** — usable in a shipped commercial mobile MMORPG, including in-app purchase and advertising contexts.
- **Texture quality** — resolution/format fits the tier texture budget; albedo/roughness/metalness/normal discipline; no baked-in lighting.

Every imported asset must be recorded with:

- **Source** (URL/repo) and **license** (exact terms).
- **Intended role** (hero character, weapon, monster family, region kit, prop).
- **Visual tier** (hero / secondary / ambient).
- **Polygon budget** (per LOD, per tier).
- **Texture budget** (resolutions per map, count).
- **Fallback plan** (what procedural/manifest scaffold it replaces, and the reverse if integration fails).

**No random asset dumping. No random low-poly assets simply because they are free.** Anything that fails the evaluation does not enter the repository, regardless of license or price.

---

# 20. SILKROAD 2026 QUALITY GATE

Final approval checklist. Before any future visual implementation, feature, or asset is accepted, it must pass all eight gates. **Anything failing must not be integrated.**

1. **Silkroad-recognizable**: Does it feel recognizably Silkroad-style (P1)? A region, monster, or item that reads as generic fantasy fails.
2. **Professional 2026**: Does it look like a professional 2026 MMORPG (P2)? Prototype, low-poly, or unpolished presentation fails.
3. **No prototype visuals**: Does it avoid prototype/low-poly visuals (P2, Section 15.3)?
4. **No generic fantasy**: Does it avoid generic fantasy identity (P1, Section 15.4)? Working names, motifs, and props are judged on this.
5. **Logic preserved**: Does it preserve existing gameplay logic (P3, Section 16)? Any contract touched without approval fails.
6. **Mobile-appropriate**: Is it technically appropriate for mobile (P2, Section 13.3)? Fails if it cannot run on the low tier at target framerate.
7. **Art-direction fit**: Does it fit the master art direction (P7, Sections 3/4)? Palette, material language, and civilization identity must align.
8. **Coherence with future content**: Would it look coherent beside future content (P7)? A one-off beautiful object that cannot sit next to the rest fails.

Gate verdicts are recorded per feature in the phase's success criteria (Section 17). The Golden Vertical Slice (Section 18) is the reference sample the gate is measured against.

---

## Document status

- **Phase**: 10.3 — analysis and design only. No assets added, no scenes modified, no HUD redesigned, no gameplay/network/combat/server code changed.
- **Single deliverable**: this file (`SILKROAD_2026_MASTER_BIBLE.md`), committed as `Phase 10.3: define Silkroad 2026 master vision`.
- **Next action**: wait for Phase 10.4 instruction before implementing Phase M0 (Golden Vertical Slice).
