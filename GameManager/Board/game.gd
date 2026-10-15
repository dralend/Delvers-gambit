extends Control

const PLAYER := 0
const COMPUTER := 1
const CARD_SCENE: PackedScene = preload("res://GameManager/Card/card.tscn")
const RUN_INVENTORY = preload("uid://bqe5tibyclgvm")
const INVENTORY_SCENE: PackedScene = preload("res://menus/run_inventory.tscn")
const ITEM_DATA_PATHS: Dictionary = {
	"iron_sword": "res://GameManager/Map/rooms/Item/Weapons/Iron_Sword.tres",
	"ancient_sword": "res://GameManager/Map/rooms/Item/Relics/Ancient_Sword.tres"
}

enum AIDifficulty {
	NORMAL,
	MEDIUM,
	HARD
}

var normal_enemy_pool: Array[String] = [
	"res://GameManager/Card/Type/humanoid/Dwarf.tres",
	"res://GameManager/Card/Type/humanoid/Elf(high).tres",
	"res://GameManager/Card/Type/humanoid/Elf(wild).tres",
	"res://GameManager/Card/Type/humanoid/Human.tres",
	"res://GameManager/Card/Type/outsider/Angel.tres"
]


var elite_enemy_pool: Array[String] = [
	"res://GameManager/Card/Type/dragons/RedDragon.tres",
	"res://GameManager/Card/Type/humanoid/Dwarf.tres",
	"res://GameManager/Card/Type/monstrosity/Hydra.tres",
	"res://GameManager/Card/Type/outsider/Angel.tres",
	"res://GameManager/Card/Type/plants/Mandrake.tres"
]


var boss_enemy_pool: Array[String] = [
	"res://GameManager/Card/Type/dragons/RedDragon.tres",
	"res://GameManager/Card/Type/dragons/GreenDragon.tres",
	"res://GameManager/Card/Type/dragons/BlackDragon.tres",
	"res://GameManager/Card/Type/dragons/BlueDragon.tres",
	"res://GameManager/Card/Type/monstrosity/Hydra.tres"
	]

var ai_difficulty: AIDifficulty = AIDifficulty.NORMAL
var difficulty_selected: bool = false
var board: Array = [
	null, null, null,
	null, null, null,
	null, null, null
]

@onready var board_container: GridContainer = $CenterContainer/Board
@onready var player_hand: VBoxContainer = $PlayerHand
@onready var opponent_hand: VBoxContainer = $OpponentHand
@onready var combat_type_label: Label = $UI/VBoxContainer/HBoxContainer/CombatTypeLabel
@onready var health_label: Label = $UI/VBoxContainer/HBoxContainer/health/HealthLabel
@onready var health_bar: ProgressBar = $UI/VBoxContainer/HBoxContainer/health/HealthBar
@onready var inventory_button: Button = $UI/VBoxContainer/HBoxContainer/InventoryButton
@onready var turn_label: Label = $UI/VBoxContainer/TurnLabel
@onready var encounter_progress_label: Label = $UI/VBoxContainer/EncounterProgressLabel
@onready var player_score_label: Label = $UI/VBoxContainer/PlayerScore
@onready var enemy_score_label: Label = $UI/VBoxContainer/EnemyScore
@onready var result_label: Label = $UI/VBoxContainer/ResultLabel
@onready var continue_button: Button = $UI/ContinueButton
@onready var audio_manager: Node = get_node("/root/AudioManager")
@onready var coin_flip_panel: Panel = $CoinFlipPanel
@onready var coin_label: Label = $CoinFlipPanel/VBoxContainer/CoinLabel
@onready var coin_result_label: Label = $CoinFlipPanel/VBoxContainer/ResultLabel
@onready var flip_button: Button = $CoinFlipPanel/VBoxContainer/FlipButton
@onready var combat_info_label: Label = $UI/VBoxContainer/HBoxContainer/CombatInfoLabel


var current_player: int = PLAYER
var selected_card: GameCard = null
var game_over: bool = false
var run_defeated: bool = false

var combat_buff_value_bonus: int = 0
var enemy_combat_value_bonus: int = 0

var player_goes_first: bool = false
var coin_flip_finished: bool = false

var boss_special_ability: String = ""
var boss_ability_active: bool = false

var boss_vengeance_active: bool = false
var boss_dark_pact_used: bool = false
var boss_first_strike_done: bool = false


func _ready() -> void:
	RunManager.reset_combat_item_state()
	audio_manager.play_battle_music()
	for slot in board_container.get_children():
		if slot is BoardSlot:
			slot.slot_clicked.connect(_on_slot_clicked)
	setup_roguelite_combat()
	if should_show_coin_flip():
		start_coin_flip()
	else:
		start_hidden_coin_flip()


func _on_slot_clicked(slot: BoardSlot) -> void:
	if game_over:
		return
	if not coin_flip_finished:
		return
	if current_player != PLAYER:
		return
	if selected_card == null:
		print("Select a card first.")
		return
	if slot.card != null:
		print("That space is occupied.")
		return
	var card: GameCard = selected_card
	selected_card = null
	card.position.y = 0
	place_card(card, slot)
	finish_turn()


func _on_card_clicked(card: GameCard) -> void:
	if game_over:
		return
	if not coin_flip_finished:
		return
	if current_player != PLAYER:
		return
	if card.owner_id != PLAYER:
		return
	if selected_card != null and selected_card != card:
		selected_card.return_to_starting_position()
	selected_card = card
	selected_card.is_selected = true
	selected_card.position.y = -20
	selected_card.position.x = 60
	AudioManager.play_sfx("card_select")
	print("Selected: ", card.data.card_name)


