class_name GameCard
extends Control

signal card_clicked(card: GameCard)

@export var data: CardData

var owner_id: int = 0
var board_position: Vector2i = Vector2i(-1, -1)
var starting_position: Vector2
var is_selected: bool = false

@onready var card_background: Panel = $CardBackground
@onready var background: Panel = $Background
@onready var rarity_frame: Panel = $RarityFrame
@onready var artwork: TextureRect = $Artwork
@onready var rarity_label: Label = $RarityLabel
@onready var up_value: Label = $UpValue
@onready var right_value: Label = $RightValue
@onready var down_value: Label = $DownValue
@onready var left_value: Label = $LeftValue
@onready var name_label: Label = $NameLabel
@onready var card_back: Panel = $CardBack
@onready var bonus_container: VBoxContainer = $BonusContainer
@onready var bonus_icons: HBoxContainer = $BonusContainer/BonusIcons
@onready var ability_label: Label = $BonusContainer/AbilityLabel

var petrified: bool = false
var petrify_used: bool = false
var divine_shield_used: bool = false

var displayed_bonus: int = 0
var bonus_sources: Array[Dictionary] = []
var bonus_tooltip: String = ""


func _ready() -> void:
	update_card()
	update_owner_visual()
	clear_bonus_display()
	# Bonus text is shown only by Godot's hover tooltip, never inside the card.
	bonus_container.hide()
	mouse_entered.connect(_on_card_mouse_entered)
	mouse_exited.connect(_on_card_mouse_exited)


func set_card_data(new_data: CardData) -> void:
	data = new_data
	update_card()


func update_card() -> void:
	if data == null:
		return
	name_label.text = data.card_name
	var selected_artwork: Texture2D = data.artwork
	match data.rarity:
		CardData.Rarity.RARE:
			if data.rare_artwork != null:
				selected_artwork = data.rare_artwork
		CardData.Rarity.MYTHIC:
			if data.mythic_artwork != null:
				selected_artwork = data.mythic_artwork
	artwork.texture = selected_artwork
	artwork.visible = selected_artwork != null
	_apply_rarity_appearance()
	up_value.text = str(data.up)
	right_value.text = str(data.right)
	down_value.text = str(data.down)
	left_value.text = str(data.left)
	update_rarity()
	update_ability_bonus_display()


func _apply_rarity_appearance() -> void:
	if rarity_frame == null or card_background == null or artwork == null or data == null:
		return
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0, 0, 0, 0)
	frame_style.draw_center = false
	frame_style.set_border_width_all(3)
	frame_style.set_corner_radius_all(3)
	match data.rarity:
		CardData.Rarity.NORMAL:
			frame_style.border_color = Color(0.65, 0.65, 0.68, 0.9)
			artwork.modulate = Color.WHITE
			rarity_frame.modulate = Color.WHITE
		CardData.Rarity.RARE:
			frame_style.border_color = Color(0.20, 0.62, 1.0, 1.0)
			artwork.modulate = Color(0.88, 0.95, 1.12)
			rarity_frame.modulate = Color(0.55, 0.82, 1.0)
		CardData.Rarity.MYTHIC:
			frame_style.border_color = Color(0.82, 0.35, 1.0, 1.0)
			artwork.modulate = Color(1.12, 0.88, 1.18)
			rarity_frame.modulate = Color(0.9, 0.55, 1.0)
	if rarity_frame != null:
		rarity_frame.add_theme_stylebox_override("panel", frame_style)


func update_rarity() -> void:
	if data == null:
		rarity_label.text = ""
		return
	match data.rarity:
		CardData.Rarity.NORMAL:
			rarity_label.text = "◆"
			rarity_label.modulate = Color(0.75, 0.75, 0.75)
		CardData.Rarity.RARE:
			rarity_label.text = "◆◆"
			rarity_label.modulate = Color(0.25, 0.55, 1.0)
		CardData.Rarity.MYTHIC:
			rarity_label.text = "◆◆◆"
			rarity_label.modulate = Color(0.8, 0.3, 1.0)
		_:
			rarity_label.text = "◆"
			rarity_label.modulate = Color.WHITE


func set_card_owner(new_owner: int) -> void:
	owner_id = new_owner
	update_owner_visual()


func update_owner_visual() -> void:
	if card_background == null:
		return
	if owner_id == 0:
		card_background.modulate = Color(0.75, 0.85, 1.0)
	else:
		card_background.modulate = Color(1.0, 0.75, 0.75)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			card_clicked.emit(self)


func set_card_hidden(is_hidden: bool) -> void:
	if card_back == null:
		return
	card_back.visible = is_hidden
	if artwork != null:
		artwork.visible = not is_hidden
	if rarity_label != null:
		rarity_label.visible = not is_hidden
	if rarity_frame != null:
		rarity_frame.visible = not is_hidden
	if up_value != null:
		up_value.visible = not is_hidden
	if right_value != null:
		right_value.visible = not is_hidden
	if down_value != null:
		down_value.visible = not is_hidden
	if left_value != null:
		left_value.visible = not is_hidden
	if name_label != null:
		name_label.visible = not is_hidden
	if bonus_container != null:
		bonus_container.hide()
	tooltip_text = "" if is_hidden else _build_hover_info()


