# Phase 10 — External 3D Asset Pipeline

> Status: analysis and architecture only.
> This document audits the current visual architecture and specifies the migration plan for
> replacing the procedural visual layer with **premium semi-realistic external GLB/glTF
> assets** (modern East/West MMORPG direction). It does **not** modify gameplay, networking,
> combat, UI, `starter_world.gd`, or any existing `.gd` file. It does **not** add assets.
> The procedural systems are preserved as permanent fallbacks.

---

## Scope Guardrails

- **No existing `.gd` file is modified.**
- No gameplay, networking, combat, UI, or `starter_world.gd` changes.
- No new runtime assets are added (no trees/rocks/flowers/fences/generic props).
- Nothing is deleted (assets or commits).
- The objective is a **visual architecture** that lets external GLB/glTF rigs replace the
  procedural models over time — not more low-poly decoration.

---

## A. Current Visual Architecture

The runtime entry is `MobileClient/boot.tscn` → `boot.gd` (threaded preload) → `main.tscn`
→ `main.gd` → `CharacterSelect` → `StarterWorld`. Every visible entity is constructed
**at runtime in GDScript** from either (a) primitive `MeshInstance3D`s built in code, or
(b) self-generated GLB files whose geometry is also procedurally authored primitives.

```
boot.gd ──load_threaded_request──> assets/models/*.glb  (5 self-generated GLBs)
main.gd ──> CharacterSelect ──preview──> HumanoidModel (humanoid GLB + podium primitives)
         └─> StarterWorld
               ├── _build_environment/_build_city/_build_*   (primitives + shaders)
               ├── _scatter_cc0_props                        (Kenney CC0 GLBs)
               ├── MobilePlayer ──visual──> HumanoidModel
               └── MonsterMob ──body_visual──> AnimalMobModel
```

Three visual producers coexist today:
1. **Procedural primitives** (in `starter_world.gd`, `character_select.gd`,
   `monster_mob.gd`, `drop_item.gd`, `combat_vfx.gd`, `floating_damage.gd`).
2. **Self-generated skeletal GLBs** (`tools/generate_glb_models.py` → `assets/models/*.glb`)
   used for player, monster, and weapon bodies.
3. **External CC0 GLBs** (Kenney nature props in `assets/cc0/`, ambientCG PBR maps).

The architectural gap: there is no asset registry, no per-asset metadata (scale, socket
map, animation map), and no runtime adapter. Replacing a procedural body with a real
external rig currently requires editing hard-coded paths and rig plumbing inside the
visual scripts.

## B. Procedural Character Pipeline

- **Owner:** `MobileClient/player_controller.gd` (`MobilePlayer`, `CharacterBody3D`).
  - `_build_body()` (`:21-32`) creates a `CapsuleShape3D` collider
    (`radius 0.38`, `height 1.65`, `position.y 0.86`) and instantiates
    `visual = load("res://humanoid_model.gd").new()`.
  - `configure_build(data)` (`:47-52`) forwards to `visual.configure_build(data)` and
    derives `weapon_style` from `class_id` (`wizard`/`european_wizard`/`staff` → wizard,
    else spear).
  - `play_attack()` (`:60-62`), `_physics_process` (`:70-95`) call
    `visual.set_animation_state("walk"/"idle")`, yaw is stored on `rotation.y`.
  - `get_attack_origin()` (`:57-58`) returns
    `global_position + Vector3(0, 1.35, -0.55).rotated(UP, rotation.y)` — a hard-coded
    offset, not a bone socket.
- **Owner:** `MobileClient/humanoid_model.gd` (`HumanoidModel`, `extends Node3D`).
  - `configure_build(data)` (`:19-27`) frees children then calls `_build_imported_model()`.
  - `_build_imported_model()` (`:46-79`):
    - loads `res://asset_loader.gd`, calls `instantiate_humanoid(weapon_style)`;
    - finds `AnimationPlayer`, loops `idle`/`walk`, plays `idle`;
    - finds `Skeleton3D`, builds `bones[bone_name] = index` map;
    - creates `BoneAttachment3D("WeaponMount")` with `bone_name = "hand_r"` (`:68-71`);
    - instantiates the weapon via `instantiate_weapon(weapon_style)`, parents it to the
      mount, applies `rotation_degrees = (0, 0, -8)` and `_tint_weapon()`.
  - `play_attack()` (`:41-44`) plays the `attack` animation if present.