func place_card(card: GameCard, slot: BoardSlot) -> void:
	var index: int = slot.slot_index
	board[index] = card
	slot.card = card
	card.board_position = Vector2i(index % 3, int(float(index) / 3.0)
	)
	card.reparent(slot)
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.position = Vector2.ZERO
	card.size = slot.size
	card.custom_minimum_size = slot.size
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if card.owner_id == COMPUTER:
		card.reveal_card()
		card.visible = true
	if card.owner_id == PLAYER:
		if RunManager.has_combat_buff("first_strike"):
			if not RunManager.first_strike_used:
				RunManager.first_strike_used = true
				RunManager.first_strike_active = true
				print("FIRST STRIKE ACTIVATED!")
	check_captures(card)
	if card.owner_id == COMPUTER:
		if RunManager.current_combat_type == "boss":
			if RunManager.boss_special_ability == "vengeance":
				RunManager.boss_vengeance_active = false
	RunManager.first_strike_active = false
	update_score()
	AudioManager.play_sfx("card_place")
	print(card.data.card_name, " placed in slot ", index)
	update_scores()


func get_card_at(board_position: Vector2i) -> GameCard:
	if board_position.x < 0 or board_position.x >= 3:
		return null
	if board_position.y < 0 or board_position.y >= 3:
		return null
	var index := board_position.y * 3 + board_position.x
	return board[index]


func check_captures(card: GameCard) -> void:
	var pos := card.board_position
	check_direction(card, pos + Vector2i.UP, "up")
	check_direction(card, pos + Vector2i.RIGHT, "right")
	check_direction(card, pos + Vector2i.DOWN, "down")
	check_direction(card, pos + Vector2i.LEFT, "left")


func check_direction(card: GameCard, target_position: Vector2i, direction: String) -> void:
	var enemy: GameCard = get_card_at(target_position)
	if enemy == null:
		return
	if card.petrified:
		print(card.data.card_name, " is petrified and cannot capture.")
		return
	if enemy.owner_id == card.owner_id:
		return
	var attack_value: int = get_card_attack_power(card, direction, enemy)
	var defense_value: int = get_card_defense_power(enemy, get_opposite_direction(direction))
	print(card.data.card_name, " attacks ", enemy.data.card_name, " | ", attack_value, " vs ", defense_value)
	var can_capture: bool = false
	if card.owner_id == PLAYER:
		if RunManager.has_relic("ancient_sword"):
			can_capture = attack_value >= defense_value
		else:
			can_capture = attack_value > defense_value
	else:
		can_capture = attack_value > defense_value
	if can_capture:
		capture_card(enemy, card.owner_id)
	if card.has_mythic_ability("Petrify"):
		if not card.petrify_used:
			card.petrify_used = true
			enemy.petrified = true
			print(card.data.card_name, " petrified ", enemy.data.card_name)
		return
	if card.owner_id == PLAYER:
		if RunManager.has_item("twin_blades"):
			if not RunManager.twin_blades_used:
				RunManager.twin_blades_used = true
				print("Twin Blades activated!")
				var second_attack: int = attack_value + 1
				if second_attack > defense_value:
					capture_card(enemy, card.owner_id)
				return
	if card.owner_id == COMPUTER:
		if enemy.owner_id == PLAYER:
			if RunManager.has_item("lucky_charm"):
				if not RunManager.lucky_charm_used:
					if attack_value == defense_value + 1:
						RunManager.lucky_charm_used = true
						print("Lucky Charm prevented a capture!")
						return


func capture_card(card: GameCard, new_owner: int) -> void:
	if card == null:
		return
	if card.has_mythic_ability("Divine_Shield"):
		if not card.divine_shield_used:
			card.divine_shield_used = true
			print(card.data.card_name, " activated DIVINE SHIELD!")
			AudioManager.play_sfx("card_capture")
			return
	if card.owner_id == PLAYER and new_owner == COMPUTER:
		if guardian_relic_protects(card):
			return
		if guardian_plate_protects(card):
			return
	card.set_card_owner(new_owner)
	if RunManager.current_combat_type == "boss":
		if RunManager.boss_special_ability == "vengeance":
			if new_owner == PLAYER:
				RunManager.boss_vengeance_active = true
				print("BOSS VENGEANCE ACTIVATED!")
	AudioManager.play_sfx("card_capture")
	print(card.data.card_name, " was captured!")


func finish_turn() -> void:
	if board_full():
		end_game()
		return
	if current_player == PLAYER:
		current_player = COMPUTER
		update_turn_label()
		AudioManager.play_sfx("turn_change")
		computer_turn()
	else:
		current_player = PLAYER
		update_turn_label()
		AudioManager.play_sfx("turn_change")


func computer_turn() -> void:
	if game_over:
		return
	await get_tree().create_timer(0.75).timeout
	if game_over:
		return
	var available_cards: Array[GameCard] = []
	for child in opponent_hand.get_children():
		if child is GameCard:
			available_cards.append(child)
	var empty_slots: Array[BoardSlot] = get_empty_slots()
	if available_cards.is_empty() or empty_slots.is_empty():
		end_game()
		return
	match ai_difficulty:
		AIDifficulty.NORMAL:
			normal_ai_move(available_cards, empty_slots)
		AIDifficulty.MEDIUM:
			medium_ai_move(available_cards, empty_slots)
		AIDifficulty.HARD:
			hard_ai_move(available_cards, empty_slots)

func get_empty_slots() -> Array[BoardSlot]:
	var empty_slots: Array[BoardSlot] = []
	for child in board_container.get_children():
		if child is BoardSlot:
			if child.card == null:
				empty_slots.append(child)
	return empty_slots


func board_full() -> bool:
	for space in board:
		if space == null:
			return false
	return true