func reveal_card() -> void:
	if card_back != null:
		card_back.visible = false
	if artwork != null:
		artwork.visible = true
	if rarity_label != null:
		rarity_label.visible = true
	if rarity_frame != null:
		rarity_frame.visible = true
	if up_value != null:
		up_value.visible = true
	if right_value != null:
		right_value.visible = true
	if down_value != null:
		down_value.visible = true
	if left_value != null:
		left_value.visible = true
	if name_label != null:
		name_label.visible = true
	tooltip_text = _build_hover_info()
	if bonus_container != null:
		bonus_container.hide()
	visible = true


func has_mythic_ability(ability_id: String) -> bool:
	if data == null:
		return false
	return data.rarity == CardData.Rarity.MYTHIC and data.mythic_ability == ability_id


func reset_combat_abilities() -> void:
	petrified = false
	petrify_used = false
	divine_shield_used = false


func clear_bonus_display() -> void:
	displayed_bonus = 0
	bonus_sources.clear()
	bonus_tooltip = ""
	if bonus_container != null:
		bonus_container.hide()
	tooltip_text = _build_hover_info() if is_node_ready() else ""


func set_bonus_sources(sources: Array[Dictionary]) -> void:
	bonus_sources = sources.duplicate(true)
	displayed_bonus = 0
	for source: Dictionary in bonus_sources:
		displayed_bonus += int(source.get("amount", 0))
	update_bonus_icons()
	update_bonus_tooltip()
	if bonus_container != null:
		bonus_container.hide()


func update_bonus_tooltip() -> void:
	if data == null:
		return
	var tooltip: String = data.card_name + "\n"
	tooltip += "--------------------\n"
	tooltip += "Base Values:\n"
	tooltip += "UP: " + str(data.up) + "\n"
	tooltip += "RIGHT: " + str(data.right) + "\n"
	tooltip += "DOWN: " + str(data.down) + "\n"
	tooltip += "LEFT: " + str(data.left) + "\n"
	tooltip += "\nActive Bonuses:\n"
	for source: Dictionary in bonus_sources:
		var source_name: String = str(source.get("name", "Bonus"))
		var amount: int = int(source.get("amount", 0))
		var amount_text: String = str(amount)
		if amount >= 0:
			amount_text = "+" + str(amount)
		tooltip += source_name + ": " + amount_text + "\n"
	tooltip += "--------------------\n"
	tooltip += "Displayed Bonus: "
	if displayed_bonus >= 0:
		tooltip += "+" + str(displayed_bonus)
	else:
		tooltip += str(displayed_bonus)
	bonus_tooltip = tooltip
	tooltip_text = _build_hover_info()


func _build_hover_info() -> String:
	if data == null:
		return ""

	var info := data.card_name + "\n"
	info += "Base Values: UP " + str(data.up) + " | RIGHT " + str(data.right)
	info += " | DOWN " + str(data.down) + " | LEFT " + str(data.left)

	match data.rarity:
		CardData.Rarity.RARE:
			info += "\n\nRARE CARD BONUS\n+1 to all sides (max 10)"
			info += "\nRare cards have improved stats."
		CardData.Rarity.MYTHIC:
			info += "\n\nMYTHIC CARD BONUS\n+2 to all sides (max 10)"
			if not data.mythic_ability.strip_edges().is_empty():
				info += "\n\nABILITY: " + _format_ability_name(data.mythic_ability)
				if not data.mythic_description.strip_edges().is_empty():
					info += "\n" + data.mythic_description

	if not bonus_sources.is_empty():
		info += "\n\nActive Bonuses:"
		for source: Dictionary in bonus_sources:
			var amount := int(source.get("amount", 0))
			var amount_text := ("+" if amount >= 0 else "") + str(amount)
			info += "\n" + str(source.get("name", "Bonus")) + ": " + amount_text
	return info


func _on_card_mouse_entered() -> void:
	if card_back != null and card_back.visible:
		tooltip_text = ""
		return
	tooltip_text = _build_hover_info()


func _on_card_mouse_exited() -> void:
	# Clear the tooltip source after the pointer leaves the card.
	tooltip_text = ""
	if bonus_container != null:
		bonus_container.hide()


func update_ability_bonus_display() -> void:
	# Keep the in-card container hidden; all detail is displayed in a hover tooltip.
	if bonus_container != null:
		bonus_container.hide()
	if is_node_ready():
		tooltip_text = _build_hover_info()


func _format_ability_name(ability_id: String) -> String:
	return ability_id.replace("_", " ").capitalize()


func save_starting_position() -> void:
	starting_position = position


func return_to_starting_position() -> void:
	position = starting_position
	is_selected = false


func update_bonus_icons() -> void:
	for child in bonus_icons.get_children():
		bonus_icons.remove_child(child)
		child.queue_free()
	for source: Dictionary in bonus_sources:
		var texture: Texture2D = source.get("icon") as Texture2D
		if texture == null:
			continue
		var icon := TextureRect.new()
		icon.texture = texture
		icon.custom_minimum_size = Vector2(20, 20)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.tooltip_text = str(source.get("name", "Bonus"))
		bonus_icons.add_child(icon)




































































#
