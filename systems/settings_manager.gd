extends Node

const SETTINGS_PATH := "user://settings.cfg"

const DEFAULT_MASTER_VOLUME := 1.0
const DEFAULT_MUSIC_VOLUME := 0.55
const DEFAULT_SFX_VOLUME := 0.75
const DEFAULT_FULLSCREEN := false
const DEFAULT_RESOLUTION := Vector2i(1280, 720)
const DEFAULT_VSYNC := true

var master_volume: float = DEFAULT_MASTER_VOLUME
var music_volume: float = DEFAULT_MUSIC_VOLUME
var sfx_volume: float = DEFAULT_SFX_VOLUME

var fullscreen: bool = DEFAULT_FULLSCREEN
var resolution: Vector2i = DEFAULT_RESOLUTION
var vsync: bool = DEFAULT_VSYNC


func _ready() -> void:
	load_settings()
	apply_all_settings()


func load_settings() -> void:
	var config := ConfigFile.new()
	var error := config.load(SETTINGS_PATH)
	if error != OK:
		return
	master_volume = float(config.get_value("audio", "master_volume", DEFAULT_MASTER_VOLUME))
	music_volume = float(config.get_value("audio", "music_volume",DEFAULT_MUSIC_VOLUME))
	sfx_volume = float(config.get_value("audio", "sfx_volume", DEFAULT_SFX_VOLUME))
	fullscreen = bool(config.get_value("display", "fullscreen", DEFAULT_FULLSCREEN))
	var saved_width := int(config.get_value("display", "resolution_width", DEFAULT_RESOLUTION.x))
	var saved_height := int(config.get_value("display", "resolution_height", DEFAULT_RESOLUTION.y))
	resolution = Vector2i(saved_width, saved_height)
	vsync = bool(config.get_value("display", "vsync", DEFAULT_VSYNC))


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("display", "resolution_width", resolution.x)
	config.set_value("display", "resolution_height", resolution.y)
	config.set_value("display", "vsync", vsync)
	config.save(SETTINGS_PATH)


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	if AudioManager != null:
		AudioManager.set_master_volume(master_volume)
	save_settings()


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	if AudioManager != null:
		AudioManager.set_music_volume(music_volume)
	save_settings()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	if AudioManager != null:
		AudioManager.set_sfx_volume(sfx_volume)
	save_settings()


func set_fullscreen(enabled: bool) -> void:
	fullscreen = enabled
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(resolution)
	save_settings()


func set_resolution(new_resolution: Vector2i) -> void:
	resolution = new_resolution
	if not fullscreen:
		DisplayServer.window_set_size(resolution)
	save_settings()


func set_vsync(enabled: bool) -> void:
	vsync = enabled
	if vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	save_settings()


func apply_all_settings() -> void:
	if AudioManager != null:
		AudioManager.set_master_volume(master_volume)
		AudioManager.set_music_volume(music_volume)
		AudioManager.set_sfx_volume(sfx_volume)
	if vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(resolution)


func reset_to_defaults() -> void:
	master_volume = DEFAULT_MASTER_VOLUME
	music_volume = DEFAULT_MUSIC_VOLUME
	sfx_volume = DEFAULT_SFX_VOLUME
	fullscreen = DEFAULT_FULLSCREEN
	resolution = DEFAULT_RESOLUTION
	vsync = DEFAULT_VSYNC
	save_settings()
	apply_all_settings()
