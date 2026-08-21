extends RefCounted
class_name SROProtocol

signal status_changed(message: String)
signal gateway_login_succeeded(session_id: int, agent_host: String, agent_port: int)
signal agent_login_succeeded()
signal login_failed(message: String)
signal character_list_received(characters: Array)
signal character_create_result(success: bool, code: int)
signal character_name_check_result(available: bool, code: int)
signal character_selected(character_index: int)
signal character_loaded(data: Dictionary)
signal stats_updated(hp: int, mp: int, max_hp: int, max_mp: int)
signal world_ready()

const OP_HANDSHAKE := 0x5000
const OP_HANDSHAKE_ACCEPT := 0x9000
const OP_IDENTITY := 0x2001
const OP_GATEWAY_LOGIN := 0x6102
const OP_AGENT_LOGIN := 0x6103
const OP_GATEWAY_LOGIN_RESPONSE := 0xA102
const OP_AGENT_LOGIN_RESPONSE := 0xA103
const OP_AGENT_CHARACTER_SCREEN := 0x7007
const OP_AGENT_CHARACTER_SCREEN_RESPONSE := 0xB007
const OP_AGENT_CHARACTER_SELECT := 0x7001
const OP_AGENT_CHARACTER_SELECT_RESPONSE := 0xB001
const OP_AGENT_ENTER_WORLD := 0x3012
const OP_AGENT_LOAD_START := 0x34A5
const OP_AGENT_LOAD_DATA := 0x3013
const OP_AGENT_LOAD_END := 0x34A6
const OP_AGENT_CELESTIAL := 0x3020
const OP_AGENT_STATS := 0x303D
const OP_AGENT_WORLD_READY := 0x3077
const OP_AGENT_MOVE := 0x7021
const OP_AGENT_STOP := 0x7023
const ENCRYPTED_OPCODES := [OP_IDENTITY, 0x6100, 0x6101, OP_GATEWAY_LOGIN, OP_AGENT_LOGIN, 0x6107]
const MASK := 0xffffffff
const BASE_SECURITY_TABLE: Array[int] = [0xb1, 0xd6, 0x8b, 0x96, 0x96, 0x30, 0x07, 0x77, 0x2c, 0x61, 0x0e, 0xee, 0xba, 0x51, 0x09, 0x99, 0x19, 0xc4, 0x6d, 0x07, 0x8f, 0xf4, 0x6a, 0x70, 0x35, 0xa5, 0x63, 0xe9, 0xa3, 0x95, 0x64, 0x9e, 0x32, 0x88, 0xdb, 0x0e, 0xa4, 0xb8, 0xdc, 0x79, 0x1e, 0xe9, 0xd5, 0xe0, 0x88, 0xd9, 0xd2, 0x97, 0x2b, 0x4c, 0xb6, 0x09, 0xbd, 0x7c, 0xb1, 0x7e, 0x07, 0x2d, 0xb8, 0xe7, 0x91, 0x1d, 0xbf, 0x90, 0x64, 0x10, 0xb7, 0x1d, 0xf2, 0x20, 0xb0, 0x6a, 0x48, 0x71, 0xb1, 0xf3, 0xde, 0x41, 0xbe, 0x8c, 0x7d, 0xd4, 0xda, 0x1a, 0xeb, 0xe4, 0xdd, 0x6d, 0x51, 0xb5, 0xd4, 0xf4, 0xc7, 0x85, 0xd3, 0x83, 0x56, 0x98, 0x6c, 0x13, 0xc0, 0xa8, 0x6b, 0x64, 0x7a, 0xf9, 0x62, 0xfd, 0xec, 0xc9, 0x65, 0x8a, 0x4f, 0x5c, 0x01, 0x14, 0xd9, 0x6c, 0x06, 0x63, 0x63, 0x3d, 0x0f, 0xfa, 0xf5, 0x0d, 0x08, 0x8d, 0xc8, 0x20, 0x6e, 0x3b, 0x5e, 0x10, 0x69, 0x4c, 0xe4, 0x41, 0x60, 0xd5, 0x72, 0x71, 0x67, 0xa2, 0xd1, 0xe4, 0x03, 0x3c, 0x47, 0xd4, 0x04, 0x4b, 0xfd, 0x85, 0x0d, 0xd2, 0x6b, 0xb5, 0x0a, 0xa5, 0xfa, 0xa8, 0xb5, 0x35, 0x6c, 0x98, 0xb2, 0x42, 0xd6, 0xc9, 0xbb, 0xdb, 0x40, 0xf9, 0xbc, 0xac, 0xe3, 0x6c, 0xd8, 0x32, 0x75, 0x5c, 0xdf, 0x45, 0xcf, 0x0d, 0xd6, 0xdc, 0x59, 0x3d, 0xd1, 0xab, 0xac, 0x30, 0xd9, 0x26, 0x3a, 0x00, 0xde, 0x51, 0x80, 0x51, 0xd7, 0xc8, 0x16, 0x61, 0xd0, 0xbf, 0xb5, 0xf4, 0xb4, 0x21, 0x23, 0xc4, 0xb3, 0x56, 0x99, 0x95, 0xba, 0xcf, 0x0f, 0xa5, 0xb7, 0xb8, 0x9e, 0xb8, 0x02, 0x28, 0x08, 0x88, 0x05, 0x5f, 0xb2, 0xd9, 0xec, 0xc6, 0x24, 0xe9, 0x0b, 0xb1, 0x87, 0x7c, 0x6f, 0x2f, 0x11, 0x4c, 0x68, 0x58, 0xab, 0x1d, 0x61, 0xc1, 0x3d, 0x2d, 0x66, 0xb6, 0x90, 0x41, 0xdc, 0x76, 0x06, 0x71, 0xdb, 0x01, 0xbc, 0x20, 0xd2, 0x98, 0x2a, 0x10, 0xd5, 0xef, 0x89, 0x85, 0xb1, 0x71, 0x1f, 0xb5, 0xb6, 0x06, 0xa5, 0xe4, 0xbf, 0x9f, 0x33, 0xd4, 0xb8, 0xe8, 0xa2, 0xc9, 0x07, 0x78, 0x34, 0xf9, 0xa0, 0x0f, 0x8e, 0xa8, 0x09, 0x96, 0x18, 0x98, 0x0e, 0xe1, 0xbb, 0x0d, 0x6a, 0x7f, 0x2d, 0x3d, 0x6d, 0x08, 0x97, 0x6c, 0x64, 0x91, 0x01, 0x5c, 0x63, 0xe6, 0xf4, 0x51, 0x6b, 0x6b, 0x62, 0x61, 0x6c, 0x1c, 0xd8, 0x30, 0x65, 0x85, 0x4e, 0x00, 0x62, 0xf2, 0xed, 0x95, 0x06, 0x6c, 0x7b, 0xa5, 0x01, 0x1b, 0xc1, 0xf4, 0x08, 0x82, 0x57, 0xc4, 0x0f, 0xf5, 0xc6, 0xd9, 0xb0, 0x63, 0x50, 0xe9, 0xb7, 0x12, 0xea, 0xb8, 0xbe, 0x8b, 0x7c, 0x88, 0xb9, 0xfc, 0xdf, 0x1d, 0xdd, 0x62, 0x49, 0x2d, 0xda, 0x15, 0xf3, 0x7c, 0xd3, 0x8c, 0x65, 0x4c, 0xd4, 0xfb, 0x58, 0x61, 0xb2, 0x4d, 0xce, 0x51, 0xb5, 0x3a, 0x74, 0x00, 0xbc, 0xa3, 0xe2, 0x30, 0xbb, 0xd4, 0x41, 0xa5, 0xdf, 0x4a, 0xd7, 0x95, 0xd8, 0x3d, 0x6d, 0xc4, 0xd1, 0xa4, 0xfb, 0xf4, 0xd6, 0xd3, 0x6a, 0xe9, 0x69, 0x43, 0xfc, 0xd9, 0x6e, 0x34, 0x46, 0x88, 0x67, 0xad, 0xd0, 0xb8, 0x60, 0xda, 0x73, 0x2d, 0x04, 0x44, 0xe5, 0x1d, 0x03, 0x33, 0x5f, 0x4c, 0x0a, 0xaa, 0xc9, 0x7c, 0x0d, 0xdd, 0x3c, 0x71, 0x05, 0x50, 0xaa, 0x41, 0x02, 0x27, 0x10, 0x10, 0x0b, 0xbe, 0x86, 0x20, 0x0c, 0xc9, 0x25, 0xb5, 0x68, 0x57, 0xb3, 0x85, 0x6f, 0x20, 0x09, 0xd4, 0x66, 0xb9, 0x9f, 0xe4, 0x61, 0xce, 0x0e, 0xf9, 0xde, 0x5e, 0x08, 0xc9, 0xd9, 0x29, 0x22, 0x98, 0xd0, 0xb0, 0xb4, 0xa8, 0x57, 0xc7, 0x17, 0x3d, 0xb3, 0x59, 0x81, 0x0d, 0xb4, 0x3e, 0x3b, 0x5c, 0xbd, 0xb7, 0xad, 0x6c, 0xba, 0xc0, 0x20, 0x83, 0xb8, 0xed, 0xb6, 0xb3, 0xbf, 0x9a, 0x0c, 0xe2, 0xb6, 0x03, 0x9a, 0xd2, 0xb1, 0x74, 0x39, 0x47, 0xd5, 0xea, 0xaf, 0x77, 0xd2, 0x9d, 0x15, 0x26, 0xdb, 0x04, 0x83, 0x16, 0xdc, 0x73, 0x12, 0x0b, 0x63, 0xe3, 0x84, 0x3b, 0x64, 0x94, 0x3e, 0x6a, 0x6d, 0x0d, 0xa8, 0x5a, 0x6a, 0x7a, 0x0b, 0xcf, 0x0e, 0xe4, 0x9d, 0xff, 0x09, 0x93, 0x27, 0xae, 0x00, 0x0a, 0xb1, 0x9e, 0x07, 0x7d, 0x44, 0x93, 0x0f, 0xf0, 0xd2, 0xa2, 0x08, 0x87, 0x68, 0xf2, 0x01, 0x1e, 0xfe, 0xc2, 0x06, 0x69, 0x5d, 0x57, 0x62, 0xf7, 0xcb, 0x67, 0x65, 0x80, 0x71, 0x36, 0x6c, 0x19, 0xe7, 0x06, 0x6b, 0x6e, 0x76, 0x1b, 0xd4, 0xfe, 0xe0, 0x2b, 0xd3, 0x89, 0x5a, 0x7a, 0xda, 0x10, 0xcc, 0x4a, 0xdd, 0x67, 0x6f, 0xdf, 0xb9, 0xf9, 0xf9, 0xef, 0xbe, 0x8e, 0x43, 0xbe, 0xb7, 0x17, 0xd5, 0x8e, 0xb0, 0x60, 0xe8, 0xa3, 0xd6, 0xd6, 0x7e, 0x93, 0xd1, 0xa1, 0xc4, 0xc2, 0xd8, 0x38, 0x52, 0xf2, 0xdf, 0x4f, 0xf1, 0x67, 0xbb, 0xd1, 0x67, 0x57, 0xbc, 0xa6, 0xdd, 0x06, 0xb5, 0x3f, 0x4b, 0x36, 0xb2, 0x48, 0xda, 0x2b, 0x0d, 0xd8, 0x4c, 0x1b, 0x0a, 0xaf, 0xf6, 0x4a, 0x03, 0x36, 0x60, 0x7a, 0x04, 0x41, 0xc3, 0xef, 0x60, 0xdf, 0x55, 0xdf, 0x67, 0xa8, 0xef, 0x8e, 0x6e, 0x31, 0x79, 0x0e, 0x69, 0x46, 0x8c, 0xb3, 0x51, 0xcb, 0x1a, 0x83, 0x63, 0xbc, 0xa0, 0xd2, 0x6f, 0x25, 0x36, 0xe2, 0x68, 0x52, 0x95, 0x77, 0x0c, 0xcc, 0x03, 0x47, 0x0b, 0xbb, 0xb9, 0x14, 0x02, 0x22, 0x2f, 0x26, 0x05, 0x55, 0xbe, 0x3b, 0xb6, 0xc5, 0x28, 0x0b, 0xbd, 0xb2, 0x92, 0x5a, 0xb4, 0x2b, 0x04, 0x6a, 0xb3, 0x5c, 0xa7, 0xff, 0xd7, 0xc2, 0x31, 0xcf, 0xd0, 0xb5, 0x8b, 0x9e, 0xd9, 0x2c, 0x1d, 0xae, 0xde, 0x5b, 0xb0, 0x72, 0x64, 0x9b, 0x26, 0xf2, 0xe3, 0xec, 0x9c, 0xa3, 0x6a, 0x75, 0x0a, 0x93, 0x6d, 0x02, 0xa9, 0x06, 0x09, 0x9c, 0x3f, 0x36, 0x0e, 0xeb, 0x85, 0x68, 0x07, 0x72, 0x13, 0x07, 0x00, 0x05, 0x82, 0x48, 0xbf, 0x95, 0x14, 0x7a, 0xb8, 0xe2, 0xae, 0x2b, 0xb1, 0x7b, 0x38, 0x1b, 0xb6, 0x0c, 0x9b, 0x8e, 0xd2, 0x92, 0x0d, 0xbe, 0xd5, 0xe5, 0xb7, 0xef, 0xdc, 0x7c, 0x21, 0xdf, 0xdb, 0x0b, 0x94, 0xd2, 0xd3, 0x86, 0x42, 0xe2, 0xd4, 0xf1, 0xf8, 0xb3, 0xdd, 0x68, 0x6e, 0x83, 0xda, 0x1f, 0xcd, 0x16, 0xbe, 0x81, 0x5b, 0x26, 0xb9, 0xf6, 0xe1, 0x77, 0xb0, 0x6f, 0x77, 0x47, 0xb7, 0x18, 0xe0, 0x5a, 0x08, 0x88, 0x70, 0x6a, 0x0f, 0xf1, 0xca, 0x3b, 0x06, 0x66, 0x5c, 0x0b, 0x01, 0x11, 0xff, 0x9e, 0x65, 0x8f, 0x69, 0xae, 0x62, 0xf8, 0xd3, 0xff, 0x6b, 0x61, 0x45, 0xcf, 0x6c, 0x16, 0x78, 0xe2, 0x0a, 0xa0, 0xee, 0xd2, 0x0d, 0xd7, 0x54, 0x83, 0x04, 0x4e, 0xc2, 0xb3, 0x03, 0x39, 0x61, 0x26, 0x67, 0xa7, 0xf7, 0x16, 0x60, 0xd0, 0x4d, 0x47, 0x69, 0x49, 0xdb, 0x77, 0x6e, 0x3e, 0x4a, 0x6a, 0xd1, 0xae, 0xdc, 0x5a, 0xd6, 0xd9, 0x66, 0x0b, 0xdf, 0x40, 0xf0, 0x3b, 0xd8, 0x37, 0x53, 0xae, 0xbc, 0xa9, 0xc5, 0x9e, 0xbb, 0xde, 0x7f, 0xcf, 0xb2, 0x47, 0xe9, 0xff, 0xb5, 0x30, 0x1c, 0xf9, 0xbd, 0xbd, 0x8a, 0xcd, 0xba, 0xca, 0x30, 0x9e, 0xb3, 0x53, 0xa6, 0xa3, 0xbc, 0x24, 0x05, 0x3b, 0xd0, 0xba, 0xa3, 0x06, 0xd7, 0xcd, 0xe9, 0x57, 0xde, 0x54, 0xbf, 0x67, 0xd9, 0x23, 0x2e, 0x72, 0x66, 0xb3, 0xb8, 0x4a, 0x61, 0xc4, 0x02, 0x1b, 0x38, 0x5d, 0x94, 0x2b, 0x6f, 0x2b, 0x37, 0xbe, 0xcb, 0xb4, 0xa1, 0x8e, 0xcc, 0xc3, 0x1b, 0xdf, 0x0d, 0x5a, 0x8d, 0xed, 0x02, 0x2d]

