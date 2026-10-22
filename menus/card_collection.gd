extends Control

const LOCKED_CARD_SCENE: PackedScene = preload("res://GameManager/Card/LockedCard.tscn")
const CARD_SCENE: PackedScene = preload("res://GameManager/Card/card.tscn")

const PLAYER: int = 0

@onready var collection_grid: GridContainer = $MarginContainer/VBoxContainer/ScrollContainer/CollectionGrid
@onready var details_panel: Panel = $CardDetailsPanel
@onready var selected_name_label: Label = $CardDetailsPanel/VBoxContainer/SelectedNameLabel
@onready var selected_artwork: TextureRect = $CardDetailsPanel/VBoxContainer/SelectedArtwork
@onready var values_label: Label = $CardDetailsPanel/VBoxContainer/ValuesLabel
@onready var description_label: Label = $CardDetailsPanel/VBoxContainer/DescriptionLabel
@onready var card_count_label: Label = $MarginContainer/VBoxContainer/Header/CardCountLabel
@onready var main_container: MarginContainer = $MarginContainer
@onready var main_vbox: VBoxContainer = $MarginContainer/VBoxContainer
@onready var scroll_container: ScrollContainer = $MarginContainer/VBoxContainer/ScrollContainer

var all_card_paths: Array[String] = []


func _ready() -> void:
	# Keep the backdrop decorative so it never blocks clicks.
	var backdrop: Control = get_node_or_null("CollectionBackdrop") as Control
	if backdrop != null:
		backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background_overlay: Control = get_node_or_null("Background") as Control
	if background_overlay != null:
		background_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	main_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.custom_minimum_size = Vector2(0, 500)
	collection_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	collection_grid.custom_minimum_size = Vector2(900, 0)
	collection_grid.columns = 4
	collection_grid.visible = true
	collection_grid.z_index = 2
	collection_grid.add_theme_constant_override("h_separation", 18)
	collection_grid.add_theme_constant_override("v_separation", 18)
	load_all_cards()
	build_collection()
	details_panel.visible = false
	print("Card Collection loaded: ", all_card_paths.size(), " card types; ",
		RunManager.card_collection.size(), " unlocked paths; ",
		RunManager.card_collection_variants.size(), " saved variants.")
	var deck_button: Button = get_node_or_null("MarginContainer/VBoxContainer/Header/DeckBuilderButton") as Button
	if deck_button != null and not deck_button.pressed.is_connected(_on_deck_builder_button_pressed):
		deck_button.pressed.connect(_on_deck_builder_button_pressed)
	var back_button: Button = get_node_or_null("MarginContainer/VBoxContainer/Header/BackButton") as Button
	if back_button != null and not back_button.pressed.is_connected(_on_back_button_pressed):
		back_button.pressed.connect(_on_back_button_pressed)
	call_deferred("_debug_collection_layout")


func load_all_cards() -> void:
	all_card_paths.clear()
	# Use the explicit database rather than directory scanning.
	for card_path: String in CardDatabase.ALL_CARDS:
		if ResourceLoader.exists(card_path) and not all_card_paths.has(card_path):
			var data := ResourceLoader.load(card_path) as CardData
			if data != null:
				all_card_paths.append(card_path)
	all_card_paths.sort()
	if card_count_label != null:
		card_count_label.text = "%d unlocked / %d card types" % [
			RunManager.card_collection.size(), all_card_paths.size()
		]
	if all_card_paths.is_empty():
		push_error("Card Collection: no CardData resources loaded from CardDatabase.ALL_CARDS.")


func build_collection() -> void:
	for child: Node in collection_grid.get_children():
		collection_grid.remove_child(child)
		child.queue_free()
	collection_grid.visible = true
	collection_grid.columns = 4

	var display_paths: Array[String] = []
	for card_path: String in RunManager.card_collection:
		if all_card_paths.has(card_path) and not display_paths.has(card_path):
			display_paths.append(card_path)
	for card_path: String in all_card_paths:
		if not display_paths.has(card_path):
			display_paths.append(card_path)
	for card_path: String in display_paths:
		create_card_variants(card_path)


func create_card_variants(card_path: String) -> void:
	var base_card := ResourceLoader.load(card_path) as CardData
	if base_card == null:
		push_warning("Could not load card: " + card_path)
		return

	var best_variant: Dictionary = {}
	var best_rarity := -1
	for variant: Dictionary in RunManager.card_collection_variants:
		if str(variant.get("path", "")) != card_path:
			continue
		var rarity := int(variant.get("rarity", int(CardData.Rarity.NORMAL)))
		if rarity > best_rarity:
			best_rarity = rarity
			best_variant = variant

	if RunManager.card_collection.has(card_path):
		if not best_variant.is_empty():
			var saved_card := RunManager.create_saved_card_variant(best_variant) as CardData
			if saved_card != null:
				create_unlocked_card(saved_card)
				return
		# Older saves store unlocked cards as paths without rarity dictionaries.
		create_unlocked_card(base_card)
	else:
		create_locked_card(base_card)


