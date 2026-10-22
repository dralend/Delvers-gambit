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
			apply_rare_ability(card)
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


# Named rare-card abilities. Each ability is stored on the generated variant so
# it is saved with the card, shown in the hover tooltip, and available to combat logic.
static func apply_rare_ability(card: CardData) -> void:
	var key := card.card_name.strip_edges().to_lower()
	var abilities: Dictionary = {
		"birds": ["Sky Dive", "When attacking from a higher-value side, gain +1 attack."],
		"insects": ["Swarm Tactics", "Gain +1 attack when another friendly card is adjacent."],
		"rats": ["Scavenger", "Gain +1 attack against a card with any side at 3 or lower."],
		"spider": ["Web Snare", "The first card this captures cannot trigger a counter-ability."],
		"squirrel": ["Quick Escape", "Once per battle, survive the first capture attempt."],
		"ghost": ["Ethereal", "The first attack against this card receives -1 power."],
		"ghast": ["Grave Chill", "Gain +1 attack against undead or humanoid foes."],
		"skeleton (armored)": ["Bone Armor", "The first attack against this card receives -1 power."],
		"skeleton (normal)": ["Rattle Strike", "Gain +1 attack when attacking a side of 4 or lower."],
		"zombie": ["Rotting Grasp", "Gain +1 attack against a card that has already changed owners."],
		"myconid": ["Spore Cloud", "Adjacent enemy cards receive -1 attack on their next clash."],
		"treefolk": ["Rooted Guard", "This card gains +1 defense while on an edge tile."],
		"mandrake (plant)": ["Shriek", "Gain +1 attack when defending against a stronger card."],
		"pincher (plant)": ["Crushing Claw", "Gain +1 attack against cards with a side of 6 or higher."],
		"trap (plant)": ["Hidden Snare", "Gain +2 attack on the first attack this card makes."],
		"angel": ["Divine Favor", "Once per battle, prevent one friendly card from being captured."],
		"devil": ["Infernal Bargain", "Gain +2 attack, but lose 1 power on another side after a successful capture."],
		"fiend": ["Soul Rend", "Gain +1 attack against a card with higher total power."],
		"dreaded shadow": ["Umbral Shift", "Gain +1 attack when attacking from a lower-value side."],
		"bulette": ["Burrow Ambush", "Gain +2 attack on its first attack."],
		"gorgon": ["Petrifying Gaze", "The first card this attacks has -1 power on its next clash."],
		"hydra": ["Regeneration", "Once per battle, survive a capture attempt."],
		"manticore": ["Barbed Tail", "Gain +1 attack against a card with a side of 7 or higher."],
		"winged winter wolf": ["Frost Pounce", "Gain +1 attack; opposing cards receive -1 on the attacked side."],
		"dwarf": ["Stout Guard", "Gain +1 defense when attacked from an adjacent tile."],
		"elf(high)": ["Keen Aim", "Gain +1 attack against a card with a side of 5 or higher."],
		"elf(wild)": ["Wild Instinct", "Gain +1 attack when another friendly card is adjacent."],
		"giant": ["Colossal Blow", "Gain +2 attack against cards with a side of 5 or lower."],
		"human": ["Adaptable", "Gain +1 attack against the same side used in the previous clash."],
		"black dragon": ["Voidfire", "Gain +2 attack against cards with a side of 7 or higher."],
		"blue dragon": ["Storm Breath", "Gain +1 attack against cards with a side of 6 or higher."],
		"green dragon": ["Venom Breath", "Gain +1 attack against cards with a side of 5 or lower."],
		"red dragon": ["Inferno", "Gain +2 attack on its first successful attack."],
		"white dragon": ["Glacial Breath", "The attacked side receives -1 power for the next clash."],
		"eyetyrant": ["Dominating Eye", "Gain +1 attack against a card with any side of 7 or higher."],
		"brainspawn": ["Mind Leech", "Gain +1 attack against a card with a side of 4 or lower."],
		"chitinous": ["Chitin Shell", "The first attack against this card receives -1 power."],
		"fleshwarped": ["Mutating Form", "At the start of a clash, gain +1 to a random side."],
		"voidspawn": ["Null Pulse", "Gain +1 attack against cards with any side of 8 or higher."]
	}
	if abilities.has(key):
		var ability: Array = abilities[key]
		card.rare_ability = str(ability[0]).to_snake_case()
		card.rare_description = str(ability[1])
	else:
		card.rare_ability = "veteran_instinct"
		card.rare_description = "Gain +1 attack on the first clash."
