extends CanvasLayer
class_name MobileHUD

signal action_requested(action: String)
signal inventory_requested()

var hp_bar: ProgressBar
var mp_bar: ProgressBar
var exp_bar: ProgressBar
var hp_label: Label
var mp_label: Label
var minimap: MinimapView
var joystick: VirtualJoystick
var status_label: Label
var target_panel: VBoxContainer
var target_bar: ProgressBar
var target_label: Label
var exp_label: Label
var offline_badge: Label

const GOLD := Color("#e7c77b")
const PALE_GOLD := Color("#fff1c2")
const DEEP_STONE := Color("#111625")
const STONE := Color("#1b2233")
const EDGE := Color("#80643b")

func _ready() -> void:
    layer = 20
    _build_hud()

func _build_hud() -> void:
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(root)

    var crest := PanelContainer.new()
    crest.set_anchors_preset(Control.PRESET_TOP_LEFT)
    crest.position = Vector2(20, 18)
    crest.custom_minimum_size = Vector2(342, 150)
    crest.add_theme_stylebox_override("panel", _panel_style(Color("#111725cc"), GOLD, 18, 2))
    root.add_child(crest)
    var top := VBoxContainer.new()
    top.add_theme_constant_override("separation", 5)
    crest.add_child(top)
    var title := Label.new()
    title.text = "✦  CELESTIAL REALM"
    title.add_theme_font_size_override("font_size", 21)
    title.add_theme_color_override("font_color", PALE_GOLD)
    title.add_theme_color_override("font_outline_color", Color("#050816"))
    title.add_theme_constant_override("outline_size", 7)
    top.add_child(title)
    var subtitle := Label.new()
    subtitle.text = "ASTRAL OUTPOST  •  SANCTUM GATE"
    subtitle.add_theme_font_size_override("font_size", 10)
    subtitle.add_theme_color_override("font_color", Color("#8fa6c7"))
    top.add_child(subtitle)
    hp_bar = _bar(top, Color("#9d4255"), "HP")
    hp_label = _bar_label("HP  100 / 100")
    hp_bar.add_child(hp_label)
    mp_bar = _bar(top, Color("#3b72a4"), "MP")
    mp_label = _bar_label("MP  100 / 100")
    mp_bar.add_child(mp_label)
    exp_bar = _bar(top, Color("#a87a37"), "EXP")
    exp_bar.custom_minimum_size = Vector2(300, 17)
    exp_label = _bar_label("LV 1  •  EXP 0 / 100")
    exp_label.add_theme_font_size_override("font_size", 10)
    exp_bar.add_child(exp_label)

    offline_badge = Label.new()
    offline_badge.text = "◈  LOCAL REALM"
    offline_badge.visible = false
    offline_badge.set_anchors_preset(Control.PRESET_TOP_LEFT)
    offline_badge.position = Vector2(34, 178)
    offline_badge.add_theme_font_size_override("font_size", 12)
    offline_badge.add_theme_color_override("font_color", GOLD)
    root.add_child(offline_badge)
    _build_target_panel(root)

    minimap = MinimapView.new()
    minimap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    minimap.position = Vector2(-8, 18)
    minimap.anchor_left = 1.0
    minimap.anchor_right = 1.0
    minimap.offset_left = -250
    minimap.offset_right = -18
    minimap.custom_minimum_size = Vector2(232, 232)
    root.add_child(minimap)

    joystick = VirtualJoystick.new()
    joystick.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
    joystick.position = Vector2(22, -198)
    joystick.anchor_top = 1.0
    joystick.anchor_bottom = 1.0
    joystick.custom_minimum_size = Vector2(250, 250)
    root.add_child(joystick)

    var actions_panel := PanelContainer.new()
    actions_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    actions_panel.position = Vector2(-520, -190)
    actions_panel.anchor_left = 1.0
    actions_panel.anchor_right = 1.0
    actions_panel.anchor_top = 1.0
    actions_panel.anchor_bottom = 1.0
    actions_panel.custom_minimum_size = Vector2(500, 112)
    actions_panel.add_theme_stylebox_override("panel", _panel_style(Color("#101523b8"), EDGE, 18, 2))
    root.add_child(actions_panel)
    var actions := HBoxContainer.new()
    actions.alignment = BoxContainer.ALIGNMENT_CENTER
    actions.add_theme_constant_override("separation", 10)
    actions_panel.add_child(actions)
    _action_button(actions, "✧\nSTRIKE", "attack", Color("#74384b"))
    _action_button(actions, "✚\nELIXIR", "potion", Color("#2e685e"))
    _action_button(actions, "✦\nARCANA", "skill", Color("#51417d"))
    _action_button(actions, "◈\nRELIC", "pickup", Color("#80623b"))
    _action_button(actions, "▣\nVAULT", "bag", Color("#385479"))

    status_label = Label.new()
    status_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
    status_label.position = Vector2(28, -76)
    status_label.anchor_top = 1.0
    status_label.anchor_bottom = 1.0
    status_label.add_theme_color_override("font_color", Color("#e7c778"))
    status_label.add_theme_color_override("font_outline_color", Color("#070b15"))
    status_label.add_theme_constant_override("outline_size", 6)
    status_label.add_theme_font_size_override("font_size", 15)
    root.add_child(status_label)

