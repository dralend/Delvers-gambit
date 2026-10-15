class_name MapConnections
extends Control

var map_rooms: Array[RoomData] = []
var room_nodes: Dictionary = {}

const LINE_COLOR := Color(0.25, 0.25, 0.25, 1.0)
const LINE_WIDTH: float = 4.0
const DASH_LENGTH: float = 12.0
const GAP_LENGTH: float = 8.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(rooms: Array[RoomData], nodes: Dictionary) -> void:
	map_rooms = rooms
	room_nodes = nodes
	queue_redraw()


func _draw() -> void:
	for room: RoomData in map_rooms:
		if not room_nodes.has(room):
			continue
		var room_node: Control = room_nodes[room] as Control
		if room_node == null:
			continue
		for target: RoomData in room.connections:
			if not room_nodes.has(target):
				continue
			var target_node: Control = room_nodes[target] as Control
			if target_node == null:
				continue
			draw_connection(room_node, target_node)


func draw_connection(from_room: Control, to_room: Control) -> void:
	var from_center: Vector2 = get_room_center(from_room)
	var to_center: Vector2 = get_room_center(to_room)
	var direction: Vector2 = to_center - from_center
	if direction.length_squared() <= 0.01:
		return
	direction = direction.normalized()
	var start_point: Vector2 = get_rect_edge_point(from_room, from_center, direction)
	var end_point: Vector2 = get_rect_edge_point(to_room, to_center, -direction)
	start_point = get_global_transform_with_canvas().affine_inverse() * start_point
	end_point = get_global_transform_with_canvas().affine_inverse() * end_point
	draw_dashed_line(start_point, end_point, LINE_COLOR, LINE_WIDTH, DASH_LENGTH, true)


func get_room_center(room: Control) -> Vector2:
	return room.get_global_rect().get_center()


func get_rect_edge_point(room: Control, center: Vector2, direction: Vector2) -> Vector2:
	var rect: Rect2 = room.get_global_rect()
	var half_width: float = rect.size.x * 0.5
	var half_height: float = rect.size.y * 0.5
	var distance_x: float = INF
	var distance_y: float = INF
	if abs(direction.x) > 0.001:
		distance_x = half_width / abs(direction.x)
	if abs(direction.y) > 0.001:
		distance_y = half_height / abs(direction.y)
	var distance_to_edge: float = minf(distance_x, distance_y)
	const EDGE_PADDING: float = 5.0
	return center + direction * (distance_to_edge + EDGE_PADDING)
