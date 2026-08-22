extends Control

signal skill_use_requested(skill_id: String)
signal skill_upgrade_requested(skill_id: String)

const UI_SCALE := 2.5

var skill_system
var panel: PanelContainer
var list: VBoxContainer
var points_label: Label
var mana_label: Label
var title_label: Label

func _fs(points: int) -> int:
    return int(round(float(points) * UI_SCALE))

func _px(points: float) -> float:
    return points * UI_SCALE

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _build()
    visible = false

func configure(value) -> void:
    skill_system = value
    if skill_system and not skill_system.changed.is_connected(_refresh):
        skill_system.changed.connect(_refresh)
    _refresh()

func open_for_build() -> void:
    visible = true
    mouse_filter = Control.MOUSE_FILTER_STOP
    _refresh()

func close_menu() -> void:
    visible = false
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func _build() -> void:
    panel = PanelContainer.new()
    panel.position = Vector2(0, 0)
    panel.anchor_left = 0.5
    panel.anchor_right = 0.5
    panel.anchor_top = 0.5
    panel.anchor_bottom = 0.5
    panel.offset_left = -_px(245)
    panel.offset_right = _px(245)
    panel.offset_top = -_px(330)
    panel.offset_bottom = _px(330)
    panel.add_theme_stylebox_override("panel", _panel_style())
    panel.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(panel)
    var content := VBoxContainer.new()
    content.add_theme_constant_override("separation", _px(10))
    panel.add_child(content)
    var header := HBoxContainer.new()
    content.add_child(header)
    title_label = Label.new()
    title_label.text = "SKILL TREE"
    title_label.add_theme_font_size_override("font_size", _fs(24))
    title_label.add_theme_color_override("font_color", Color("#f5d486"))
    title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(title_label)
    var close := Button.new()
    close.text = "CLOSE"
    close.custom_minimum_size = Vector2(_px(120), _px(44))
    close.add_theme_font_size_override("font_size", _fs(16))
    close.pressed.connect(close_menu)
    header.add_child(close)
    points_label = Label.new()
    points_label.add_theme_font_size_override("font_size", _fs(16))
    points_label.add_theme_color_override("font_color", Color("#ffe5a4"))
    content.add_child(points_label)
    mana_label = Label.new()
    mana_label.add_theme_font_size_override("font_size", _fs(16))
    mana_label.add_theme_color_override("font_color", Color("#93d8ff"))
    content.add_child(mana_label)
    var divider := HSeparator.new()
    content.add_child(divider)
    list = VBoxContainer.new()
    list.add_theme_constant_override("separation", _px(8))
    list.size_flags_vertical = Control.SIZE_EXPAND_FILL
    content.add_child(list)

func _refresh() -> void:
    if not list or not skill_system:
        return
    title_label.text = "WIZARD SKILLS" if skill_system.build_id == "wizard" else "SPEAR SKILLS"
    points_label.text = "Skill Points: %d" % skill_system.skill_points
    mana_label.text = "Mana: %d / %d" % [skill_system.mana, skill_system.max_mana]
    for child in list.get_children():
        child.queue_free()
    for definition in skill_system.get_definitions():
        var row := PanelContainer.new()
        row.add_theme_stylebox_override("panel", _row_style(definition.color))
        list.add_child(row)
        var row_box := VBoxContainer.new()
        row_box.add_theme_constant_override("separation", _px(3))
        row.add_child(row_box)
        var header := HBoxContainer.new()
        row_box.add_child(header)
        var name := Label.new()
        name.text = "%s  •  Rank %d/5" % [definition.name, skill_system.get_rank(definition.id)]
        name.add_theme_color_override("font_color", definition.color)
        name.add_theme_font_size_override("font_size", _fs(16))
        name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        header.add_child(name)
        var use := Button.new()
        use.text = "USE"
        use.custom_minimum_size = Vector2(_px(68), _px(34))
        use.add_theme_font_size_override("font_size", _fs(15))
        use.disabled = not skill_system.can_use(definition.id)
        use.pressed.connect(func(): skill_use_requested.emit(definition.id))
        header.add_child(use)
        var upgrade := Button.new()
        upgrade.text = "UPGRADE"
        upgrade.custom_minimum_size = Vector2(_px(92), _px(34))
        upgrade.add_theme_font_size_override("font_size", _fs(15))
        upgrade.disabled = not skill_system.can_upgrade(definition.id)
        upgrade.pressed.connect(func(): skill_upgrade_requested.emit(definition.id))
        header.add_child(upgrade)
        var detail := Label.new()
        detail.text = "%s  |  Lv.%d  |  Mana %d  |  CD %.1fs" % [definition.description, int(definition.required_level), int(definition.mana), float(definition.cooldown)]
        detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        detail.add_theme_color_override("font_color", Color("#d0c7b1"))
        detail.add_theme_font_size_override("font_size", _fs(12))
        row_box.add_child(detail)

func _panel_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color("#111827ee")
    style.border_color = Color("#c99b4e")
    style.set_border_width_all(2)
    style.set_corner_radius_all(16)
    style.content_margin_left = _px(18)
    style.content_margin_right = _px(18)
    style.content_margin_top = _px(18)
    style.content_margin_bottom = _px(18)
    return style

func _row_style(color: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color("#1b2336e8")
    style.border_color = color.darkened(0.22)
    style.set_border_width_all(1)
    style.set_corner_radius_all(9)
    style.content_margin_left = _px(10)
    style.content_margin_right = _px(10)
    style.content_margin_top = _px(8)
    style.content_margin_bottom = _px(8)
    return style
