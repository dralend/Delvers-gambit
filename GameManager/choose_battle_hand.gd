extends Control

const BATTLE_HAND_SIZE: int = 5

const DECK_CARD_SCENE: PackedScene = preload("res://menus/deck_card_button.tscn")

@onready var available_grid: GridContainer = $MarginContainer/VBoxContainer/Content/AvailablePanel/AvailableVBox/AvailableScroll/AvailableGrid
@onready var hand_list: VBoxContainer = $MarginContainer/VBoxContainer/Content/HandPanel/HandVBox/HandScroll/HandList
@onready var combat_type_label: Label = $MarginContainer/VBoxContainer/Header/CombatTypeLabel
@onready var hand_count_label: Label = $MarginContainer/VBoxContainer/Header/HandCountLabel
@onready var start_battle_button: Button = $MarginContainer/VBoxContainer/ButtonBar/StartBattleButton

var selected_hand: Array[Dictionary] = []


func _ready() -> void:
	print("========== BATTLE HAND ==========")
	print("Collection variants: ", RunManager.card_collection_variants.size())
	print("Player cards: ", RunManager.player_cards.size())
	print("Saved deck: ", RunManager.saved_deck.size())
	print("=================================")
	setup_combat_label()
	create_available_cards()
	update_hand_display()


func setup_combat_label() -> void:
	match RunManager.current_combat_type:
		"normal":
			combat_type_label.text = "NORMAL COMBAT"
		"elite":
			combat_type_label.text = "ELITE COMBAT"
		"boss":
			combat_type_label.text = "BOSS BATTLE"
		_:
			combat_type_label.text = "COMBAT"


func create_available_cards() -> void:
	for child: Node in available_grid.get_children():
		child.queue_free()
	print("Creating battle cards: ", RunManager.card_collection_variants.size())
	for variant: Dictionary in RunManager.card_collection_variants:
		var card_path: String = str(variant.get("path", ""))
		if card_path.is_empty():
			continue
		var card_data: CardData = RunManager.create_saved_card_variant(variant)
		if card_data == null:
			print("Could not create saved card variant: ", card_path)
			continue
		var button: DeckCardButton = DECK_CARD_SCENE.instantiate() as DeckCardButton
		if button == null:
			push_error("Could not create DeckCardButton.")
			continue
		available_grid.add_child(button)
		button.setup(card_path, card_data)
		button.card_pressed.connect(_on_available_card_pressed.bind(variant))
		print("Displayed battle card: ", card_data.card_name, " | Rarity: ", card_data.rarity)


func _on_available_card_pressed(_card_path: String, variant: Dictionary) -> void:
	if selected_hand.size() >= BATTLE_HAND_SIZE:
		return
	if variant_is_selected(variant):
		return
	selected_hand.append(variant)
	update_hand_display()


func variant_is_selected(variant: Dictionary) -> bool:
	var new_path: String = str(variant.get("path", ""))
	var new_rarity: int = int(variant.get("rarity", CardData.Rarity.NORMAL))
	for selected: Dictionary in selected_hand:
		var selected_path: String = str(selected.get("path", ""))
		var selected_rarity: int = int(selected.get("rarity", CardData.Rarity.NORMAL))
		if selected_path == new_path:
			if selected_rarity == new_rarity:
				return true
	return false


func update_hand_display() -> void:
	for child: Node in hand_list.get_children():
		child.queue_free()
	for variant: Dictionary in selected_hand:
		var card_data: CardData = RunManager.create_saved_card_variant(variant)
		if card_data == null:
			continue
		var card_button: DeckCardButton = DECK_CARD_SCENE.instantiate() as DeckCardButton
		if card_button == null:
			continue
		hand_list.add_child(card_button)
		card_button.setup_variant(variant, card_data)
		card_button.card_pressed.connect(_on_hand_card_pressed.bind(variant))
	hand_count_label.text = ("Hand: " + str(selected_hand.size()) + " / " + str(BATTLE_HAND_SIZE))
	start_battle_button.disabled = (selected_hand.size() != BATTLE_HAND_SIZE)


func _remove_card(variant: Dictionary) -> void:
	var index: int = find_selected_variant(variant)
	if index == -1:
		return
	selected_hand.remove_at(index)
	update_hand_display()


func find_selected_variant(variant: Dictionary) -> int:
	var path: String = str(variant.get("path", ""))
	var rarity: int = int(variant.get("rarity", CardData.Rarity.NORMAL))
	for i in range(selected_hand.size()):
		var selected: Dictionary = selected_hand[i]
		if str(selected.get("path", "")) == path:
			if int(selected.get("rarity", 0)) == rarity:
				return i
	return -1


func get_rarity_text(rarity: CardData.Rarity) -> String:
	match rarity:
		CardData.Rarity.NORMAL:
			return "◆"
		CardData.Rarity.RARE:
			return "◆◆"
		CardData.Rarity.MYTHIC:
			return "◆◆◆"
	return "◆"


func _on_auto_select_button_pressed() -> void:
	selected_hand.clear()
	var available_cards: Array[Dictionary] = []
	for variant: Dictionary in RunManager.card_collection_variants:
		available_cards.append(variant)
	available_cards.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			var card_a: CardData = RunManager.create_saved_card_variant(a)
			var card_b: CardData = RunManager.create_saved_card_variant(b)
			if card_a == null:
				return false
			if card_b == null:
				return true
			return get_card_power(card_a) > get_card_power(card_b)
	)
	var amount: int = mini(BATTLE_HAND_SIZE, available_cards.size())
	for i in range(amount):
		selected_hand.append(available_cards[i])
	update_hand_display()


func _on_start_battle_button_pressed() -> void:
	if selected_hand.size() != BATTLE_HAND_SIZE:
		return
	RunManager.set_battle_hand_variants(selected_hand)
	if not RunManager.battle_hand_is_ready():
		return
	get_tree().change_scene_to_file("res://GameManager/Board/game.tscn")


func _on_back_button_pressed() -> void:
	RunManager.clear_battle_hand()
	get_tree().change_scene_to_file("res://GameManager/Map/RunMap.tscn")


func _on_hand_card_pressed(_card_path: String, variant: Dictionary) -> void:
	_remove_card(variant)


func get_card_power(card_data: CardData) -> int:
	if card_data == null:
		return 0
	return (card_data.up + card_data.right + card_data.down + card_data.left)


















































#
