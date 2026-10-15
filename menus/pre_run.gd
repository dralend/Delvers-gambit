extends Control

enum RunLength {
	SHORT,
	STANDARD,
	LONG
}

@onready var easy_button: Button = $CenterContainer/Panel/VBoxContainer/EasyButton
@onready var normal_button: Button = $CenterContainer/Panel/VBoxContainer/NormalButton
@onready var hard_button: Button = $CenterContainer/Panel/VBoxContainer/HardButton
@onready var run_info_label: Label = $CenterContainer/Panel/VBoxContainer/RunInfoLabel
@onready var start_button: Button = $CenterContainer/Panel/VBoxContainer/StartButton
@onready var back_button: Button = $CenterContainer/Panel/VBoxContainer/BackButton
@onready var tutorial_button: Button = $CenterContainer/Panel/VBoxContainer/TutorialButton

var selected_run_length: RunLength = RunLength.SHORT

var selected_encounters: int = 12
var selected_bosses: int = 2


func _ready() -> void:
	tutorial_button.pressed.connect(_on_tutorial_pressed)
	if RunManager.is_run_length_unlocked("standard"):
		select_normal()
	else:
		select_easy()
	update_difficulty_buttons()


func select_easy() -> void:
	selected_run_length = RunLength.SHORT
	selected_encounters = 12
	selected_bosses = 1
	update_button_states()


func select_normal() -> void:
	if not RunManager.is_run_length_unlocked("standard"):
		return
	selected_run_length = RunLength.STANDARD
	selected_encounters = 24
	selected_bosses = 2
	update_button_states()


func select_hard() -> void:
	if not RunManager.is_run_length_unlocked("long"):
		return
	selected_run_length = RunLength.LONG
	selected_encounters = 36
	selected_bosses = 3
	update_button_states()


func update_button_states() -> void:
	easy_button.text = "SHORT RUN"
	if RunManager.is_run_length_unlocked("standard"):
		normal_button.text = "STANDARD RUN"
	else:
		normal_button.text = "STANDARD RUN\n🔒 Beat Short to unlock"
	if RunManager.is_run_length_unlocked("long"):
		hard_button.text = "LONG RUN"
	else:
		hard_button.text = "LONG RUN\n🔒 Beat Normal to unlock"
	match selected_run_length:
		RunLength.SHORT:
			easy_button.text = "▶ SHORT RUN"
		RunLength.STANDARD:
			if RunManager.is_difficulty_unlocked("normal"):
				normal_button.text = "▶ STANDARD RUN"
		RunLength.LONG:
			if RunManager.is_difficulty_unlocked("hard"):
				hard_button.text = "▶ LONG RUN"
	update_run_info()


func update_run_info() -> void:
	match selected_run_length:
		RunLength.SHORT:
			run_info_label.text = ("SHORT RUN\n\n" + "Rooms: 12\n" + "Bosses: 1")
		RunLength.STANDARD:
			run_info_label.text = ("STANDARD RUN\n\n" + "Rooms: 24\n" + "Bosses: 2")
		RunLength.LONG:
			run_info_label.text = ("LONG RUN\n\n" + "Rooms: 36\n" + "Bosses: 3")


func _on_easy_button_pressed() -> void:
	select_easy()


func _on_normal_button_pressed() -> void:
	normal_button.disabled = not RunManager.is_run_length_unlocked("standard")
	select_normal()


func _on_hard_button_pressed() -> void:
	hard_button.disabled = not RunManager.is_run_length_unlocked("long")
	select_hard()


func _on_start_button_pressed() -> void:
	match selected_run_length:
		RunLength.SHORT:
			RunManager.current_run_length = "short"
		RunLength.STANDARD:
			RunManager.current_run_length = "standard"
		RunLength.LONG:
			RunManager.current_run_length = "long"
	RunManager.run_encounter_count = selected_encounters
	RunManager.run_boss_count = selected_bosses
	RunManager.start_new_run()
	get_tree().change_scene_to_file("res://GameManager/Map/RunMap.tscn")


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://menus/MainMenu.tscn")


func update_difficulty_buttons() -> void:
	var normal_unlocked: bool = RunManager.is_run_length_unlocked("standard")
	var hard_unlocked: bool = RunManager.is_run_length_unlocked("long")
	normal_button.disabled = not normal_unlocked
	hard_button.disabled = not hard_unlocked
	update_button_states()


func _on_tutorial_pressed() -> void:
	get_tree().change_scene_to_file("res://menus/Tutorial.tscn")
