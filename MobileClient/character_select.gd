class_name CharacterSelect
extends Node3D

signal select_requested(slot: int)
signal create_requested(char_name: String, model: int, scale: int, items: Array[int])
signal enter_requested(slot: int)

const MODEL_IDS := [1907, 1908, 1473]
const WEAPON_IDS := [3630, 3631, 3632]
const OUTFIT_IDS := [1035, 1036, 1037]
const UI_SCALE := 2.5

var preview_body
var preview_root: Node3D
var podium_light: OmniLight3D
var hp_bar: ProgressBar
var mp_bar: ProgressBar
var hp_value_label: Label
var mp_value_label: Label
var character_list: Array = []
var list_box: VBoxContainer
var name_edit: LineEdit
var race_select: OptionButton
var weapon_select: OptionButton
var build_select: OptionButton
var outfit_select: OptionButton
var scale_slider: HSlider
var status_label: Label
var enter_button: Button
var selected_slot := -1
var offline_mode := false

func _ready() -> void:
    # Android hotfix: paint the selection UI first; defer 3D preview construction.
    _build_ui()
    call_deferred("_build_preview_after_first_frame")

func _build_preview_after_first_frame() -> void:
    if not is_inside_tree():
        return
    _build_preview()
    _refresh_preview()

func _build_preview() -> void:
    var environment := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var sky_material := ProceduralSkyMaterial.new()
    sky_material.sky_top_color = Color("#020713")
    sky_material.sky_horizon_color = Color("#405f86")
    sky_material.ground_bottom_color = Color("#050a18")
    sky_material.ground_horizon_color = Color("#1d2947")
    sky.sky_material = sky_material
    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("#d8b08c")
    env.ambient_light_energy = 0.55
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.tonemap_exposure = 0.82
    env.tonemap_white = 1.6
    env.fog_enabled = true
    env.fog_light_color = Color("#55739c")
    env.fog_light_energy = 0.32
    env.fog_density = 0.006
    env.fog_sky_affect = 0.4
    env.adjustment_enabled = true
    env.adjustment_contrast = 1.06
    env.adjustment_saturation = 1.04
    environment.environment = env
    add_child(environment)

    var key := DirectionalLight3D.new()
    key.rotation_degrees = Vector3(-38, -28, 0)
    key.light_color = Color("#f0c984")
    key.light_energy = 0.9
    key.shadow_enabled = true
    key.directional_shadow_max_distance = 40.0
    key.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
    add_child(key)

    var rim := DirectionalLight3D.new()
    rim.rotation_degrees = Vector3(-12, 138, 0)
    rim.light_color = Color("#ffb37a")
    rim.light_energy = 1.15
    rim.shadow_enabled = false
    add_child(rim)

    var fill := OmniLight3D.new()
    fill.position = Vector3(1.5, 2.0, 2.0)
    fill.light_color = Color("#70dfff")
    fill.light_energy = 1.05
    fill.omni_range = 8.0
    add_child(fill)

    var camera := Camera3D.new()
    camera.position = Vector3(0, 1.7, 7.6)
    camera.look_at_from_position(camera.position, Vector3(0, 1.3, 0))
    camera.fov = 42.0
    camera.current = true
    add_child(camera)

    preview_root = Node3D.new()
    add_child(preview_root)

    var stage_base := MeshInstance3D.new()
    var stage_base_mesh := CylinderMesh.new()
    stage_base_mesh.top_radius = 3.4
    stage_base_mesh.bottom_radius = 3.7
    stage_base_mesh.height = 0.5
    stage_base_mesh.radial_segments = 48
    stage_base.mesh = stage_base_mesh
    stage_base.position = Vector3(0, -0.25, 0)
    stage_base.material_override = _material(Color("#2b3b5a"), 0.42, 0.2)
    preview_root.add_child(stage_base)

    var stage_ring := MeshInstance3D.new()
    var stage_ring_mesh := TorusMesh.new()
    stage_ring_mesh.inner_radius = 2.2
    stage_ring_mesh.outer_radius = 2.32
    stage_ring_mesh.rings = 40
    stage_ring_mesh.ring_segments = 20
    stage_ring.mesh = stage_ring_mesh
    stage_ring.position = Vector3(0, 0.2, 0)
    stage_ring.material_override = _material(Color("#e2bc6e"), 0.6, 0.18)
    preview_root.add_child(stage_ring)

    var top := MeshInstance3D.new()
    var top_mesh := CylinderMesh.new()
    top_mesh.top_radius = 2.2
    top_mesh.bottom_radius = 2.35
    top_mesh.height = 0.3
    top_mesh.radial_segments = 48
    top.mesh = top_mesh
    top.position = Vector3(0, 0.08, 0)
    top.material_override = _material(Color("#1d2a43"), 0.38, 0.18)
    preview_root.add_child(top)

    podium_light = OmniLight3D.new()
    podium_light.position = Vector3(0, 0.55, 0)
    podium_light.light_color = Color("#ffcf8a")
    podium_light.light_energy = 0.9
    podium_light.omni_range = 3.0
    preview_root.add_child(podium_light)

    preview_body = load("res://humanoid_model.gd").new()
    preview_body.configure_build({"class_id": "wizard", "race": "European", "outfit": "Arcane Regalia"})
    preview_body.position = Vector3(0, 0.3, 0)
    preview_body.scale = Vector3.ONE * 1.05
    preview_root.add_child(preview_body)

