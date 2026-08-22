extends Control

var protocol: SROProtocol
var login_layer: Control
var host_edit: LineEdit
var port_edit: SpinBox
var user_edit: LineEdit
var password_edit: LineEdit
var locale_edit: SpinBox
var shard_edit: SpinBox
var login_button: Button
var offline_button: Button
var status_label: Label
var result_label: Label
var character_select: CharacterSelect
var starter_world: StarterWorld
var offline_mode := false

func _ready() -> void:
    protocol = SROProtocol.new()
    protocol.status_changed.connect(_on_status_changed)
    protocol.gateway_login_succeeded.connect(_on_gateway_login_succeeded)
    protocol.agent_login_succeeded.connect(_on_agent_login_succeeded)
    protocol.login_failed.connect(_on_login_failed)
    protocol.character_list_received.connect(_on_character_list_received)
    protocol.character_create_result.connect(_on_character_create_result)
    protocol.character_selected.connect(_on_character_selected)
    protocol.character_loaded.connect(_on_character_loaded)
    protocol.stats_updated.connect(_on_stats_updated)
    protocol.world_ready.connect(_on_world_ready)
    _build_login_ui()
    # Android hotfix: render the mandatory Character Select screen before any heavy preview/world work.
    login_layer.visible = false
    offline_mode = true
    call_deferred("_boot_character_select_first_frame")

func _boot_character_select_first_frame() -> void:
    _show_character_select(true)
    if character_select:
        character_select.set_status("Choose a name and build, then enter the sanctum.")

func _process(_delta: float) -> void:
    if protocol:
        protocol.poll()

func _build_login_ui() -> void:
    login_layer = Control.new()
    login_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(login_layer)
    var background := ColorRect.new()
    background.color = Color("#090f1f")
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    login_layer.add_child(background)
    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    login_layer.add_child(center)
    var card := PanelContainer.new()
    card.custom_minimum_size = Vector2(860, 0)
    card.add_theme_stylebox_override("panel", _login_panel_style())
    center.add_child(card)
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 34)
    margin.add_theme_constant_override("margin_right", 34)
    margin.add_theme_constant_override("margin_top", 28)
    margin.add_theme_constant_override("margin_bottom", 28)
    card.add_child(margin)
    var content := VBoxContainer.new()
    content.add_theme_constant_override("separation", 12)
    margin.add_child(content)
    var title := Label.new()
    title.text = "SILKROAD MOBILE  •  CHARACTER SELECT"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 30)
    title.add_theme_color_override("font_color", Color("#f2c66d"))
    content.add_child(title)
    var subtitle := Label.new()
    subtitle.text = "Choose your build before entering the Jangan frontier"
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 17)
    subtitle.add_theme_color_override("font_color", Color("#a9b7d1"))
    content.add_child(subtitle)
    host_edit = _add_text_field(content, "Gateway host", "127.0.0.1")
    port_edit = _add_number_field(content, "Gateway port", 15779, 1, 65535, 1)
    user_edit = _add_text_field(content, "Account ID", "")
    password_edit = _add_text_field(content, "Password", "")
    password_edit.secret = true
    locale_edit = _add_number_field(content, "Locale", 22, 0, 255, 1)
    shard_edit = _add_number_field(content, "Shard ID", 1, 0, 65535, 1)
    login_button = Button.new()
    login_button.text = "CONNECT TO GATEWAY / AGENT"
    login_button.custom_minimum_size = Vector2(0, 62)
    login_button.add_theme_font_size_override("font_size", 20)
    login_button.pressed.connect(_on_login_pressed)
    content.add_child(login_button)
    offline_button = Button.new()
    offline_button.text = "PLAY OFFLINE"
    offline_button.custom_minimum_size = Vector2(0, 58)
    offline_button.add_theme_font_size_override("font_size", 18)
    offline_button.add_theme_color_override("font_color", Color("#ffe6a0"))
    offline_button.add_theme_color_override("font_hover_color", Color("#ffffff"))
    offline_button.pressed.connect(_on_offline_pressed)
    content.add_child(offline_button)
    result_label = Label.new()
    result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    result_label.add_theme_font_size_override("font_size", 17)
    content.add_child(result_label)
    status_label = Label.new()
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
    status_label.add_theme_font_size_override("font_size", 15)
    status_label.add_theme_color_override("font_color", Color("#c8d3e8"))
    content.add_child(status_label)
    var note := Label.new()
    note.text = "Landscape RPG client • Choose a hero, then enter the Jangan frontier."
    note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    note.add_theme_font_size_override("font_size", 13)
    note.add_theme_color_override("font_color", Color("#71809c"))
    content.add_child(note)

func _login_panel_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color("#101827e8")
    style.border_color = Color("#9e793f")
    style.set_border_width_all(2)
    style.set_corner_radius_all(18)
    return style

func _add_text_field(parent: VBoxContainer, caption: String, value: String) -> LineEdit:
    var label := Label.new()
    label.text = caption
    label.add_theme_font_size_override("font_size", 15)
    parent.add_child(label)
    var edit := LineEdit.new()
    edit.text = value
    edit.custom_minimum_size = Vector2(0, 48)
    edit.add_theme_font_size_override("font_size", 17)
    parent.add_child(edit)
    return edit

