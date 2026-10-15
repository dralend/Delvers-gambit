class_name CollectionCardButton
extends Button

signal card_selected(card_data: CardData, unlocked: bool)

var card_data: CardData = null
var is_unlocked: bool = false

@onready var artwork: TextureRect = $VBoxContainer/Artwork
@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var values_label: Label = $VBoxContainer/ValuesLabel


func _ready() -> void:
	custom_minimum_size = Vector2(180.0, 240.0)


func setup(data: CardData, unlocked: bool) -> void:
	card_data = data
	is_unlocked = unlocked
	if is_unlocked:
		show_unlocked_card()
	else:
		show_locked_card()


func show_unlocked_card() -> void:
	name_label.text = card_data.card_name
	artwork.texture = card_data.artwork
	artwork.modulate = Color.WHITE
	values_label.text = ("↑ " + str(card_data.up) + "  → " + str(card_data.right) + "\n" + "↓ " + str(card_data.down) + "  ← " + str(card_data.left))


func show_locked_card() -> void:
	name_label.text = "???"
	artwork.texture = card_data.artwork
	artwork.modulate = Color(0.08, 0.08, 0.08, 1.0)
	values_label.text = ("↑ ?  → ?" + "\n" + "↓ ?  ← ?")


func _pressed() -> void:
	if card_data == null:
		return
	card_selected.emit(card_data, is_unlocked)
