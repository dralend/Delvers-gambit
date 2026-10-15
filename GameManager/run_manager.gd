extends Node

const RELIC_SAVE_PATH: String = "user://relics_collection.cfg"
const RELIC_UNLOCKS_SAVE_PATH: String = "user://relic_unlocks.cfg"
const COLLECTION_SAVE_PATH: String = "user://collection.cfg"
const DIFFICULTY_SAVE_PATH: String = "user://difficulty_progress.cfg"
const BATTLE_HAND_SIZE: int = 5
const DECK_SIZE: int = 5

const RUN_LENGTH_SAVE_PATH: String = "user://run_length_progress.cfg"

const BUFF_EXTRA_CARD_POWER: String = "extra_card_power"
const BUFF_WEAKENING_CURSE: String = "weakening_curse"
const BUFF_FIRST_STRIKE: String = "first_strike"
const BUFF_LAST_STAND: String = "last_stand"
const BUFF_TACTICAL_INSIGHT: String = "tactical_insight"

const STARTING_CARDS: Array[String] = [
	"res://GameManager/Card/Type/dragons/RedDragon.tres",
	"res://GameManager/Card/Type/humanoid/Elf(high).tres",
	"res://GameManager/Card/Type/monstrosity/Manticore.tres",
	"res://GameManager/Card/Type/outsider/Angel.tres",
	"res://GameManager/Card/Type/plants/Trap.tres"
]

var boss_special_ability: String = ""
var boss_vengeance_active: bool = false
var boss_dark_pact_used: bool = false

var run_active: bool = false

var run_encounter_count: int = 12
var run_boss_count: int = 2

var standard_run_unlocked: bool = false
var long_run_unlocked: bool = false
var current_run_length: String = "short"

var current_room_id: int = -1
var selected_room_id: int = -1
var map_data: Array[Dictionary] = []

var player_health: int = 5
var player_max_health: int = 5
var player_cards: Array[String] = []

var card_collection: Array[String] = []
var card_collection_variants: Array[Dictionary] = []
var saved_deck: Array[Dictionary] = []
var battle_hand: Array[Dictionary] = []
var encounter_coin_flip_done: bool = false

var items: Array[String] = []
var relics: Array[String] = []
var unlocked_relic_ids: Array[String] = []


var reward_points: int = 0

var active_combat_buffs: Array[String] = []
var game_difficulty: int = 1
var current_combat_type: String = ""
var offered_card_paths: Array[String] = []
var encounter_wins: int = 0
var encounter_wins_required: int = 1
var encounter_room_id: int = -1

var iron_sword_used: bool = false
var twin_blades_used: bool = false
var guardian_plate_used: bool = false
var chainmail_used: bool = false
var iron_armor_used: bool = false
var lucky_charm_used: bool = false
var guardian_relic_used: bool = false
var phoenix_used_this_run: bool = false

var first_strike_used: bool = false
var first_strike_active: bool = false

var run_ending: bool = false
var run_won: bool = false

var easy_completed: bool = false
var normal_completed: bool = false
var hard_completed: bool = false


func _ready() -> void:
	load_difficulty_progress()
	load_card_collection()
	load_relics()
	load_relic_unlocks()
	load_run_length_progress()


func start_new_run() -> void:
	clear_encounter_progress()
	run_active = true
	run_ending = false
	run_won = false
	current_room_id = -1
	selected_room_id = -1
	map_data.clear()
	player_health = player_max_health
	player_cards.clear()
	initialize_starting_cards()
	items.clear()
	setup_starting_deck()
	battle_hand.clear()
	print("New run started.")


func setup_starting_deck() -> void:
	player_cards.clear()
	for variant: Dictionary in saved_deck:
		var card_path: String = str(variant.get("path", ""))
		if not card_path.is_empty() and ResourceLoader.exists(card_path):
			player_cards.append(card_path)


func end_run() -> void:
	run_active = false
	current_room_id = -1
	selected_room_id = -1
	map_data.clear()
	player_cards.clear()
	items.clear()
	print("Run ended.")
	battle_hand.clear()
	clear_encounter_progress()


func complete_selected_room() -> void:
	if selected_room_id == -1:
		return
	var completed_room: Dictionary = {}
	for room in map_data:
		room["available"] = false
	for room in map_data:
		if room["id"] == selected_room_id:
			room["completed"] = true
			completed_room = room
			break
	if completed_room.is_empty():
		return
	for connection_id in completed_room["connections"]:
		for room in map_data:
			if room["id"] == connection_id:
				room["available"] = true
				break
	current_room_id = selected_room_id
	selected_room_id = -1


