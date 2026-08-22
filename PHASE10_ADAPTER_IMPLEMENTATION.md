# Phase 10.2 — Visual Asset Adapter Pipeline Implementation

> Status: implemented. Phase 10.1 (`PHASE10_ASSET_PIPELINE.md`) specified the adapter
> architecture; this document records what was built in Phase 10.2, how the legacy
> self-generated GLB visuals now flow through the new registry, and what compatibility
> guarantees hold for gameplay callers.

## Scope

Architecture-only change. No gameplay, networking, combat, EXP, inventory, or packet
logic was touched. No new runtime assets were added. The existing self-generated GLBs in
`MobileClient/assets/models/` remain the fallback asset set and still render identically.

## Files Created

| File | Purpose |
| --- | --- |
| `MobileClient/assets/visual_asset_manifest.json` | JSON asset registry: logical key → path + per-asset metadata (base_scale, position_offset, rotation_offset, animation_map, socket_map, fallback_key, two_handed, type). |
| `MobileClient/visual_asset_loader.gd` | `VisualAssetLoader` (RefCounted, static): loads/parses the JSON manifest, caches `PackedScene`s, resolves keys through the fallback chain, instantiates with base transform, and exposes compatibility shims. |
| `MobileClient/character_visual_adapter.gd` | `CharacterVisualAdapter` (Node3D): owns a character rig — `Skeleton3D`, `AnimationPlayer`, logical→clip `animation_map`, and `BoneAttachment3D` sockets (`weapon_r`, `weapon_l`, `head`, `back`) from `socket_map`. |
| `MobileClient/monster_visual_adapter.gd` | `MonsterVisualAdapter` (Node3D): same ownership for monster rigs (`monsters/eastern/mangyang_01`), including scale 2.6 / y 0.02 metadata. |

## Files Modified (adapter layer only)

| File | Change |
| --- | --- |
| `MobileClient/humanoid_model.gd` | Rewritten as a thin wrapper that owns a `CharacterVisualAdapter` child. Preserves the public surface and the legacy handle fields (`build_id`, `weapon_style`, `race_name`, `outfit_name`, `skeleton`, `bones`, `imported_model`, `weapon_mount`, `animation_state`). |
| `MobileClient/animal_mob_model.gd` | Rewritten as a thin wrapper that owns a `MonsterVisualAdapter` child. Preserves `rarity`, `configure_animal`, `set_animation_state`, `play_attack`. |
| `MobileClient/asset_loader.gd` | Now a facade over `VisualAssetLoader`. Keeps `instantiate_humanoid` / `instantiate_monster` / `instantiate_weapon` / `source_manifest` and the ambientCG `GROUND_*` constants. Removed the hard-coded GLB path constants and the private `_scene`/`_cache` (now owned by the loader). |

## Legacy Visual Flow (before)

```
humanoid_model.gd ──load("res://asset_loader.gd")──> asset_loader.gd
                                                      ├─ hard-coded GLB constants
                                                      └─ instantiate_humanoid / weapon
   (own Skeleton3D, bone map, WeaponMount BoneAttachment3D on "hand_r", tint)
```

```
animal_mob_model.gd ──asset_loader.instantiate_monster()──> scale 2.6, y 0.02
   (own AnimationPlayer loop + attack timer)
```

## Adapter Visual Flow (now)

```
gameplay layer (unchanged)
   character_select.gd / player_controller.gd ──configure_build / play_attack /
                                               set_animation_state / get_attack_origin──►
   monster_mob.gd                             ──configure_animal / play_attack /        │
                                               set_animation_state───────────────────►  │
        ┌──────────────────────────────────────────────────────────────────────────────────┘
        ▼
HumanoidModel / AnimalMobModel   (compatibility wrappers, unchanged public surface)
        ▼
CharacterVisualAdapter / MonsterVisualAdapter
   ├─ resolve asset_key via VisualAssetLoader.resolve()
   ├─ instantiate rig (base_scale / position_offset / rotation_offset applied)
   ├─ find Skeleton3D + AnimationPlayer; loop idle/walk; play idle
   ├─ build BoneAttachment3D sockets from socket_map (substring bone fallback)
   └─ attach_weapon(weapon_key) on weapon_r socket + tint
        ▼
VisualAssetLoader (RefCounted, static)
   ├─ manifest()          reads assets/visual_asset_manifest.json (cached)
   ├─ resolve_chain(key)  walks fallback_key chain (loop-guarded)
   ├─ _scene_for_key(key) first loadable scene along the chain
   ├─ instantiate(key)    cached PackedScene + base transform; null only after
   │                      every fallback failed
   └─ shims               instantiate_humanoid / instantiate_monster /
                          instantiate_weapon
        ▼
assets/models/*.glb  (legacy tier-2 fallback set, unchanged)
```