func get_scores() -> Array[int]:
	var player_score := 0
	var computer_score := 0
	for card in board:
		if card == null:
			continue
		if card.owner_id == PLAYER:
			player_score += 1
		if card.owner_id == COMPUTER:
			computer_score += 1
	for child in player_hand.get_children():
		if child is GameCard:
			player_score += 1
	for child in opponent_hand.get_children():
		if child is GameCard:
			computer_score += 1
	return [player_score, computer_score]


func update_score() -> void:
	var scores := get_scores()
	player_score_label.text = "Player: " + str(scores[0])
	enemy_score_label.text = "Computer: " + str(scores[1])


func update_turn_label() -> void:
	if current_player == PLAYER:
		turn_label.text = "Your Turn"
	else:
		turn_label.text = "Computer's Turn"


func end_game() -> void:
	if game_over:
		return
	game_over = true
	var scores: Array[int] = get_scores()
	var player_score: int = scores[0]
	var computer_score: int = scores[1]
	update_scores()
	resolve_combat(player_score, computer_score)


func _on_continue_button_pressed() -> void:
	var encounter_complete: bool = (RunManager.encounter_room_id == -1)
	if encounter_complete:
		get_tree().change_scene_to_file("res://GameManager/Map/RunMap.tscn")
		return
	get_tree().reload_current_scene()


func evaluate_move(card: GameCard, slot: BoardSlot) -> int:
	var score: int = 0
	var index := slot.slot_index
	@warning_ignore("shadowed_variable_base_class")
	var position := Vector2i(index % 3, int(float(index) / 3.0))
	score += evaluate_capture(card.data.up, position + Vector2i.UP, "down")
	score += evaluate_capture(card.data.right, position + Vector2i.RIGHT,"left")
	score += evaluate_capture(card.data.down, position + Vector2i.DOWN, "up")
	score += evaluate_capture(card.data.left, position + Vector2i.LEFT, "right")
	if position.y == 0:
		score += 10 - card.data.up
	if position.y == 2:
		score += 10 - card.data.down
	if position.x == 0:
		score += 10 - card.data.left
	if position.x == 2:
		score += 10 - card.data.right
	if is_corner(position):
		score += 5
	score -= evaluate_danger(card, position)
	return score


func evaluate_capture(attack_value: int, target_position: Vector2i, enemy_side: String) -> int:
	var target := get_card_at(target_position)
	if target == null:
		return 0
	if target.owner_id == COMPUTER:
		return 0
	var defense_value: int = 0
	match enemy_side:
		"up":
			defense_value = target.data.up
		"right":
			defense_value = target.data.right
		"down":
			defense_value = target.data.down
		"left":
			defense_value = target.data.left
	if attack_value > defense_value:
		return 100

	return 0


func is_corner(board_position: Vector2i) -> bool:
	return (
		board_position == Vector2i(0, 0)
		or board_position == Vector2i(2, 0)
		or board_position == Vector2i(0, 2)
		or board_position == Vector2i(2, 2)
	)


func evaluate_danger(card: GameCard, board_position: Vector2i) -> int:
	var danger: int = 0
	if board_position.y > 0:
		if get_card_at(board_position + Vector2i.UP) == null:
			danger += get_side_threat(card.data.up, "down")
	if board_position.x < 2:
		if get_card_at(board_position + Vector2i.RIGHT) == null:
			danger += get_side_threat(card.data.right, "left")
	if board_position.y < 2:
		if get_card_at(board_position + Vector2i.DOWN) == null:
			danger += get_side_threat(card.data.down, "up")
	if board_position.x > 0:
		if get_card_at(board_position + Vector2i.LEFT) == null:
			danger += get_side_threat(card.data.left, "right")
	return danger


func side_danger(side_value: int) -> int:
	var danger: int = 0
	for child in player_hand.get_children():
		if child is not GameCard:
			continue
		var player_card: GameCard = child
		if player_card.data.up > side_value:
			danger += 2
		if player_card.data.right > side_value:
			danger += 2
		if player_card.data.down > side_value:
			danger += 2
		if player_card.data.left > side_value:
			danger += 2
	return danger


func get_side_threat(defense_value: int, attacking_side: String) -> int:
	var threat: int = 0
	for child in player_hand.get_children():
		if child is not GameCard:
			continue
		var player_card: GameCard = child
		var attack_value: int = 0
		match attacking_side:
			"up":
				attack_value = player_card.data.up
			"right":
				attack_value = player_card.data.right
			"down":
				attack_value = player_card.data.down
			"left":
				attack_value = player_card.data.left
		if attack_value > defense_value:
			threat += 5
	return threat


func setup_ai_difficulty() -> void:
	match RunManager.current_combat_type:
		"normal":
			ai_difficulty = AIDifficulty.NORMAL
		"elite":
			ai_difficulty = AIDifficulty.HARD
		"boss":
			ai_difficulty = AIDifficulty.HARD
		_:
			ai_difficulty = AIDifficulty.NORMAL


func normal_ai_move(available_cards: Array[GameCard], empty_slots: Array[BoardSlot]) -> void:
	if randf() < 0.25:
		medium_ai_move(available_cards, empty_slots)
		return
	var chosen_card: GameCard = available_cards.pick_random()
	var chosen_slot: BoardSlot = empty_slots.pick_random()
	place_card(chosen_card, chosen_slot)
	finish_turn()


func medium_ai_move(available_cards: Array[GameCard], empty_slots: Array[BoardSlot])  -> void:
	if randf() < 0.20:
		var random_card: GameCard = available_cards.pick_random()
		var random_slot: BoardSlot = empty_slots.pick_random()
		place_card(random_card, random_slot)
		finish_turn()
		return
	var best_card: GameCard = null
	var best_slot: BoardSlot = null
	var best_score: int = -999999
	for card in available_cards:
		for slot in empty_slots:
			var score := evaluate_move(card, slot)
			score += randi_range(0, 2)
			if score > best_score:
				best_score = score
				best_card = card
				best_slot = slot
	if best_card != null and best_slot != null:
		place_card(best_card, best_slot)
	finish_turn()