func player_defeated() -> void:
	run_active = false
	clear_battle_hand()
	clear_encounter_progress()
	print("Run failed.")


func is_player_dead() -> bool:
	return player_health <= 0


func lose_run() -> void:
	RunManager.player_defeated()
	get_tree().change_scene_to_file("res://menus/GameOver.tscn")


func set_combat_type(combat_type: String) -> void:
	current_combat_type = combat_type


func is_run_complete() -> bool:
	for room: Dictionary in map_data:
		var room_type: int = int(room["type"])
		var completed: bool = bool(room["completed"])
		if (room_type == RoomData.RoomType.BOSS and not completed):
			return false
	return true


func start_combat_encounter(room_id: int, combat_type: String) -> void:
	current_combat_type = combat_type
	if encounter_room_id != room_id:
		encounter_room_id = room_id
		encounter_wins = 0
	match combat_type:
		"elite":
			encounter_wins_required = 2
		"boss":
			encounter_wins_required = 3
		_:
			encounter_wins_required = 1


func add_encounter_win() -> bool:
	encounter_wins += 1
	return encounter_wins >= encounter_wins_required


func clear_encounter_progress() -> void:
	encounter_wins = 0
	encounter_wins_required = 1
	encounter_room_id = -1


func unlock_card(card_path: String) -> void:
	if card_path.is_empty():
		return
	if card_collection.has(card_path):
		return
	if not ResourceLoader.exists(card_path):
		push_warning("Cannot unlock missing card: " + card_path)
		return
	card_collection.append(card_path)
	save_card_collection()
	print("Unlocked card: ", card_path)


func is_card_unlocked(card_path: String) -> bool:
	return card_collection.has(card_path)


func setup_starting_collection() -> void:
	if not card_collection.is_empty():
		return
	add_starting_card("res://GameManager/Card/Type/dragons/RedDragon.tres")
	add_starting_card("res://GameManager/Card/Type/humanoid/Elf(high).tres")
	add_starting_card("res://GameManager/Card/Type/monstrosity/Manticore.tres")
	add_starting_card("res://GameManager/Card/Type/outsider/Angel.tres")
	add_starting_card("res://GameManager/Card/Type/plants/Trap.tres")


func save_card_collection() -> void:
	var config := ConfigFile.new()
	config.set_value("collection", "cards", card_collection)
	config.set_value("collection", "card_variants", card_collection_variants)
	config.set_value("deck", "selected_cards", saved_deck)
	var error: Error = config.save(COLLECTION_SAVE_PATH)
	if error != OK:
		push_error("Failed to save card collection.")
		return
	print("Card collection and deck saved.")


func load_card_collection() -> void:
	var starting_cards: Array[String] = [
	"res://GameManager/Card/Type/dragons/RedDragon.tres",
	"res://GameManager/Card/Type/humanoid/Elf(high).tres",
	"res://GameManager/Card/Type/monstrosity/Manticore.tres",
	"res://GameManager/Card/Type/outsider/Angel.tres",
	"res://GameManager/Card/Type/plants/Trap.tres"
]
	for card_path: String in starting_cards:
		if not card_collection.has(card_path):
			card_collection.append(card_path)
	var config := ConfigFile.new()
	var error: Error = config.load(COLLECTION_SAVE_PATH)
	if error != OK:
		print("No collection save found. Creating starting collection.")
		card_collection.clear()
		card_collection_variants.clear()
		setup_starting_collection()
		save_card_collection()
		return
	var saved_cards: Variant = config.get_value("collection", "cards", [])
	card_collection.clear()
	if saved_cards is Array:
		for card_path: Variant in saved_cards:
			if card_path is String:
				card_collection.append(String(card_path))
	print("Loaded ", card_collection.size(), " unlocked cards.")
	var saved_variants: Variant = config.get_value("collection", "card_variants", [])
	card_collection_variants.clear()
	if saved_variants is Array:
		for entry: Variant in saved_variants:
			if entry is Dictionary:
				card_collection_variants.append(entry)
	var saved_deck_data: Variant = config.get_value("deck", "selected_cards", [])
	saved_deck.clear()

	if saved_deck_data is Array:
		for entry: Variant in saved_deck_data:
			if entry is Dictionary:
				var variant: Dictionary = entry.duplicate(true)
				var path: String = str(variant.get("path", ""))
				if card_collection.has(path) and ResourceLoader.exists(path):
					saved_deck.append(variant)
			elif entry is String:
				# Migrate old saves that stored only the base card path.
				var path: String = str(entry)
				if card_collection.has(path) and ResourceLoader.exists(path):
					var legacy_card: CardData = load(path) as CardData
					if legacy_card != null:
						var legacy_variant: Dictionary = {
							"path": path,
							"rarity": int(CardData.Rarity.NORMAL),
							"up": legacy_card.up,
							"right": legacy_card.right,
							"down": legacy_card.down,
							"left": legacy_card.left,
							"mythic_ability": "",
							"mythic_description": ""
						}
						saved_deck.append(legacy_variant)

	if saved_deck.is_empty():
		setup_default_deck()
		save_card_collection()