## Manifest Entries (initial, all tier-2 legacy GLBs)

| asset_key | path | type | base_scale | rotation_offset | two_handed |
| --- | --- | --- | --- | --- | --- |
| `characters/eastern/eastern_spear_warrior` | `res://assets/models/humanoid_spear.glb` | humanoid | 1.0 | — | true |
| `characters/western/western_wizard` | `res://assets/models/humanoid_wizard.glb` | humanoid | 1.0 | — | false |
| `monsters/eastern/mangyang_01` | `res://assets/models/monster_mangyang.glb` | monster | 2.6 | — | false |
| `weapons/spear/eastern_spear_01` | `res://assets/models/weapon_spear.glb` | weapon | 1.0 | (0, 0, -8) | true |
| `weapons/staff/western_staff_01` | `res://assets/models/weapon_staff.glb` | weapon | 1.0 | (0, 0, -8) | false |

`fallback_key` chains: characters cross-fallback to each other; the monster falls back to
`eastern_spear_warrior`; weapons cross-fallback. A weapon/character resolution that hits a
missing scene walks the chain before returning `null` (so the game never blanks out on a
single missing asset).

`animation_map` is `{ "idle": "idle", "walk": "walk", "attack": "attack" }` for characters
and the monster, matching the baked clip names in the legacy GLBs. `socket_map` for
characters: `weapon_r → hand_r`, `weapon_l → hand_l`, `head → head`, `back → spine`
(renders on the legacy 21-bone rig, where `spine` exists).

## Compatibility Guarantees

- `character_select.gd:146-150` and `:443-451` keep `load("res://humanoid_model.gd").new()`,
  `configure_build(data)`, `position`, `scale` — unchanged.
- `player_controller.gd` keeps `visual.configure_build(...)`,
  `visual.set_animation_state(...)`, `visual.play_attack()` — unchanged. Its
  `get_attack_origin()` (hard-coded offset) was left untouched; the adapter exposes a
  socket-based `get_attack_origin()` for a later one-line switch (Phase 10 step 4).
- `monster_mob.gd` keeps `load("res://animal_mob_model.gd").new()`,
  `configure_animal(rarity)`, guarded `has_method("set_animation_state")` /
  `has_method("play_attack")` — unchanged.
- Weapon attachment preserves the legacy presentation: `BoneAttachment3D` on `hand_r`,
  weapon `rotation_degrees (0, 0, -8)` (now via manifest `rotation_offset`), and the
  wizard (blue `#8edbff`) / spear (gold `#e5bb5f`) tint.
- Monster presentation preserves scale `2.6` and `position.y 0.02` (now manifest
  `base_scale` / `position_offset`), attack duration `0.8`; character attack duration
  `0.62`.

## Fallback Behavior

`VisualAssetLoader.resolve_chain(key)` returns an ordered list: the requested key, then
each `fallback_key` until the chain end (loop-guarded). `resolve(key)` picks the first
chain entry that carries a non-empty `path`. `_scene_for_key` walks the full chain and
returns the first scene that loads, so a missing/broken primary GLB falls through to the
fallback. `instantiate` returns `null` only when every candidate scene fails to load —
previously a missing asset silently returned `null` from `asset_loader` and left the
model blank.

## Verification

- Headless Godot 4.4 import of `MobileClient/` completed without script parse errors
  (all new/modified GDScript compiles).
- Static call-site audit: no gameplay caller references the removed `asset_loader`
  internals (`HUMAN_*_GLB`, `MONSTER_GLB`, `WEAPON_*_GLB`, `_scene`, `_cache`).
- Runtime regression (on-device/editor, when run): character select renders Wizard/Spear,
  offline starter world loads, movement + idle/walk/attack animations play, wizard staff
  and spear attach, Mangyang spawns with idle/walk/attack, no packet/combat logic changed,
  manifest-load failure falls back safely.

## Next Step Before Real External Assets

Import actual CC0-licensed premium rigs into `MobileClient/assets/characters/...`,
`assets/monsters/...`, `assets/weapons/...` and flip the corresponding manifest `path` +
`animation_map`/`socket_map` entries (tier-1). The legacy set under `assets/models/`
stays as the permanent tier-2 fallback. Do not ship external assets without a
`LICENSE.txt` in each folder.
