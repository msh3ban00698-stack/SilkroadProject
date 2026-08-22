class_name CharacterSelect
extends Node3D

signal select_requested(slot: int)
signal create_requested(char_name: String, model: int, scale: int, items: Array[int])
signal enter_requested(slot: int)

const MODEL_IDS := [1907, 1908, 1473]
const WEAPON_IDS := [3630, 3631, 3632]
const OUTFIT_IDS := [1035, 1036, 1037]

var preview_body
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
    env.ambient_light_color = Color("#7894c4")
    env.ambient_light_energy = 0.4
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.tonemap_exposure = 0.82
    env.tonemap_white = 1.6
    env.fog_enabled = true
    env.fog_light_color = Color("#55739c")
    env.fog_light_energy = 0.32
    env.fog_density = 0.006
    env.fog_sky_affect = 0.4
    env.ssao_enabled = true
    env.ssao_radius = 1.6
    env.ssao_intensity = 1.15
    env.adjustment_enabled = true
    env.adjustment_contrast = 1.06
    env.adjustment_saturation = 1.04
    environment.environment = env
    add_child(environment)

    var key := DirectionalLight3D.new()
    key.rotation_degrees = Vector3(-38, -28, 0)
    key.light_color = Color("#f0c984")
    key.light_energy = 0.84
    key.shadow_enabled = true
    add_child(key)

    var fill := OmniLight3D.new()
    fill.position = Vector3(1.5, 2.0, 2.0)
    fill.light_color = Color("#70dfff")
    fill.light_energy = 1.35
    fill.omni_range = 8.0
    add_child(fill)

    var camera := Camera3D.new()
    camera.position = Vector3(-1.15, 1.55, 7.2)
    camera.look_at_from_position(camera.position, Vector3(-1.15, 1.2, 0))
    camera.current = true
    add_child(camera)

    var floor := MeshInstance3D.new()
    var floor_mesh := CylinderMesh.new()
    floor_mesh.top_radius = 2.2
    floor_mesh.bottom_radius = 2.2
    floor_mesh.height = 0.18
    floor.mesh = floor_mesh
    floor.position.y = -0.12
    floor.material_override = _material(Color("#1d2a43"), 0.38, 0.18)
    add_child(floor)

    preview_body = load("res://humanoid_model.gd").new()
    preview_body.configure_build({"class_id": "wizard", "race": "European", "outfit": "Arcane Regalia"})
    preview_body.position = Vector3(3.2, 0.02, -0.25)
    preview_body.scale = Vector3.ONE * 1.05
    add_child(preview_body)

func _build_ui() -> void:
    var canvas := CanvasLayer.new()
    canvas.layer = 10
    add_child(canvas)

    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 64)
    margin.add_theme_constant_override("margin_right", 64)
    margin.add_theme_constant_override("margin_top", 44)
    margin.add_theme_constant_override("margin_bottom", 44)
    canvas.add_child(margin)

    var root := HBoxContainer.new()
    root.add_theme_constant_override("separation", 34)
    root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    root.size_flags_vertical = Control.SIZE_EXPAND_FILL
    margin.add_child(root)

    var left := VBoxContainer.new()
    left.custom_minimum_size = Vector2(460, 0)
    left.size_flags_horizontal = Control.SIZE_FILL
    left.add_theme_constant_override("separation", 10)
    root.add_child(left)
    var title := Label.new()
    title.text = "✦  CELESTIAL ASCENSION"
    title.add_theme_font_size_override("font_size", 27)
    title.add_theme_color_override("font_color", Color("#f2c66d"))
    left.add_child(title)
    var caption := Label.new()
    caption.text = "Choose the constellation that will carry your legend"
    caption.add_theme_color_override("font_color", Color("#a9b7d1"))
    left.add_child(caption)
    list_box = VBoxContainer.new()
    list_box.add_theme_constant_override("separation", 8)
    left.add_child(list_box)
    var list_hint := Label.new()
    list_hint.text = "No character data yet. Requesting Agent list..."
    list_hint.name = "ListHint"
    list_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    list_hint.add_theme_color_override("font_color", Color("#8d9bb8"))
    list_box.add_child(list_hint)
    enter_button = Button.new()
    enter_button.text = "ENTER THE SANCTUM"
    enter_button.disabled = true
    enter_button.custom_minimum_size = Vector2(0, 52)
    enter_button.add_theme_stylebox_override("normal", _panel_style(Color("#26365a"), Color("#e7c77b"), 10, 2))
    enter_button.add_theme_color_override("font_color", Color("#fff1c2"))
    enter_button.pressed.connect(func():
        if selected_slot >= 0:
            enter_requested.emit(selected_slot)
    )
    left.add_child(enter_button)

    var panel := PanelContainer.new()
    panel.add_theme_stylebox_override("panel", _panel_style(Color("#101625e8"), Color("#80643b"), 20, 2))
    panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    panel.custom_minimum_size = Vector2(660, 0)
    root.add_child(panel)
    var panel_margin := MarginContainer.new()
    panel_margin.add_theme_constant_override("margin_left", 26)
    panel_margin.add_theme_constant_override("margin_right", 26)
    panel_margin.add_theme_constant_override("margin_top", 26)
    panel_margin.add_theme_constant_override("margin_bottom", 26)
    panel.add_child(panel_margin)
    var form := VBoxContainer.new()
    form.add_theme_constant_override("separation", 12)
    panel_margin.add_child(form)
    var form_title := Label.new()
    form_title.text = "FORGE A CELESTIAL HERO"
    form_title.add_theme_font_size_override("font_size", 23)
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
    form.add_child(scale_label)
    scale_slider = HSlider.new()
    scale_slider.min_value = 0
    scale_slider.max_value = 68
    scale_slider.value = 50
    scale_slider.custom_minimum_size = Vector2(0, 36)
    scale_slider.value_changed.connect(func(_value): _refresh_preview())
    form.add_child(scale_slider)
    var create := Button.new()
    create.text = "FORGE CHARACTER"
    create.custom_minimum_size = Vector2(0, 54)
    create.add_theme_stylebox_override("normal", _panel_style(Color("#26365a"), Color("#e7c77b"), 10, 2))
    create.add_theme_color_override("font_color", Color("#fff1c2"))
    create.pressed.connect(_on_create_pressed)
    form.add_child(create)
    status_label = Label.new()
    status_label.text = "Character IDs are validated by the Agent database."
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status_label.add_theme_color_override("font_color", Color("#9eb2d5"))
    form.add_child(status_label)

func _field(parent: VBoxContainer, label_text: String, value: String) -> LineEdit:
    var label := Label.new()
    label.text = label_text
    parent.add_child(label)
    var edit := LineEdit.new()
    edit.text = value
    edit.add_theme_stylebox_override("normal", _panel_style(Color("#0b1120"), Color("#80643b"), 8, 1))
    edit.add_theme_color_override("font_color", Color("#f2e6c5"))
    edit.custom_minimum_size = Vector2(0, 48)
    parent.add_child(edit)
    return edit

func _option(parent: VBoxContainer, label_text: String, values: Array[String]) -> OptionButton:
    var label := Label.new()
    label.text = label_text
    parent.add_child(label)
    var option := OptionButton.new()
    option.add_theme_stylebox_override("normal", _panel_style(Color("#0b1120"), Color("#80643b"), 8, 1))
    option.add_theme_color_override("font_color", Color("#f2e6c5"))
    for value in values:
        option.add_item(value)
    option.custom_minimum_size = Vector2(0, 46)
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
        button.custom_minimum_size = Vector2(0, 54)
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
