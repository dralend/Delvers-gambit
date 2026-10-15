extends Control

const DECK_CARD_SCENE: PackedScene = preload("res://menus/deck_card_button.tscn")
const DECK_SIZE: int = 5

@onready var collection_grid: GridContainer = $MarginContainer/VBoxContainer/Content/CollectionPanel/VBoxContainer/ScrollContainer/CollectionGrid
@onready var deck_list: VBoxContainer = $MarginContainer/VBoxContainer/Content/DeckPanel/VBoxContainer/VScrollBar/DeckList
@onready var deck_count_label: Label = $MarginContainer/VBoxContainer/Header/DeckCountLabel
@onready var save_deck_button: Button = $MarginContainer/VBoxContainer/SaveDeckButton

var working_deck: Array[Dictionary] = []


func _ready() -> void:
	print("========== DECK BUILDER ==========")
	print("Collection variants: ", RunManager.card_collection_variants.size())
	for variant: Dictionary in RunManager.card_collection_variants:
		print(
			"Unlocked card: ",
			str(variant.get("path", "")),
			" | Rarity: ",
			int(variant.get("rarity", CardData.Rarity.NORMAL))
		)
	working_deck.clear()
	for saved_variant: Dictionary in RunManager.saved_deck:
		working_deck.append(saved_variant.duplicate(true))
	create_collection()
	update_deck_display()
	print("==================================")


func create_collection() -> void:
	for child: Node in collection_grid.get_children():
		child.queue_free()
	for variant: Dictionary in RunManager.card_collection_variants:
		var card_path: String = str(variant.get("path", ""))
		if card_path.is_empty():
			continue
		if not ResourceLoader.exists(card_path):
			push_warning("Card does not exist: " + card_path)
			continue
		var card_data: CardData = RunManager.create_saved_card_variant(variant)
		if card_data == null:
			push_warning("Could not create card variant: " + card_path)
			continue
		var card_button: DeckCardButton = DECK_CARD_SCENE.instantiate() as DeckCardButton
		if card_button == null:
			push_error("Could not create DeckCardButton.")
			continue
		collection_grid.add_child(card_button)
		card_button.setup_variant(variant, card_data)
		card_button.card_pressed.connect(_on_collection_card_pressed.bind(variant))


func _on_collection_card_pressed(_card_path: String, variant: Dictionary) -> void:
	if working_deck.size() >= DECK_SIZE:
		print("Deck is full.")
		return

	if variant_is_in_deck(variant):
		print("Card variant already in deck.")
		return

	working_deck.append(variant.duplicate(true))
	update_deck_display()


func variant_is_in_deck(variant: Dictionary) -> bool:
	var new_path: String = str(variant.get("path", ""))
	var new_rarity: int = int(variant.get("rarity", CardData.Rarity.NORMAL))
	for selected: Dictionary in working_deck:
		var selected_path: String = str(selected.get("path", ""))
		var selected_rarity: int = int(selected.get("rarity", CardData.Rarity.NORMAL))
		if selected_path == new_path and selected_rarity == new_rarity:
			return true
	return false


func update_deck_display() -> void:
	for child: Node in deck_list.get_children():
		child.queue_free()
	for variant: Dictionary in working_deck:
		var card_path: String = str(variant.get("path", ""))
		if card_path.is_empty():
			continue
		if not ResourceLoader.exists(card_path):
			continue
		var card_data: CardData = RunManager.create_saved_card_variant(variant)
		if card_data == null:
			continue
		var card_button: DeckCardButton = DECK_CARD_SCENE.instantiate() as DeckCardButton
		if card_button == null:
			continue
		deck_list.add_child(card_button)
		card_button.setup_variant(variant, card_data)
		card_button.card_pressed.connect(_remove_card.bind(variant))
	deck_count_label.text = "Deck: " + str(working_deck.size()) + " / " + str(DECK_SIZE)
	save_deck_button.disabled = working_deck.size() != DECK_SIZE


func _remove_card(_card_path: String, variant: Dictionary) -> void:
	var index: int = find_variant(working_deck, variant)
	if index == -1:
		return
	working_deck.remove_at(index)
	update_deck_display()


func find_variant(list: Array[Dictionary], variant: Dictionary) -> int:
	var path: String = str(variant.get("path", ""))
	var rarity: int = int(variant.get("rarity", CardData.Rarity.NORMAL))
	for i: int in range(list.size()):
		var current: Dictionary = list[i]
		if str(current.get("path", "")) == path:
			if int(current.get("rarity", CardData.Rarity.NORMAL)) == rarity:
				return i
	return -1


func _on_save_deck_button_pressed() -> void:
	if working_deck.size() != DECK_SIZE:
		print("Deck must contain exactly ", DECK_SIZE, " cards.")
		return
	RunManager.saved_deck.clear()
	for variant: Dictionary in working_deck:
		RunManager.saved_deck.append(variant.duplicate(true))
	RunManager.save_card_collection()
	print("Deck saved with rarity variants.")
	get_tree().change_scene_to_file("res://menus/card_collection.tscn")


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://menus/card_collection.tscn")
