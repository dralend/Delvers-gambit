extends Control

const RUN_INVENTORY = preload("uid://bqe5tibyclgvm")
const INVENTORY_SCENE: PackedScene = preload("res://menus/run_inventory.tscn")

@export var room_scene: PackedScene

const ROWS: int = 3

var columns_per_act: int = 0
var total_columns: int = 0

var encounter_columns_per_act: Array[int] = []

@onready var map_panel: Panel = $MapScroll/MapPanel
@onready var connection_lines: MapConnections = $MapScroll/MapPanel/ConnectionLines
@onready var rooms_container: Control = $MapScroll/MapPanel/Rooms
@onready var health_label: Label = $RunHUD/VBoxContainer/HBoxContainer/HealthLabel
@onready var health_bar: ProgressBar = $RunHUD/VBoxContainer/HBoxContainer/HealthBar

@onready var map_scroll: ScrollContainer = $MapScroll

var room_nodes: Dictionary = {}
var map_rooms: Array[RoomData] = []


func _ready() -> void:
	if not RunManager.run_active:
		RunManager.start_new_run()
	if RunManager.map_data.is_empty():
		print("Generating new map.")
		calculate_run_layout()
		generate_map()
		create_connections()
		unlock_starting_rooms()
		save_map_to_run_manager()
	else:
		print("Loading existing map.")
		load_map_from_run_manager()
		calculate_run_layout()
	update_map_size()
	create_map_visuals()
	update_health_hud()
	await get_tree().process_frame
	scroll_to_available_column()


func get_random_room_type() -> RoomData.RoomType:
	var possible_rooms = [
		RoomData.RoomType.COMBAT,
		RoomData.RoomType.COMBAT,
		RoomData.RoomType.COMBAT,
		RoomData.RoomType.ELITE,
		RoomData.RoomType.HEALING,
		RoomData.RoomType.CARD,
		RoomData.RoomType.CARD,
		RoomData.RoomType.ITEM,
		RoomData.RoomType.BUFF,
		RoomData.RoomType.RANDOM,
		RoomData.RoomType.RANDOM,
	]
	return possible_rooms.pick_random()


func generate_map() -> void:
	map_rooms.clear()
	calculate_run_layout()
	var next_id: int = 0
	var current_column: int = 0
	for act: int in range(encounter_columns_per_act.size()):
		var encounters_this_act: int = encounter_columns_per_act[act]
		for encounter: int in range(encounters_this_act):
			for row: int in range(ROWS):
				var room := RoomData.new()
				room.id = next_id
				next_id += 1
				room.column = current_column
				room.row = row
				room.room_type = get_room_type_for_column(current_column)
				room.visual_offset = Vector2(0.0, randf_range(-25.0, 25.0))
				map_rooms.append(room)
			current_column += 1
		var boss := RoomData.new()
		boss.id = next_id
		next_id += 1
		boss.column = current_column
		boss.row = 1
		boss.room_type = RoomData.RoomType.BOSS
		map_rooms.append(boss)
		current_column += 1


func get_room_type_for_column(column: int) -> RoomData.RoomType:
	if column == 0:
		var starting_rooms: Array[RoomData.RoomType] = [
			RoomData.RoomType.COMBAT,
			RoomData.RoomType.CARD,
			RoomData.RoomType.ITEM,
			RoomData.RoomType.BUFF
		]
		return starting_rooms.pick_random()
	return get_random_room_type()


func create_connections() -> void:
	for room: RoomData in map_rooms:
		room.connections.clear()
	for column: int in range(total_columns - 1):
		var current_rooms: Array[RoomData] = get_rooms_in_column(column)
		var next_rooms: Array[RoomData] = get_rooms_in_column(column + 1)
		if current_rooms.is_empty():
			continue
		if next_rooms.is_empty():
			continue
		if next_rooms.size() == 1:
			var boss: RoomData = next_rooms[0]
			for room: RoomData in current_rooms:
				room.connections.append(boss)
			continue
		for target: RoomData in next_rooms:
			var valid_sources: Array[RoomData] = []
			for source: RoomData in current_rooms:
				if abs(source.row - target.row) <= 1:
					valid_sources.append(source)
			if valid_sources.is_empty():
				continue
			var source: RoomData = valid_sources.pick_random()
			if not source.connections.has(target):
				source.connections.append(target)
		for source: RoomData in current_rooms:
			var valid_targets: Array[RoomData] = []
			for target: RoomData in next_rooms:
				if abs(target.row - source.row) <= 1:
					valid_targets.append(target)
			if valid_targets.is_empty():
				continue
			if source.connections.is_empty():
				var target: RoomData = valid_targets.pick_random()
				source.connections.append(target)
			if valid_targets.size() > 1 and randf() < 0.35:
				var second_target: RoomData = valid_targets.pick_random()
				if not source.connections.has(second_target):
					source.connections.append(second_target)


