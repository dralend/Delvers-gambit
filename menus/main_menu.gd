extends Control

@onready var new_run_button: Button = $MenuPanel/VBoxContainer/NewRunButton
@onready var continue_button: Button = $MenuPanel/VBoxContainer/ContinueButton
@onready var collection_button: Button = $MenuPanel/VBoxContainer/CollectionButton
@onready var settings_button: Button = $MenuPanel/VBoxContainer/SettingsButton
@onready var quit_button: Button = $MenuPanel/VBoxContainer/QuitButton
@onready var settings_panel: PanelContainer = $SettingsPanel
@onready var master_slider: HSlider = $SettingsPanel/Panel/MarginContainer/VBoxContainer/MasterSlider
@onready var music_slider: HSlider = $SettingsPanel/Panel/MarginContainer/VBoxContainer/MusicSlider
@onready var sfx_slider: HSlider = $SettingsPanel/Panel/MarginContainer/VBoxContainer/SFXSlider
@onready var fullscreen_check_box: CheckBox = $SettingsPanel/Panel/MarginContainer/VBoxContainer/FullscreenCheckBox
@onready var resolution_option: OptionButton = $SettingsPanel/Panel/MarginContainer/VBoxContainer/ResolutionOptionButton
@onready var close_button: Button = $SettingsPanel/Panel/MarginContainer/VBoxContainer/CloseButton
@onready var reset_button: Button = $SettingsPanel/Panel/MarginContainer/VBoxContainer/ResetButton
@onready var vsync_check_box: CheckBox = $SettingsPanel/Panel/MarginContainer/VBoxContainer/VSyncCheckBox


func _ready() -> void:
	settings_panel.hide()
	setup_resolution_options()
	update_settings_ui()
	master_slider.value_changed.connect(_on_master_slider_changed)
	music_slider.value_changed.connect(_on_music_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	resolution_option.item_selected.connect(_on_resolution_selected)
	fullscreen_check_box.toggled.connect(_on_fullscreen_toggled)
	vsync_check_box.toggled.connect(_on_vsync_toggled)
	close_button.pressed.connect(_on_settings_close_pressed)
	reset_button.pressed.connect(_on_settings_reset_pressed)


func update_continue_button() -> void:
	continue_button.disabled = not RunManager.run_active


func _on_new_run_button_pressed() -> void:
	get_tree().change_scene_to_file("res://menus/PreRun.tscn")


func _on_continue_button_pressed() -> void:
	if not RunManager.run_active:
		return
	get_tree().change_scene_to_file("res://GameManager/Map/RunMap.tscn")


func _on_collection_button_pressed() -> void:
	get_tree().change_scene_to_file("res://menus/card_collection.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_music_slider_changed(value: float) -> void:
	SettingsManager.set_music_volume(value)


func _on_sfx_slider_changed(value: float) -> void:
	SettingsManager.set_sfx_volume(value)
	AudioManager.play_sfx("ui_click")


func _on_settings_close_pressed() -> void:
	settings_panel.hide()


func _on_settings_reset_pressed() -> void:
	SettingsManager.reset_to_defaults()
	update_settings_ui()


func _on_settings_pressed() -> void:
	settings_panel.show()


func _on_master_slider_changed(value: float) -> void:
	SettingsManager.set_master_volume(value)


func _on_fullscreen_toggled(enabled: bool) -> void:
	SettingsManager.set_fullscreen(enabled)


func setup_resolution_options() -> void:
	resolution_option.clear()
	resolution_option.add_item("1280 x 720")
	resolution_option.add_item("1152 x 648")
	resolution_option.add_item("960 x 540")
	resolution_option.add_item("800 x 450")


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


func update_settings_ui() -> void:
	master_slider.value = SettingsManager.master_volume
	music_slider.value = SettingsManager.music_volume
	sfx_slider.value = SettingsManager.sfx_volume
	fullscreen_check_box.button_pressed = SettingsManager.fullscreen
	vsync_check_box.button_pressed = SettingsManager.vsync
	var resolutions: Array[Vector2i] = [
		Vector2i(1280, 720),
		Vector2i(1152, 648),
		Vector2i(960, 540),
		Vector2i(800, 450)
	]
	var current_resolution_index := resolutions.find(SettingsManager.resolution)
	if current_resolution_index >= 0:
		resolution_option.select(current_resolution_index)


























































#