func hard_ai_move(available_cards: Array[GameCard], empty_slots: Array[BoardSlot]) -> void:
	var best_card: GameCard = null
	var best_slot: BoardSlot = null
	var best_score: int = -999999
	for card in available_cards:
		for slot in empty_slots:
			var score := evaluate_move(card, slot)
			score += evaluate_future_danger(card, slot)
			if score > best_score:
				best_score = score
				best_card = card
				best_slot = slot
	if best_card != null and best_slot != null:
		print("Hard AI chooses ", best_card.data.card_name, " -> Slot ", best_slot.slot_index, " Score: ", best_score)
		place_card(best_card, best_slot)
	finish_turn()


func evaluate_future_danger(card: GameCard, slot: BoardSlot) -> int:
	var score: int = 0
	var board_position := Vector2i(slot.slot_index % 3, int(float(slot.slot_index) / 3.0))
	if board_position.y > 0:
		if get_card_at(board_position + Vector2i.UP) == null:
			score -= get_side_threat(card.data.up, "down")
	if board_position.x < 2:
		if get_card_at(board_position + Vector2i.RIGHT) == null:
			score -= get_side_threat(card.data.right, "left")
	if board_position.y < 2:
		if get_card_at(board_position + Vector2i.DOWN) == null:
			score -= get_side_threat(card.data.down, "up")
	if board_position.x > 0:
		if get_card_at(board_position + Vector2i.LEFT) == null:
			score -= get_side_threat(card.data.left, "right")
	return score


func setup_enemy() -> void:
	match RunManager.current_combat_type:
		"normal":
			ai_difficulty = AIDifficulty.NORMAL
		"elite":
			ai_difficulty = AIDifficulty.MEDIUM
		"boss":
			ai_difficulty = AIDifficulty.HARD


func setup_roguelite_combat() -> void:
	continue_button.hide()
	setup_combat_buffs()
	setup_combat_type()
	if RunManager.current_combat_type == "boss":
		if RunManager.boss_special_ability.is_empty():
			RunManager.choose_boss_special_ability()
	update_health_display()
	create_player_hand_from_run()
	create_enemy_hand()
	show_boss_special_ability()
	show_combat_information()
	update_encounter_progress()
	current_player = PLAYER
	game_over = false
	update_turn_label()
	update_scores()


func update_health_display() -> void:
	health_label.text = ("HP: " + str(RunManager.player_health) + " / " + str(RunManager.player_max_health))
	health_bar.max_value = RunManager.player_max_health
	health_bar.value = RunManager.player_health


func setup_combat_type() -> void:
	match RunManager.current_combat_type:
		"normal":
			combat_type_label.text = "NORMAL COMBAT"
		"elite":
			combat_type_label.text = "ELITE COMBAT"
		"boss":
			combat_type_label.text = "BOSS BATTLE"
		_:
			combat_type_label.text = "COMBAT"
	setup_ai_difficulty()


func create_player_hand_from_run() -> void:
	for child: Node in player_hand.get_children():
		child.queue_free()
	for variant: Dictionary in RunManager.battle_hand:
		var card_path: String = str(variant.get("path", ""))
		if card_path.is_empty():
			continue
		if not ResourceLoader.exists(card_path):
			push_error("Battle card does not exist: " + card_path)
			continue
		var card_data: CardData = RunManager.create_saved_card_variant(variant)
		if card_data == null:
			push_error("Could not create card variant: " + card_path)
			continue
		var card: GameCard = CARD_SCENE.instantiate() as GameCard
		if card == null:
			continue
		player_hand.add_child(card)
		card.data = card_data
		card.update_card()
		card.set_card_owner(PLAYER)
		get_card_bonus_sources(card)
		await get_tree().process_frame
		card.save_starting_position()
		card.reset_combat_abilities()
		card.card_clicked.connect(_on_card_clicked)
		print(
			"Battle card created: ",
			card_data.card_name,
			" | Rarity: ",
			card_data.rarity,
			" | Stats: ",
			card_data.up,
			"/",
			card_data.right,
			"/",
			card_data.down,
			"/",
			card_data.left
		)


func get_enemy_pool() -> Array[String]:
	match RunManager.current_combat_type:
		"elite":
			return elite_enemy_pool
		"boss":
			return boss_enemy_pool
		_:
			return normal_enemy_pool


func create_enemy_hand() -> void:
	for child: Node in opponent_hand.get_children():
		child.queue_free()
	var pool: Array[String] = get_enemy_pool()
	var shuffled_pool: Array[String] = pool.duplicate()
	shuffled_pool.shuffle()
	var cards_to_create: int = mini(5, shuffled_pool.size())
	var can_see_enemy_hand: bool = RunManager.has_item("scrying_lens")
	for i: int in range(cards_to_create):
		var card_path: String = shuffled_pool[i]
		var resource: Resource = load(card_path)
		if resource is CardData:
			var card_data: CardData = resource as CardData
			var card: GameCard = CARD_SCENE.instantiate() as GameCard
			if card == null:
				continue
			opponent_hand.add_child(card)
			card.data = card_data
			card.update_card()
			card.set_card_owner(COMPUTER)
			card.reset_combat_abilities()
			get_card_bonus_sources(card)
			if can_see_enemy_hand:
				card.set_card_hidden(false)
				card.visible = true
			else:
				card.set_card_hidden(true)
				card.visible = true