func get_saved_variant(card_path: String, rarity: CardData.Rarity) -> Dictionary:
	for variant: Dictionary in RunManager.card_collection_variants:
		var saved_path: String = str(
			variant.get("path", "")
		)
		var saved_rarity: int = int(
			variant.get(
				"rarity",
				CardData.Rarity.NORMAL
			)
		)
		if saved_path == card_path:
			if saved_rarity == int(rarity):
				return variant
	return {}


# ============================================================
# CREATE UNLOCKED CARD
# ============================================================

func create_unlocked_card(card_data: CardData) -> void:

	if card_data == null:
		return
	var card: GameCard = CARD_SCENE.instantiate() as GameCard
	if card == null:
		push_error("Could not instantiate GameCard.")
		return
	collection_grid.add_child(card)
	card.custom_minimum_size = Vector2(220, 300)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.set_card_data(card_data)
	card.set_card_owner(PLAYER)
	if not card.card_clicked.is_connected(_on_card_clicked):
		card.card_clicked.connect(_on_card_clicked)
	print(
		"Displayed collection card: ",
		card_data.card_name,
		" | Rarity: ",
		card_data.rarity
	)


# ============================================================
# CREATE LOCKED CARD
# ============================================================

func create_locked_card(card_data: CardData) -> void:
	if card_data == null:
		return
	var locked_card: Control = LOCKED_CARD_SCENE.instantiate() as Control
	if locked_card == null:
		push_error("Could not instantiate LockedCard.")
		return
	locked_card.custom_minimum_size = Vector2(220, 300)
	locked_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var question_mark: Label = locked_card.get_node_or_null(
		"QuestionMark"
	) as Label
	if question_mark != null:
		question_mark.text = "?"
	var rarity_label: Label = locked_card.get_node_or_null(
		"RarityLabel"
	) as Label
	if rarity_label != null:
		match card_data.rarity:
			CardData.Rarity.NORMAL:
				rarity_label.text = "◆"
			CardData.Rarity.RARE:
				rarity_label.text = "◆◆"
			CardData.Rarity.MYTHIC:
				rarity_label.text = "◆◆◆"
	collection_grid.add_child(locked_card)


func _on_card_clicked(card: GameCard) -> void:
	if card == null:
		return
	if card.data == null:
		return
	var card_data: CardData = card.data
	details_panel.visible = true
	selected_name_label.text = card_data.card_name
	if card_data.artwork != null:
		selected_artwork.texture = card_data.artwork
		selected_artwork.visible = true
	else:
		selected_artwork.texture = null
		selected_artwork.visible = false
	values_label.text = (
		"UP: " + str(card_data.up)
		+ "\nRIGHT: " + str(card_data.right)
		+ "\nDOWN: " + str(card_data.down)
		+ "\nLEFT: " + str(card_data.left)
	)
	description_label.text = get_card_description(card_data)


func get_card_description(card_data: CardData) -> String:
	var text: String = ""
	match card_data.rarity:
		CardData.Rarity.NORMAL:
			text += "◆ Normal"
		CardData.Rarity.RARE:
			text += "◆◆ Rare"
		CardData.Rarity.MYTHIC:
			text += "◆◆◆ Mythic"
			if not card_data.mythic_ability.is_empty():
				text += "\n\nMythic Ability: "
				text += card_data.mythic_ability
			if not card_data.mythic_description.is_empty():
				text += "\n"
				text += card_data.mythic_description
	return text


func _on_deck_builder_button_pressed() -> void:
	get_tree().change_scene_to_file("res://menus/DeckBuilder.tscn")


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://menus/MainMenu.tscn")


func _debug_collection_layout() -> void:
	print("ScrollContainer size: ", scroll_container.size)
	print("Grid size: ", collection_grid.size)
	print("Grid child count: ", collection_grid.get_child_count())
	for i in range(mini(3, collection_grid.get_child_count())):
		var child: Control = collection_grid.get_child(i) as Control
		if child != null:
			print(
				"Card ", i,
				" | size: ", child.size,
				" | visible: ", child.is_visible_in_tree(),
				" | position: ", child.global_position,
				" | modulate: ", child.modulate
			)
