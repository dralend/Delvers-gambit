extends Control

const ENTRY_SCENE: PackedScene = preload(
	"res://menus/RunInventoryEntry.tscn"
)

@onready var items_grid: GridContainer = $MarginContainer/VBoxContainer/ItemsScroll/ItemsGrid
@onready var relics_grid: GridContainer = $MarginContainer/VBoxContainer/RelicsScroll/RelicsGrid
@onready var buffs_list: VBoxContainer = $MarginContainer/VBoxContainer/BuffsScroll/BuffList


func _ready() -> void:
	print("===== RUN INVENTORY OPENED =====")
	print("Items: ", RunManager.items)
	print("Relics: ", RunManager.relics)
	print("Buffs: ", RunManager.active_combat_buffs)

	refresh_inventory()


func refresh_inventory() -> void:
	clear_container(items_grid)
	clear_container(relics_grid)
	clear_container(buffs_list)

	display_items()
	display_relics()
	display_buffs()


func clear_container(container: Container) -> void:
	for child in container.get_children():
		child.queue_free()


# =========================================================
# ITEMS
# =========================================================

func display_items() -> void:
	print("Displaying items: ", RunManager.items.size())

	if RunManager.items.is_empty():
		print("No items currently owned.")
		return

	for item_path: String in RunManager.items:
		print("Loading item: ", item_path)

		if item_path.is_empty():
			continue

		if not ResourceLoader.exists(item_path):
			push_warning("Item resource does not exist: " + item_path)
			continue

		var item: ItemData = load(item_path) as ItemData

		if item == null:
			push_warning("Could not load ItemData: " + item_path)
			continue

		var entry: RunInventoryEntry = ENTRY_SCENE.instantiate() as RunInventoryEntry

		if entry == null:
			push_warning("Could not create inventory entry.")
			continue

		items_grid.add_child(entry)
		entry.setup_item(item)


# =========================================================
# RELICS
# =========================================================

func display_relics() -> void:
	print("Displaying relics: ", RunManager.relics.size())

	if RunManager.relics.is_empty():
		print("No relics currently owned.")
		return

	for relic_path: String in RunManager.relics:
		print("Loading relic: ", relic_path)

		if relic_path.is_empty():
			continue

		if not ResourceLoader.exists(relic_path):
			push_warning("Relic resource does not exist: " + relic_path)
			continue

		var relic: ItemData = load(relic_path) as ItemData

		if relic == null:
			push_warning("Could not load RelicData: " + relic_path)
			continue

		var entry: RunInventoryEntry = ENTRY_SCENE.instantiate() as RunInventoryEntry

		if entry == null:
			push_warning("Could not create relic entry.")
			continue

		relics_grid.add_child(entry)
		entry.setup_item(relic)


# =========================================================
# BUFFS
# =========================================================

func display_buffs() -> void:
	print("Displaying buffs: ", RunManager.active_combat_buffs.size())

	if RunManager.active_combat_buffs.is_empty():
		print("No active combat buffs.")
		return

	for buff_id: String in RunManager.active_combat_buffs:
		var entry: RunInventoryEntry = ENTRY_SCENE.instantiate() as RunInventoryEntry

		if entry == null:
			continue

		buffs_list.add_child(entry)

		entry.setup_buff(
			get_buff_name(buff_id),
			get_buff_description(buff_id)
		)


# =========================================================
# BUFF INFORMATION
# =========================================================

func get_buff_name(buff_id: String) -> String:
	match buff_id:
		RunManager.BUFF_EXTRA_CARD_POWER:
			return "Power Surge"

		RunManager.BUFF_WEAKENING_CURSE:
			return "Weakening Curse"

		_:
			return buff_id


func get_buff_description(buff_id: String) -> String:
	match buff_id:
		RunManager.BUFF_EXTRA_CARD_POWER:
			return "Your cards gain extra attack power."

		RunManager.BUFF_WEAKENING_CURSE:
			return "Enemy cards have reduced power."

		_:
			return "Unknown buff."


# =========================================================
# BUTTONS
# =========================================================

func _on_close_button_pressed() -> void:
	queue_free()


func _on_back_button_pressed() -> void:
	queue_free()
