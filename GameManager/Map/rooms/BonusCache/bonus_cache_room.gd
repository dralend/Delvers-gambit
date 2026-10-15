extends Control

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var description_label: Label = $MarginContainer/VBoxContainer/DescriptionLabel
@onready var choices: HBoxContainer = $MarginContainer/VBoxContainer/Choices
@onready var card_choice: Button = $MarginContainer/VBoxContainer/Choices/CardChoice
@onready var item_choice: Button = $MarginContainer/VBoxContainer/Choices/ItemChoice
@onready var continue_button: Button = $MarginContainer/VBoxContainer/ContinueButton

var reward_selected: bool = false


func _ready() -> void:
	title_label.text = "BONUS CACHE"
	description_label.text = ("You discovered a hidden cache!\n" + "Choose one reward.")
	card_choice.pressed.connect(_on_card_choice_pressed)
	item_choice.pressed.connect(_on_item_choice_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	if get_random_card().is_empty():
		card_choice.disabled = true
		card_choice.text = "NO NEW CARDS"
	continue_button.hide()


func _on_card_choice_pressed() -> void:
	if reward_selected:
		return
	reward_selected = true
	give_card_reward()
	card_choice.disabled = true
	item_choice.disabled = true
	continue_button.show()


func _on_item_choice_pressed() -> void:
	if reward_selected:
		return
	reward_selected = true
	give_item_reward()
	card_choice.disabled = true
	item_choice.disabled = true
	continue_button.show()


func give_card_reward() -> void:
	var card_path: String = get_random_card()
	if card_path.is_empty():
		description_label.text = "No card reward was available."
		return
	RunManager.add_card_to_collection(card_path)
	var card_data := load(card_path) as CardData
	if card_data != null:
		description_label.text = ("You received:\n\n" + card_data.card_name)
	else:
		description_label.text = "You received a new card!"


func give_item_reward() -> void:
	var item: ItemData = ItemGenerator.generate_item()
	if item == null:
		description_label.text = "No item reward was available."
		return
	RunManager.give_item(item)
	description_label.text = ("You received:\n\n" + item.item_name + "\n\n" + item.description)


func get_random_card() -> String:
	var available_cards: Array[String] = []
	for card_path: String in CardDatabase.ALL_CARDS:
		if not RunManager.card_collection.has(card_path):
			available_cards.append(card_path)
	if available_cards.is_empty():
		return ""
	var index: int = randi_range(0, available_cards.size() - 1)
	return available_cards[index]


func _on_continue_pressed() -> void:
	RunManager.complete_selected_room()
	get_tree().change_scene_to_file("res://GameManager/Map/run_map.tscn")