func _fs(points: int) -> int:
    return int(round(float(points) * UI_SCALE))

func _px(points: float) -> float:
    return points * UI_SCALE

func _build_ui() -> void:
    var canvas := CanvasLayer.new()
    canvas.layer = 10
    add_child(canvas)

    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", _px(48))
    margin.add_theme_constant_override("margin_right", _px(48))
    margin.add_theme_constant_override("margin_top", _px(36))
    margin.add_theme_constant_override("margin_bottom", _px(36))
    canvas.add_child(margin)

    var root := HBoxContainer.new()
    root.add_theme_constant_override("separation", _px(30))
    root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    root.size_flags_vertical = Control.SIZE_EXPAND_FILL
    margin.add_child(root)

    var left := VBoxContainer.new()
    left.custom_minimum_size = Vector2(_px(300), 0)
    left.size_flags_horizontal = Control.SIZE_FILL
    left.add_theme_constant_override("separation", _px(10))
    root.add_child(left)
    var title := Label.new()
    title.text = "✦  CELESTIAL ASCENSION"
    title.add_theme_font_size_override("font_size", _fs(27))
    title.add_theme_color_override("font_color", Color("#f2c66d"))
    left.add_child(title)
    var caption := Label.new()
    caption.text = "Choose the constellation that will carry your legend"
    caption.add_theme_font_size_override("font_size", _fs(16))
    caption.add_theme_color_override("font_color", Color("#a9b7d1"))
    left.add_child(caption)
    list_box = VBoxContainer.new()
    list_box.add_theme_constant_override("separation", _px(8))
    left.add_child(list_box)
    var list_hint := Label.new()
    list_hint.text = "No character data yet. Requesting Agent list..."
    list_hint.name = "ListHint"
    list_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    list_hint.add_theme_font_size_override("font_size", _fs(14))
    list_hint.add_theme_color_override("font_color", Color("#8d9bb8"))
    list_box.add_child(list_hint)
    enter_button = Button.new()
    enter_button.text = "ENTER THE SANCTUM"
    enter_button.disabled = true
    enter_button.custom_minimum_size = Vector2(0, _px(52))
    enter_button.add_theme_font_size_override("font_size", _fs(17))
    enter_button.add_theme_stylebox_override("normal", _panel_style(Color("#26365a"), Color("#e7c77b"), 10, 2))
    enter_button.add_theme_color_override("font_color", Color("#fff1c2"))
    enter_button.pressed.connect(func():
        if selected_slot >= 0:
            enter_requested.emit(selected_slot)
    )
    left.add_child(enter_button)

    var stats_panel := PanelContainer.new()
    stats_panel.add_theme_stylebox_override("panel", _panel_style(Color("#101625e8"), Color("#80643b"), 16, 2))
    left.add_child(stats_panel)
    var stats_margin := MarginContainer.new()
    stats_margin.add_theme_constant_override("margin_left", _px(16))
    stats_margin.add_theme_constant_override("margin_right", _px(16))
    stats_margin.add_theme_constant_override("margin_top", _px(12))
    stats_margin.add_theme_constant_override("margin_bottom", _px(12))
    stats_panel.add_child(stats_margin)
    var stats := VBoxContainer.new()
    stats.add_theme_constant_override("separation", _px(8))
    stats_margin.add_child(stats)
    var stats_title := Label.new()
    stats_title.text = "STATS"
    stats_title.add_theme_font_size_override("font_size", _fs(15))
    stats_title.add_theme_color_override("font_color", Color("#f2c66d"))
    stats.add_child(stats_title)
    hp_bar = _stat_bar(stats, Color("#9d4255"))
    hp_value_label = _stat_value_label(stats, "HP  120 / 120")
    mp_bar = _stat_bar(stats, Color("#3b72a4"))
    mp_value_label = _stat_value_label(stats, "MP  82 / 82")

    var panel := PanelContainer.new()
    panel.add_theme_stylebox_override("panel", _panel_style(Color("#101625e8"), Color("#80643b"), 20, 2))
    panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    panel.custom_minimum_size = Vector2(_px(400), 0)
    root.add_child(panel)
    var panel_margin := MarginContainer.new()
    panel_margin.add_theme_constant_override("margin_left", _px(26))
    panel_margin.add_theme_constant_override("margin_right", _px(26))
    panel_margin.add_theme_constant_override("margin_top", _px(26))
    panel_margin.add_theme_constant_override("margin_bottom", _px(26))
    panel.add_child(panel_margin)
    var form := VBoxContainer.new()
    form.add_theme_constant_override("separation", _px(12))
    panel_margin.add_child(form)
    var form_title := Label.new()
    form_title.text = "FORGE A CELESTIAL HERO"
    form_title.add_theme_font_size_override("font_size", _fs(23))
    form_title.add_theme_color_override("font_color", Color("#f2c66d"))
    form.add_child(form_title)
    name_edit = _field(form, "Character name", "Aurelia")
    build_select = _option(form, "Build", ["European Wizard", "Chinese Spear"])
    build_select.item_selected.connect(_apply_build_selection)
    race_select = _option(form, "Race / lineage", ["European", "Chinese"])
    weapon_select = _option(form, "Weapon", ["Staff", "Spear"])
    outfit_select = _option(form, "Clothing", ["Arcane Regalia", "Jade War Robe"])
    var scale_label := Label.new()
    scale_label.text = "Body scale"
    scale_label.add_theme_font_size_override("font_size", _fs(15))
    form.add_child(scale_label)
    scale_slider = HSlider.new()
    scale_slider.min_value = 0
    scale_slider.max_value = 68
    scale_slider.value = 50
    scale_slider.custom_minimum_size = Vector2(0, _px(36))
    scale_slider.value_changed.connect(func(_value): _refresh_preview())
    form.add_child(scale_slider)
    var create := Button.new()
    create.text = "FORGE CHARACTER"
    create.custom_minimum_size = Vector2(0, _px(54))
    create.add_theme_font_size_override("font_size", _fs(17))
    create.add_theme_stylebox_override("normal", _panel_style(Color("#26365a"), Color("#e7c77b"), 10, 2))
    create.add_theme_color_override("font_color", Color("#fff1c2"))
    create.pressed.connect(_on_create_pressed)
    form.add_child(create)
    status_label = Label.new()
    status_label.text = "Character IDs are validated by the Agent database."
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status_label.add_theme_font_size_override("font_size", _fs(14))
    status_label.add_theme_color_override("font_color", Color("#9eb2d5"))
    form.add_child(status_label)

