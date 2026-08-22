class_name VisualAssetLoader
extends RefCounted

## Phase 10.2 visual asset registry + loader.
## Reads assets/visual_asset_manifest.json, caches PackedScenes, resolves logical
## asset keys through their fallback chain, and exposes compatibility shims that
## mirror asset_loader.gd so existing callers keep working unchanged.

const MANIFEST_PATH := "res://assets/visual_asset_manifest.json"
const DEFAULT_ASSET_KEY := "characters/western/western_wizard"

static var _manifest: Dictionary = {}
static var _manifest_loaded := false
static var _scene_cache := {}

static func manifest() -> Dictionary:
	if _manifest_loaded:
		return _manifest
	_manifest_loaded = true
	_manifest = {}
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		push_error("VisualAssetLoader: manifest not found at %s" % MANIFEST_PATH)
		return _manifest
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_manifest = parsed
	else:
		push_error("VisualAssetLoader: manifest JSON at %s is invalid" % MANIFEST_PATH)
	return _manifest

static func has_manifest() -> bool:
	return (manifest().get("assets", []) as Array).size() > 0

static func _entry(key: String) -> Dictionary:
	var needle := String(key).to_lower()
	for entry in manifest().get("assets", []):
		if str(entry.get("asset_key", "")).to_lower() == needle:
			return entry
	return {}

static func resolve_chain(key: String) -> Array:
	var chain: Array = []
	var seen := {}
	var current := String(key)
	var guard := 0
	while guard < 16:
		if current.is_empty() or seen.has(current):
			break
		seen[current] = true
		chain.append(current)
		var entry := _entry(current)
		if entry.is_empty():
			break
		var fallback := str(entry.get("fallback_key", ""))
		if fallback.is_empty():
			break
		current = fallback
		guard += 1
	return chain

static func resolve(key: String) -> String:
	var chain := resolve_chain(key)
	for candidate in chain:
		if not str(_entry(candidate).get("path", "")).is_empty():
			return candidate
	if not chain.is_empty():
		return chain[0]
	return DEFAULT_ASSET_KEY

static func _scene(path: String) -> PackedScene:
	if path.is_empty():
		return null
	if _scene_cache.has(path):
		return _scene_cache[path]
	var packed: PackedScene = load(path)
	if packed == null:
		push_error("VisualAssetLoader: failed to load scene %s" % path)
		return null
	_scene_cache[path] = packed
	return packed

static func _scene_for_key(key: String) -> PackedScene:
	for candidate in resolve_chain(key):
		var entry := _entry(candidate)
		var path := str(entry.get("path", ""))
		if path.is_empty():
			continue
		var packed := _scene(path)
		if packed != null:
			return packed
	return null

static func instantiate(key: String) -> Node3D:
	var resolved := resolve(key)
	var packed := _scene_for_key(key)
	if packed == null:
		push_error("VisualAssetLoader: no loadable scene for key %s (fallbacks exhausted)" % key)
		return null
	var entry := _entry(resolved)
	var instance: Node3D = packed.instantiate()
	instance.name = "VisualAsset(%s)" % resolved
	var scale := float(entry.get("base_scale", 1.0))
	if scale != 1.0:
		instance.scale = Vector3.ONE * scale
	var pos = entry.get("position_offset", {})
	if pos is Dictionary and not pos.is_empty():
		instance.position = Vector3(float(pos.get("x", 0.0)), float(pos.get("y", 0.0)), float(pos.get("z", 0.0)))
	var rot = entry.get("rotation_offset", {})
	if rot is Dictionary and not rot.is_empty():
		instance.rotation_degrees = Vector3(float(rot.get("x", 0.0)), float(rot.get("y", 0.0)), float(rot.get("z", 0.0)))
	return instance

static func has_key(key: String) -> bool:
	return not _entry(key).is_empty()

static func fallback_key(key: String) -> String:
	return str(_entry(key).get("fallback_key", ""))

static func animation_map(key: String) -> Dictionary:
	var map = _entry(resolve(key)).get("animation_map", {})
	return map if map is Dictionary else {}

static func socket_map(key: String) -> Dictionary:
	var map = _entry(resolve(key)).get("socket_map", {})
	return map if map is Dictionary else {}

static func two_handed(key: String) -> bool:
	return bool(_entry(resolve(key)).get("two_handed", false))

static func type_of(key: String) -> String:
	return str(_entry(resolve(key)).get("type", ""))

static func preload_assets(keys: Array) -> void:
	for key in keys:
		_scene_for_key(key)

# --- Compatibility shims (mirror asset_loader.gd) ---

static func instantiate_humanoid(build_id := "") -> Node3D:
	var key := "characters/eastern/eastern_spear_warrior"
	if str(build_id).to_lower() in ["wizard", "european_wizard", "staff"]:
		key = "characters/western/western_wizard"
	var instance := instantiate(key)
	if instance != null:
		instance.name = "CelestialHumanoid"
	return instance

static func instantiate_monster() -> Node3D:
	var instance := instantiate("monsters/eastern/mangyang_01")
	if instance != null:
		instance.name = "Mangyang"
	return instance

static func instantiate_weapon(build_id: String) -> Node3D:
	var key := "weapons/spear/eastern_spear_01"
	if str(build_id).to_lower() in ["wizard", "european_wizard", "staff"]:
		key = "weapons/staff/western_staff_01"
	var instance := instantiate(key)
	if instance != null:
		instance.name = "CelestialWeapon"
	return instance