var tcp := StreamPeerTCP.new()
var blowfish: BlowfishGD
var receive_buffer := PackedByteArray()
var security_ready := false
var count_seeds := PackedByteArray([0, 0, 0])
var crc_seed := 0
var gateway_host := ""
var gateway_port := 0
var account_id := ""
var account_password := ""
var locale := 22
var shard_id := 1
var session_id := 0
var agent_host := ""
var agent_port := 0
var stage := "idle"
var connecting_deadline := 0

func _init() -> void:
    blowfish = BlowfishGD.new()

func begin_login(host: String, port: int, user_id: String, password: String, login_locale: int, login_shard: int) -> void:
    gateway_host = host.strip_edges()
    gateway_port = port
    account_id = user_id
    account_password = password
    locale = login_locale
    shard_id = login_shard
    session_id = 0
    stage = "gateway"
    _reset_connection_state()
    status_changed.emit("Connecting to Gateway %s:%d" % [gateway_host, gateway_port])
    var error := tcp.connect_to_host(gateway_host, gateway_port)
    if error != OK:
        _fail("TCP connect failed: %s" % error)
        return
    connecting_deadline = Time.get_ticks_msec() + 10000

func poll() -> void:
    tcp.poll()
    var state := tcp.get_status()
    if state == StreamPeerTCP.STATUS_ERROR:
        _fail("TCP connection error")
        return
    if state == StreamPeerTCP.STATUS_NONE:
        if stage != "idle" and Time.get_ticks_msec() > connecting_deadline:
            _fail("Connection timed out")
        return
    if state == StreamPeerTCP.STATUS_CONNECTED:
        if connecting_deadline != 0 and stage != "idle":
            connecting_deadline = Time.get_ticks_msec() + 10000
        var available := tcp.get_available_bytes()
        if available > 0:
            var result := tcp.get_data(available)
            if result[0] != OK:
                _fail("TCP read failed")
                return
            receive_buffer.append_array(result[1])
            _process_frames()

