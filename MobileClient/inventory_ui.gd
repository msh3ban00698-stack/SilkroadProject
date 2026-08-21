class_name InventoryUI
extends Control

var panel: PanelContainer
var list: VBoxContainer
var items: Array = []

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _build()
    visible = false

func _build() -> void:
    panel = PanelContainer.new()
    panel.position = Vector2(0, 0)
    panel.anchor_left = 0.5
    panel.anchor_right = 0.5
    panel.anchor_top = 0.5
    panel.anchor_bottom = 0.5
    panel.offset_left = -180
    panel.offset_right = 180
    panel.offset_top = -235
    panel.offset_bottom = 235
    panel.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(panel)
    var content := VBoxContainer.new()
    content.add_theme_constant_override("separation", 12)
    panel.add_child(content)
    var header := HBoxContainer.new()
    content.add_child(header)
    var title := Label.new()
    title.text = "INVENTORY"
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.add_theme_font_size_override("font_size", 24)
    title.add_theme_color_override("font_color", Color("#f2c66d"))
    header.add_child(title)
    var close := Button.new()
    close.text = "X"
    close.pressed.connect(func(): visible = false)
    header.add_child(close)
    var hint := Label.new()
    hint.text = "Items confirmed by Agent"
    hint.add_theme_color_override("font_color", Color("#9eb2d5"))
    content.add_child(hint)
    list = VBoxContainer.new()
    list.add_theme_constant_override("separation", 7)
    list.size_flags_vertical = Control.SIZE_EXPAND_FILL
    content.add_child(list)
    _refresh()

func add_item(item_id: int, item_name: String = "Item") -> void:
    items.append({"id": item_id, "name": item_name})
    _refresh()

func _refresh() -> void:
    if not list:
        return
    for child in list.get_children():
        child.queue_free()
    if items.is_empty():
        var empty := Label.new()
        empty.text = "Your bag is empty."
        empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        list.add_child(empty)
        return
    for index in range(items.size()):
        var row := Label.new()
        row.text = "%02d   %s   [0x%08X]" % [index + 1, items[index].name, int(items[index].id)]
        row.add_theme_font_size_override("font_size", 16)
        row.add_theme_color_override("font_color", Color("#e5d7b5"))
        list.add_child(row)
