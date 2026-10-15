class_name RunInventoryEntry
extends Panel


@onready var icon: TextureRect = $VBoxContainer/Icon
@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var description_label: Label = $VBoxContainer/DescriptionLabel


func setup_item(item: ItemData) -> void:
	if item == null:
		return
	name_label.text = item.item_name
	description_label.text = item.description
	if item.icon != null:
		icon.texture = item.icon


func setup_buff(buff_name: String, buff_description: String) -> void:
	name_label.text = buff_name
	description_label.text = buff_description