func _reset_connection_state() -> void:
    receive_buffer = PackedByteArray()
    security_ready = false
    count_seeds = PackedByteArray([0, 0, 0])
    crc_seed = 0
    blowfish = BlowfishGD.new()

func _process_frames() -> void:
    while receive_buffer.size() >= 2:
        var length_word := _read_u16(receive_buffer, 0)
        var encrypted := (length_word & 0x8000) != 0
        var payload_length := length_word & 0x7fff
        var total := 6 + payload_length
        if encrypted:
            total = 2 + int(ceil(float(4 + payload_length) / 8.0)) * 8
        if receive_buffer.size() < total:
            return
        var frame := receive_buffer.slice(0, total)
        receive_buffer = receive_buffer.slice(total)
        var decoded := _decode_frame(frame, payload_length, encrypted)
        if decoded.is_empty():
            _fail("Invalid or truncated frame")
            return
        _handle_packet(decoded[0], decoded[1])
        if stage == "idle":
            return

func _decode_frame(frame: PackedByteArray, payload_length: int, encrypted: bool) -> Array:
    if encrypted:
        var decrypted := blowfish.decode(frame.slice(2))
        if decrypted.size() < 4 + payload_length:
            return []
        var opcode := _read_u16(decrypted, 0)
        return [opcode, decrypted.slice(4, 4 + payload_length)]
    if frame.size() < 6 + payload_length:
        return []
    return [_read_u16(frame, 2), frame.slice(6, 6 + payload_length)]