- **Geometry source:** `tools/generate_glb_models.py` → `build_humanoid()` (`:758`).
  Bones (`:772-791`): `root, hips, spine, chest, neck, head, shoulder_l, upper_arm_l,
  lower_arm_l, hand_l, shoulder_r, upper_arm_r, lower_arm_r, hand_r, thigh_l, shin_l,
  foot_l, thigh_r, shin_r, foot_r`. Animations: `idle`, `walk`, `attack` (`:988-990`).
  Meshes are `box()/sphere()/torus()/cylinder()/cone()` primitives.
- **Preview:** `character_select.gd:146-150` builds the same `HumanoidModel` as
  `preview_body` and rescales it.

## C. Procedural Monster Pipeline

- **Owner:** `MobileClient/monster_mob.gd` (`MonsterMob`, `extends Area3D`).
  - `_build_visual()` (`:58-102`) creates:
    - `CapsuleShape3D` collider (`radius 0.72`, `height 1.9`, `position.y 0.9`);
    - `body_visual = load("res://animal_mob_model.gd").new()`,
      `configure_animal(rarity)` (`:67-69`);
    - a `TorusMesh` gold target ring;
    - a world-space HP bar (`ProgressBar`) + name `Label`.
  - `_process` (`:127-134`) drives `body_visual.set_animation_state(...)`.
  - `apply_damage()` calls `body_visual.play_attack()`; `play_defeat()` tweens the whole
    `MonsterMob` scale/rotation.
- **Owner:** `MobileClient/animal_mob_model.gd` (`AnimalMobModel`, `extends Node3D`).
  - `configure_animal(value)` (`:11-16`) frees children, then `_build_imported_animal()`.
  - `_build_imported_animal()` (`:34-52`) loads `asset_loader.instantiate_monster()`,
    applies `scale = Vector3.ONE * 2.6`, `position.y 0.02`, finds `AnimationPlayer`,
    loops `idle`/`walk`, plays `idle`.
  - `set_animation_state` / `play_attack` (`:24-32`).
- **Geometry source:** `generate_glb_models.py` → `build_monster()` (`:996`). Bones
  (`:1012-1036`): `root, spine, chest, neck, head, shoulder_l/r, upper_arm_l/r,
  lower_arm_l/r, hand_l/r, thigh_l/r, shin_l/r, foot_l/r, tail_1, tail_2, tail_3`.
  Animations: `idle`, `walk`, `attack` (`:1186-1188`). All primitive meshes.

## D. Current Environment Pipeline

All in `MobileClient/starter_world.gd`:

- `_build_environment()` (`:94-159`): `WorldEnvironment` (HDR Filmic, glow, fog, sky),
  `DirectionalLight3D` sun + moon fill, `OmniLight3D` golden fill.
- `_build_city()` (`:160-223`): ground `PlaneMesh` + `BoxShape3D` collider, celestial
  stone apron, PBR road, water strip, then dispatches to `_build_house`, `_build_tree`,
  `_build_lantern`, `_build_gate`, `_build_bridge`, `_build_market`,
  `_build_celestial_sanctum`, `_scatter_cc0_props`.
- `_build_celestial_sanctum` (`:225-302`): `CylinderMesh` dais/altar/steps,
  `TorusMesh` energy rings, `_build_moon_gate`, `_build_floating_island`,
  `GPUParticles3D` motes.
- `_build_moon_gate` (`:304-342`): `CylinderMesh` pillars, `TorusMesh` arch/caps,
  `OmniLight3D`.
