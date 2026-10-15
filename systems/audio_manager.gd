extends Node


const SFX_PATHS: Dictionary = {
	"ui_hover": "res://audio/ui_hover.wav",
	"ui_click": "res://audio/ui_click.mp3",
	"card_select": "res://audio/card_select.wav",
	"card_place": "res://audio/card_place.wav",
	"card_capture": "res://audio/card_capture.mp3",
	"turn_change": "res://audio/turn_change.wav",
	"victory": "res://audio/victory.wav",
	"defeat": "res://audio/defeat.wav",
	"room_select": "res://audio/room_select.wav",
	"draw": "res://audio/draw.wav"
}


const MUSIC_PATH: String = "res://audio/Explorer's Market.wav"
const BATTLE_MUSIC_PATH: String = "res://audio/battle_music.wav"

const SFX_POOL_SIZE: int = 8


var music_player: AudioStreamPlayer
var battle_music_player: AudioStreamPlayer

var sfx_players: Array[AudioStreamPlayer] = []
var sfx_streams: Dictionary = {}

var master_volume: float = 1.0
var music_volume: float = 0.55
var sfx_volume: float = 0.75

var last_scene_path: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)
	battle_music_player = AudioStreamPlayer.new()
	battle_music_player.bus = "Music"
	add_child(battle_music_player)
	for i in range(SFX_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		sfx_players.append(player)
	load_sfx()
	var normal_music := load(MUSIC_PATH) as AudioStream
	if normal_music != null:
		music_player.stream = normal_music
	var battle_music := load(BATTLE_MUSIC_PATH) as AudioStream
	if battle_music != null:
		battle_music_player.stream = battle_music
	set_music_volume(music_volume)
	set_sfx_volume(sfx_volume)
	music_player.finished.connect(_on_music_finished)
	battle_music_player.finished.connect(_on_battle_music_finished)
	get_tree().node_added.connect(_on_node_added)
	get_tree().scene_changed.connect(_on_scene_changed)
	play_normal_music()


func load_sfx() -> void:
	sfx_streams.clear()
	for sound_name: String in SFX_PATHS:
		var path: String = SFX_PATHS[sound_name]
		var stream := load(path) as AudioStream
		if stream == null:
			push_warning("Could not load SFX: " + sound_name + " | " + path)
			continue
		sfx_streams[sound_name] = stream


func _on_node_added(node: Node) -> void:
	if node is Button:
		call_deferred("_connect_button", node as Button)


func _on_scene_changed() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	call_deferred("_scan_scene_for_buttons", scene)
	var path: String = scene.scene_file_path
	if path == last_scene_path:
		return
	last_scene_path = path
	if path == "res://menus/GameOver.tscn":
		pause_music()
		return
	if path == "res://GameManager/game.tscn":
		play_battle_music()
		return
	if path == "res://menus/MainMenu.tscn":
		play_normal_music()
		return
	if path.begins_with("res://GameManager/"):
		play_normal_music()
	elif path.begins_with("res://menus/"):
		play_normal_music()


func _scan_scene_for_buttons(node: Node) -> void:
	if node == null:
		return
	if node is Button:
		_connect_button(node as Button)
	for child: Node in node.get_children():
		_scan_scene_for_buttons(child)


func _connect_button(button: Button) -> void:
	if not is_instance_valid(button):
		return
	if button.has_meta("audio_manager_connected"):
		return
	button.set_meta("audio_manager_connected", true)
	button.mouse_entered.connect(_on_button_hover)
	button.pressed.connect(_on_button_pressed)


func _on_button_hover() -> void:
	play_sfx("ui_hover")


func _on_button_pressed() -> void:
	play_sfx("ui_click")


func play_sfx(sound_name: String) -> void:
	if not sfx_streams.has(sound_name):
		push_warning("SFX not found: " + sound_name)
		return
	var stream: AudioStream = sfx_streams[sound_name]
	if stream == null:
		push_warning("SFX stream is null: " + sound_name)
		return
	if sfx_players.is_empty():
		push_warning("No SFX players available.")
		return
	for player: AudioStreamPlayer in sfx_players:
		if is_instance_valid(player) and not player.playing:
			player.stream = stream
			player.volume_db = _get_sfx_volume_db()
			player.play()
			return
	if is_instance_valid(sfx_players[0]):
		var fallback: AudioStreamPlayer = sfx_players[0]
		fallback.stream = stream
		fallback.volume_db = _get_sfx_volume_db()
		fallback.play()


func play_music() -> void:
	play_normal_music()


func play_normal_music() -> void:
	if music_player == null:
		return
	battle_music_player.stop()
	if music_player.stream == null:
		var stream := load(MUSIC_PATH) as AudioStream
		if stream == null:
			push_warning("Could not load normal music.")
			return
		music_player.stream = stream
	music_player.volume_db = _get_music_volume_db()
	music_player.stream_paused = false
	if not music_player.playing:
		music_player.play()


func play_battle_music() -> void:
	if battle_music_player == null:
		return
	music_player.stop()
	if battle_music_player.stream == null:
		var stream := load(BATTLE_MUSIC_PATH) as AudioStream
		if stream == null:
			push_warning("Could not load battle music: " + BATTLE_MUSIC_PATH)
			return
		battle_music_player.stream = stream
	battle_music_player.volume_db = _get_music_volume_db()
	battle_music_player.stream_paused = false
	if not battle_music_player.playing:
		battle_music_player.play()


func pause_music() -> void:
	if music_player != null:
		music_player.stream_paused = true
	if battle_music_player != null:
		battle_music_player.stream_paused = true


func resume_music() -> void:
	if music_player != null:
		if music_player.stream != null:
			music_player.stream_paused = false
	if battle_music_player != null:
		if battle_music_player.stream != null:
			battle_music_player.stream_paused = false


func _on_music_finished() -> void:
	if music_player == null:
		return
	if music_player.stream != null:
		music_player.play()


func _on_battle_music_finished() -> void:
	if battle_music_player == null:
		return
	if battle_music_player.stream != null:
		battle_music_player.play()


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	var volume_db: float = _get_master_volume_db() + _get_music_volume_db()
	if music_player != null:
		music_player.volume_db = volume_db
	if battle_music_player != null:
		battle_music_player.volume_db = volume_db


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	var volume_db: float = _get_master_volume_db() + _get_sfx_volume_db()
	for player in sfx_players:
		if player != null:
			player.volume_db = volume_db


func _get_music_volume_db() -> float:
	if music_volume <= 0.0:
		return -80.0
	return linear_to_db(music_volume)


func _get_sfx_volume_db() -> float:
	if sfx_volume <= 0.0:
		return -80.0
	return linear_to_db(sfx_volume)


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	var volume_db: float = _get_master_volume_db()
	for player in sfx_players:
		if player != null:
			player.volume_db = volume_db + _get_sfx_volume_db()
	if music_player != null:
		music_player.volume_db = volume_db + _get_music_volume_db()
	if battle_music_player != null:
		battle_music_player.volume_db = volume_db + _get_music_volume_db()


func _get_master_volume_db() -> float:
	if master_volume <= 0.0:
		return -80.0
	return linear_to_db(master_volume)