func _add_number_field(parent: VBoxContainer, caption: String, value: float, minimum: float, maximum: float, step: float) -> SpinBox:
    var label := Label.new()
    label.text = caption
    label.add_theme_font_size_override("font_size", 15)
    parent.add_child(label)
    var spin := SpinBox.new()
    spin.value = value
    spin.min_value = minimum
    spin.max_value = maximum
    spin.step = step
    spin.custom_minimum_size = Vector2(0, 48)
    spin.add_theme_font_size_override("font_size", 17)
    parent.add_child(spin)
    return spin

func _on_offline_pressed() -> void:
    offline_mode = true
    login_button.disabled = true
    offline_button.disabled = true
    result_label.text = "OFFLINE MODE — CHOOSE YOUR HERO"
    result_label.add_theme_color_override("font_color", Color("#ffd36e"))
    _show_character_select(true)
    character_select.set_status("Choose a name and build, then enter the frontier.")

func _enter_world_offline(character_data: Dictionary) -> void:
    if starter_world:
        return
    starter_world = StarterWorld.new()
    starter_world.set_offline_mode(true)
    add_child(starter_world)
    starter_world.set_character(character_data)
    if character_select:
        character_select.queue_free()
        character_select = null
    login_layer.visible = false

func _on_login_pressed() -> void:
    var host := host_edit.text.strip_edges()
    var user_id := user_edit.text.strip_edges()
    if host.is_empty() or user_id.is_empty() or password_edit.text.is_empty():
        _on_status_changed("Host, account ID and password are required.")
        return
    login_button.disabled = true
    result_label.text = ""
    protocol.begin_login(host, int(port_edit.value), user_id, password_edit.text, int(locale_edit.value), int(shard_edit.value))

func _on_gateway_login_succeeded(new_session_id: int, agent_host: String, agent_port: int) -> void:
    result_label.text = "Gateway accepted. Session %d → Agent %s:%d" % [new_session_id, agent_host, agent_port]
    result_label.add_theme_color_override("font_color", Color("#f2c66d"))

func _on_agent_login_succeeded() -> void:
    result_label.text = "Agent authenticated. Loading character screen..."
    _show_character_select()

func _show_character_select(for_offline: bool = false) -> void:
    if character_select:
        return
    character_select = CharacterSelect.new()
    character_select.select_requested.connect(_on_select_requested)
    character_select.create_requested.connect(_on_create_requested)
    character_select.enter_requested.connect(_on_enter_requested)
    add_child(character_select)
    character_select.set_offline_mode(for_offline)
    login_layer.visible = false

func _on_character_list_received(characters: Array) -> void:
    if not character_select:
        _show_character_select()
    character_select.set_characters(characters)

func _on_select_requested(slot: int) -> void:
    if offline_mode:
        if character_select:
            character_select.set_status("Build selected. Confirm your name and press ENTER.")
        return
    protocol.select_character(slot)
    if character_select:
        character_select.set_status("Selecting slot %d and waiting for Agent load data..." % (slot + 1))

func _on_create_requested(char_name: String, model: int, scale: int, items: Array[int]) -> void:
    if offline_mode:
        return
    protocol.create_character(char_name, model, scale, items)

func _on_character_create_result(success: bool, code: int) -> void:
    if character_select:
        character_select.set_status("Character created; refreshing list." if success else "Creation rejected by Agent, code %d." % code)

func _on_character_selected(_slot: int) -> void:
    if character_select:
        character_select.set_status("Agent accepted selection. Loading stats and world data...")

func _on_character_loaded(data: Dictionary) -> void:
    if character_select:
        character_select.set_status("Loaded %s. Press ENTER SELECTED CHARACTER to enter the world." % data.get("name", "Traveler"))

func _on_enter_requested(_slot: int) -> void:
    if offline_mode:
        var character_data := character_select.get_offline_character()
        if character_data.get("name", "").is_empty():
            character_select.set_status("Enter a character name before continuing.")
            return
        character_select.set_status("Entering Jangan frontier as %s..." % character_data.get("name", "Hero"))
        _enter_world_offline(character_data)
        return
    protocol.enter_world()
    if character_select:
        character_select.set_status("Entering Jangan outskirts...")

func _on_world_ready() -> void:
    if starter_world:
        return
    starter_world = StarterWorld.new()
    starter_world.set_protocol(protocol)
    add_child(starter_world)
    if character_select:
        character_select.queue_free()
        character_select = null
    login_layer.visible = false

func _on_stats_updated(hp: int, mp: int, max_hp: int, max_mp: int) -> void:
    if starter_world and starter_world.hud:
        starter_world.hud.set_stats(hp, mp, max_hp, max_mp)

func _on_status_changed(message: String) -> void:
    if status_label:
        status_label.text = message
    if character_select:
        character_select.set_status(message)
    if starter_world and starter_world.hud:
        starter_world.hud.set_status(message)

func _on_login_failed(message: String) -> void:
    result_label.text = "LOGIN / AGENT FAILED"
    result_label.add_theme_color_override("font_color", Color("#f28b8b"))
    if login_button:
        login_button.disabled = false