- `_build_floating_island` (`:344-379`): `CylinderMesh` + `PrismMesh` crystals.
- `_build_house` (`:391-451`): `BoxMesh` base/windows/beams/trim/ridge/eaves,
  `PrismMesh` roof; `_plaster_shader`, `_wood_grain_material`, `_roof_tile_material`.
- `_build_tree` (`:453-473`): `CylinderMesh` trunk, `SphereMesh` crowns.
- `_build_lantern` (`:475-529`): `CylinderMesh` pole/body/ribs/cap, `SphereMesh` finial,
  `OmniLight3D`.
- `_build_gate` (`:531-578`): `BoxMesh` pillars/beam/ridge/eaves, `PrismMesh` roof,
  `Label3D` sign.
- `_build_bridge` (`:580-589`): `BoxMesh` planks on a sine arc.
- `_build_market` (`:659-697`): `BoxMesh` table/canopy, `CylinderMesh` legs,
  `PrismMesh` roof, `OmniLight3D`.
- `_scatter_cc0_props` (`:591-657`): loads Kenney CC0 GLBs (`tree_default`,
  `rock_largeA/C`, `flower_purpleA/redB`, `grass_large`, `campfire_stones`,
  `fence_planks`) and scatters them at fixed positions.
- Materials/shaders: `_pbr_stone_material` (ambientCG PBR maps, `:1130-1147`),
  `_water_shader` (`:1203-1227`), `_pattern_shader` (`:1229-1252`), `_fabric_shader`,
  `_asian_roof_shader`, `_asian_wood_shader`, `_texture_or_fallback`, plus
  `assets/textures/*.png` procedural albedo maps.

`character_select.gd` also builds a podium from `CylinderMesh`/`TorusMesh` primitives
(`:106-137`). `drop_item.gd` uses a gold `BoxMesh` (`:41-47`).

## E. Existing External GLB/glTF Loading Support

1. **Central loader — `MobileClient/asset_loader.gd`** (`extends RefCounted`, static):
   - Constants for all GLB paths (`:13-17`).
   - `_scene(path)` static cache `_cache` (`:21-28`).
   - `instantiate_humanoid(build_id)` (`:30-39`), `instantiate_monster()` (`:41-47`),
     `instantiate_weapon(build_id)` (`:49-58`) — `load(path)` → `instantiate()`.
   - `source_manifest()` (`:60-70`) documents the self-generated/CC0 provenance.
   - Consumed by `humanoid_model.gd` and `animal_mob_model.gd`.
2. **Direct `load()`:** `starter_world.gd:_add_glb_asset()` (`:381-389`) and
   `_scatter_cc0_props()` (`:591-657`) call `load(path).instantiate()` directly.
3. **Boot preload:** `boot.gd:_start_loading()` (`:92-104`) uses
   `ResourceLoader.load_threaded_request` for the 5 model GLBs + `main.tscn`, then
   `_enter_main()`.

Godot GLB import is fully supported (see `.glb.import` files: skeleton, animation, LOD,
tangents enabled). The Android export filter (`export_presets.cfg`) already includes
`*.glb, *.gltf, *.png, *.tscn, *.tres`.

**Limitations of the current loader for the target pipeline:**
- Paths are hard-coded constants, not a registry keyed by logical asset.
- No per-asset metadata (base scale, socket map, animation map, offsets).
- No fallback chain — a missing asset silently returns `null` and the model stays blank.
- The adapter logic (skeleton/bone map, weapon mount, animation remap) lives inside
  `humanoid_model.gd` / `animal_mob_model.gd` instead of a reusable visual layer.

## F. Exact Adapter Architecture Required

Three new reusable components sit **below** the gameplay layer and above the raw GLB files.
The gameplay scripts keep calling the same public methods; the adapters resolve which
asset backs each entity.

