extends Control

@onready var health_label: Label = $CenterContainer/Panel/VBoxContainer/HealthLabel
@onready var health_bar: ProgressBar = $CenterContainer/Panel/VBoxContainer/HealthBar
@onready var heal_button: Button = $CenterContainer/Panel/VBoxContainer/HealButton
@onready var leave_button: Button = $CenterContainer/Panel/VBoxContainer/LeaveButton


const HEAL_AMOUNT: int = 1
var healing_used: bool = false


func _ready() -> void:
	update_health_display()


func update_health_display() -> void:
	health_label.text = ("HP: " + str(RunManager.player_health) + " / " + str(RunManager.player_max_health))
	health_bar.max_value = RunManager.player_max_health
	health_bar.value = RunManager.player_health


func heal_player() -> void:
	if healing_used:
		return
	var heal_amount: int = int(RunManager.player_max_health * HEAL_AMOUNT)
	RunManager.player_health += heal_amount
	RunManager.player_health = mini(RunManager.player_health, RunManager.player_max_health)
	healing_used = true
	update_health_display()
	heal_button.disabled = true
	heal_button.text = "Rested"
	print("Recovered 1 health.")


func _on_heal_button_pressed() -> void:
	heal_player()


func _on_leave_button_pressed() -> void:
	finish_healing_room()


func finish_healing_room() -> void:
	RunManager.complete_selected_room()
	get_tree().change_scene_to_file("res://GameManager/Map/RunMap.tscn")






#
