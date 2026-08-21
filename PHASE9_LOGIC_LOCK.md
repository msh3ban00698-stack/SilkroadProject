# Phase 9 Logic Lock

Phase 9 is a visual rebrand. The following gameplay contracts are frozen and must not be changed by the visual implementation: SRO packet serialization/parsing, login and character-selection state transitions, skill definitions and cooldown/mana rules, progression and EXP handling, monster targeting and combat result handling, inventory and loot pickup behavior, and the Android/Windows CI interfaces.

| Contract | Protected files | Allowed Phase 9 changes |
| --- | --- | --- |
| SRO packet and state-machine behavior | `MobileClient/sro_protocol.gd`, `MobileClient/blowfish.gd`, `MobileClient/main.gd` | None |
| Skills, mana, cooldown, progression | `MobileClient/skill_system.gd`, relevant handlers in `starter_world.gd` | Visual call sites only; no packet/state formulas |
| Player movement and class attack routing | `MobileClient/player_controller.gd`, relevant handlers in `starter_world.gd` | Model, animation, VFX, and presentation parameters only |
| Monster targeting, damage, despawn, loot | `MobileClient/monster_mob.gd`, `MobileClient/drop_item.gd`, relevant handlers in `starter_world.gd` | Meshes, materials, VFX, labels, and UI skins only |
| Build contracts | `.github/workflows/android-build.yml`, `.github/workflows/windows-server-build.yml` | Artifact names and build commands remain unchanged |

The baseline commit for this rebrand is `c0e6cbe`. Pure gameplay files were hashed during the Phase 9 audit before visual work began. Any future change to a protected handler must be treated as a logic regression and rejected.
