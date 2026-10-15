class_name MapRoom
extends Button

signal room_selected(room: MapRoom)

var data: RoomData

@onready var room_label: Label = $RoomLabel


func setup(room_data: RoomData) -> void:
	data = room_data
	text = ""
	custom_minimum_size = Vector2(100, 100)
	size = custom_minimum_size
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	update_visual()
	tooltip_text = get_room_description()


func update_visual() -> void:
	if data == null:
		return
	text = ""
	match data.room_type:
		RoomData.RoomType.COMBAT:
			set_room_display("⚔", "Combat")
		RoomData.RoomType.ELITE:
			set_room_display("★", "Elite")
		RoomData.RoomType.HEALING:
			set_room_display("♥", "Healing")
		RoomData.RoomType.CARD:
			set_room_display("♦", "Card")
		RoomData.RoomType.ITEM:
			set_room_display("◆", "Item")
		RoomData.RoomType.BUFF:
			set_room_display("✦", "Buff")
		RoomData.RoomType.RANDOM:
			set_room_display("?", "Random")
		RoomData.RoomType.BOSS:
			set_room_display("♛", "Boss")
			custom_minimum_size = Vector2(100, 100)
	size = custom_minimum_size
	if data.completed:
		modulate = Color(0.5, 0.5, 0.5)
		disabled = true
	elif data.available:
		modulate = Color.WHITE
		disabled = false
	else:
		modulate = Color(0.35, 0.35, 0.35)
		disabled = true


func set_room_display(symbol: String, room_name: String) -> void:
	room_label.text = symbol + "\n" + room_name
	room_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	room_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	room_label.add_theme_font_size_override("font_size", 20)


func get_room_description() -> String:
	if data == null:
		return "Unknown Room"
	match data.room_type:
		RoomData.RoomType.COMBAT:
			return "Normal Combat\nFight a standard card opponent."
		RoomData.RoomType.ELITE:
			return "Elite Combat\nFight a powerful opponent for better rewards."
		RoomData.RoomType.HEALING:
			return "Healing Room\nRecover health."
		RoomData.RoomType.CARD:
			return "Card Room\nChoose a new card."
		RoomData.RoomType.ITEM:
			return "Item Room\nGain a useful item."
		RoomData.RoomType.BUFF:
			return "Buff Room\nGain a one combat bonus."
		RoomData.RoomType.RANDOM:
			return "Unknown Room\nAnything could happen."
		RoomData.RoomType.BOSS:
			return "Boss\nDefeat the final opponent."
	return "Unknown Room"


func _pressed() -> void:
	if data == null:
		return
	if not data.available:
		return
	AudioManager.play_sfx("room_select")
	room_selected.emit(self)