func setup_default_deck() -> void:
	saved_deck.clear()

	for card_path: String in card_collection:
		if saved_deck.size() >= DECK_SIZE:
			break
		if not ResourceLoader.exists(card_path):
			continue

		var card_data: CardData = load(card_path) as CardData
		if card_data == null:
			continue

		var variant: Dictionary = {
			"path": card_path,
			"rarity": int(CardData.Rarity.NORMAL),
			"up": card_data.up,
			"right": card_data.right,
			"down": card_data.down,
			"left": card_data.left,
			"mythic_ability": "",
			"mythic_description": ""
		}

		saved_deck.append(variant)


func clear_battle_hand() -> void:
	battle_hand.clear()


func set_battle_hand(selected_cards: Array[String]) -> void:
	battle_hand.clear()
	for card_path: String in selected_cards:
		if battle_hand.size() >= BATTLE_HAND_SIZE:
			break
		if player_cards.has(card_path):
			battle_hand.append(card_path)


func battle_hand_is_ready() -> bool:
	return battle_hand.size() == BATTLE_HAND_SIZE


func add_combat_buff(buff_id: String) -> void:
	if buff_id.is_empty():
		return
	active_combat_buffs.append(buff_id)
	print("Added combat buff: ", buff_id)


func has_combat_buff(buff_id: String) -> bool:
	return active_combat_buffs.has(buff_id)


func consume_combat_buffs() -> void:
	active_combat_buffs.clear()
	print("Combat buffs cleared.")


func save_relics() -> void:
	var config := ConfigFile.new()
	config.set_value("relics", "unlocked_relics", relics)
	var error: Error = config.save(RELIC_SAVE_PATH)
	if error != OK:
		push_error("Failed to save relics. Error: " + str(error))
		return
	print("Permanent relics saved: ", relics)


func load_relics() -> void:
	var config := ConfigFile.new()
	var error: Error = config.load(RELIC_SAVE_PATH)
	relics.clear()
	if error == OK:
		var saved_relics: Variant = config.get_value("relics", "unlocked_relics", [])
		if saved_relics is Array:
			for relic_path: Variant in saved_relics:
				if relic_path is String and ResourceLoader.exists(String(relic_path)) and not relics.has(String(relic_path)):
					relics.append(String(relic_path))
	# Migrate path-based saves into normalized IDs, preserving old unlocks.
	for relic_path: String in relics:
		var relic_data := load(relic_path) as ItemData
		if relic_data != null:
			var normalized_id := relic_data.item_id.strip_edges().to_lower()
			if not normalized_id.is_empty() and not unlocked_relic_ids.has(normalized_id):
				unlocked_relic_ids.append(normalized_id)
	load_relic_unlocks()
	for relic_path: String in relics:
		var relic_data := load(relic_path) as ItemData
		if relic_data != null:
			var normalized_id := relic_data.item_id.strip_edges().to_lower()
			if not unlocked_relic_ids.has(normalized_id):
				unlocked_relic_ids.append(normalized_id)
	save_relic_unlocks()
	print("Loaded permanent relic paths: ", relics)
	print("Loaded permanent relic IDs: ", unlocked_relic_ids)

func give_item(item: ItemData) -> void:
	if item == null:
		push_error("Cannot give a null item.")
		return
	var item_path := item.resource_path
	if item_path.is_empty():
		push_error("Item has no resource path: " + item.item_name)
		return
	if item.is_relic:
		add_relic(item_path)
	else:
		add_item(item_path)

