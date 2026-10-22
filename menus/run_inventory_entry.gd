class_name RunInventoryEntry
extends Panel

@onready var icon: TextureRect = get_node_or_null("VBoxContainer/Icon") as TextureRect
@onready var name_label: Label = get_node_or_null("VBoxContainer/NameLabel") as Label
@onready var description_label: Label = get_node_or_null("VBoxContainer/DescriptionLabel") as Label

const MAIN_MENU_TEXT := Color(0.96, 0.87, 0.68, 1)
const MAIN_MENU_HIGHLIGHT := Color(1.0, 0.86, 0.45, 1)

func _ready() -> void:
	if name_label != null:
		name_label.add_theme_color_override("font_color", MAIN_MENU_TEXT)
	if description_label != null:
		description_label.add_theme_color_override("font_color", MAIN_MENU_TEXT)
	if name_label == null:
		push_error("RunInventoryEntry: missing VBoxContainer/NameLabel.")
	if description_label == null:
		push_error("RunInventoryEntry: missing VBoxContainer/DescriptionLabel.")
	if icon == null:
		push_warning("RunInventoryEntry: missing VBoxContainer/Icon.")

func setup_item(item: ItemData) -> void:
	if item == null:
		_set_text("Unknown item", "Item data could not be loaded.")
		return
	_set_text(item.item_name, item.description)
	if icon != null:
		icon.texture = item.icon
		icon.visible = item.icon != null

func setup_buff(buff_name: String, buff_description: String) -> void:
	_set_text(buff_name, buff_description)
	if icon != null:
		icon.texture = null
		icon.visible = false

func _set_text(entry_name: String, entry_description: String) -> void:
	if name_label != null:
		name_label.text = entry_name
	if description_label != null:
		description_label.text = entry_description
