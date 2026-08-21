# Phase 9 Asset Research Notes

## Verified sources

Quaternius RPG Character Pack: https://quaternius.com/packs/rpgcharacters.html. The primary page states that the pack contains six rigged, animated, textured fantasy characters, supports FBX/OBJ/Blend/glTF formats, and is licensed CC0. The page describes the pack as usable in personal and commercial projects.

OpenGameArt CC0 humanoid collection: https://opengameart.org/content/3d-humanoids-under-cc0. The collection is explicitly presented as CC0 and lists multiple rigged or animated humanoid entries, including a mid-poly rigged knight. The collection is useful as a legally clear fallback, but many entries are visibly low-poly and may not satisfy the Phase 9 high-end target without substantial material and silhouette treatment.

## Phase 9 direction

The implementation must preserve the existing SRO-style logic and focus changes on visual scripts, asset loading, materials, VFX, world construction, and HUD styling. Candidate external humanoid assets will be evaluated for mobile suitability, license clarity, rig availability, and whether they can be integrated without changing gameplay state or packet handlers.


## Visual QA findings

The Phase 9 Starter World capture now shows the celestially themed sanctum dais, moon gate, floating crystal islands, teal-and-gold creature palette, ornate HUD, and water strip without script errors. The red checkerboard foreground persists after adding a dedicated compatibility-safe celestial stone apron, so it is not caused by the new sanctum geometry; it remains tracked as a local Xvfb/llvmpipe capture artifact.

Character Select uses the same celestial palette and premium panel treatment. The preview composition is being tuned independently because the CanvasLayer form can occlude the 3D preview in the software capture; this does not affect the mandatory selection or creation contract.