func update_scores() -> void:
	var player_score: int = 0
	var computer_score: int = 0
	for card in board:
		if card == null:
			continue
		var game_card: GameCard = card as GameCard
		if game_card == null:
			continue
		if game_card.owner_id == PLAYER:
			player_score += 1
		elif game_card.owner_id == COMPUTER:
			computer_score += 1
	for child: Node in player_hand.get_children():
		if child is GameCard:
			player_score += 1
	for child: Node in opponent_hand.get_children():
		if child is GameCard:
			computer_score += 1
	player_score_label.text = "Player: " + str(player_score)
	enemy_score_label.text = "Enemy: " + str(computer_score)


func resolve_combat(player_score: int, computer_score: int) -> void:
	game_over = true
	if player_score > computer_score:
		AudioManager.play_sfx("victory")
		handle_combat_win()
	elif computer_score > player_score:
		handle_combat_loss(player_score, computer_score)
	else:
		AudioManager.play_sfx("draw")
		handle_combat_draw()


func handle_combat_win() -> void:
	var encounter_complete: bool = RunManager.add_encounter_win()
	update_encounter_progress()
	RunManager.consume_combat_buffs()
	if encounter_complete:
		handle_encounter_complete()
		return
	match RunManager.current_combat_type:
		"elite":
			result_label.text = ("Victory!\n" + "Elite Wins: " + str(RunManager.encounter_wins) + " / " + str(RunManager.encounter_wins_required))
		"boss":
			result_label.text = ("Victory!\n" + "Boss Wins: " + str(RunManager.encounter_wins) + " / " + str(RunManager.encounter_wins_required))
		_:
			result_label.text = "Victory!"
	continue_button.text = "Next Match"
	continue_button.show()


func handle_combat_loss(_player_score: int, _computer_score: int) -> void:
	RunManager.consume_combat_buffs()
	if RunManager.has_item("iron_armor"):
		if not RunManager.iron_armor_used:
			RunManager.iron_armor_used = true
			result_label.text = "Iron Armor prevented the HP loss!"
			print("Iron Armor activated!")
			return
	RunManager.player_health -= 1
	RunManager.player_health = maxi(RunManager.player_health, 0)
	update_health_display()
	update_encounter_progress()
	if RunManager.player_health <= 0:
		handle_run_defeat()
		return
	match RunManager.current_combat_type:
		"boss":
			result_label.text = ("Boss Match Lost!\n" + "Lost 1 Health\n" + "Boss Wins: " + str(RunManager.encounter_wins) + " / 3")
			if RunManager.current_combat_type == "boss":
				if RunManager.boss_special_ability == "dark_pact":
					if not RunManager.boss_dark_pact_used:
						RunManager.boss_dark_pact_used = true
						result_label.text = (
						"Dark Pact!\n"
						+ "The Boss ignored its defeat!"
						+ "\nLost 1 Health"
						)
			print("DARK PACT ACTIVATED!")
			continue_button.text = "Try Again"
			continue_button.show()
			return
		"elite":
			result_label.text = ("Elite Match Lost!\n" + "Lost 1 Health\n" + "Elite Wins: " + str(RunManager.encounter_wins) + " / 2")
		_:
			result_label.text = ("Defeat!\nLost 1 Health")
	continue_button.text = "Try Again"
	continue_button.show()


func handle_combat_draw() -> void:
	result_label.text = "Draw!"
	continue_button.text = "Try Again"
	continue_button.show()


func handle_run_defeat() -> void:
	if RunManager.has_relic("phoenix_relic"):
		if not RunManager.phoenix_used_this_run:
			RunManager.phoenix_used_this_run = true
			RunManager.player_health = 2
			result_label.text = "Phoenix Relic saved you!"
			print("Phoenix Relic activated!")
			update_health_display()
			return
	game_over = true
	run_defeated = true
	AudioManager.play_sfx("defeat")
	get_tree().change_scene_to_file("res://menus/GameOver.tscn")


func update_encounter_progress() -> void:
	encounter_progress_label.text = ("Wins: " + str(RunManager.encounter_wins) + " / " + str(RunManager.encounter_wins_required))


func handle_encounter_complete() -> void:
	# Award money once when the encounter is fully won.
	var money_earned: int = RunManager.award_enemy_defeat_money()
	match RunManager.current_combat_type:
		"elite":
			result_label.text = "Elite Defeated!"
		"boss":
			result_label.text = "Boss Defeated!"
		_:
			result_label.text = "Victory!"
	result_label.text += "\n+" + str(money_earned) + " gold"
	RunManager.complete_selected_room()
	if RunManager.is_run_complete():
		result_label.text = "FINAL BOSS DEFEATED!\nYOU WIN!"
		RunManager.complete_run_length(RunManager.current_run_length)
		RunManager.run_won = true
		RunManager.run_active = false
		RunManager.clear_battle_hand()
		RunManager.clear_encounter_progress()
		continue_button.text = "Game Complete"
		continue_button.show()
		if continue_button.pressed.is_connected(_on_continue_button_pressed):
			continue_button.pressed.disconnect(_on_continue_button_pressed)
		if not continue_button.pressed.is_connected(_on_final_boss_complete):
			continue_button.pressed.connect(_on_final_boss_complete)
		return
	RunManager.clear_encounter_progress()
	RunManager.clear_battle_hand()
	continue_button.text = "Return to Map"
	continue_button.show()


func setup_combat_buffs() -> void:
	combat_buff_value_bonus = 0
	enemy_combat_value_bonus = 0
	if RunManager.has_combat_buff("extra_card_power"):
		combat_buff_value_bonus = 1
	if RunManager.has_combat_buff("weakening_curse"):
		enemy_combat_value_bonus = -1
	print("===== COMBAT BUFF TEST =====")
	print("Active buffs: ", RunManager.active_combat_buffs)
	print("Player power bonus: ", combat_buff_value_bonus)
	print("Enemy power bonus: ", enemy_combat_value_bonus)
	print("============================")


