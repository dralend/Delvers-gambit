class_name BoardSlot
extends Panel

signal slot_clicked(slot: BoardSlot)

@export var slot_index: int = 0

var card: GameCard = null
var occupied: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			slot_clicked.emit(self)


func set_card(new_card: GameCard) -> void:
	card = new_card
	if card == null:
		return
	occupied = true
	card.position = Vector2.ZERO
	card.size = size
	card.custom_minimum_size = size
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