func add_item(item_path: String) -> void:
	if item_path.is_empty():
		return
	if not ResourceLoader.exists(item_path):
		push_error("Item does not exist: " + item_path)
		return
	if not items.has(item_path):
		items.append(item_path)
	print("Item obtained: ", item_path)


func add_relic(relic_path: String) -> void:
	if relic_path.is_empty() or not ResourceLoader.exists(relic_path):
		push_error("Relic does not exist: " + relic_path)
		return
	var relic_data := load(relic_path) as ItemData
	if relic_data == null or relic_data.item_id.strip_edges().is_empty():
		push_error("Relic has invalid ItemData: " + relic_path)
		return
	var relic_id := relic_data.item_id.strip_edges().to_lower()
	if not relics.has(relic_path):
		relics.append(relic_path)
		save_relics()
	if not unlocked_relic_ids.has(relic_id):
		unlocked_relic_ids.append(relic_id)
		save_relic_unlocks()
	print("Permanent relic unlocked: ", relic_data.item_name, " | id=", relic_id)
	print("Permanent relic paths: ", relics)
	print("Permanent relic IDs: ", unlocked_relic_ids)

func has_item(item_id: String) -> bool:
	for item_path: String in items:
		var item := load(item_path) as ItemData
		if item != null and item.item_id == item_id:
			return true
	return false


func has_relic(relic_id: String) -> bool:
	return is_relic_unlocked(relic_id)


func reset_combat_item_state() -> void:
	iron_sword_used = false
	twin_blades_used = false
	guardian_plate_used = false
	chainmail_used = false
	lucky_charm_used = false
	guardian_relic_used = false
	iron_armor_used = false
	first_strike_used = false
	first_strike_active = false


func give_room_reward(base_reward: int) -> void:
	var reward: int = base_reward
	if has_item("coin_pouch"):
		reward += 10
	if has_relic("lucky_crown"):
		reward += 10
	reward_points += reward
	print("Reward received: ", reward)
	print("Total rewards: ", reward_points)


func award_enemy_defeat_money() -> int:
	# Random reward based on selected game difficulty.
	var minimum_reward: int
	var maximum_reward: int
	match game_difficulty:
		0: # Easy
			minimum_reward = 5
			maximum_reward = 10
		1: # Normal
			minimum_reward = 10
			maximum_reward = 20
		2: # Hard
			minimum_reward = 15
			maximum_reward = 30
		_:
			minimum_reward = 10
			maximum_reward = 20

	var multiplier: int = 1
	match current_combat_type:
		"elite":
			multiplier = 2
		"boss":
			multiplier = 3

	var base_reward: int = randi_range(minimum_reward, maximum_reward)
	var reward: int = base_reward * multiplier

	# Existing money bonuses apply to combat rewards too.
	if has_item("coin_pouch"):
		reward += 10
	if has_relic("lucky_crown"):
		reward += 10

	reward_points += reward
	print("Enemy defeated! Difficulty: ", game_difficulty,
		" | Combat: ", current_combat_type,
		" | Money earned: ", reward,
		" | Total money: ", reward_points)
	return reward


func treasure_map_bonus_reward() -> bool:
	if not has_item("treasure_map"):
		return false
	return randf() < 0.25


func should_generate_bonus_reward() -> bool:
	if treasure_map_bonus_reward():
		return true
	if has_relic("lucky_crown"):
		return randf() < 0.20
	return false


func add_card_variant(card_path: String, rarity: CardData.Rarity, card_data: CardData) -> void:
	if card_path.is_empty():
		return
	if not ResourceLoader.exists(card_path):
		push_warning("Cannot add missing card: " + card_path)
		return
	if not card_collection.has(card_path):
		card_collection.append(card_path)
	if not player_cards.has(card_path):
		player_cards.append(card_path)
	var variant: Dictionary = {
		"path": card_path,
		"rarity": int(rarity),
		"up": card_data.up,
		"right": card_data.right,
		"down": card_data.down,
		"left": card_data.left,
		"mythic_ability": card_data.mythic_ability,
		"mythic_description": card_data.mythic_description
	}
	for existing: Dictionary in card_collection_variants:
		var existing_path: String = str(existing.get("path", ""))
		var existing_rarity: int = int(existing.get("rarity", 0))
		if existing_path == card_path and existing_rarity == int(rarity):
			print("Already own: ", card_data.card_name)
			return
	card_collection_variants.append(variant)
	save_card_collection()
	print("Added card variant: ", card_data.card_name, " | Rarity: ", rarity)