```
manifest.tres  (asset registry: key -> path + metadata)
      │
      ▼
VisualAssetLoader  (RefCounted, static)
  - register_manifest(path)
  - get(key) -> Dictionary
  - resolve(key) -> String            (fallback chain, see L)
  - instantiate(key) -> Node3D        (cached PackedScene + base transform)
  - preload(keys) / preload_threaded(keys)
  - compatibility shims: instantiate_humanoid / instantiate_monster / instantiate_weapon
      │
      ├──────────────┬─────────────────────────────┐
      ▼              ▼                             ▼
CharacterVisualAdapter      MonsterVisualAdapter     EnvironmentObjectPlacer
  (player + previews)         (monster rigs)          (world placement)
  ├ attach_weapon / attach_armor / equipment
  ├ socket_map (BoneAttachment3D)
  └ animation_map (logical -> clip)
```

Layering contract:
- **Gameplay layer (unchanged):** `MobilePlayer`, `MonsterMob`, `StarterWorld` handlers,
  `SkillSystem`, protocol. They call `configure_build`, `configure_animal`, `play_attack`,
  `set_animation_state`, `get_attack_origin` exactly as today.
- **Adapter layer (new):** resolves asset keys, owns `Skeleton3D`/`AnimationPlayer`/
  `BoneAttachment3D`, applies metadata, exposes the same method names.
- **Asset layer (data):** GLB/glTF files + `manifest.tres` metadata. No logic.

## G. CharacterVisualAdapter Design

`class_name CharacterVisualAdapter extends Node3D` (replaces the body-owning role of
`HumanoidModel`, keeping its public surface).

State:
- `asset_key: String`, `rig_root: Node3D`
- `skeleton: Skeleton3D`, `animation_player: AnimationPlayer`
- `sockets: Dictionary` — logical name (`weapon_r`, `weapon_l`, `head`, `back`) →
  `BoneAttachment3D`
- `animation_map: Dictionary` — logical state → clip name (per-asset)

Public API (mirrors `humanoid_model.gd` / `player_controller.gd` usage):
- `configure(data: Dictionary)`
  - resolve `asset_key` from `data.class_id` / `data.race` / `data.weapon` via
    `VisualAssetLoader.resolve()`;
  - instantiate rig, apply `base_scale`/`position_offset`/`rotation_offset`;
  - find `Skeleton3D` + `AnimationPlayer`; loop `idle`/`walk`; play `idle`;
  - build `BoneAttachment3D` sockets from `socket_map`.
- `set_animation_state(state)` → map logical → clip, play (respects attack lockout).
- `play_attack()` → play mapped attack clip, restore base clip after duration.
- `attach_weapon(weapon_key)` → delegate to Weapon Attachment Pipeline (I).
- `attach_armor(armor_key)` → delegate to Equipment Pipeline (J).
- `get_attack_origin()` → world position of the `weapon_r` (or configurable muzzle)
  `BoneAttachment3D` — replaces `player_controller.gd:57-58` hard-coded offset.
- `set_highlight(value)` → optional selection ring/emissive.

Fallback behavior: if `resolve()` returns the legacy self-generated GLB (tier-2) or the
procedural path (tier-3), the adapter still works because it only requires
`Skeleton3D` + `AnimationPlayer` + bone names, all of which the legacy rigs provide.

## H. MonsterVisualAdapter Design

