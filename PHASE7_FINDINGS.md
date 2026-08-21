# Phase 7 Findings

## Display verification

`project.godot` now uses a 1920x1080 viewport, `viewport` stretch mode, `expand` aspect, and Landscape handheld orientation. A Godot run inside Xvfb produced a 1920x1080 PNG with no portrait-only black side bars. The first capture showed the login layer because the temporary capture occurred before CharacterSelect appeared; a second capture must wait longer than the 4.5-second transition.

## Asset research

Kenney's official Animated Characters Protagonists page identifies the pack as Creative Commons CC0 and provides a free download. The downloaded archive contained an FBX model and animations, but the Mini Dungeon archive provided smaller GLB assets that import directly in Godot.

Kenney Mini Dungeon is identified on the official page as a 3D pack with animation, variations, weapons and shields, and Creative Commons CC0. The downloaded GLB subset includes `character-human.glb`, `character-orc.glb`, `weapon-spear.glb`, `weapon-sword.glb`, `floor.glb`, `floor-detail.glb`, `rocks.glb`, and `wood-structure.glb`, plus `colormap.png` and `License.txt` files.

## Integration status

`asset_loader.gd` loads the local GLB assets. `HumanoidModel` prefers `character-human.glb` and attaches a downloaded weapon GLB; its procedural Skeleton3D remains only as a fallback. `AnimalMobModel` prefers `character-orc.glb`. StarterWorld adds imported floor-detail, rocks, and wood-structure models. CharacterSelect uses the same imported HumanoidModel preview.

## Sources

- https://kenney.nl/assets/animated-characters-protagonists
- https://kenney.nl/assets/mini-dungeon
- https://quaternius.com/packs/universalbasecharacters.html
- https://quaternius.itch.io/universal-base-characters

## Visual verification updates

The final Xvfb capture is 1920×1080. CharacterSelect fills the landscape canvas with a left slot column, a responsive create-hero panel, a procedural sky, and the imported humanoid preview positioned on the right. The Offline transition now removes CharacterSelect before showing StarterWorld. The final StarterWorld capture shows the imported Kenney orc models, imported world props, anchored HUD/minimap/joystick/action buttons, procedural sky and dressed road/water scene. Exposure and light energy were reduced from the previous overexposed capture while retaining glow for combat VFX.

A headless editor import followed by the world smoke test completes with no script or parse diagnostics. The remaining ALSA messages only indicate that Xvfb has no audio device and Godot falls back to its dummy audio driver.
