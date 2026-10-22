extends Control

const ITEM_POOL: Array[String] = [
	"res://GameManager/Map/rooms/Item/Armor/Chainmail.tres",
	"res://GameManager/Map/rooms/Item/Armor/Guardian_Plate.tres",
	"res://GameManager/Map/rooms/Item/Armor/Iron_Armor.tres",
	"res://GameManager/Map/rooms/Item/Bonus Rewards/Coin_Pouch.tres",
	"res://GameManager/Map/rooms/Item/Bonus Rewards/Treasure_Map.tres",
	"res://GameManager/Map/rooms/Item/Support/Lucky_Charm.tres",
	"res://GameManager/Map/rooms/Item/Support/Scrying_Lens.tres",
	"res://GameManager/Map/rooms/Item/Support/Tactical_Compass.tres",
	"res://GameManager/Map/rooms/Item/Weapons/Iron_Sword.tres",
	"res://GameManager/Map/rooms/Item/Weapons/Twin_Blades.tres",
	"res://GameManager/Map/rooms/Item/Weapons/War_blade.tres"
]
const CARD_ROOT := "res://GameManager/Card/Type/"
const ITEM_PRICE := 25
const CARD_PRICE := 40
const BONUS_PRICE := 30

@onready var gold_label: Label = $Margin/VBox/TopRow/GoldLabel
@onready var offers: HBoxContainer = $Margin/VBox/Offers
@onready var message_label: Label = $Margin/VBox/MessageLabel

var current_offers: Array[Dictionary] = []

func _ready() -> void:
	_apply_shop_theme()
	generate_offers()
	update_gold()

func _apply_shop_theme() -> void:
	var title_panel := StyleBoxFlat.new()
	title_panel.bg_color = Color(0.035, 0.025, 0.035, 0.90)
	title_panel.border_color = Color(0.72, 0.48, 0.19, 0.95)
	title_panel.set_border_width_all(2)
	title_panel.set_corner_radius_all(12)
	title_panel.content_margin_left = 18
	title_panel.content_margin_right = 18
	var title := get_node_or_null("Margin/VBox/TopRow/Title") as Label
	if title:
		title.add_theme_stylebox_override("normal", title_panel)
	var gold := get_node_or_null("Margin/VBox/TopRow/GoldLabel") as Label
	if gold:
		gold.add_theme_stylebox_override("normal", title_panel)
	var subtitle := get_node_or_null("Margin/VBox/Subtitle") as Label
	if subtitle:
		subtitle.add_theme_stylebox_override("normal", title_panel)
		subtitle.add_theme_color_override("font_color", Color(0.97, 0.91, 0.78))
	for button in [get_node_or_null("Margin/VBox/BottomRow/RefreshButton"), get_node_or_null("Margin/VBox/BottomRow/BackButton")]:
		if button is Button:
			var normal := StyleBoxFlat.new()
			normal.bg_color = Color(0.07, 0.10, 0.15, 0.96)
			normal.border_color = Color(0.78, 0.56, 0.25, 1.0)
			normal.set_border_width_all(2)
			normal.set_corner_radius_all(8)
			normal.content_margin_left = 18
			normal.content_margin_right = 18
			button.add_theme_stylebox_override("normal", normal)
			var hover := normal.duplicate() as StyleBoxFlat
			hover.bg_color = Color(0.18, 0.13, 0.08, 1.0)
			button.add_theme_stylebox_override("hover", hover)
			button.add_theme_color_override("font_color", Color(1.0, 0.88, 0.58))

func update_gold() -> void:
	gold_label.text = "Gold: " + str(RunManager.reward_points)

func generate_offers() -> void:
	for child in offers.get_children():
		child.queue_free()
	current_offers.clear()
	var pool: Array[Dictionary] = []
	for path in ITEM_POOL:
		if ResourceLoader.exists(path):
			var item := load(path) as ItemData
			if item != null:
				pool.append({"kind":"item", "path":path, "name":item.item_name, "description":item.description, "price":ITEM_PRICE, "icon":item.icon})
	var card_paths: Array[String] = []
	var dir := DirAccess.open(CARD_ROOT)
	if dir != null:
		_collect_cards_recursive(CARD_ROOT, card_paths)
	for path in card_paths:
		if RunManager.is_card_unlocked(path):
			continue
		var card := load(path) as CardData
		if card != null:
			var card_art: Texture2D = card.mythic_artwork if card.rarity == CardData.Rarity.MYTHIC and card.mythic_artwork != null else (card.rare_artwork if card.rarity == CardData.Rarity.RARE and card.rare_artwork != null else card.artwork)
			pool.append({"kind":"card", "path":path, "name":card.card_name, "description":"Unlock this card permanently for your collection.", "price":CARD_PRICE, "icon":card_art})
	pool.append({"kind":"bonus", "path":"", "name":"Fortune Token", "description":"Earn a small bonus at the beginning of your next run.", "price":BONUS_PRICE, "icon":null})
	pool.shuffle()
	for i in range(mini(3, pool.size())):
		current_offers.append(pool[i])
	for i in range(current_offers.size()):
		_add_offer_card(current_offers[i], i)

