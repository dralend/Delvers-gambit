class_name CardVariantGenerator
extends RefCounted


static func create_variant(card_path: String, rarity: CardData.Rarity) -> CardData:
	var original_card: CardData = load(card_path) as CardData
	if original_card == null:
		return null
	var card: CardData = original_card.duplicate() as CardData
	card.rarity = rarity
	match rarity:
		CardData.Rarity.NORMAL:
			pass
		CardData.Rarity.RARE:
			card.up = mini(card.up + 1, 10)
			card.right = mini(card.right + 1, 10)
			card.down = mini(card.down + 1, 10)
			card.left = mini(card.left + 1, 10)
		CardData.Rarity.MYTHIC:
			card.up = mini(card.up + 2, 10)
			card.right = mini(card.right + 2, 10)
			card.down = mini(card.down + 2, 10)
			card.left = mini(card.left + 2, 10)
			apply_mythic_ability(card)
	return card


static func apply_mythic_ability(card: CardData) -> void:
	var abilities: Array[Dictionary] = [
		{
			"id": "Dragon_Fury",
			"description": "Gain +2 attack when capturing an enemy card."
		},
		{
			"id": "Blood_Hunt",
			"description": "Gain +1 attack against powerful enemy cards."
		},
		{
			"id": "Petrify",
			"description": "The first card captured by this card cannot recapture."
		},
		{
			"id": "Divine_Shield",
			"description": "Survive the first capture against this card."
		}
	]
	var ability: Dictionary = abilities.pick_random()
	card.mythic_ability = str(ability["id"])
	card.mythic_description = str(ability["description"])