func _stat_bar(parent: VBoxContainer, color: Color) -> ProgressBar:
    var bar := ProgressBar.new()
    bar.max_value = 100
    bar.value = 100
    bar.custom_minimum_size = Vector2(_px(280), _px(22))
    bar.show_percentage = false
    bar.add_theme_stylebox_override("background", _panel_style(Color("#0b1120"), Color("#80643b"), 7, 1))
    bar.add_theme_stylebox_override("fill", _panel_style(color, Color("#e7c77b"), 7, 1))
    parent.add_child(bar)
    return bar

func _stat_value_label(parent: VBoxContainer, text_value: String) -> Label:
    var label := Label.new()
    label.text = text_value
    label.add_theme_font_size_override("font_size", _fs(13))
    label.add_theme_color_override("font_color", Color("#f2e6c5"))
    parent.add_child(label)
    return label

func _set_stat_values(hp: int, max_hp: int, mp: int, max_mp: int) -> void:
    if hp_bar:
        hp_bar.max_value = max(1, max_hp)
        hp_bar.value = clamp(hp, 0, max_hp)
    if hp_value_label:
        hp_value_label.text = "HP  %d / %d" % [hp, max_hp]
    if mp_bar:
        mp_bar.max_value = max(1, max_mp)
        mp_bar.value = clamp(mp, 0, max_mp)
    if mp_value_label:
        mp_value_label.text = "MP  %d / %d" % [mp, max_mp]

func _field(parent: VBoxContainer, label_text: String, value: String) -> LineEdit:
    var label := Label.new()
    label.text = label_text
    label.add_theme_font_size_override("font_size", _fs(15))
    parent.add_child(label)
    var edit := LineEdit.new()
    edit.text = value
    edit.add_theme_stylebox_override("normal", _panel_style(Color("#0b1120"), Color("#80643b"), 8, 1))
    edit.add_theme_color_override("font_color", Color("#f2e6c5"))
    edit.custom_minimum_size = Vector2(0, _px(48))
    edit.add_theme_font_size_override("font_size", _fs(17))
    parent.add_child(edit)
    return edit