func _handle_packet(opcode: int, payload: PackedByteArray) -> void:
    match opcode:
        OP_HANDSHAKE:
            _handle_security_offer(payload)
        OP_HANDSHAKE_ACCEPT:
            status_changed.emit("Security handshake accepted")
        OP_IDENTITY:
            var reader := PacketReader.new(payload)
            var identity := reader.read_ascii()
            if stage == "gateway" and identity == "GatewayServer":
                status_changed.emit("Gateway identity accepted; sending login")
                _send_gateway_login()
            elif stage == "agent" and identity == "AgentServer":
                status_changed.emit("Agent identity accepted; sending session")
                _send_agent_login()
            else:
                _fail("Unexpected server identity: %s" % identity)
        OP_GATEWAY_LOGIN_RESPONSE:
            _handle_gateway_login(payload)
        OP_AGENT_LOGIN_RESPONSE:
            _handle_agent_login(payload)
        OP_AGENT_CHARACTER_SCREEN_RESPONSE:
            _handle_character_screen(payload)
        OP_AGENT_CHARACTER_SELECT_RESPONSE:
            _handle_character_select_response(payload)
        OP_AGENT_LOAD_START:
            status_changed.emit("Agent started character load")
        OP_AGENT_LOAD_DATA:
            _handle_character_load(payload)
        OP_AGENT_LOAD_END:
            status_changed.emit("Character load complete")
        OP_AGENT_STATS:
            _handle_stats(payload)
        OP_AGENT_WORLD_READY:
            status_changed.emit("World entry accepted")
            world_ready.emit()
        _:
            status_changed.emit("Received opcode 0x%04X" % opcode)

