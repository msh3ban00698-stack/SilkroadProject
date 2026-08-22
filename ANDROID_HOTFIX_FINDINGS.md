# Android Hotfix Findings

## Diagnosis

`project.godot` already uses `res://main.tscn`, `gl_compatibility`, and `gl_compatibility` for the mobile rendering method. `main.tscn` exists and its root Control is full-rect. `asset_loader.gd` has no network or heavy asset request; it returns null for legacy imported assets. Protected autoload/logic paths were not changed by the Phase 9 visual commit.

The release-blocking risk was startup ordering: the entry scene built the login layer and then the mandatory Character Select scene could synchronously construct a WorldEnvironment, camera, 3D preview, particles, and upgraded materials before Android had painted a stable first frame. The hotfix makes the application boot directly to Character Select and makes Character Select UI-first: Canvas/UI are built synchronously, while the 3D preview is created from a deferred callback after the first frame.

## Verification

Running the real `main.tscn` with `--rendering-method gl_compatibility --rendering-driver opengl3` produces a visible Celestial Character Select frame locally. Headless startup exits successfully without Parse Error, Script Error, Invalid property, or Invalid call output. The image is captured at `/tmp/android_hotfix_boot.png`.