func get_rooms_in_column(column: int) -> Array[RoomData]:
	var results: Array[RoomData] = []
	for room in map_rooms:
		if room.column == column:
			results.append(room)
	return results


func create_map_visuals() -> void:
	room_nodes.clear()
	for child: Node in rooms_container.get_children():
		child.queue_free()
	connection_lines.z_index = 0
	rooms_container.z_index = 10
	for room_data in map_rooms:
		var room_node: MapRoom = room_scene.instantiate()
		rooms_container.add_child(room_node)
		room_node.setup(room_data)
		room_node.position = get_room_position(room_data)
		room_node.room_selected.connect(_on_room_selected)
		room_nodes[room_data] = room_node
	rooms_container.custom_minimum_size = map_panel.custom_minimum_size
	connection_lines.custom_minimum_size = map_panel.custom_minimum_size
	connection_lines.setup(map_rooms, room_nodes)


func add_room_icon(room_node: MapRoom, room_data: RoomData) -> void:
	var icon_container := VBoxContainer.new()
	icon_container.name = "RoomIconContainer"
	icon_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_container.set_anchors_preset(Control.PRESET_CENTER)
	icon_container.position = Vector2(-45.0, -45.0)
	icon_container.size = Vector2(90.0, 90.0)
	icon_container.add_theme_constant_override("separation", 2)
	icon_container.alignment = BoxContainer.ALIGNMENT_CENTER
	var icon := Label.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(90.0, 48.0)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 36)
	var room_name := Label.new()
	room_name.name = "RoomName"
	room_name.custom_minimum_size = Vector2(90.0, 24.0)
	room_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	room_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	room_name.add_theme_font_size_override("font_size", 14)
	match room_data.room_type:
		RoomData.RoomType.COMBAT:
			icon.text = "⚔"
			room_name.text = "Combat"
		RoomData.RoomType.ELITE:
			icon.text = "★"
			room_name.text = "Elite"
		RoomData.RoomType.BOSS:
			icon.text = "♛"
			room_name.text = "Boss"
		RoomData.RoomType.HEALING:
			icon.text = "♥"
			room_name.text = "Healing"
		RoomData.RoomType.CARD:
			icon.text = "♦"
			room_name.text = "Card"
		RoomData.RoomType.ITEM:
			icon.text = "◆"
			room_name.text = "Item"
		RoomData.RoomType.BUFF:
			icon.text = "✦"
			room_name.text = "Buff"
		RoomData.RoomType.RANDOM:
			icon.text = "?"
			room_name.text = "Random"
	icon_container.add_child(icon)
	icon_container.add_child(room_name)
	room_node.add_child(icon_container)


func unlock_starting_rooms() -> void:
	for room in map_rooms:
		if room.column == 0:
			room.available = true


func _on_room_selected(room: MapRoom) -> void:
	if room.data == null:
		return
	RunManager.selected_room_id = room.data.id
	print("Entering room ID: ", room.data.id)
	enter_room(room.data)


func enter_room(room: RoomData) -> void:
	match room.room_type:
		RoomData.RoomType.COMBAT:
			start_combat("normal")
		RoomData.RoomType.ELITE:
			start_combat("elite")
		RoomData.RoomType.HEALING:
			open_healing_room()
		RoomData.RoomType.CARD:
			open_card_room()
		RoomData.RoomType.ITEM:
			open_item_room()
		RoomData.RoomType.BUFF:
			open_buff_room()
		RoomData.RoomType.RANDOM:
			open_random_room()
		RoomData.RoomType.BOSS:
			start_combat("boss")


func open_random_room() -> void:
	var events: Array[String] = ["combat", "heal", "card", "item", "buff"]
	var event: String = events.pick_random()
	match event:
		"combat":
			start_combat("normal")
		"heal":
			open_healing_room()
		"card":
			open_card_room()
		"item":
			open_item_room()
		"buff":
			open_buff_room()


func complete_room(room: RoomData) -> void:
	room.completed = true
	room.available = false
	for map_room in map_rooms:
		map_room.available = false
	for connected_room in room.connections:
		connected_room.available = true
	refresh_map()


func get_room_position(room: RoomData) -> Vector2:
	const START_X: float = 120.0
	const START_Y: float = 70.0
	const COLUMN_SPACING: float = 200.0
	const ROW_SPACING: float = 170.0
	var x: float = START_X + (float(room.column) * COLUMN_SPACING)
	var y: float = START_Y + (float(room.row) * ROW_SPACING)
	return Vector2(x, y)