func get_card_bonus_sources(card: GameCard) -> Array[Dictionary]:
	var sources: Array[Dictionary] = []
	if card == null or card.data == null:
		return sources
	if card.owner_id == PLAYER:
		if RunManager.has_item("iron_sword"):
			sources.append({
				"name": "Iron Sword",
				"type": "item",
				"amount": 1,
				"icon": get_item_icon("iron_sword")
			})
		sources.append({
				"name": "Ancient Sword",
				"type": "relic",
				"amount": 2,
				"icon": get_item_icon("ancient_sword")
			})
		if RunManager.has_item("chainmail") and not RunManager.chainmail_used:
			sources.append({
				"name": "Chainmail",
				"type": "item",
				"amount": 1,
				"icon": get_item_icon_by_id("chainmail")
			})
		if RunManager.has_combat_buff("extra_card_power"):
			sources.append({
				"name": "Power Surge",
				"type": "buff",
				"amount": 1
			})
		if RunManager.has_combat_buff("first_strike"):
			if RunManager.first_strike_active:
				sources.append({
					"name": "First Strike",
					"type": "buff",
					"amount": 2
				})
		if RunManager.has_combat_buff("last_stand"):
			if RunManager.player_health <= 1:
				sources.append({
					"name": "Last Stand",
					"type": "buff",
					"amount": 2
				})
		if card.data.rarity == CardData.Rarity.MYTHIC:
			match card.data.mythic_ability:
				"Dragon_Fury":
					sources.append({
						"name": "Dragon Fury",
						"type": "mythic",
						"amount": 2
					})
	elif card.owner_id == COMPUTER:
		if RunManager.has_combat_buff("weakening_curse"):
			sources.append({
				"name": "Weakening Curse",
				"type": "enemy",
				"amount": -1
			})
		if RunManager.current_combat_type == "boss":
			match RunManager.boss_special_ability:
				"brutal_might":
					sources.append({
						"name": "Brutal Might",
						"type": "enemy",
						"amount": 1
					})
				"blood_rush":
					var remaining_cards: int = 0
					for child: Node in opponent_hand.get_children():
						if child is GameCard:
							remaining_cards += 1
					if remaining_cards <= 2:
						sources.append({
							"name": "Blood Rush",
							"type": "enemy",
							"amount": 2
						})
				"vengeance":
					if RunManager.boss_vengeance_active:
						sources.append({
							"name": "Vengeance",
							"type": "enemy",
							"amount": 2
						})
	card.set_bonus_sources(sources)
	return sources


func get_card_attack_power(card: GameCard, direction: String, enemy_card: GameCard = null) -> int:
	if card == null or card.data == null:
		return 0
	var power: int = 0
	match direction:
		"up":
			power = card.data.up
		"right":
			power = card.data.right
		"down":
			power = card.data.down
		"left":
			power = card.data.left
	if card.owner_id == PLAYER:
		power += combat_buff_value_bonus
		if RunManager.has_item("iron_sword"):
			power += 1
		if RunManager.has_relic("ancient_sword"):
			power += 2
		if RunManager.has_item("war_blade"):
			var enemy_count: int = count_adjacent_enemies(card)
			if enemy_count >= 2:
				power += 1
		if RunManager.has_combat_buff("first_strike"):
			if RunManager.first_strike_active:
				power += 2
		if RunManager.has_combat_buff("last_stand"):
			if RunManager.player_health <= 1:
				power += 2
	if card.owner_id == COMPUTER:
		power += enemy_combat_value_bonus
		if RunManager.current_combat_type == "boss":
			if RunManager.boss_special_ability == "brutal_might":
				power += 1
		if RunManager.current_combat_type == "boss":
			if RunManager.boss_special_ability == "blood_rush":
				var remaining_cards: int = 0
				for child: Node in opponent_hand.get_children():
					if child is GameCard:
						remaining_cards += 1
				if remaining_cards <= 2:
					power += 2
		if RunManager.current_combat_type == "boss":
			if RunManager.boss_special_ability == "vengeance":
				if RunManager.boss_vengeance_active:
					power += 2
	power += get_mythic_attack_bonus(card, enemy_card)
	power = maxi(power, 1)
	return power


func count_adjacent_enemies(card: GameCard) -> int:
	if card == null:
		return 0
	var count: int = 0
	var pos: Vector2i = card.board_position
	var directions: Array[Vector2i] = [
		Vector2i.UP, 
		Vector2i.RIGHT, 
		Vector2i.DOWN, 
		Vector2i.LEFT
		]
	for direction: Vector2i in directions:
		var enemy := get_card_at(pos + direction)
		if enemy == null:
			continue
		if enemy.owner_id != card.owner_id:
			count += 1
	return count


func get_card_defense_power(card: GameCard, direction: String) -> int:
	if card == null:
		return 0
	if card.data == null:
		return 0
	var defense: int = 0
	match direction:
		"up":
			defense = card.data.up
		"right":
			defense = card.data.right
		"down":
			defense = card.data.down
		"left":
			defense = card.data.left
	if card.owner_id == PLAYER:
		if RunManager.has_item("chainmail"):
			if not RunManager.chainmail_used:
				defense += 1
		if RunManager.has_relic("guardian_relic"):
			defense += 2
	if card.owner_id == COMPUTER:
		if RunManager.current_combat_type == "boss":
			if RunManager.boss_special_ability == "fortified_cards":
				defense += 1
	return defense


func get_opposite_direction(direction: String) -> String:
	match direction:
		"up":
			return "down"
		"right":
			return "left"
		"down":
			return "up"
		"left":
			return "right"
	return ""


