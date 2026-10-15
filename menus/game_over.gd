extends Control

@onready var title_label: Label = $CenterContainer/PanelContainer/VBoxContainer/TitleLabel
@onready var message_label: Label = $CenterContainer/PanelContainer/VBoxContainer/MessageLabel
@onready var reset_button: Button = $CenterContainer/PanelContainer/VBoxContainer/ResetButton
@onready var continue_button: Button = $CenterContainer/PanelContainer/VBoxContainer/MainMenuButton


func _ready() -> void:
	reset_button.pressed.connect(_on_reset_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	if RunManager.run_won:
		setup_victory()
	else:
		setup_game_over()


func setup_game_over() -> void:
	title_label.text = "GAME OVER"
	message_label.text = "Your run has ended."
	reset_button.text = "Reset Run"
	reset_button.show()
	continue_button.text = "Return to Main Menu"


func setup_victory() -> void:
	title_label.text = "VICTORY!"
	message_label.text = "You defeated the final boss!\nThe kingdom is saved!"
	reset_button.hide()
	continue_button.text = "Return to Main Menu"


func _on_reset_pressed() -> void:
	RunManager.start_new_run()
	RunManager.run_ending = false
	RunManager.run_won = false
	get_tree().change_scene_to_file("res://GameManager/Map/RunMap.tscn")


func _on_continue_pressed() -> void:
	RunManager.run_ending = false
	RunManager.run_won = false
	get_tree().change_scene_to_file("res://menus/MainMenu.tscn")