func get_card_variant(card_path: String) -> CardData:
	for variant: Dictionary in card_collection_variants:
		var variant_path: String = str(variant.get("path", ""))
		if variant_path != card_path:
			continue
		var rarity: int = int(variant.get("rarity", 0))
		var card_data: CardData = CardVariantGenerator.create_variant(card_path, rarity as CardData.Rarity)
		if card_data == null:
			return null
		card_data.up = int(variant.get("up", card_data.up))
		card_data.right = int(variant.get("right", card_data.right))
		card_data.down = int(variant.get("down", card_data.down))
		card_data.left = int(variant.get("left", card_data.left))
		card_data.mythic_ability = str(variant.get("mythic_ability", ""))
		card_data.mythic_description = str(variant.get("mythic_description", ""))
		return card_data
	return load(card_path) as CardData


func create_saved_card_variant(variant: Dictionary) -> CardData:
	var card_path: String = str(variant.get("path", ""))
	if card_path.is_empty():
		return null
	if not ResourceLoader.exists(card_path):
		return null
	var resource: Resource = load(card_path)
	if not resource is CardData:
		return null
	var original: CardData = resource as CardData
	var card_data: CardData = original.duplicate() as CardData
	card_data.rarity = int(variant.get("rarity", CardData.Rarity.NORMAL)) as CardData.Rarity
	card_data.up = int(variant.get("up", card_data.up))
	card_data.right = int(variant.get("right", card_data.right))
	card_data.down = int(variant.get("down", card_data.down))
	card_data.left = int(variant.get("left", card_data.left))
	card_data.mythic_ability = str(variant.get("mythic_ability", ""))
	card_data.mythic_description = str(variant.get("mythic_description", ""))
	return card_data


func initialize_starting_cards() -> void:
	for card_path: String in STARTING_CARDS:
		add_starting_card(card_path)
	save_card_collection()


func add_starting_card(card_path: String) -> void:
	if card_path.is_empty():
		return
	if not ResourceLoader.exists(card_path):
		push_warning("Starting card does not exist: " + card_path)
		return
	var resource: Resource = load(card_path)
	if not resource is CardData:
		push_warning("Starting card is not CardData: " + card_path)
		return
	var card_data: CardData = resource as CardData
	card_data = card_data.duplicate() as CardData
	card_data.rarity = CardData.Rarity.NORMAL
	card_data.mythic_ability = ""
	card_data.mythic_description = ""
	add_card_variant(card_path, CardData.Rarity.NORMAL, card_data)


func set_battle_hand_variants(variants: Array[Dictionary]) -> void:
	battle_hand.clear()
	for variant: Dictionary in variants:
		var card_path: String = str(variant.get("path", ""))
		if card_path.is_empty():
			continue
		battle_hand.append(variant.duplicate())
		if battle_hand.size() >= BATTLE_HAND_SIZE:
			break


func choose_boss_special_ability() -> void:
	var abilities: Array[String] = [
		"brutal_might",
		"fortified_cards",
		"blood_rush",
		"vengeance",
		"first_strike",
		"dark_pact"
	]
	boss_special_ability = abilities.pick_random()
	boss_vengeance_active = false
	boss_dark_pact_used = false
	print("BOSS ABILITY: ", boss_special_ability)


func is_difficulty_unlocked(difficulty: String) -> bool:
	match difficulty:
		"easy":
			return true
		"normal":
			return easy_completed
		"hard":
			return normal_completed
		"tutorial":
			return true
		_:
			return false


func complete_difficulty(difficulty: String) -> void:
	match difficulty:
		"easy":
			easy_completed = true
		"normal":
			normal_completed = true
		"hard":
			hard_completed = true
	save_difficulty_progress()


func save_difficulty_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("difficulty", "easy_completed", easy_completed)
	config.set_value("difficulty", "normal_completed", normal_completed)
	config.set_value("difficulty", "hard_completed", hard_completed)
	var error: Error = config.save(DIFFICULTY_SAVE_PATH)
	if error != OK:
		push_error("Could not save difficulty progress. Error: " + str(error))
	else:
		print("Difficulty progress saved.")


