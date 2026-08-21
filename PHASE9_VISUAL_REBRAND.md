# Phase 9 Visual Rebrand

## Art direction

Phase 9 rebrands the client as an original **Mythical Celestial Asian** fantasy RPG. The visual language uses midnight blue, jade teal, ceremonial gold, astral cyan, dark stone, silk-like cloth response, luminous sigils, floating sanctum architecture, moon gates, suspended crystal islands, and layered light bursts. The rebrand is intentionally not branded as Silkroad Online and does not include original Silkroad assets.

The generated art-direction reference is `PHASE9_CELESTIAL_REFERENCE.png`. It is a concept reference only; the shipped runtime uses Godot-native materials and geometry so the package remains deterministic and mobile-compatible.

## Runtime changes

The Celestial Mage and Dragon Warrior presentation is implemented in `humanoid_model.gd` through original proportional humanoid rigs, layered regalia, metallic shoulder ornaments, emissive chest crests, floating mage talismans, dragon-warrior sash details, halo geometry, and lightweight aura particles. `animal_mob_model.gd` now presents the encounter creatures as spectral jade-and-amethyst celestial guardians with luminous eyes, horns, collars, tail-light forms, and particle motes.

`combat_vfx.gd` now provides layered slash and cast effects, shader-driven arcs, orbiting spell rings, projectile cores, impact shockwaves, meteor trails, spear waves, spark bursts, and light flashes. Existing public functions and skill IDs remain unchanged, so the visual implementation is isolated from combat and packet logic.

StarterWorld now adds a sanctum dais, stepped altar, moon gate, floating crystal islands, ceremonial energy rings, drifting astral particles, and a deeper teal-and-gold environment. The existing water, PBR road, collision floor, monster spawning, movement, combat, skill, EXP, inventory, and loot handlers remain in place. MobileHUD and CharacterSelect use dark-stone panels, gold filigree borders, celestial labels, and premium action controls while preserving their existing signals and function names.

## Open-source asset decision

Quaternius' primary RPG Character Pack page was verified as CC0 and describes rigged, animated, textured characters in glTF/FBX/OBJ/Blend formats: https://quaternius.com/packs/rpgcharacters.html. The OpenGameArt CC0 humanoid collection was also verified: https://opengameart.org/content/3d-humanoids-under-cc0. Their available visual sets are predominantly low-poly or generic and were not reintroduced into the runtime because they conflict with the requested high-end celestial direction. Existing ambientCG PBR maps remain the legally clear surface source, and the new character/environment identity is authored in the project's visual scripts.

## Logic boundary

The protected SRO-style contracts are recorded in `PHASE9_LOGIC_LOCK.md`. Phase 9 must not alter packet parsing/serialization, the state machine, skill definitions, mana/cooldown/progression formulas, combat result handling, inventory/loot behavior, or CI artifact contracts.