func get_strongest_player_card() -> GameCard:
	var strongest: GameCard = null
	var strongest_power: int = -1
	for card in board:
		if card == null:
			continue
		var game_card := card as GameCard
		if game_card == null:
			continue
		if game_card.owner_id != PLAYER:
			continue
		if game_card.data == null:
			continue
		var total: int = (game_card.data.up + game_card.data.right + game_card.data.down + game_card.data.left)
		if total > strongest_power:
			strongest_power = total
			strongest = game_card
	return strongest


func guardian_plate_protects(card: GameCard) -> bool:
	if card == null:
		return false
	if RunManager.guardian_plate_used:
		return false
	if not RunManager.has_item("guardian_plate"):
		return false
	var strongest := get_strongest_player_card()
	if strongest != card:
		return false
	RunManager.guardian_plate_used = true
	print("Guardian Plate protected the strongest card!")
	return true


func guardian_relic_protects(card: GameCard) -> bool:
	if card == null:
		return false
	if RunManager.guardian_relic_used:
		return false
	if not RunManager.has_relic("guardian_relic"):
		return false
	RunManager.guardian_relic_used = true
	print("Guardian Relic prevented a capture!")
	return true


func get_scrying_lens_information() -> String:
	if not RunManager.has_item("scrying_lens"):
		return ""
	var result: String = "Scrying Lens:\nEnemy Hand\n"
	for card_path: String in get_enemy_card_paths():
		var resource: Resource = load(card_path)
		if not resource is CardData:
			continue
		var card_data: CardData = resource as CardData
		result += (
			card_data.card_name
			+ "  "
			+ str(card_data.up)
			+ "/"
			+ str(card_data.right)
			+ "/"
			+ str(card_data.down)
			+ "/"
			+ str(card_data.left)
			+ "\n"
		)
	return result


func get_enemy_card_paths() -> Array[String]:
	var result: Array[String] = []
	for card: GameCard in opponent_hand.get_children():
		if card.data == null:
			continue
		if not card.data.resource_path.is_empty():
			result.append(card.data.resource_path)
	return result


func get_tactical_compass_information() -> String:
	if not RunManager.has_item("tactical_compass"):
		return ""
	var strongest: CardData = null
	var strongest_total: int = -1
	for card: GameCard in opponent_hand.get_children():
		if card.data == null:
			continue
		var total: int = (card.data.up + card.data.right + card.data.down + card.data.left)
		if total > strongest_total:
			strongest_total = total
			strongest = card.data
	if strongest == null:
		return ""
	var result: String = "Tactical Compass:\n"
	result += "Strongest Enemy Card: " + strongest.card_name + "\n"
	result += "Values: "
	result += str(strongest.up) + " / "
	result += str(strongest.right) + " / "
	result += str(strongest.down) + " / "
	result += str(strongest.left)
	return result


func get_tactical_insight_information() -> String:
	if not RunManager.has_combat_buff("tactical_insight"):
		return ""
	var strongest: GameCard = null
	var strongest_total: int = -1
	for child in opponent_hand.get_children():
		if not child is GameCard:
			continue
		var card: GameCard = child
		if card.data == null:
			continue
		var total: int = (card.data.up + card.data.right + card.data.down + card.data.left)
		if total > strongest_total:
			strongest_total = total
			strongest = card
	if strongest == null:
		return ""
	var result: String = "TACTICAL INSIGHT\n"
	result += "Strongest Enemy Card: " + strongest.data.card_name + "\n"
	result += "↑ " + str(strongest.data.up)
	result += "  → " + str(strongest.data.right)
	result += "\n↓ " + str(strongest.data.down)
	result += "  ← " + str(strongest.data.left)
	return result


func handle_bonus_cache_reward() -> void:
	if not RunManager.has_item("bonus_cache"):
		return
	print("BONUS CACHE ACTIVATED")
	get_tree().change_scene_to_file("res://GameManager/Map/rooms/BonusCache/BonusCacheRoom.tscn")


func is_mythic(card: GameCard) -> bool:
	if card == null or card.data == null:
		return false
	return card.data.rarity == CardData.Rarity.MYTHIC


func get_mythic_attack_bonus(card: GameCard, enemy_card: GameCard) -> int:
	if card == null:
		return 0
	if card.data == null:
		return 0
	if card.data.rarity != CardData.Rarity.MYTHIC:
		return 0
	match card.data.mythic_ability:
		"Dragon_Fury":
			# Dragon Fury gets its bonus when attacking.
			return 2
		"Blood_Hunt":
			# Blood Hunt gets +1 against a powerful enemy card.
			if enemy_card == null:
				return 0
			if enemy_card.data == null:
				return 0
			var enemy_power: int = maxi(enemy_card.data.up, maxi(enemy_card.data.right, maxi(enemy_card.data.down, enemy_card.data.left)))
			if enemy_power >= 7:
				return 1
		"Petrify":
			return 0
		"Divine_Shield":
			return 0
		_:
			return 0
	return 0


func _on_inventory_button_pressed() -> void:
	var inventory = INVENTORY_SCENE.instantiate()
	add_child(inventory)


func start_coin_flip() -> void:
	coin_flip_finished = false
	coin_flip_panel.visible = true
	coin_label.text = "🪙"
	coin_result_label.text = "WHO GOES FIRST?"
	flip_button.visible = true
	flip_button.disabled = false


func _on_flip_button_pressed() -> void:
	if coin_flip_finished:
		return
	flip_button.disabled = true
	coin_result_label.text = "FLIPPING..."
	await get_tree().create_timer(0.5).timeout
	var result: int = randi_range(0, 1)
	if result == 0:
		player_goes_first = true
		coin_label.text = "HEADS"
		coin_result_label.text = "PLAYER GOES FIRST!"
		RunManager.encounter_coin_flip_done = true
	else:
		player_goes_first = false
		coin_label.text = "TAILS"
		coin_result_label.text = "COMPUTER GOES FIRST!"
		RunManager.encounter_coin_flip_done = true
	await get_tree().create_timer(1.0).timeout
	finish_coin_flip()


