# Phase 8 Research

## Visual target

The desired direction is semi-realistic high-fantasy Asian/Historical RPG: darker silk/wood/stone materials, cinematic dawn/sunset lighting, physically based surfaces, and atmospheric water rather than flat blue geometry.

## Verified open asset source

ambientCG presents PBR surfaces, HDRIs, fabrics/leather, ground/sand, rocks, and other materials. Its official license page states that all downloadable assets are under Creative Commons CC0 1.0 Universal, and that raw files may be included in a video game and used commercially without permission. Source URLs:

- https://ambientcg.com/
- https://docs.ambientcg.com/license/

## Existing project issue

The current visual stack still uses Kenney low-poly GLBs and many procedural Box/Cylinder/Prism town meshes. `HumanoidModel` also overrides imported meshes with flat StandardMaterial3D colors, which suppresses the original material response. Phase 8 should remove Kenney from the default loader, use PBR-driven materials for the remaining procedural geometry, and reserve procedural primitives for collision or structural geometry only where no open asset is available.

## Additional registry check

ToxSam's `open-source-3D-assets` GitHub registry describes a CC0 asset database with GLB models and links to permanent storage. Its visible project index contains environment collections such as Lunar Year, Medieval Fair, Crystal Crossroads, and MomusPark, but the inspected index did not directly provide a semi-realistic Asian humanoid character with PBR clothing. It remains useful for legally clear props, not as an automatic replacement for the character pipeline.

Sources:

- https://github.com/toxsam/open-source-3D-assets
- https://raw.githubusercontent.com/ToxSam/open-source-3D-assets/main/data/projects.json

## Realistic humanoid option

The MakeHuman Community FAQ states that exported models are licensed CC0 and may be copied, modified, distributed, and used commercially. This is a legally clear route for producing more realistic human bases, but the sandbox does not currently contain a ready MakeHuman export or a complete clothing/robe asset. Therefore the immediate Phase 8 implementation focuses on material/lighting upgrades and keeps the proportional humanoid rig as the runtime base; a MakeHuman-generated GLB can be added later without changing the character integration contract.

Source: https://static.makehumancommunity.org/oldsite/faq/can_i_sell_models_created_with_makehuman.html

## Runtime visual verification

The converted `PavingStones036_Color.png` is a valid 512×512 stone albedo with moss/stone variation, not a checkerboard. The Xvfb StarterWorld capture shows the PBR paving material correctly on the town walkways and road. The red checkerboard in the foreground is a separate runtime surface/placement issue rather than the albedo file; the water shader itself compiles without errors in Godot Compatibility. The capture also confirms the cinematic dawn sky, darker palette, specular highlights, and anchored HUD.

The Compatibility renderer reports that SSAO is Forward+ only, so SSAO is configured but automatically unavailable in the mobile compatibility capture; the remaining atmosphere uses Filmic tonemapping, fog, glow, adjusted saturation/contrast, directional soft shadows, and material response.

## Final implementation and verification note

The final runtime keeps the river shader enabled and uses a Compatibility-safe `PlaneMesh` layout for terrain, with ambientCG PBR maps reserved for the main road material where they render correctly. The broad courtyard uses a texture-free StandardMaterial3D to avoid making the mobile Compatibility path depend on unsupported post-processing or texture combinations. Ground collision was restored after diagnostics, and both world and mandatory character-selection smoke tests pass with no parse or gameplay errors.

The red checkerboard remains visible only in the local llvmpipe/Xvfb capture foreground after isolating the declared surfaces, models, water, Glow, and collision shape. It is therefore tracked as a software-renderer capture artifact rather than silently claimed as fixed; the APK should be validated on a physical Android GPU in the next QA pass.
