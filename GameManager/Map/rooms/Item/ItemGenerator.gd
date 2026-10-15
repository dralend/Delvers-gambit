class_name ItemGenerator
extends RefCounted


const RELIC_CHANCE: float = 0.10


static func generate_item() -> ItemData:
	var relic_roll: float = randf()
	if relic_roll < RELIC_CHANCE:
		var relic := get_random_relic()
		if relic != null:
			return relic
	return get_random_normal_item()


static func get_random_normal_item() -> ItemData:
	var pool: Array[String] = ItemDatabase.ALL_ITEMS
	if pool.is_empty():
		return null
	var item_path: String = pool.pick_random()
	return load_item(item_path)


static func get_random_relic() -> ItemData:
	var pool: Array[String] = ItemDatabase.RELICS
	if pool.is_empty():
		return null
	var relic_path: String = pool.pick_random()
	return load_item(relic_path)


static func load_item(item_path: String) -> ItemData:
	if not ResourceLoader.exists(item_path):
		push_error("Item does not exist: " + item_path)
		return null
	var resource: Resource = load(item_path)
	if resource == null:
		push_error("Could not load item: " + item_path)
		return null
	if not resource is ItemData:
		push_error("Resource is not ItemData: " + item_path)
		return null
	return resource as ItemData
