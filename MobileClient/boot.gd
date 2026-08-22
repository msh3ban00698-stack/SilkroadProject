extends Control

const UI_SCALE := 2.5

var label: Label
var sublabel: Label
var loading := false
var preloads: Array[String] = []

func _fs(points: int) -> int:
    return int(round(float(points) * UI_SCALE))

func _px(points: float) -> float:
    return points * UI_SCALE

func _ready() -> void:
    set_process(false)
    _build_ui()
    call_deferred("_start_loading")

func _build_ui() -> void:
    var background := ColorRect.new()
    background.color = Color("#090f1f")
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(background)

    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(center)

    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(_px(720), _px(300))
    panel.add_theme_stylebox_override("panel", _panel_style())
    center.add_child(panel)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", _px(48))
    margin.add_theme_constant_override("margin_right", _px(48))
    margin.add_theme_constant_override("margin_top", _px(36))
    margin.add_theme_constant_override("margin_bottom", _px(36))
    panel.add_child(margin)

    var content := VBoxContainer.new()
    content.add_theme_constant_override("separation", _px(16))
    margin.add_child(content)

    var title := Label.new()
    title.text = "SILKROAD MOBILE"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", _fs(38))
    title.add_theme_color_override("font_color", Color("#f2c66d"))
    content.add_child(title)

    label = Label.new()
    label.text = "Awakening the Jangan frontier..."
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", _fs(20))
    label.add_theme_color_override("font_color", Color("#c8d3e8"))
    content.add_child(label)

    sublabel = Label.new()
    sublabel.text = "Loading models and world data"
    sublabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    sublabel.add_theme_font_size_override("font_size", _fs(14))
    sublabel.add_theme_color_override("font_color", Color("#71809c"))
    content.add_child(sublabel)

    var progress := ProgressBar.new()
    progress.name = "ProgressBar"
    progress.max_value = 1.0
    progress.value = 0.0
    progress.show_percentage = false
    progress.custom_minimum_size = Vector2(0, _px(18))
    progress.add_theme_stylebox_override("background", _bar_style(Color("#101827")))
    progress.add_theme_stylebox_override("fill", _bar_style(Color("#9e793f")))
    content.add_child(progress)

func _panel_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color("#101827e8")
    style.border_color = Color("#9e793f")
    style.set_border_width_all(2)
    style.set_corner_radius_all(18)
    return style

func _bar_style(color: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.set_corner_radius_all(6)
    return style

func _start_loading() -> void:
    preloads = [
        "res://main.tscn",
        "res://assets/models/humanoid_wizard.glb",
        "res://assets/models/humanoid_spear.glb",
        "res://assets/models/monster_mangyang.glb",
        "res://assets/models/weapon_staff.glb",
        "res://assets/models/weapon_spear.glb",
    ]
    for path in preloads:
        ResourceLoader.load_threaded_request(path)
    loading = true
    set_process(true)

func _process(_delta: float) -> void:
    if not loading:
        return
    var remaining := 0.0
    var done := 0.0
    for path in preloads:
        var status := ResourceLoader.load_threaded_get_status(path)
        match status:
            ResourceLoader.THREAD_LOAD_LOADED:
                done += 1.0
            ResourceLoader.THREAD_LOAD_IN_PROGRESS:
                done += 0.5
            ResourceLoader.THREAD_LOAD_FAILED:
                done += 1.0
            _:
                remaining += 1.0
    var progress_value := done / preloads.size()
    var bar := find_child("ProgressBar", true, false) as ProgressBar
    if bar:
        bar.value = progress_value
    sublabel.text = "Loading resources... %d%%" % int(progress_value * 100.0)
    if remaining == 0.0:
        loading = false
        set_process(false)
        call_deferred("_enter_main")

func _enter_main() -> void:
    var main_scene: PackedScene = ResourceLoader.load("res://main.tscn")
    if main_scene:
        get_tree().change_scene_to_packed(main_scene)
