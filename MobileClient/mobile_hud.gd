class_name MobileHUD
extends CanvasLayer

signal action_requested(action: String)
signal inventory_requested()

var hp_bar: ProgressBar
var mp_bar: ProgressBar
var hp_label: Label
var mp_label: Label
var minimap: MinimapView
var joystick: VirtualJoystick
var status_label: Label
var target_panel: VBoxContainer
var target_bar: ProgressBar
var target_label: Label

func _ready() -> void:
    layer = 20
    _build_hud()

func _build_hud() -> void:
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(root)

    var top := VBoxContainer.new()
    top.position = Vector2(24, 22)
    top.custom_minimum_size = Vector2(300, 112)
    top.add_theme_constant_override("separation", 7)
    root.add_child(top)
    var title := Label.new()
    title.text = "JANGAN OUTSKIRTS"
    title.add_theme_font_size_override("font_size", 19)
    title.add_theme_color_override("font_color", Color("#f2c66d"))
    top.add_child(title)
    hp_bar = _bar(top, Color("#d94f5c"))
    hp_label = Label.new()
    hp_label.text = "HP  100 / 100"
    hp_label.position = Vector2(12, 25)
    hp_label.add_theme_font_size_override("font_size", 13)
    hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hp_bar.add_child(hp_label)
    mp_bar = _bar(top, Color("#4e91e8"))
    mp_label = Label.new()
    mp_label.text = "MP  100 / 100"
    mp_label.position = Vector2(12, 25)
    mp_label.add_theme_font_size_override("font_size", 13)
    mp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    mp_bar.add_child(mp_label)
    _build_target_panel(root)

    var minimap := MinimapView.new()
    minimap.position = Vector2(-8, 18)
    minimap.anchor_left = 1.0
    minimap.anchor_right = 1.0
    minimap.offset_left = -235
    minimap.offset_right = -18
    minimap.custom_minimum_size = Vector2(220, 220)
    root.add_child(minimap)

    joystick = VirtualJoystick.new()
    joystick.position = Vector2(22, -198)
    joystick.anchor_top = 1.0
    joystick.anchor_bottom = 1.0
    joystick.custom_minimum_size = Vector2(250, 250)
    root.add_child(joystick)

    var actions := HBoxContainer.new()
    actions.position = Vector2(-480, -190)
    actions.anchor_left = 1.0
    actions.anchor_right = 1.0
    actions.anchor_top = 1.0
    actions.anchor_bottom = 1.0
    actions.add_theme_constant_override("separation", 12)
    root.add_child(actions)
    _action_button(actions, "ATTACK", "attack", Color("#c95a4d"))
    _action_button(actions, "POTION", "potion", Color("#4fa97c"))
    _action_button(actions, "SKILL", "skill", Color("#a765c9"))
    _action_button(actions, "PICKUP", "pickup", Color("#b58a47"))
    _action_button(actions, "BAG", "bag", Color("#527aa9"))

    status_label = Label.new()
    status_label.position = Vector2(24, -78)
    status_label.anchor_top = 1.0
    status_label.anchor_bottom = 1.0
    status_label.add_theme_color_override("font_color", Color("#c8d7ee"))
    status_label.add_theme_font_size_override("font_size", 15)
    root.add_child(status_label)

func _build_target_panel(root: Control) -> void:
    target_panel = VBoxContainer.new()
    target_panel.position = Vector2(0, 26)
    target_panel.anchor_left = 0.5
    target_panel.anchor_right = 0.5
    target_panel.offset_left = -130
    target_panel.offset_right = 130
    target_panel.add_theme_constant_override("separation", 5)
    root.add_child(target_panel)
    target_label = Label.new()
    target_label.text = "NO TARGET"
    target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    target_label.add_theme_color_override("font_color", Color("#f2c66d"))
    target_panel.add_child(target_label)
    target_bar = ProgressBar.new()
    target_bar.max_value = 100
    target_bar.value = 0
    target_bar.show_percentage = false
    target_bar.custom_minimum_size = Vector2(260, 20)
    target_bar.add_theme_stylebox_override("background", _bar_style(Color("#261521")))
    target_bar.add_theme_stylebox_override("fill", _bar_style(Color("#d94f5c")))
    target_panel.add_child(target_bar)

func _bar_style(color: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.set_corner_radius_all(8)
    return style

func _bar(parent: VBoxContainer, color: Color) -> ProgressBar:
    var bar := ProgressBar.new()
    bar.max_value = 100
    bar.value = 100
    bar.custom_minimum_size = Vector2(300, 30)
    bar.show_percentage = false
    var background := StyleBoxFlat.new()
    background.bg_color = Color("#1c2740")
    background.set_corner_radius_all(8)
    var fill := StyleBoxFlat.new()
    fill.bg_color = color
    fill.set_corner_radius_all(8)
    bar.add_theme_stylebox_override("background", background)
    bar.add_theme_stylebox_override("fill", fill)
    parent.add_child(bar)
    return bar

func _action_button(parent: HBoxContainer, text: String, action: String, color: Color) -> void:
    var button := Button.new()
    button.text = text
    button.custom_minimum_size = Vector2(82, 82)
    button.add_theme_font_size_override("font_size", 13)
    var normal := StyleBoxFlat.new()
    normal.bg_color = color
    normal.set_corner_radius_all(41)
    button.add_theme_stylebox_override("normal", normal)
    button.pressed.connect(func():
        if action == "bag":
            inventory_requested.emit()
        else:
            action_requested.emit(action)
    )
    parent.add_child(button)

func set_stats(hp: int, mp: int, max_hp: int, max_mp: int) -> void:
    hp_bar.max_value = max(1, max_hp)
    hp_bar.value = clamp(hp, 0, max_hp)
    mp_bar.max_value = max(1, max_mp)
    mp_bar.value = clamp(mp, 0, max_mp)
    hp_label.text = "HP  %d / %d" % [hp, max_hp]
    mp_label.text = "MP  %d / %d" % [mp, max_mp]

func set_target(name: String, hp: int, max_hp: int) -> void:
    if target_label:
        target_label.text = name
    if target_bar:
        target_bar.max_value = max(1, max_hp)
        target_bar.value = clamp(hp, 0, max_hp)

func clear_target() -> void:
    if target_label:
        target_label.text = "NO TARGET"
    if target_bar:
        target_bar.value = 0

func set_target_hp(hp: int, max_hp: int) -> void:
    set_target(target_label.text, hp, max_hp)

func set_world_position(position: Vector3) -> void:
    if minimap:
        minimap.set_player_position(position)

func set_status(text: String) -> void:
    if status_label:
        status_label.text = text