func _handle_security_offer(payload: PackedByteArray) -> void:
    if payload.size() < 1:
        _fail("Empty security offer")
        return
    var reader := PacketReader.new(payload)
    var flags := reader.read_u8()
    if (flags & 0x02) != 0:
        if reader.remaining() < 8:
            _fail("Security offer has no Blowfish key")
            return
        var key := reader.read_bytes(8)
        blowfish.initialize(key)
    if (flags & 0x04) != 0:
        if reader.remaining() < 8:
            _fail("Security offer has no Security Bytes seeds")
            return
        var seed_count := reader.read_u32()
        crc_seed = reader.read_u32()
        _setup_count_bytes(seed_count)
    security_ready = true
    status_changed.emit("Security parameters received")
    _send_plain(OP_HANDSHAKE_ACCEPT, PackedByteArray())
    _send_encrypted(OP_IDENTITY, _ascii_with_flag("SR_Client", 0))

func _send_gateway_login() -> void:
    var writer := PacketWriter.new()
    writer.write_u8(locale)
    writer.write_ascii(account_id)
    writer.write_ascii(account_password)
    writer.write_u16(shard_id)
    _send_encrypted(OP_GATEWAY_LOGIN, writer.data)
    status_changed.emit("Gateway login packet sent")

func _send_agent_login() -> void:
    var writer := PacketWriter.new()
    writer.write_i32(session_id)
    writer.write_ascii(account_id)
    writer.write_ascii(account_password)
    _send_encrypted(OP_AGENT_LOGIN, writer.data)
    status_changed.emit("Agent login packet sent")

