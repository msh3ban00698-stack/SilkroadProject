class_name CharacterSelect
extends Node3D

signal select_requested(slot: int)
signal create_requested(char_name: String, model: int, scale: int, items: Array[int])
signal enter_requested(slot: int)

const MODEL_IDS := [1907, 1908, 1473]
const WEAPON_IDS := [3630, 3631, 3632]
const OUTFIT_IDS := [1035, 1036, 1037]

var preview_body: MeshInstance3D
var preview_weapon: MeshInstance3D
var preview_cloak: MeshInstance3D
var character_list: Array = []
var list_box: VBoxContainer
var name_edit: LineEdit
var race_select: OptionButton
var weapon_select: OptionButton
var outfit_select: OptionButton
var scale_slider: HSlider
var status_label: Label
var enter_button: Button
var selected_slot := -1

func _ready() -> void:
    _build_preview()
    _build_ui()

func _build_preview() -> void:
    var environment := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("#11192d")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("#8ca6d9")
    env.ambient_light_energy = 0.8
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    environment.environment = env
    add_child(environment)

    var key := DirectionalLight3D.new()
    key.rotation_degrees = Vector3(-38, -28, 0)
    key.light_color = Color("#ffe2b0")
    key.light_energy = 1.6
    key.shadow_enabled = true
    add_child(key)

    var fill := OmniLight3D.new()
    fill.position = Vector3(1.5, 2.0, 2.0)
    fill.light_color = Color("#5ca9ff")
    fill.light_energy = 3.0
    fill.omni_range = 8.0
    add_child(fill)

    var camera := Camera3D.new()
    camera.position = Vector3(0, 1.6, 5.5)
    camera.look_at_from_position(camera.position, Vector3(0, 1.2, 0))
    camera.current = true
    add_child(camera)

    var floor := MeshInstance3D.new()
    var floor_mesh := CylinderMesh.new()
    floor_mesh.top_radius = 2.2
    floor_mesh.bottom_radius = 2.2
    floor_mesh.height = 0.18
    floor.mesh = floor_mesh
    floor.position.y = -0.12
    floor.material_override = _material(Color("#26365a"), 0.15, 0.2)
    add_child(floor)

    preview_body = MeshInstance3D.new()
    var body_mesh := CapsuleMesh.new()
    body_mesh.height = 1.8
    body_mesh.radius = 0.48
    preview_body.mesh = body_mesh
    preview_body.position.y = 0.92
    preview_body.material_override = _material(Color("#d89168"), 0.55, 0.25)
    add_child(preview_body)

    var head := MeshInstance3D.new()
    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.38
    head_mesh.height = 0.76
    head.mesh = head_mesh
    head.position = Vector3(0, 2.05, 0)
    head.material_override = _material(Color("#e6a47a"), 0.6, 0.2)
    add_child(head)

    preview_weapon = MeshInstance3D.new()
    var blade := BoxMesh.new()
    blade.size = Vector3(0.10, 1.6, 0.12)
    preview_weapon.mesh = blade
    preview_weapon.position = Vector3(0.72, 1.05, 0)
    preview_weapon.rotation_degrees = Vector3(0, 0, -18)
    preview_weapon.material_override = _material(Color("#d8e9ff"), 0.2, 0.75)
    add_child(preview_weapon)

    preview_cloak = MeshInstance3D.new()
    var cloak := CylinderMesh.new()
    cloak.top_radius = 0.54
    cloak.bottom_radius = 0.72
    cloak.height = 1.0
    preview_cloak.mesh = cloak
    preview_cloak.position = Vector3(0, 0.75, 0)
    preview_cloak.material_override = _material(Color("#b5454d"), 0.7, 0.15)
    add_child(preview_cloak)

func _build_ui() -> void:
    var canvas := CanvasLayer.new()
    canvas.layer = 10
    add_child(canvas)

    var root := HBoxContainer.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_theme_constant_override("separation", 18)
    root.add_theme_constant_override("margin_left", 24)
    root.add_theme_constant_override("margin_right", 24)
    root.add_theme_constant_override("margin_top", 24)
    root.add_theme_constant_override("margin_bottom", 24)
    canvas.add_child(root)

    var left := VBoxContainer.new()
    left.custom_minimum_size = Vector2(300, 0)
    left.add_theme_constant_override("separation", 10)
    root.add_child(left)
    var title := Label.new()
    title.text = "CHARACTER SELECT"
    title.add_theme_font_size_override("font_size", 27)
    title.add_theme_color_override("font_color", Color("#f2c66d"))
    left.add_child(title)
    var caption := Label.new()
    caption.text = "Choose a hero for your journey"
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
    enter_button.text = "ENTER SELECTED CHARACTER"
    enter_button.disabled = true
    enter_button.custom_minimum_size = Vector2(0, 52)
    enter_button.pressed.connect(func():
        if selected_slot >= 0:
            enter_requested.emit(selected_slot)
    )
    left.add_child(enter_button)

    var panel := PanelContainer.new()
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.custom_minimum_size = Vector2(360, 0)
    root.add_child(panel)
    var form := VBoxContainer.new()
    form.add_theme_constant_override("separation", 10)
    panel.add_child(form)
    var form_title := Label.new()
    form_title.text = "CREATE NEW HERO"
    form_title.add_theme_font_size_override("font_size", 23)
    form_title.add_theme_color_override("font_color", Color("#f2c66d"))
    form.add_child(form_title)
    name_edit = _field(form, "Character name", "Traveler")
    race_select = _option(form, "Race / body", ["Chinese Warrior", "Chinese Rogue", "European Knight"])
    weapon_select = _option(form, "Weapon", ["Blade", "Bow", "Spear"])
    outfit_select = _option(form, "Clothing", ["Crimson Silk", "Azure Silk", "Jade Traveler"])
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
    create.text = "CREATE CHARACTER"
    create.custom_minimum_size = Vector2(0, 54)
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
    edit.custom_minimum_size = Vector2(0, 48)
    parent.add_child(edit)
    return edit

func _option(parent: VBoxContainer, label_text: String, values: Array[String]) -> OptionButton:
    var label := Label.new()
    label.text = label_text
    parent.add_child(label)
    var option := OptionButton.new()
    for value in values:
        option.add_item(value)
    option.custom_minimum_size = Vector2(0, 46)
    option.item_selected.connect(func(_index): _refresh_preview())
    parent.add_child(option)
    return option

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
        button.text = "Slot %d  •  %s  •  Lv.%d" % [character.slot + 1, character.name, character.level]
        button.custom_minimum_size = Vector2(0, 54)
        button.pressed.connect(func():
            selected_slot = character.slot
            enter_button.disabled = false
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
    var race_colors := [Color("#d89168"), Color("#7fc8b4"), Color("#c9b4df")]
    var weapon_colors := [Color("#d8e9ff"), Color("#f3c75f"), Color("#d77951")]
    var outfit_colors := [Color("#b5454d"), Color("#3676b9"), Color("#4f9b75")]
    preview_body.material_override = _material(race_colors[race_select.selected], 0.55, 0.25)
    preview_weapon.material_override = _material(weapon_colors[weapon_select.selected], 0.2, 0.75)
    preview_cloak.material_override = _material(outfit_colors[outfit_select.selected], 0.7, 0.15)
    preview_body.scale = Vector3(1.0, 0.85 + scale_slider.value / 100.0, 1.0)

func _material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = metallic
    material.roughness = roughness
    return material