func load_difficulty_progress() -> void:
	var config := ConfigFile.new()
	var error: Error = config.load(DIFFICULTY_SAVE_PATH)
	if error != OK:
		easy_completed = false
		normal_completed = false
		hard_completed = false
		return
	easy_completed = bool(config.get_value("difficulty", "easy_completed", false))
	normal_completed = bool(config.get_value("difficulty", "normal_completed", false))
	hard_completed = bool(config.get_value("difficulty", "hard_completed", false))


func save_relic_collection() -> void:
	var config := ConfigFile.new()
	config.set_value("relics", "unlocked_relic_ids", unlocked_relic_ids)
	var error := config.save(RELIC_SAVE_PATH)
	if error != OK:
		push_error("Failed to save relic collection: " + str(error))


func load_relic_collection() -> void:
	var config := ConfigFile.new()
	var error := config.load(RELIC_SAVE_PATH)
	if error != OK:
		return
	var saved_ids: Array = config.get_value("relics", "unlocked_relic_ids", [])
	unlocked_relic_ids.clear()
	for relic_id in saved_ids:
		unlocked_relic_ids.append(str(relic_id))


func save_relic_unlocks() -> void:
	var config := ConfigFile.new()
	var normalized_ids: Array[String] = []
	for relic_id: String in unlocked_relic_ids:
		var normalized_id := relic_id.strip_edges().to_lower()
		if not normalized_id.is_empty() and not normalized_ids.has(normalized_id):
			normalized_ids.append(normalized_id)
	unlocked_relic_ids = normalized_ids
	config.set_value("relics", "unlocked_ids", unlocked_relic_ids)
	var error: Error = config.save(RELIC_UNLOCKS_SAVE_PATH)
	if error != OK:
		push_error("Failed to save relic unlocks: " + str(error))


func load_relic_unlocks() -> void:
	var config := ConfigFile.new()
	var error: Error = config.load(RELIC_UNLOCKS_SAVE_PATH)
	if error != OK:
		return
	var saved_ids: Variant = config.get_value("relics", "unlocked_ids", [])
	if saved_ids is Array:
		for relic_id: Variant in saved_ids:
			var normalized_id := str(relic_id).strip_edges().to_lower()
			if not normalized_id.is_empty() and not unlocked_relic_ids.has(normalized_id):
				unlocked_relic_ids.append(normalized_id)

func unlock_relic_permanently(relic: ItemData) -> void:
	if relic == null:
		return
	var path := relic.resource_path
	if not path.is_empty():
		add_relic(path)
	else:
		var normalized_id := relic.item_id.strip_edges().to_lower()
		if not normalized_id.is_empty() and not unlocked_relic_ids.has(normalized_id):
			unlocked_relic_ids.append(normalized_id)
			save_relic_unlocks()


func is_relic_unlocked(relic_id: String) -> bool:
	var normalized_id := relic_id.strip_edges().to_lower()
	if normalized_id.is_empty():
		return false
	if unlocked_relic_ids.has(normalized_id):
		return true
	# Backward compatibility: older saves stored only resource paths.
	for relic_path: String in relics:
		if not ResourceLoader.exists(relic_path):
			continue
		var relic_data := load(relic_path) as ItemData
		if relic_data != null and relic_data.item_id.strip_edges().to_lower() == normalized_id:
			return true
	return false

func is_run_length_unlocked(run_length: String) -> bool:
	match run_length.to_lower():
		"short":
			return true
		"standard", "normal":
			return standard_run_unlocked
		"long", "hard":
			return long_run_unlocked
	return false


func complete_run_length(run_length: String) -> void:
	match run_length.strip_edges().to_lower():
		"short", "easy":
			standard_run_unlocked = true
		"standard", "normal":
			long_run_unlocked = true
	save_run_length_progress()


func save_run_length_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "standard_unlocked", standard_run_unlocked)
	config.set_value("progress", "long_unlocked", long_run_unlocked)
	config.save(RUN_LENGTH_SAVE_PATH)


func load_run_length_progress() -> void:
	var config := ConfigFile.new()
	if config.load(RUN_LENGTH_SAVE_PATH) != OK:
		standard_run_unlocked = false
		long_run_unlocked = false
		return
	standard_run_unlocked = config.get_value("progress", "standard_unlocked", false)
	long_run_unlocked = config.get_value("progress", "long_unlocked", false)















#
