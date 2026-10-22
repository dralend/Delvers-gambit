class_name DeckCardButton
extends Button

signal card_pressed(card_path: String)

var card_path: String = ""
var card_data: CardData = null
var variant_data: Dictionary = {}

var artwork: TextureRect
var rarity_label: Label
var name_label: Label
var values_label: Label


func _ready() -> void:
	custom_minimum_size = Vector2(220.0, 310.0)
	_resolve_controls()
	update_display()


func _resolve_controls() -> void:
	# Resolve nodes dynamically because setup_variant() can run before controls are ready.
	artwork = get_node_or_null("VBoxContainer/Artwork") as TextureRect
	rarity_label = get_node_or_null("VBoxContainer/RarityLabel") as Label
	name_label = get_node_or_null("VBoxContainer/NameLabel") as Label
	values_label = get_node_or_null("VBoxContainer/ValuesLabel") as Label


func setup(path: String, data: CardData) -> void:
	card_path = path
	card_data = data
	variant_data.clear()
	update_display()


func setup_variant(variant: Dictionary, data: CardData) -> void:
	variant_data = variant.duplicate(true)
	card_path = str(variant.get("path", ""))
	card_data = data
	update_display()


func update_display() -> void:
	if card_data == null:
		return

	if artwork == null or rarity_label == null or name_label == null or values_label == null:
		_resolve_controls()
	if artwork == null or rarity_label == null or name_label == null or values_label == null:
		push_warning("DeckCardButton: expected child controls were not found under VBoxContainer.")
		return

	name_label.text = card_data.card_name

	if card_data.artwork != null:
		artwork.texture = card_data.artwork
		artwork.visible = true
	else:
		artwork.texture = null
		artwork.visible = false

	values_label.text = (
		"↑ " + str(card_data.up)
		+ "    → " + str(card_data.right)
		+ "\n"
		+ "↓ " + str(card_data.down)
		+ "    ← " + str(card_data.left)
	)

	update_rarity()


func update_rarity() -> void:
	if rarity_label == null:
		_resolve_controls()
	if rarity_label == null:
		return
	if card_data == null:
		rarity_label.text = ""
		return

	match card_data.rarity:
		CardData.Rarity.NORMAL:
			rarity_label.text = "◆ NORMAL"
			rarity_label.modulate = Color(0.75, 0.75, 0.75)

		CardData.Rarity.RARE:
			rarity_label.text = "◆◆ RARE"
			rarity_label.modulate = Color(0.25, 0.55, 1.0)

		CardData.Rarity.MYTHIC:
			rarity_label.text = "◆◆◆ MYTHIC"
			rarity_label.modulate = Color(0.8, 0.3, 1.0)

		_:
			rarity_label.text = "◆ NORMAL"
			rarity_label.modulate = Color(0.75, 0.75, 0.75)


func _pressed() -> void:
	if card_path.is_empty():
		return

	card_pressed.emit(card_path)