func _build_target_panel(root: Control) -> void:
    target_panel = VBoxContainer.new()
    target_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
    target_panel.position = Vector2(0, 24)
    target_panel.anchor_left = 0.5
    target_panel.anchor_right = 0.5
    target_panel.offset_left = -170
    target_panel.offset_right = 170
    target_panel.add_theme_constant_override("separation", 5)
    root.add_child(target_panel)
    target_label = Label.new()
    target_label.text = "—  NO TARGET  —"
    target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    target_label.add_theme_color_override("font_color", PALE_GOLD)
    target_label.add_theme_font_size_override("font_size", 16)
    target_panel.add_child(target_label)
    target_bar = ProgressBar.new()
    target_bar.max_value = 100
    target_bar.value = 0
    target_bar.show_percentage = false
    target_bar.custom_minimum_size = Vector2(300, 22)
    target_bar.add_theme_stylebox_override("background", _bar_style(Color("#171524"), EDGE, 10))
    target_bar.add_theme_stylebox_override("fill", _bar_style(Color("#9d4255"), PALE_GOLD, 10))
    target_panel.add_child(target_bar)

func _panel_style(fill: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = fill
    style.border_color = border
    style.set_border_width_all(width)
    style.set_corner_radius_all(radius)
    style.shadow_color = Color(0, 0, 0, 0.42)
    style.shadow_size = 8
    return style

func _bar_style(color: Color, border: Color, radius: int) -> StyleBoxFlat:
    var style := _panel_style(color, border, radius, 1)
    style.content_margin_left = 10
    style.content_margin_right = 10
    return style

func _bar(parent: VBoxContainer, color: Color, _label: String) -> ProgressBar:
    var bar := ProgressBar.new()
    bar.max_value = 100
    bar.value = 100
    bar.custom_minimum_size = Vector2(300, 24)
    bar.show_percentage = false
    bar.add_theme_stylebox_override("background", _bar_style(DEEP_STONE, EDGE, 7))
    bar.add_theme_stylebox_override("fill", _bar_style(color, GOLD, 7))
    parent.add_child(bar)
    return bar

func _bar_label(text_value: String) -> Label:
    var label := Label.new()
    label.text = text_value
    label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    label.position = Vector2(12, 0)
    label.add_theme_font_size_override("font_size", 12)
    label.add_theme_color_override("font_color", PALE_GOLD)
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return label

func _action_button(parent: HBoxContainer, text_value: String, action: String, color: Color) -> void:
    var button := Button.new()
    button.text = text_value
    button.custom_minimum_size = Vector2(88, 88)
    button.add_theme_font_size_override("font_size", 11)
    var normal := _panel_style(color, GOLD, 16, 2)
    var hover := normal.duplicate()
    hover.bg_color = color.lightened(0.16)
    hover.border_color = PALE_GOLD
    var pressed := normal.duplicate()
    pressed.bg_color = color.darkened(0.2)
    button.add_theme_stylebox_override("normal", normal)
    button.add_theme_stylebox_override("hover", hover)
    button.add_theme_stylebox_override("pressed", pressed)
    button.add_theme_color_override("font_color", PALE_GOLD)
    button.add_theme_color_override("font_hover_color", Color.WHITE)
    button.pressed.connect(func():
        if action == "bag":
            inventory_requested.emit()
        else:
            action_requested.emit(action)
    )
    parent.add_child(button)

func set_offline_mode(enabled: bool) -> void:
    if offline_badge:
        offline_badge.visible = enabled

func set_exp(current: int, required: int, level: int) -> void:
    if exp_bar:
        exp_bar.max_value = max(1, required)
        exp_bar.value = clamp(current, 0, required)
    if exp_label:
        exp_label.text = "LV %d  •  EXP %d / %d" % [level, current, required]

func set_mana(mp: int, max_mp: int) -> void:
    if mp_bar:
        mp_bar.max_value = max(1, max_mp)
        mp_bar.value = clamp(mp, 0, max_mp)
    if mp_label:
        mp_label.text = "MP  %d / %d" % [mp, max_mp]

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
        target_label.text = "—  NO TARGET  —"
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