func _handle_gateway_login(payload: PackedByteArray) -> void:
    var reader := PacketReader.new(payload)
    if reader.remaining() < 1:
        _fail("Empty Gateway login response")
        return
    var result := reader.read_u8()
    if result != 1:
        var code := reader.read_u8() if reader.remaining() > 0 else 0
        _fail("Gateway rejected login (result=%d, code=%d)" % [result, code])
        return
    if reader.remaining() < 4:
        _fail("Gateway success response has no session")
        return
    session_id = reader.read_i32()
    agent_host = reader.read_ascii()
    agent_port = reader.read_u16()
    status_changed.emit("Gateway login succeeded; Agent %s:%d" % [agent_host, agent_port])
    gateway_login_succeeded.emit(session_id, agent_host, agent_port)
    _connect_agent()

func _handle_agent_login(payload: PackedByteArray) -> void:
    var reader := PacketReader.new(payload)
    if reader.remaining() > 0 and reader.read_u8() == 1:
        status_changed.emit("Agent authentication succeeded; requesting character list")
        agent_login_succeeded.emit()
        stage = "character_screen"
        request_character_list()
    else:
        _fail("Agent rejected the session")

func _connect_agent() -> void:
    tcp.disconnect_from_host()
    stage = "agent"
    _reset_connection_state()
    status_changed.emit("Connecting to Agent %s:%d" % [agent_host, agent_port])
    var error := tcp.connect_to_host(agent_host, agent_port)
    if error != OK:
        _fail("Agent TCP connect failed: %s" % error)
        return
    connecting_deadline = Time.get_ticks_msec() + 10000

func request_character_list() -> void:
    stage = "character_screen"
    var writer := PacketWriter.new()
    writer.write_u8(2)
    _send_encrypted(OP_AGENT_CHARACTER_SCREEN, writer.data)
    status_changed.emit("Requesting character list")

func check_character_name(char_name: String) -> void:
    var writer := PacketWriter.new()
    writer.write_u8(4)
    writer.write_ascii(char_name)
    _send_encrypted(OP_AGENT_CHARACTER_SCREEN, writer.data)

func create_character(char_name: String, model: int, scale: int, items: Array[int]) -> void:
    var writer := PacketWriter.new()
    writer.write_u8(1)
    writer.write_ascii(char_name)
    writer.write_i32(model)
    writer.write_u8(clampi(scale, 0, 68))
    for i in range(4):
        writer.write_i32(items[i] if i < items.size() else 0)
    _send_encrypted(OP_AGENT_CHARACTER_SCREEN, writer.data)
    status_changed.emit("Character creation request sent")

func select_character(index: int) -> void:
    _send_encrypted(OP_AGENT_CHARACTER_SELECT, PackedByteArray([index & 0xff]))
    status_changed.emit("Selecting character slot %d" % index)

func enter_world() -> void:
    _send_encrypted(OP_AGENT_ENTER_WORLD, PackedByteArray())
    status_changed.emit("Entering the starter world")

func send_move_to(region: int, x: int, y: int, z: int) -> void:
    var writer := PacketWriter.new()
    writer.write_u8(1)
    writer.write_i16(region)
    writer.write_i16(x)
    writer.write_i16(y)
    writer.write_i16(z)
    _send_encrypted(OP_AGENT_MOVE, writer.data)

func send_stop(angle: int = 0) -> void:
    var writer := PacketWriter.new()
    writer.write_u16(angle)
    _send_encrypted(OP_AGENT_STOP, writer.data)

func _handle_character_screen(payload: PackedByteArray) -> void:
    var reader := PacketReader.new(payload)
    if reader.remaining() < 2:
        return
    var mode := reader.read_u8()
    var result := reader.read_u8()
    if mode == 1:
        character_create_result.emit(result == 1, result)
        status_changed.emit("Character creation accepted" if result == 1 else "Character creation rejected (code %d)" % result)
        if result == 1:
            request_character_list()
    elif mode == 4:
        character_name_check_result.emit(result == 1, result)
    elif mode == 2 and result == 1:
        var characters: Array = []
        for slot in range(3):
            if reader.remaining() < 1:
                break
            var exists := reader.read_u8()
            if exists == 0:
                continue
            if reader.remaining() < 4:
                break
            var character := {"slot": slot, "model": reader.read_i32(), "name": reader.read_ascii(), "scale": reader.read_u8(), "level": reader.read_u8(), "exp": reader.read_i64(), "strength": reader.read_i16(), "intellect": reader.read_i16(), "stat_points": reader.read_i16(), "hp": reader.read_i32(), "mp": reader.read_i32(), "items": []}
            var item_count := reader.read_u8() if reader.remaining() > 0 else 0
            for _item in range(item_count):
                if reader.remaining() < 4:
                    break
                character.items.append(reader.read_i32())
            characters.append(character)
        character_list_received.emit(characters)
        status_changed.emit("Received %d character slot(s)" % characters.size())

