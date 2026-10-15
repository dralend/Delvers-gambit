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
@onready var main_container: MarginContainer = $MarginContainer
@onready var main_vbox: VBoxContainer = $MarginContainer/VBoxContainer
@onready var scroll_container: ScrollContainer = $MarginContainer/VBoxContainer/ScrollContainer

var all_card_paths: Array[String] = []


func _ready() -> void:
	main_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.custom_minimum_size = Vector2(0, 500)
	collection_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	collection_grid.custom_minimum_size = Vector2(900, 0)
	collection_grid.columns = 4
	collection_grid.add_theme_constant_override("h_separation", 18)
	collection_grid.add_theme_constant_override("v_separation", 18)
	load_all_cards()
	build_collection()
	details_panel.visible = false
	call_deferred("_debug_collection_layout")


func load_all_cards() -> void:
	all_card_paths.clear()
	print("Starting card scan...")
	print("Folder exists: ", DirAccess.dir_exists_absolute("res://GameManager/Card/Type"))
	scan_card_folder("res://GameManager/Card/Type")
	print("Cards found: ", all_card_paths.size())
	for path: String in all_card_paths:
		print("Found card: ", path)


func scan_card_folder(folder_path: String) -> void:
	var directory: DirAccess = DirAccess.open(folder_path)
	if directory == null:
		push_error("Could not open card folder: " + folder_path)
		return
	directory.list_dir_begin()
	while true:
		var file_name: String = directory.get_next()
		if file_name.is_empty():
			break
		if file_name == "." or file_name == "..":
			continue
		var full_path: String = folder_path + "/" + file_name
		if directory.current_is_dir():
			scan_card_folder(full_path)
			continue
		if file_name.ends_with(".tres"):
			var card_data: CardData = load(full_path) as CardData
			if card_data != null:
				all_card_paths.append(full_path)
	directory.list_dir_end()


func build_collection() -> void:
	print("Collection grid valid: ", is_instance_valid(collection_grid))
	for child: Node in collection_grid.get_children():
		collection_grid.remove_child(child)
		child.queue_free()
	print("Building collection from ", all_card_paths.size(), " cards.")
	for card_path: String in all_card_paths:
		create_card_variants(card_path)
	print("Cards added to grid: ", collection_grid.get_child_count())
	print("Grid size: ", collection_grid.size)
	print("Grid position: ", collection_grid.global_position)
	print("Grid visible: ", collection_grid.is_visible_in_tree())


func create_card_variants(card_path: String) -> void:
	var base_card: CardData = load(card_path) as CardData
	if base_card == null:
		push_warning("Could not load card: " + card_path)
		return
	var normal_card: CardData = base_card.duplicate() as CardData
	normal_card.rarity = CardData.Rarity.NORMAL
	normal_card.mythic_ability = ""
	normal_card.mythic_description = ""
	create_collection_entry(
		card_path,
		CardData.Rarity.NORMAL,
		normal_card
	)
	var rare_card: CardData = CardVariantGenerator.create_variant(
		card_path,
		CardData.Rarity.RARE
	)
	if rare_card != null:
		create_collection_entry(
			card_path,
			CardData.Rarity.RARE,
			rare_card
		)
	var mythic_card: CardData = CardVariantGenerator.create_variant(
		card_path,
		CardData.Rarity.MYTHIC
	)
	if mythic_card != null:
		create_collection_entry(
			card_path,
			CardData.Rarity.MYTHIC,
			mythic_card
		)


# ============================================================
# DETERMINE IF VARIANT IS UNLOCKED
# ============================================================

func create_collection_entry(card_path: String, rarity: CardData.Rarity, generated_card: CardData) -> void:
	var saved_variant: Dictionary = get_saved_variant(card_path, rarity)
	if not saved_variant.is_empty():
		var saved_card: CardData = RunManager.create_saved_card_variant(
			saved_variant
		)
		if saved_card != null:
			create_unlocked_card(saved_card)
		return
	create_locked_card(generated_card)


# ============================================================
# FIND SAVED VARIANT
# ============================================================

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
