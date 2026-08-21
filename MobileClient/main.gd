extends Control

var protocol: SROProtocol
var host_edit: LineEdit
var port_edit: SpinBox
var user_edit: LineEdit
var password_edit: LineEdit
var locale_edit: SpinBox
var shard_edit: SpinBox
var login_button: Button
var status_label: Label
var result_label: Label

func _ready() -> void:
    _build_ui()
    protocol = SROProtocol.new()
    protocol.status_changed.connect(_on_status_changed)
    protocol.gateway_login_succeeded.connect(_on_gateway_login_succeeded)
    protocol.agent_login_succeeded.connect(_on_agent_login_succeeded)
    protocol.login_failed.connect(_on_login_failed)
    _on_status_changed("Ready. Enter the server settings and credentials.")

func _process(_delta: float) -> void:
    if protocol != null:
        protocol.poll()

func _build_ui() -> void:
    var background := ColorRect.new()
    background.color = Color("#090f1f")
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(background)

    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 54)
    margin.add_theme_constant_override("margin_right", 54)
    margin.add_theme_constant_override("margin_top", 72)
    margin.add_theme_constant_override("margin_bottom", 72)
    add_child(margin)

    var content := VBoxContainer.new()
    content.add_theme_constant_override("separation", 22)
    margin.add_child(content)

    var title := Label.new()
    title.text = "SILKROAD MOBILE"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 34)
    title.add_theme_color_override("font_color", Color("#f2c66d"))
    content.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "Gateway / Agent connectivity test"
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 18)
    subtitle.add_theme_color_override("font_color", Color("#a9b7d1"))
    content.add_child(subtitle)

    var separator := HSeparator.new()
    content.add_child(separator)

    host_edit = _add_text_field(content, "Gateway host", "127.0.0.1")
    port_edit = _add_number_field(content, "Gateway port", 15779, 1, 65535, 1)
    user_edit = _add_text_field(content, "Account ID", "")
    password_edit = _add_text_field(content, "Password", "")
    password_edit.secret = true
    locale_edit = _add_number_field(content, "Locale", 22, 0, 255, 1)
    shard_edit = _add_number_field(content, "Shard ID", 1, 0, 65535, 1)

    login_button = Button.new()
    login_button.text = "CONNECT AND LOGIN"
    login_button.custom_minimum_size = Vector2(0, 66)
    login_button.add_theme_font_size_override("font_size", 20)
    login_button.pressed.connect(_on_login_pressed)
    content.add_child(login_button)

    result_label = Label.new()
    result_label.text = ""
    result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    result_label.add_theme_font_size_override("font_size", 18)
    result_label.add_theme_color_override("font_color", Color("#8be0a3"))
    content.add_child(result_label)

    status_label = Label.new()
    status_label.text = ""
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
    status_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
    status_label.add_theme_font_size_override("font_size", 16)
    status_label.add_theme_color_override("font_color", Color("#c8d3e8"))
    content.add_child(status_label)

    var note := Label.new()
    note.text = "The server address and port are configurable because the repository reads them from SQL _ServerConfig."
    note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    note.add_theme_font_size_override("font_size", 14)
    note.add_theme_color_override("font_color", Color("#71809c"))
    content.add_child(note)

func _add_text_field(parent: VBoxContainer, caption: String, value: String) -> LineEdit:
    var label := Label.new()
    label.text = caption
    label.add_theme_font_size_override("font_size", 16)
    parent.add_child(label)
    var edit := LineEdit.new()
    edit.text = value
    edit.custom_minimum_size = Vector2(0, 52)
    edit.add_theme_font_size_override("font_size", 18)
    parent.add_child(edit)
    return edit

func _add_number_field(parent: VBoxContainer, caption: String, value: float, minimum: float, maximum: float, step: float) -> SpinBox:
    var label := Label.new()
    label.text = caption
    label.add_theme_font_size_override("font_size", 16)
    parent.add_child(label)
    var spin := SpinBox.new()
    spin.value = value
    spin.min_value = minimum
    spin.max_value = maximum
    spin.step = step
    spin.custom_minimum_size = Vector2(0, 52)
    spin.add_theme_font_size_override("font_size", 18)
    parent.add_child(spin)
    return spin

func _on_login_pressed() -> void:
    var host := host_edit.text.strip_edges()
    var user_id := user_edit.text.strip_edges()
    if host.is_empty() or user_id.is_empty() or password_edit.text.is_empty():
        _on_status_changed("Host, account ID and password are required.")
        return
    login_button.disabled = true
    result_label.text = ""
    _on_status_changed("Starting protocol negotiation...")
    protocol.begin_login(host, int(port_edit.value), user_id, password_edit.text, int(locale_edit.value), int(shard_edit.value))

func _on_status_changed(message: String) -> void:
    if status_label != null:
        status_label.text = message

func _on_gateway_login_succeeded(new_session_id: int, agent_host: String, agent_port: int) -> void:
    result_label.text = "Gateway accepted login. Session %d; Agent %s:%d" % [new_session_id, agent_host, agent_port]
    result_label.add_theme_color_override("font_color", Color("#f2c66d"))

func _on_agent_login_succeeded() -> void:
    result_label.text = "SUCCESS: Gateway and Agent authentication completed."
    result_label.add_theme_color_override("font_color", Color("#8be0a3"))
    login_button.disabled = false

func _on_login_failed(message: String) -> void:
    result_label.text = "LOGIN FAILED"
    result_label.add_theme_color_override("font_color", Color("#f28b8b"))
    login_button.disabled = false
