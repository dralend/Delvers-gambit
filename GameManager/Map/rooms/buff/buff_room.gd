extends Control

@onready var buff_choices: HBoxContainer = $MarginContainer/VBoxContainer/BuffChoices

var buff_pool: Array[String] = [
	"res://GameManager/Map/rooms/buff/First Strike.tres",
	"res://GameManager/Map/rooms/buff/Last Stand.tres",
	"res://GameManager/Map/rooms/buff/Power Surge.tres",
	"res://GameManager/Map/rooms/buff/Tactical Insight.tres",
	"res://GameManager/Map/rooms/buff/Weakening Curse.tres"
]

var offered_buffs: Array[BuffData] = []


func _ready() -> void:
	generate_buff_choices()


func generate_buff_choices() -> void:
	offered_buffs.clear()
	var available_pool: Array[String] = []
	for buff_path: String in buff_pool:
		if not ResourceLoader.exists(buff_path):
			continue
		var buff: BuffData = load(buff_path) as BuffData
		if buff == null:
			continue
		if RunManager.has_combat_buff(buff.buff_id):
			continue
		available_pool.append(buff_path)
	available_pool.shuffle()
	var amount: int = mini(3, available_pool.size())
	for i: int in range(amount):
		var buff_path: String = available_pool[i]
		var buff: BuffData = load(buff_path) as BuffData
		if buff == null:
			continue
		offered_buffs.append(buff)
	create_buff_buttons()


func create_buff_buttons() -> void:
	for child: Node in buff_choices.get_children():
		child.queue_free()
	for i: int in range(offered_buffs.size()):
		var buff: BuffData = offered_buffs[i]
		var container := PanelContainer.new()
		container.custom_minimum_size = Vector2(260.0, 360.0)
		buff_choices.add_child(container)
		var content := VBoxContainer.new()
		content.add_theme_constant_override("separation", 10)
		container.add_child(content)
		var name_label := Label.new()
		name_label.text = buff.buff_name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content.add_child(name_label)
		var icon_rect := TextureRect.new()
		icon_rect.texture = buff.icon
		icon_rect.custom_minimum_size = Vector2(128, 128)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = \
			TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		content.add_child(icon_rect)
		var description := Label.new()
		description.text = buff.description
		description.autowrap_mode = \
			TextServer.AUTOWRAP_WORD_SMART
		content.add_child(description)
		var choose_button := Button.new()
		choose_button.text = "Choose"
		choose_button.pressed.connect(_on_buff_chosen.bind(i))
		content.add_child(choose_button)


func _on_buff_chosen(index: int) -> void:
	if index < 0 or index >= offered_buffs.size():
		push_error("Invalid buff index: " + str(index))
		return
	var buff: BuffData = offered_buffs[index]
	print("Selected buff: ", buff.buff_name)
	print("Description: ", buff.description)
	RunManager.add_combat_buff(buff.buff_id)
	RunManager.complete_selected_room()
	get_tree().change_scene_to_file("res://GameManager/Map/RunMap.tscn")


func finish_buff_room() -> void:
	RunManager.complete_selected_room()
	get_tree().change_scene_to_file("res://GameManager/Map/RunMap.tscn")


func _on_skip_button_pressed() -> void:
	finish_buff_room()


func give_weakening_curse() -> void:
	RunManager.add_combat_buff("weakening_curse")
	print("Weakening Curse acquired!")


func give_power_surge() -> void:
	RunManager.add_combat_buff("extra_card_power")
	print("Power Surge acquired!")









































#