func finish_coin_flip() -> void:
	if coin_flip_finished:
		return
	coin_flip_finished = true
	coin_flip_panel.visible = false
	print("Coin flip finished.")
	print("Player goes first: ", player_goes_first)
	start_first_turn_after_coin_flip()


func start_first_turn_after_coin_flip() -> void:
	if RunManager.current_combat_type == "boss":
		if RunManager.boss_special_ability == "first_strike":
			current_player = COMPUTER
			player_goes_first = false
			update_turn_label()
			print("BOSS FIRST STRIKE!")
			computer_turn()
			return
	if player_goes_first:
		current_player = PLAYER
		update_turn_label()
		print("PLAYER'S TURN")
	else:
		current_player = COMPUTER
		update_turn_label()
		print("COMPUTER'S TURN")
		computer_turn()


func _on_final_boss_complete() -> void:
	var completed_difficulty: String = ""
	match RunManager.game_difficulty:
		0:
			completed_difficulty = "easy"
		1:
			completed_difficulty = "normal"
		2:
			completed_difficulty = "hard"
	if not completed_difficulty.is_empty():
		RunManager.complete_difficulty(completed_difficulty)
	get_tree().change_scene_to_file("res://menus/GameOver.tscn")


func should_show_coin_flip() -> bool:
	if RunManager.current_combat_type == "normal":
		return true
	if RunManager.current_combat_type == "elite":
		return not RunManager.encounter_coin_flip_done
	if RunManager.current_combat_type == "boss":
		return not RunManager.encounter_coin_flip_done
	return true


func start_hidden_coin_flip() -> void:
	var result: int = randi_range(0, 1)
	if result == 0:
		player_goes_first = true
		print("Hidden coin flip: PLAYER goes first.")
	else:
		player_goes_first = false
		print("Hidden coin flip: COMPUTER goes first.")
	RunManager.encounter_coin_flip_done = true
	coin_flip_finished = true
	coin_flip_panel.visible = false
	start_first_turn_after_coin_flip()


func show_combat_information() -> void:
	var info_text: String = ""
	if RunManager.current_combat_type == "boss":
		var ability: String = RunManager.boss_special_ability
		if not ability.is_empty():
			info_text += "BOSS SPECIAL ABILITY\n"
			info_text += get_boss_ability_name(ability) + "\n"
			info_text += get_boss_ability_description(ability)
			info_text += "\n\n"
	if RunManager.has_combat_buff("tactical_insight"):
		var strongest: GameCard = null
		var strongest_total: int = -1
		for child in opponent_hand.get_children():
			if not child is GameCard:
				continue
			var card: GameCard = child
			if card.data == null:
				continue
			var total: int = (
				card.data.up
				+ card.data.right
				+ card.data.down
				+ card.data.left
			)
			if total > strongest_total:
				strongest_total = total
				strongest = card
		if strongest != null:
			info_text += "TACTICAL INSIGHT\n"
			info_text += "Strongest Enemy Card: "
			info_text += strongest.data.card_name + "\n"
			info_text += "↑ " + str(strongest.data.up)
			info_text += "  → " + str(strongest.data.right)
			info_text += "\n"
			info_text += "↓ " + str(strongest.data.down)
			info_text += "  ← " + str(strongest.data.left)
	combat_info_label.text = info_text


func get_boss_ability_pool() -> Array[String]:
	return [
		"brutal_might",
		"fortified_cards",
		"blood_rush",
		"vengeance",
		"first_strike",
		"dark_pact"
	]


func get_boss_ability_name(ability: String) -> String:
	match ability:
		"brutal_might":
			return "BRUTAL MIGHT"
		"fortified_cards":
			return "FORTIFIED CARDS"
		"blood_rush":
			return "BLOOD RUSH"
		"vengeance":
			return "VENGEANCE"
		"first_strike":
			return "FIRST STRIKE"
		"dark_pact":
			return "DARK PACT"
		_:
			return "UNKNOWN"


func get_boss_ability_description(ability: String) -> String:
	match ability:
		"brutal_might":
			return "Boss cards gain +2 attack."
		"fortified_cards":
			return "Boss cards gain +2 defense."
		"blood_rush":
			return "Boss cards gain +3 attack when 2 or fewer cards remain."
		"vengeance":
			return "After you capture a boss card, its next card gains +3 attack."
		"first_strike":
			return "The boss always takes the first turn."
		"dark_pact":
			return "The first boss defeat is ignored."
		_:
			return ""


func show_boss_special_ability() -> void:
	if RunManager.current_combat_type != "boss":
		combat_info_label.text = ""
		return
	var ability: String = RunManager.boss_special_ability
	if ability.is_empty():
		combat_info_label.text = ""
		return
	combat_info_label.text = (
		"BOSS SPECIAL ABILITY\n"
		+ get_boss_ability_name(ability)
		+ "\n"
		+ get_boss_ability_description(ability)
	)


func get_item_icon(item_id: String) -> Texture2D:
	var path: String = str(ITEM_DATA_PATHS.get(item_id, ""))
	if path.is_empty():
		return null
	var item_data: ItemData = load(path) as ItemData
	if item_data == null:
		push_warning("Could not load ItemData: " + path)
		return null
	return item_data.icon


func get_item_icon_by_id(item_id: String) -> Texture2D:
	for item_path: String in RunManager.items:
		var item_data: ItemData = load(item_path) as ItemData
		if item_data != null and item_data.item_id == item_id:
			return item_data.icon
	for relic_path: String in RunManager.relics:
		var relic_data: ItemData = load(relic_path) as ItemData
		if relic_data != null and relic_data.item_id == item_id:
			return relic_data.icon
	return null








































#