func _collect_cards_recursive(path: String, output: Array[String]) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		if entry.begins_with("."):
			entry = directory.get_next()
			continue
		var full_path := path.path_join(entry)
		if directory.current_is_dir():
			_collect_cards_recursive(full_path, output)
		elif entry.ends_with(".tres"):
			output.append(full_path)
		entry = directory.get_next()
	directory.list_dir_end()

func _add_offer_card(offer: Dictionary, index: int) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(280, 390)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.025, 0.035, 0.045, 0.96)
	card_style.border_color = Color(0.72, 0.48, 0.19, 1.0)
	card_style.set_border_width_all(2)
	card_style.set_corner_radius_all(12)
	card_style.content_margin_left = 14
	card_style.content_margin_right = 14
	card_style.content_margin_top = 12
	card_style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", card_style)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var title := Label.new()
	title.text = str(offer.name)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.63))
	column.add_child(title)
	# Large artwork makes the type of offer immediately recognizable.
	var icon_frame := PanelContainer.new()
	icon_frame.custom_minimum_size = Vector2(160, 150)
	var icon_style := StyleBoxFlat.new()
	icon_style.bg_color = Color(0.08, 0.07, 0.08, 0.95)
	icon_style.border_color = Color(0.36, 0.29, 0.19, 1.0)
	icon_style.set_border_width_all(1)
	icon_style.set_corner_radius_all(8)
	icon_frame.add_theme_stylebox_override("panel", icon_style)
	icon_frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var icon_rect := TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(144, 134)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var offer_icon: Texture2D = offer.get("icon") as Texture2D
	if offer_icon != null:
		icon_rect.texture = offer_icon
		icon_frame.add_child(icon_rect)
	else:
		var symbol := Label.new()
		symbol.text = "✦"
		symbol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		symbol.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		symbol.add_theme_font_size_override("font_size", 64)
		symbol.add_theme_color_override("font_color", Color(1.0, 0.78, 0.24))
		icon_frame.add_child(symbol)
	column.add_child(icon_frame)
	var type_label := Label.new()
	type_label.text = "EQUIPMENT" if offer.kind == "item" else ("CARD UNLOCK" if offer.kind == "card" else "NEXT-RUN BONUS")
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.add_theme_color_override("font_color", Color(0.85, 0.72, 0.42))
	column.add_child(type_label)
	var description := Label.new()
	description.text = str(offer.description)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	description.add_theme_color_override("font_color", Color(0.91, 0.90, 0.86))
	description.add_theme_font_size_override("font_size", 16)
	column.add_child(description)
	var price := Label.new()
	price.text = str(offer.price) + " gold"
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price.add_theme_font_size_override("font_size", 20)
	price.add_theme_color_override("font_color", Color(1.0, 0.82, 0.30))
	column.add_child(price)
	var buy := Button.new()
	buy.text = "BUY OFFER"
	buy.custom_minimum_size = Vector2(0, 42)
	var buy_style := StyleBoxFlat.new()
	buy_style.bg_color = Color(0.10, 0.23, 0.16, 1.0)
	buy_style.border_color = Color(0.77, 0.61, 0.30, 1.0)
	buy_style.set_border_width_all(2)
	buy_style.set_corner_radius_all(7)
	buy.add_theme_stylebox_override("normal", buy_style)
	var buy_hover := buy_style.duplicate() as StyleBoxFlat
	buy_hover.bg_color = Color(0.16, 0.36, 0.23, 1.0)
	buy.add_theme_stylebox_override("hover", buy_hover)
	buy.add_theme_color_override("font_color", Color(1.0, 0.92, 0.68))
	buy.pressed.connect(_on_buy_pressed.bind(index))
	column.add_child(buy)
	offers.add_child(panel)

func _on_buy_pressed(index: int) -> void:
	if index < 0 or index >= current_offers.size():
		return
	var offer: Dictionary = current_offers[index]
	var price := int(offer.price)
	if RunManager.reward_points < price:
		message_label.text = "Not enough gold."
		return
	var success := false
	match str(offer.kind):
		"item":
			success = RunManager.queue_shop_item(str(offer.path))
		"card":
			success = RunManager.queue_shop_card(str(offer.path))
		"bonus":
			success = RunManager.buy_shop_bonus()
	if success:
		message_label.text = "Purchased " + str(offer.name) + "."
		current_offers.remove_at(index)
		for child in offers.get_children():
			child.queue_free()
		for i in range(current_offers.size()):
			_add_offer_card(current_offers[i], i)
	else:
		message_label.text = "Purchase failed. Try again."
	update_gold()

func _on_refresh_pressed() -> void:
	if not RunManager.spend_gold(5):
		message_label.text = "Need 5 gold to refresh."
		return
	message_label.text = "Offers refreshed for 5 gold."
	generate_offers()
	update_gold()

func _on_back_pressed() -> void:
	if RunManager.shop_return_to_map:
		RunManager.shop_return_to_map = false
		get_tree().change_scene_to_file("res://GameManager/Map/RunMap.tscn")
	else:
		get_tree().change_scene_to_file("res://menus/MainMenu.tscn")
