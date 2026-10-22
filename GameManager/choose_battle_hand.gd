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

	var best_cards: Array[Dictionary] = get_best_available_cards()
	print("Creating best-rarity battle cards: ", best_cards.size())
	for variant: Dictionary in best_cards:
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
		print("Displayed best card: ", card_data.card_name, " | Rarity: ", card_data.rarity)


func get_best_available_cards() -> Array[Dictionary]:
	# Keep only the highest rarity currently unlocked for each card name.
	# Rarity enum order is NORMAL < RARE < MYTHIC.
	var best_by_name: Dictionary = {}
	for variant: Dictionary in RunManager.card_collection_variants:
		var path: String = str(variant.get("path", ""))
		if path.is_empty():
			continue
		var card_data: CardData = RunManager.create_saved_card_variant(variant)
		if card_data == null:
			continue
		var card_name: String = card_data.card_name
		var rarity: int = int(variant.get("rarity", card_data.rarity))
		if not best_by_name.has(card_name):
			best_by_name[card_name] = variant
			continue
		var existing: Dictionary = best_by_name[card_name]
		var existing_data: CardData = RunManager.create_saved_card_variant(existing)
		var existing_rarity: int = int(existing.get("rarity", existing_data.rarity if existing_data != null else CardData.Rarity.NORMAL))
		if rarity > existing_rarity:
			best_by_name[card_name] = variant

	var result: Array[Dictionary] = []
	for card_variant: Variant in best_by_name.values():
		if card_variant is Dictionary:
			result.append(card_variant)
	return result

func _on_available_card_pressed(_card_path: String, variant: Dictionary) -> void:
	if selected_hand.size() >= BATTLE_HAND_SIZE:
		return
	if variant_is_selected(variant):
		return
	selected_hand.append(variant)
	update_hand_display()


func variant_is_selected(variant: Dictionary) -> bool:
	# A card type is identified by its source resource path.
	# Only one copy of that type is allowed in the battle hand,
	# even if the collection contains Normal, Rare, and Mythic variants.
	var new_path: String = str(variant.get("path", ""))
	for selected: Dictionary in selected_hand:
		if str(selected.get("path", "")) == new_path:
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
	for i in range(selected_hand.size()):
		if str(selected_hand[i].get("path", "")) == path:
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
	var available_cards: Array[Dictionary] = get_best_available_cards()
	available_cards.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			var card_a: CardData = RunManager.create_saved_card_variant(a)
			var card_b: CardData = RunManager.create_saved_card_variant(b)
			if card_a == null:
				return false
			if card_b == null:
				return true
			# Choose the strongest cards after selecting each card name's
			# highest unlocked rarity.
			var power_a: int = get_card_power(card_a)
			var power_b: int = get_card_power(card_b)
			if power_a == power_b:
				return int(a.get("rarity", card_a.rarity)) > int(b.get("rarity", card_b.rarity))
			return power_a > power_b
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
