class_name RoomData
extends Resource


enum RoomType {
	COMBAT,
	ELITE,
	HEALING,
	CARD,
	ITEM,
	BUFF,
	RANDOM,
	BOSS
}

var id: int = -1

@export var room_type: RoomType = RoomType.COMBAT
@export var column: int = 0
@export var row: int = 0

var connections: Array[RoomData] = []
var completed: bool = false
var available: bool = false
var visual_offset: Vector2 = Vector2.ZERO