func _handle_character_select_response(payload: PackedByteArray) -> void:
    if payload.size() > 0 and payload[0] == 1:
        character_selected.emit(0)
        status_changed.emit("Character selected; waiting for load data")
    elif payload.size() > 0:
        _fail("Agent rejected character selection")

func _handle_character_load(payload: PackedByteArray) -> void:
    var reader := PacketReader.new(payload)
    if reader.remaining() < 4:
        return
    var data := {"model": reader.read_i32(), "name": reader.read_ascii(), "scale": reader.read_u8(), "level": reader.read_u8(), "max_level": reader.read_u8(), "exp": reader.read_i64(), "skill_exp": reader.read_i32(), "gold": reader.read_i64(), "skill_points": reader.read_i32(), "stat_points": reader.read_i16(), "hwan_count": reader.read_u8(), "hp": 0, "mp": 0}
    if reader.remaining() >= 4:
        reader.read_i32()
    if reader.remaining() >= 8:
        data.hp = reader.read_i32()
        data.mp = reader.read_i32()
    character_loaded.emit(data)
    status_changed.emit("Loaded character %s (Lv.%d)" % [data.name, data.level])

func _handle_stats(payload: PackedByteArray) -> void:
    var reader := PacketReader.new(payload)
    if reader.remaining() < 40:
        return
    reader.read_i32()
    reader.read_i32()
    reader.read_i32()
    reader.read_i32()
    reader.read_u16()
    reader.read_u16()
    reader.read_u16()
    reader.read_u16()
    var max_hp := reader.read_i32()
    var max_mp := reader.read_i32()
    reader.read_i16()
    reader.read_i16()
    stats_updated.emit(max_hp, max_mp, max_hp, max_mp)

func _send_plain(opcode: int, payload: PackedByteArray) -> void:
    var frame := PackedByteArray()
    _append_u16(frame, payload.size())
    _append_u16(frame, opcode)
    frame.append(_generate_count_byte(true) if security_ready else 0)
    frame.append(0)
    frame.append_array(payload)
    if security_ready:
        frame[5] = _generate_check_byte(frame)
    _send_bytes(frame)

func _send_encrypted(opcode: int, payload: PackedByteArray) -> void:
    var plain := PackedByteArray()
    _append_u16(plain, payload.size() | 0x8000)
    _append_u16(plain, opcode)
    plain.append(_generate_count_byte(true) if security_ready else 0)
    plain.append(0)
    plain.append_array(payload)
    var crc := _generate_check_byte(plain)
    plain[5] = crc
    var encrypted := blowfish.encode(plain.slice(2))
    var frame := PackedByteArray()
    _append_u16(frame, payload.size() | 0x8000)
    frame.append_array(encrypted)
    _send_bytes(frame)

func _send_bytes(bytes: PackedByteArray) -> void:
    var error := tcp.put_data(bytes)
    if error != OK:
        _fail("TCP write failed")

func _ascii_with_flag(text: String, flag: int) -> PackedByteArray:
    var writer := PacketWriter.new()
    writer.write_ascii(text)
    writer.write_u8(flag)
    return writer.data

func _generate_value(value: int) -> int:
    var result := value & MASK
    for _i in range(32):
        result = (((((((((((result >> 2) ^ result) >> 2) ^ result) >> 1) ^ result) >> 1) ^ result) >> 1) ^ result) & 1) | ((((result & 1) << 31) | (result >> 1)) & 0xfffffffe)
        result &= MASK
    return result

func _setup_count_bytes(seed: int) -> void:
    if seed == 0:
        seed = 0x9abfb3b6
    var mut := seed
    var mut1 := _generate_value(mut)
    mut = mut1
    var mut2 := _generate_value(mut)
    mut = mut2
    var mut3 := _generate_value(mut)
    mut = mut3
    _generate_value(mut)
    var byte1 := (mut & 0xff) ^ (mut3 & 0xff)
    var byte2 := (mut1 & 0xff) ^ (mut2 & 0xff)
    if byte1 == 0:
        byte1 = 1
    if byte2 == 0:
        byte2 = 1
    count_seeds[0] = (byte1 ^ byte2) & 0xff
    count_seeds[1] = byte2 & 0xff
    count_seeds[2] = byte1 & 0xff

