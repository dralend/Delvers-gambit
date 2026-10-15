extends Control

@onready var resume_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ResumeButton
@onready var settings_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SettingsButton
@onready var return_to_map_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ReturnToMapButton
@onready var main_menu_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/MainMenuButton

@onready var settings_panel: Control = $SettingsPanel

@onready var master_slider: HSlider = $SettingsPanel/Panel/MarginContainer/VBoxContainer/MasterSlider
@onready var music_slider: HSlider = $SettingsPanel/Panel/MarginContainer/VBoxContainer/MusicSlider
@onready var sfx_slider: HSlider = $SettingsPanel/Panel/MarginContainer/VBoxContainer/SFXSlider

@onready var fullscreen_check_box: CheckBox = $SettingsPanel/Panel/MarginContainer/VBoxContainer/FullscreenCheckBox
@onready var resolution_option: OptionButton = $SettingsPanel/Panel/MarginContainer/VBoxContainer/ResolutionOptionButton
@onready var vsync_check_box: CheckBox = $SettingsPanel/Panel/MarginContainer/VBoxContainer/VSyncCheckBox

@onready var close_button: Button = $SettingsPanel/Panel/MarginContainer/VBoxContainer/CloseButton
@onready var reset_button: Button = $SettingsPanel/Panel/MarginContainer/VBoxContainer/ResetButton

var is_paused: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	resume_button.pressed.connect(_on_resume_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	return_to_map_button.pressed.connect(_on_return_to_map_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	master_slider.value_changed.connect(_on_master_slider_changed)
	music_slider.value_changed.connect(_on_music_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	fullscreen_check_box.toggled.connect(_on_fullscreen_toggled)
	resolution_option.item_selected.connect(_on_resolution_selected)
	vsync_check_box.toggled.connect(_on_vsync_toggled)
	close_button.pressed.connect(_on_settings_close_pressed)
	reset_button.pressed.connect(_on_settings_reset_pressed)
	setup_resolution_options()
	update_settings_ui()
	settings_panel.hide()
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if settings_panel.visible:
			close_settings()
		else:
			toggle_pause()


func toggle_pause() -> void:
	if is_paused:
		resume_game()
	else:
		pause_game()


func pause_game() -> void:
	is_paused = true
	update_settings_ui()
	settings_panel.hide()
	show()
	get_tree().paused = true


func resume_game() -> void:
	is_paused = false
	settings_panel.hide()
	hide()
	get_tree().paused = false


func _on_settings_pressed() -> void:
	settings_panel.show()
	update_settings_ui()


func close_settings() -> void:
	settings_panel.hide()


func _on_settings_close_pressed() -> void:
	close_settings()


func _on_master_slider_changed(value: float) -> void:
	SettingsManager.set_master_volume(value)


func _on_music_slider_changed(value: float) -> void:
	SettingsManager.set_music_volume(value)


func _on_sfx_slider_changed(value: float) -> void:
	SettingsManager.set_sfx_volume(value)
	AudioManager.play_sfx("ui_click")


func _on_fullscreen_toggled(enabled: bool) -> void:
	SettingsManager.set_fullscreen(enabled)


func _on_resolution_selected(index: int) -> void:
	var resolutions: Array[Vector2i] = [
		Vector2i(1280, 720),
		Vector2i(1152, 648),
		Vector2i(960, 540),
		Vector2i(800, 450)
	]
	if index < 0 or index >= resolutions.size():
		return
	SettingsManager.set_resolution(resolutions[index])


func _on_vsync_toggled(enabled: bool) -> void:
	SettingsManager.set_vsync(enabled)


func setup_resolution_options() -> void:
	resolution_option.clear()
	resolution_option.add_item("1280 x 720")
	resolution_option.add_item("1152 x 648")
	resolution_option.add_item("960 x 540")
	resolution_option.add_item("800 x 450")


func update_settings_ui() -> void:
	master_slider.set_value_no_signal(SettingsManager.master_volume)
	music_slider.set_value_no_signal(SettingsManager.music_volume)
	sfx_slider.set_value_no_signal(SettingsManager.sfx_volume)
	fullscreen_check_box.set_pressed_no_signal(SettingsManager.fullscreen)
	vsync_check_box.set_pressed_no_signal(SettingsManager.vsync)
	var resolutions: Array[Vector2i] = [
		Vector2i(1280, 720),
		Vector2i(1152, 648),
		Vector2i(960, 540),
		Vector2i(800, 450)
	]
	var current_index := resolutions.find(SettingsManager.resolution)
	if current_index >= 0:
		resolution_option.select(current_index)


func _on_settings_reset_pressed() -> void:
	SettingsManager.reset_to_defaults()
	update_settings_ui()


func _on_resume_pressed() -> void:
	resume_game()


func _on_return_to_map_pressed() -> void:
	get_tree().paused = false
	is_paused = false
	RunManager.clear_battle_hand()
	RunManager.clear_encounter_progress()
	get_tree().change_scene_to_file("res://GameManager/Map/RunMap.tscn")


func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	is_paused = false
	get_tree().change_scene_to_file("res://menus/MainMenu.tscn")