func _option(parent: VBoxContainer, label_text: String, values: Array[String]) -> OptionButton:
    var label := Label.new()
    label.text = label_text
    label.add_theme_font_size_override("font_size", _fs(15))
    parent.add_child(label)
    var option := OptionButton.new()
    option.add_theme_stylebox_override("normal", _panel_style(Color("#0b1120"), Color("#80643b"), 8, 1))
    option.add_theme_color_override("font_color", Color("#f2e6c5"))
    for value in values:
        option.add_item(value)
    option.custom_minimum_size = Vector2(0, _px(46))
    option.add_theme_font_size_override("font_size", _fs(15))
    option.item_selected.connect(func(_index): _refresh_preview())
    parent.add_child(option)
    return option

func set_offline_mode(value: bool) -> void:
    offline_mode = value
    if not offline_mode:
        return
    if status_label:
        status_label.text = "Offline roster: choose a build, customize the name, then enter the world."
    _set_offline_profiles()
    _apply_build_selection(build_select.selected)

func _set_offline_profiles() -> void:
    set_characters([
        {"slot": 0, "name": "European Wizard", "level": 1},
        {"slot": 1, "name": "Chinese Spear", "level": 1}
    ])
    _select_offline_slot(0)

func _select_offline_slot(slot: int) -> void:
    selected_slot = slot
    enter_button.disabled = false
    build_select.select(slot)
    _apply_build_selection(slot)

func _apply_build_selection(index: int) -> void:
    if not build_select or not race_select or not weapon_select or not outfit_select:
        return
    var wizard := index == 0
    race_select.select(0 if wizard else 1)
    weapon_select.select(0 if wizard else 1)
    outfit_select.select(0 if wizard else 1)
    if wizard:
        _set_stat_values(86, 86, 160, 160)
    else:
        _set_stat_values(120, 120, 82, 82)
    _refresh_preview()

func get_offline_character() -> Dictionary:
    var wizard := build_select.selected == 0
    var char_name := name_edit.text.strip_edges()
    return {
        "name": char_name,
        "class_id": "wizard" if wizard else "spear",
        "build": "European Wizard" if wizard else "Chinese Spear",
        "race": "European" if wizard else "Chinese",
        "weapon": "Staff" if wizard else "Spear",
        "outfit": "Arcane Regalia" if wizard else "Jade War Robe",
        "hp": 86 if wizard else 120,
        "mp": 160 if wizard else 82,
        "level": 1,
        "exp": 0,
        "gold": 0,
        "skill_points": 3
    }

func _on_create_pressed() -> void:
    var char_name := name_edit.text.strip_edges()
    if char_name.length() < 3 or char_name.length() > 12:
        status_label.text = "Name must contain 3 to 12 characters."
        return
    var items := [WEAPON_IDS[weapon_select.selected], OUTFIT_IDS[outfit_select.selected], OUTFIT_IDS[outfit_select.selected], WEAPON_IDS[weapon_select.selected]]
    create_requested.emit(char_name, MODEL_IDS[race_select.selected], int(scale_slider.value), items)
    status_label.text = "Creation request sent to Agent..."

func set_characters(characters: Array) -> void:
    character_list = characters
    for child in list_box.get_children():
        child.queue_free()
    for character in character_list:
        var button := Button.new()
        button.text = "✦  Slot %d  •  %s  •  Lv.%d" % [character.slot + 1, character.name, character.level]
        button.add_theme_stylebox_override("normal", _panel_style(Color("#18213a"), Color("#80643b"), 10, 1))
        button.add_theme_stylebox_override("hover", _panel_style(Color("#26365a"), Color("#f2c66d"), 10, 2))
        button.add_theme_color_override("font_color", Color("#f2e6c5"))
        button.custom_minimum_size = Vector2(0, _px(52))
        button.add_theme_font_size_override("font_size", _fs(16))
        button.pressed.connect(func():
            selected_slot = character.slot
            enter_button.disabled = false
            if offline_mode:
                _select_offline_slot(character.slot)
            select_requested.emit(character.slot)
        )
        list_box.add_child(button)
    if character_list.is_empty():
        var empty := Label.new()
        empty.text = "No characters found. Create your first hero."
        empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        list_box.add_child(empty)

func set_status(text: String) -> void:
    if status_label:
        status_label.text = text

func _refresh_preview() -> void:
    if preview_body == null:
        return
    var wizard := build_select.selected == 0
    preview_body.configure_build({
        "class_id": "wizard" if wizard else "spear",
        "race": "European" if wizard else "Chinese",
        "outfit": "Arcane Regalia" if wizard else "Jade War Robe"
    })
    preview_body.scale = Vector3.ONE * (1.16 + scale_slider.value / 300.0)

func _panel_style(fill: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = fill
    style.border_color = border
    style.set_border_width_all(width)
    style.set_corner_radius_all(radius)
    style.shadow_color = Color(0, 0, 0, 0.42)
    style.shadow_size = 8
    return style

func _material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = metallic
    material.roughness = roughness
    return material