func _generate_count_byte(update: bool) -> int:
    var result := (count_seeds[2] * ((~count_seeds[0]) + count_seeds[1])) & 0xff
    result = (result ^ (result >> 4)) & 0xff
    if update:
        count_seeds[0] = result
    return result

func _generate_check_byte(stream: PackedByteArray) -> int:
    var checksum := 0xffffffff
    var modded_seed := (crc_seed << 8) & MASK
    for value in stream:
        var table_index := (modded_seed + ((value ^ checksum) & 0xff)) & 0xffff
        checksum = ((checksum >> 8) ^ _security_table_value(table_index)) & MASK
    return (((checksum >> 24) & 0xff) + ((checksum >> 8) & 0xff) + ((checksum >> 16) & 0xff) + (checksum & 0xff)) & 0xff

func _security_table_value(index: int) -> int:
    var block := int(index / 256)
    var ecx := index & 0xff
    var edx := _read_u32_from_base(block * 4)
    var eax := ecx >> 1
    if (ecx & 1) != 0:
        eax ^= edx
    for _bit in range(7):
        if (eax & 1) != 0:
            eax = (eax >> 1) ^ edx
        else:
            eax >>= 1
    return eax & MASK

func _read_u32_from_base(index: int) -> int:
    return BASE_SECURITY_TABLE[index] | (BASE_SECURITY_TABLE[index + 1] << 8) | (BASE_SECURITY_TABLE[index + 2] << 16) | (BASE_SECURITY_TABLE[index + 3] << 24)

func _append_u16(out: PackedByteArray, value: int) -> void:
    out.append(value & 0xff)
    out.append((value >> 8) & 0xff)

func _append_u32(out: PackedByteArray, value: int) -> void:
    value &= MASK
    out.append(value & 0xff)
    out.append((value >> 8) & 0xff)
    out.append((value >> 16) & 0xff)
    out.append((value >> 24) & 0xff)

func _read_u16(data: PackedByteArray, index: int) -> int:
    return data[index] | (data[index + 1] << 8)

func _fail(message: String) -> void:
    status_changed.emit(message)
    login_failed.emit(message)
    stage = "idle"
    tcp.disconnect_from_host()

class PacketWriter:
    var data := PackedByteArray()
    func write_u8(value: int) -> void:
        data.append(value & 0xff)
    func write_u16(value: int) -> void:
        data.append(value & 0xff)
        data.append((value >> 8) & 0xff)
    func write_i16(value: int) -> void:
        data.append(value & 0xff)
        data.append((value >> 8) & 0xff)
    func write_i32(value: int) -> void:
        data.append(value & 0xff)
        data.append((value >> 8) & 0xff)
        data.append((value >> 16) & 0xff)
        data.append((value >> 24) & 0xff)
    func write_ascii(text: String) -> void:
        var bytes: PackedByteArray = text.to_ascii_buffer()
        write_u16(bytes.size())
        data.append_array(bytes)

class PacketReader:
    var data: PackedByteArray
    var offset := 0
    func _init(input: PackedByteArray = PackedByteArray()) -> void:
        data = input
    func remaining() -> int:
        return data.size() - offset
    func read_u8() -> int:
        var value := data[offset]
        offset += 1
        return value
    func read_u16() -> int:
        var value := data[offset] | (data[offset + 1] << 8)
        offset += 2
        return value
    func read_i16() -> int:
        var value := read_u16()
        return value - 0x10000 if value & 0x8000 else value
    func read_u32() -> int:
        var value := data[offset] | (data[offset + 1] << 8) | (data[offset + 2] << 16) | (data[offset + 3] << 24)
        offset += 4
        return value & 0xffffffff
    func read_i32() -> int:
        var value := read_u32()
        if value & 0x80000000:
            return value - 0x100000000
        return value
    func read_i64() -> int:
        var value := 0
        for i in range(8):
            value |= int(data[offset + i]) << (i * 8)
        offset += 8
        return value
    func read_bytes(count: int) -> PackedByteArray:
        var value := data.slice(offset, offset + count)
        offset += count
        return value
    func read_ascii() -> String:
        var length := read_u16()
        if length == 0:
            return ""
        return read_bytes(length).get_string_from_ascii()