func start_combat(combat_type: String) -> void:
	RunManager.start_combat_encounter(RunManager.selected_room_id, combat_type)
	RunManager.clear_battle_hand()
	get_tree().change_scene_to_file("res://GameManager/ChooseBattleHand.tscn")


func open_healing_room() -> void:
	get_tree().change_scene_to_file("res://GameManager/Map/rooms/Healing/healing_room.tscn")


func open_card_room() -> void:
	get_tree().change_scene_to_file("res://GameManager/Map/rooms/card/card_room.tscn")


func open_item_room() -> void:
	get_tree().change_scene_to_file("res://GameManager/Map/rooms/Item/item_room.tscn")


func open_buff_room() -> void:
	get_tree().change_scene_to_file("res://GameManager/Map/rooms/buff/buff_room.tscn")


func refresh_map() -> void:
	for room_data in map_rooms:
		if room_nodes.has(room_data):
			var room_node: MapRoom = room_nodes[room_data]
			room_node.update_visual()
	connection_lines.queue_redraw()


func save_map_to_run_manager() -> void:
	RunManager.map_data.clear()
	for room in map_rooms:
		var connection_ids: Array[int] = []
		for connection in room.connections:
			connection_ids.append(connection.id)
		var room_dictionary := {
			"id": room.id,
			"type": room.room_type,
			"column": room.column,
			"row": room.row,
			"completed": room.completed,
			"available": room.available,
			"offset_x": room.visual_offset.x,
			"offset_y": room.visual_offset.y,
			"connections": connection_ids
		}
		RunManager.map_data.append(room_dictionary)


func load_map_from_run_manager() -> void:
	map_rooms.clear()
	var rooms_by_id: Dictionary = {}
	for saved_room in RunManager.map_data:
		var room := RoomData.new()
		room.id = saved_room["id"]
		room.room_type = saved_room["type"]
		room.column = saved_room["column"]
		room.row = saved_room["row"]
		room.completed = saved_room["completed"]
		room.available = saved_room["available"]
		room.visual_offset = Vector2(saved_room["offset_x"], saved_room["offset_y"])
		map_rooms.append(room)
		rooms_by_id[room.id] = room
	for saved_room in RunManager.map_data:
		var room: RoomData = rooms_by_id[saved_room["id"]]
		for connection_id in saved_room["connections"]:
			if rooms_by_id.has(connection_id):
				room.connections.append(rooms_by_id[connection_id])


func update_health_hud() -> void:
	health_label.text = ("HP: " + str(RunManager.player_health) + "/" + str(RunManager.player_max_health))
	health_bar.max_value = RunManager.player_max_health
	health_bar.value = RunManager.player_health


func calculate_run_layout() -> void:
	encounter_columns_per_act.clear()
	var encounter_count: int = RunManager.run_encounter_count
	var boss_count: int = RunManager.run_boss_count
	if boss_count <= 0:
		boss_count = 1
	var base_encounters: int = int(float(encounter_count) / float(boss_count))
	var remainder: int = encounter_count % boss_count
	total_columns = 0
	for act: int in range(boss_count):
		var encounters_this_act: int = base_encounters
		if act < remainder:
			encounters_this_act += 1
		encounter_columns_per_act.append(encounters_this_act)
		total_columns += encounters_this_act
		total_columns += 1


func is_boss_column(column: int) -> bool:
	var section_size: int = columns_per_act + 1
	return ((column + 1) % section_size == 0)


func update_map_size() -> void:
	const COLUMN_SPACING: float = 200.0
	const SIDE_MARGIN: float = 120.0
	const MAP_HEIGHT: float = 600.0
	var map_width: float = (SIDE_MARGIN * 2.0 + (float(maxi(total_columns - 1, 0)) * COLUMN_SPACING))
	map_panel.custom_minimum_size = Vector2(map_width, MAP_HEIGHT)
	print("Map size: ", map_panel.custom_minimum_size)
	print("Total columns: ", total_columns)


func scroll_to_available_column() -> void:
	var target_column: int = 0
	for room: RoomData in map_rooms:
		if room.available:
			target_column = maxi(target_column, room.column)
			break
	const COLUMN_SPACING: float = 200.0
	const START_X: float = 120.0
	var target_x: float = (START_X + (float(target_column) * COLUMN_SPACING))
	var viewport_width: float = map_scroll.size.x
	target_x -= viewport_width * 0.5
	target_x = maxf(target_x, 0.0)
	var max_scroll: float = (map_panel.size.x - viewport_width)
	target_x = minf(target_x, maxf(max_scroll, 0.0))
	map_scroll.scroll_horizontal = int(target_x)


func _on_inventory_button_pressed() -> void:
	var inventory = INVENTORY_SCENE.instantiate()
	add_child(inventory)















#
