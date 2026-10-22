extends Control

@onready var gold_label: Label = $Center/Panel/VBox/GoldLabel


func _ready() -> void:
	gold_label.text = "Your gold: " + str(RunManager.reward_points)

func _on_shop_pressed() -> void:
	RunManager.shop_return_to_map = true
	get_tree().change_scene_to_file("res://menus/Shop.tscn")

func _on_continue_pressed() -> void:
	RunManager.shop_return_to_map = false
	get_tree().change_scene_to_file("res://GameManager/Map/RunMap.tscn")
