class_name CardData
extends Resource

enum Rarity {
	NORMAL,
	RARE,
	MYTHIC
}

@export_category("Card Information")
@export var card_name: String = "Card"
@export var artwork: Texture2D
@export var rare_artwork: Texture2D
@export var mythic_artwork: Texture2D

@export_category("Rarity")
@export var rarity: Rarity = Rarity.NORMAL

@export_category("Card Values")
@export_range(1, 10) var up: int = 1
@export_range(1, 10) var right: int = 1
@export_range(1, 10) var down: int = 1
@export_range(1, 10) var left: int = 1

@export_category("Rare Ability")
@export var rare_ability: String = ""
@export_multiline var rare_description: String = ""

@export_category("Mythic Ability")
@export var mythic_ability: String = ""
@export_multiline var mythic_description: String = ""
