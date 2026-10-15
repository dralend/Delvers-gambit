class_name ItemData
extends Resource

enum ItemType {
	WEAPON,
	ARMOR,
	BONUS_REWARD,
	SUPPORT
}

@export_category("Item Information")
@export var item_id: String = ""
@export var item_name: String = "Item"
@export_multiline var description: String = ""
@export var icon: Texture2D

@export_category("Item Type")
@export var item_type: ItemType = ItemType.SUPPORT

@export_category("Rarity")
@export var is_relic: bool = false

@export_category("Effect")
@export var effect_value: int = 1