`class_name MonsterVisualAdapter extends Node3D` (replaces `AnimalMobModel`'s role).

State:
- `asset_key`, `rig_root`, `skeleton`, `animation_player`
- `sockets`, `animation_map` (as G)
- `rarity` for presentation variants (palette/material overrides)

Public API (mirrors `animal_mob_model.gd` / `monster_mob.gd` usage):
- `configure_animal(data)` — resolve `asset_key` (e.g.
  `monsters/eastern/mangyang_01`), instantiate, apply scale/offset, rig sockets, animation.
- `set_animation_state(state)` — logical → clip.
- `play_attack()`, `play_hurt()`, `play_death()` — mapped clips; the current
  `MonsterMob.play_defeat()` tween on the **owner** (`monster_mob.gd:104-114`) can stay,
  but a bone-attached dissolve/death clip can replace it later (visual only).
- `set_highlight(value)`.

Notes:
- External beast rigs may use different bone sets (quadruped vs the legacy upright
  Mangyang). The adapter only depends on `socket_map` + `animation_map`; missing bones are
  resolved by substring fallback (`hand`/`Hand`, `head`/`Head`).
- `MonsterMob` keeps its collider, target ring, HP bar, targeting, damage, despawn logic
  untouched — the adapter only owns the visible rig.

## I. Weapon Attachment Pipeline

Current behavior (to be preserved through the adapter): `humanoid_model.gd:68-78` creates
a `BoneAttachment3D` with `bone_name = "hand_r"`, parents the weapon instance, and applies
`rotation_degrees = (0, 0, -8)` plus a material tint.

Adapter version:
1. `manifest.tres` entry per weapon, e.g.
   `weapons/spear/eastern_spear_01 → assets/weapons/spear/eastern_spear_01.glb`.
2. `CharacterVisualAdapter.attach_weapon(weapon_key)`:
   - `VisualAssetLoader.instantiate(weapon_key)`;
   - find socket `weapon_r` (map → bone, default `hand_r`); create `BoneAttachment3D` if
     missing, reuse if present;
   - apply per-weapon `position_offset` / `rotation_offset` / `scale` from manifest;
   - optional material override for rarity/outfit tint (replaces `_tint_weapon`).
3. `get_attack_origin()` reads the socket's global position instead of a magic offset.
4. Two-handed weapons (`spear`, `staff`, `bow`) may use both `weapon_l` and `weapon_r`
   sockets; manifest field `two_handed: true`.

## J. Equipment Visual Mapping Pipeline

Today there is no armor/equipment visual system — `outfit_name`/`race_name` are only
labels (`humanoid_model.gd:6-7`). The pipeline introduces visual-only equipment layering:

1. `manifest.tres` equipment entries, e.g.
   `armor/eastern/jade_armor → assets/armor/eastern/jade_armor.glb`,
   with `socket_map` (`chest`, `back`, `shoulder_l/r`, `head`, `forearm_l/r`, `shin_l/r`).
2. `CharacterVisualAdapter.attach_armor(armor_key)` instantiates the armor GLB and parents
   each mesh part onto the mapped `BoneAttachment3D` sockets so it animates with the rig.
3. Piece types (helmet, chest, shoulders, gloves, greaves) each map to a stable set of
   logical sockets; a character may stack several equipment pieces.
4. Presentation-driven only: weapon/outfit/race selection in `character_select.gd`
   continues to drive stat/ID values (`WEAPON_IDS`/`OUTFIT_IDS`/`MODEL_IDS`) while the
   adapter swaps visuals via the same `configure_build` data dict.
5. Equipment does not alter stats, armor value, or gameplay — it is a pure visual mapping.

## K. Recommended Asset Directory Structure

```
MobileClient/assets/
├── characters/
│   ├── eastern/
│   │   └── eastern_spear_warrior.glb
│   └── western/
│       └── western_wizard.glb
├── monsters/
│   └── eastern/
│       └── mangyang_01.glb
├── weapons/
│   ├── sword/
│   ├── spear/
│   │   └── eastern_spear_01.glb
│   ├── bow/
│   └── staff/
├── armor/
│   ├── eastern/
│   └── western/
├── environment/
│   ├── eastern/
│   ├── western/
│   ├── desert/
│   └── forest/
├── animations/
│   └── humanoid/          (optional shared clips / retarget sources)
├── textures/              (existing procedural albedo maps — kept)
├── models/                (existing self-generated fallback GLBs — kept)
├── cc0/                   (existing Kenney props — kept)
└── manifest.tres          (asset registry: key -> path + metadata)
```

Rules:
- Every external folder ships a `LICENSE.txt` recording source/license (CC0 only or
  clearly licensed).
- Existing `models/`, `textures/`, `cc0/` remain untouched as the fallback set.
- `export_presets.cfg` already filters `*.glb, *.gltf, *.png` so new folders package
  automatically.

Example registry entries:
```jsonc
{
  "characters/eastern/eastern_spear_warrior": {
    "path": "res://assets/characters/eastern/eastern_spear_warrior.glb",
    "base_scale": 1.0,
    "position_offset": [0, 0, 0],
    "rotation_offset": [0, 0, 0],
    "animation_map": { "idle": "Idle", "walk": "Walk", "attack": "Attack_1" },
    "socket_map": { "weapon_r": "hand_r", "weapon_l": "hand_l", "head": "head", "back": "spine" }
  },
  "monsters/eastern/mangyang_01": {
    "path": "res://assets/monsters/eastern/mangyang_01.glb",
    "base_scale": 2.6,
    "animation_map": { "idle": "Idle", "walk": "Walk", "attack": "Attack" },
    "socket_map": { "head": "head", "mouth": "jaw" }
  },
  "weapons/spear/eastern_spear_01": {
    "path": "res://assets/weapons/spear/eastern_spear_01.glb",
    "position_offset": [0, 0, 0],
    "rotation_offset": [0, 0, -8],
    "two_handed": true
  }
}
```

## L. Migration Strategy With Procedural Fallbacks

Resolution order in `VisualAssetLoader.resolve(key)`:

```
tier 1  external GLB   (assets/characters/..., assets/monsters/..., assets/weapons/...)
tier 2  legacy GLB     (assets/models/humanoid_*.glb, monster_mangyang.glb, weapon_*.glb)
tier 3  procedural     (existing in-scene primitive builders, generate_glb_models.py)
```

- If tier 1 exists for a key, the adapter uses it. Otherwise it falls back to tier 2, then
  tier 3 — the game keeps running identically today.
- `VisualAssetLoader.force_fallback = true` (or a project setting) lets QA compare
  external vs legacy visuals without recompiling.
- Per-entity override `"mode": "external" | "legacy" | "procedural"` in `manifest.tres`
  allows a staged, mixed rollout.
- Nothing is deleted. `generate_glb_models.py`, `assets/models/*.glb`,
  `assets/textures/*.png`, and all `_build_*` functions remain for the entire transition.
- The current untracked duplicate PNGs under `assets/models/` (copies of
  `assets/textures/*.png`) are unrelated to this task and are left untouched.

## M. Files Safe To Modify Later (adapter layer only)

- New files (create): `MobileClient/visual_asset_loader.gd`,
  `MobileClient/character_visual_adapter.gd`,
  `MobileClient/monster_visual_adapter.gd`,
  `MobileClient/environment_object_placer.gd`, `MobileClient/assets/manifest.tres`.
- Adapter integrations (edit later, visual only):
  - `MobileClient/asset_loader.gd` — become the `VisualAssetLoader` facade (keep the
    existing three method names as shims).
  - `MobileClient/humanoid_model.gd` — route `configure_build` through
    `CharacterVisualAdapter`; parameterize socket/animation maps.
  - `MobileClient/animal_mob_model.gd` — route `configure_animal` through
    `MonsterVisualAdapter`.
  - `MobileClient/character_select.gd` — preview uses the adapter; podium/UI unchanged.
  - `MobileClient/boot.gd` — preload list driven by registry keys.
  - `MobileClient/player_controller.gd` — only `get_attack_origin()` to call
    `visual.get_attack_origin()` (one line); movement/combat routing untouched.
  - `MobileClient/starter_world.gd` — only environment **placement** helpers delegate to
    `EnvironmentObjectPlacer.place()` when an asset is registered; gameplay handlers and
    packet calls unchanged.
  - `MobileClient/drop_item.gd` — optional loot-mesh registry lookup (visual only).
- VFX (`combat_vfx.gd`, `floating_damage.gd`) — optional later; no change required.

## N. Logic-Locked Files That Must Remain Untouched

Per `PHASE9_LOGIC_LOCK.md` and this task:

- `MobileClient/sro_protocol.gd` — packet serialization/parsing, handshake, `0x6102`,
  `0x6103`, entity/action/item flows.
- `MobileClient/blowfish.gd` — encryption.
- `MobileClient/main.gd` — login/character-select state machine.
- `MobileClient/skill_system.gd` — skill definitions, mana, cooldowns, damage formulas.
- `MobileClient/skill_tree_ui.gd`, `MobileClient/inventory_ui.gd`, `MobileClient/mobile_hud.gd`,
  `MobileClient/minimap.gd`, `MobileClient/virtual_joystick.gd` — UI/input behavior.
- Gameplay handlers in `MobileClient/starter_world.gd` — combat results, EXP, gold,
  inventory/loot pickup, target acquisition, monster spawn/despawn logic.
- `MobileClient/monster_mob.gd`, `MobileClient/drop_item.gd` gameplay parts — targeting,
  damage, despawn, loot behavior (only their visual children are swappable).
- `.github/workflows/android-build.yml`, `.github/workflows/windows-server-build.yml` —
  artifact names and build commands.
- `tools/generate_glb_models.py` — retained as the fallback generator.

## O. Step-by-Step Implementation Order

1. **Registry first.** Create `assets/manifest.tres` + `VisualAssetLoader` skeleton with
   compatibility shims (`instantiate_humanoid`/`instantiate_monster`/`instantiate_weapon`)
   that resolve to the current `assets/models/*.glb`. No visual change.
2. **Character adapter.** Add `CharacterVisualAdapter`; route `humanoid_model.gd`
   `configure_build` through it; behavior identical with the legacy GLBs. Verify offline
   world + character select render.
3. **Monster adapter.** Add `MonsterVisualAdapter`; route `animal_mob_model.gd`
   `configure_animal`; verify monster spawn/target/attack in offline mode.
4. **Origin fix.** Update `MobilePlayer.get_attack_origin()` to query the adapter socket;
   keep wizard/spear behavior identical. Update `boot.gd` preload to registry keys.
5. **Weapon attachments.** Add `weapons/` manifest entries; implement
   `attach_weapon()` on both `hand_r`/`hand_l` sockets with per-weapon offsets; verify
   wizard staff and spear builds.
6. **First real external assets.** Import `characters/eastern/eastern_spear_warrior.glb`,
   `characters/western/western_wizard.glb`, `monsters/eastern/mangyang_01.glb`,
   `weapons/spear/eastern_spear_01.glb` (CC0 or licensed). Register in manifest; QA in
   offline mode; compare against `force_fallback`.
7. **Equipment mapping.** Add `armor/` entries and `attach_armor()` socket mapping;
   apply per-build visual equipment without stat changes.
8. **Environment placement.** Add `environment/` entries; route selected `_build_*`
   helpers through `EnvironmentObjectPlacer.place()`; keep legacy builders as tier-3
   fallback. Do not add new generic props.
9. **Hardening.** Bone/animation substring fallbacks, per-asset LOD/poly budget checks,
   `LICENSE.txt` for every external folder, Android APK smoke test.
10. **Retire tier-3 gradually** (and only after visual QA passes) — never delete the
    fallback pipeline before the external set covers all builds.

---

## Appendix — Current GLB inventory (for reference)

| File | Type | Bones | Animations | Used by |
| --- | --- | --- | --- | --- |
| `assets/models/humanoid_wizard.glb` | humanoid | 21 | idle/walk/attack | player (wizard), character select |
| `assets/models/humanoid_spear.glb` | humanoid | 21 | idle/walk/attack | player (spear), character select |
| `assets/models/monster_mangyang.glb` | beast | 24 | idle/walk/attack | monsters |
| `assets/models/weapon_staff.glb` | static weapon | — | — | wizard weapon mount |
| `assets/models/weapon_spear.glb` | static weapon | — | — | spear weapon mount |
| `assets/cc0/*.glb` (9) | environment props | — | — | `_scatter_cc0_props` |

Generated by `tools/generate_glb_models.py` (`build_humanoid :758`, `build_monster :996`,
`build_weapon_staff :1194`, `build_weapon_spear :1227`). Godot imports them via the
standard glTF module (`Skeleton3D`/`MeshInstance3D`/`AnimationPlayer`).
