extends Control

@onready var item_choices: HBoxContainer = $ItemChoices

var item_pool: Array[String] = [
	"res://GameManager/Map/rooms/Item/Armor/Chainmail.tres",
	"res://GameManager/Map/rooms/Item/Armor/Guardian_Plate.tres",
	"res://GameManager/Map/rooms/Item/Armor/Iron_Armor.tres",
	"res://GameManager/Map/rooms/Item/Bonus Rewards/Bonus_Cache.tres",
	"res://GameManager/Map/rooms/Item/Bonus Rewards/Coin_Pouch.tres",
	"res://GameManager/Map/rooms/Item/Bonus Rewards/Treasure_Map.tres",
	"res://GameManager/Map/rooms/Item/Support/Lucky_Charm.tres",
	"res://GameManager/Map/rooms/Item/Support/Scrying_Lens.tres",
	"res://GameManager/Map/rooms/Item/Support/Tactical_Compass.tres",
	"res://GameManager/Map/rooms/Item/Weapons/Iron_Sword.tres",
	"res://GameManager/Map/rooms/Item/Weapons/Twin_Blades.tres",
	"res://GameManager/Map/rooms/Item/Weapons/War_blade.tres",
	"res://GameManager/Map/rooms/Item/Relics/Ancient_Sword.tres",
	"res://GameManager/Map/rooms/Item/Relics/Guardian_Relic.tres",
	"res://GameManager/Map/rooms/Item/Relics/Lucky_Crown.tres",
	"res://GameManager/Map/rooms/Item/Relics/Phoenix_Relic.tres"
]

var offered_items: Array[ItemData] = []
var offered_item_paths: Array[String] = []


func _ready() -> void:
	generate_item_choices()


func generate_item_choices() -> void:
	offered_items.clear()
	offered_item_paths.clear()
	var available_pool: Array[String] = []
	for item_path: String in item_pool:
		if not ResourceLoader.exists(item_path):
			continue
		var item: ItemData = load(item_path) as ItemData
		if item == null:
			continue
		if item.is_relic:
			if RunManager.is_relic_unlocked(item.item_id):
				continue
		else:
			if RunManager.has_item(item.item_id):
				continue
		available_pool.append(item_path)
	available_pool.shuffle()
	var amount: int = mini(3, available_pool.size())
	for i: int in range(amount):
		var item_path: String = available_pool[i]
		var item: ItemData = load(item_path) as ItemData
		if item == null:
			continue
		offered_items.append(item)
		offered_item_paths.append(item_path)
	create_item_buttons()
	if offered_items.is_empty():
		print("No new item rewards available.")


func create_item_buttons() -> void:
	for child: Node in item_choices.get_children():
		child.queue_free()
	for i: int in range(offered_items.size()):
		var item: ItemData = offered_items[i]
		var container := VBoxContainer.new()
		container.custom_minimum_size = Vector2(220, 250)
		item_choices.add_child(container)
		# Item name
		var name_label := Label.new()
		name_label.text = item.item_name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		container.add_child(name_label)
		# Icon
		var icon_rect := TextureRect.new()
		icon_rect.texture = item.icon
		icon_rect.custom_minimum_size = Vector2(128, 128)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		container.add_child(icon_rect)
		# Description
		var description := Label.new()
		description.text = item.description
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		container.add_child(description)
		# Choose button
		var choose_button := Button.new()
		choose_button.text = "Choose"
		choose_button.pressed.connect(_on_item_chosen.bind(i))
		container.add_child(choose_button)


func _on_item_chosen(index: int) -> void:
	if index < 0:
		return
	if index >= offered_item_paths.size():
		return
	var item_path: String = offered_item_paths[index]
	var item: ItemData = offered_items[index]
	print("Selected item: ", item.item_name)
	RunManager.give_item(item)
	finish_item_room()


func finish_item_room() -> void:
	RunManager.complete_selected_room()
	get_tree().change_scene_to_file("res://GameManager/Map/RunMap.tscn")


func _on_skip_button_pressed() -> void:
	finish_item_room()

































#
