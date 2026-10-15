extends Control

const TOTAL_PAGES: int = 6

var current_page: int = 0
var page_completed: bool = false

var direction_clicked: Dictionary = {
	"up": false,
	"right": false,
	"down": false,
	"left": false
}

var capture_completed: bool = false

var board_cards: Dictionary = {}
var board_placed_count: int = 0
var multiple_capture_completed: bool = false

var battle_selected_cards: Array[String] = []
var battle_turn: int = 0
var battle_board: Dictionary = {}
var battle_player_cards: int = 0
var battle_enemy_cards: int = 0

var visited_rooms: Dictionary = {
	"combat": false,
	"elite": false,
	"healing": false,
	"card": false,
	"buff": false,
	"boss": false
}

var tutorial_easy_unlocked: bool = true
var tutorial_normal_unlocked: bool = false
var tutorial_hard_unlocked: bool = false

@onready var title_label: Label = $MarginContainer/VBoxContainer/Header/TitleLabel
@onready var page_label: Label = $MarginContainer/VBoxContainer/Header/PageLabel
@onready var section_title: Label = $MarginContainer/VBoxContainer/ContentPanel/ContentMargin/ContentVBox/SectionTitle
@onready var description_label: Label = $MarginContainer/VBoxContainer/ContentPanel/ContentMargin/ContentVBox/DescriptionLabel
@onready var example_container: VBoxContainer = $MarginContainer/VBoxContainer/ContentPanel/ContentMargin/ContentVBox/ExampleContainer
@onready var tip_label: Label = $MarginContainer/VBoxContainer/ContentPanel/ContentMargin/ContentVBox/TipLabel
@onready var back_button: Button = $MarginContainer/VBoxContainer/ButtonBar/BackButton
@onready var skip_button: Button = $MarginContainer/VBoxContainer/ButtonBar/SkipButton
@onready var next_button: Button = $MarginContainer/VBoxContainer/ButtonBar/NextButton


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	skip_button.pressed.connect(_on_skip_pressed)
	next_button.pressed.connect(_on_next_pressed)
	show_page(0)


func show_page(page: int) -> void:
	current_page = clampi(page, 0, TOTAL_PAGES - 1)
	page_completed = false
	clear_example()
	page_label.text = "PAGE %d / %d" % [
		current_page + 1,
		TOTAL_PAGES
	]
	back_button.disabled = current_page == 0
	next_button.disabled = true
	if current_page == TOTAL_PAGES - 1:
		next_button.text = "FINISH"
	else:
		next_button.text = "NEXT"
	match current_page:
		0:
			show_tutorial_1()
		1:
			show_tutorial_2()
		2:
			show_tutorial_3()
		3:
			show_tutorial_4()
		4:
			show_tutorial_5()
		5:
			show_tutorial_6()


func complete_page() -> void:
	page_completed = true
	next_button.disabled = false
	tip_label.text = "✓ Tutorial section complete! Click NEXT to continue."


func clear_example() -> void:
	for child: Node in example_container.get_children():
		child.queue_free()


# ============================================================
# TUTORIAL 1
# CARD BASICS
# ============================================================


func show_tutorial_1() -> void:
	title_label.text = "HOW TO PLAY"
	section_title.text = "1. BASIC CARD RULES"
	description_label.text = (
		"Cards have four values. Click each side of the card "
		+ "to learn what that value does."
	)
	direction_clicked = {
		"up": false,
		"right": false,
		"down": false,
		"left": false
	}
	create_interactive_card()
	tip_label.text = "Click all four directions to continue."


func create_interactive_card() -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 300)
	var card_box := VBoxContainer.new()
	panel.add_child(card_box)
	var card_title := Label.new()
	card_title.text = "TRAINING CARD"
	card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_box.add_child(card_title)
	var card := GridContainer.new()
	card.columns = 3
	card.custom_minimum_size = Vector2(400, 220)
	card_box.add_child(card)
	var empty1 := Control.new()
	card.add_child(empty1)
	var up_button := Button.new()
	up_button.text = "↑\n7"
	up_button.custom_minimum_size = Vector2(120, 70)
	up_button.pressed.connect(_on_direction_clicked.bind("up", up_button))
	card.add_child(up_button)
	var empty2 := Control.new()
	card.add_child(empty2)
	var left_button := Button.new()
	left_button.text = "← 4"
	left_button.custom_minimum_size = Vector2(120, 70)
	left_button.pressed.connect(_on_direction_clicked.bind("left", left_button))
	card.add_child(left_button)
	var center := Label.new()
	center.text = "DRAGON"
	center.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	center.custom_minimum_size = Vector2(120, 70)
	card.add_child(center)
	var right_button := Button.new()
	right_button.text = "9 →"
	right_button.custom_minimum_size = Vector2(120, 70)
	right_button.pressed.connect(_on_direction_clicked.bind("right", right_button))
	card.add_child(right_button)
	var empty3 := Control.new()
	card.add_child(empty3)
	var down_button := Button.new()
	down_button.text = "↓\n6"
	down_button.custom_minimum_size = Vector2(120, 70)
	down_button.pressed.connect(_on_direction_clicked.bind("down", down_button))
	card.add_child(down_button)
	var empty4 := Control.new()
	card.add_child(empty4)
	example_container.add_child(panel)


func _on_direction_clicked(direction: String, button: Button) -> void:
	if direction_clicked[direction]:
		return
	direction_clicked[direction] = true
	match direction:
		"up":
			button.text = "↑\nATTACKS ABOVE"
		"right":
			button.text = "RIGHT →\nATTACKS RIGHT"
		"down":
			button.text = "↓\nATTACKS BELOW"
		"left":
			button.text = "← LEFT\nATTACKS LEFT"
	button.disabled = true
	if (
		direction_clicked["up"]
		and direction_clicked["right"]
		and direction_clicked["down"]
		and direction_clicked["left"]
	):
		complete_page()


# ============================================================
# TUTORIAL 2
# CAPTURING
# ============================================================


func show_tutorial_2() -> void:
	title_label.text = "HOW TO PLAY"
	section_title.text = "2. CAPTURING CARDS"
	description_label.text = (
		"Click the attacking side to compare it against "
		+ "the enemy's defending side."
	)
	capture_completed = false
	create_capture_training()
	tip_label.text = "Click ATTACK to perform the comparison."


func create_capture_training() -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(600, 300)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var title := Label.new()
	title.text = "CAPTURE TRAINING"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var comparison := Label.new()
	comparison.name = "ComparisonLabel"
	comparison.text = "YOUR CARD        ENEMY CARD\n\n      8  →  6"
	comparison.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	comparison.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	comparison.custom_minimum_size = Vector2(500, 100)
	box.add_child(comparison)
	var attack_button := Button.new()
	attack_button.text = "ATTACK"
	attack_button.custom_minimum_size = Vector2(250, 60)
	attack_button.pressed.connect(
		_on_capture_attack_pressed.bind(attack_button, comparison)
	)
	box.add_child(attack_button)
	example_container.add_child(panel)


func _on_capture_attack_pressed(button: Button, comparison: Label) -> void:
	if capture_completed:
		return
	capture_completed = true
	comparison.text = (
		"YOUR CARD        ENEMY CARD\n\n"
		+ "      8  →  6\n\n"
		+ "          8 > 6\n\n"
		+ "       ✓ CAPTURE!"
	)
	button.text = "CAPTURED!"
	button.disabled = true
	tip_label.text = ("8 is higher than 6, so the enemy card is captured.")
	complete_page()



# ============================================================
# TUTORIAL 3
# 3 × 3 BOARD
# ============================================================


func show_tutorial_3() -> void:
	title_label.text = "HOW TO PLAY"
	section_title.text = "3. THE 3 × 3 BOARD"
	description_label.text = (
		"Cards are placed on a 3 × 3 board. "
		+ "Click the center space to place your card."
	)
	board_cards.clear()
	board_placed_count = 0
	multiple_capture_completed = false
	create_training_board()
	tip_label.text = "Click the CENTER space to place your card."


func create_training_board() -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(600, 390)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var instruction := Label.new()
	instruction.name = "BoardInstruction"
	instruction.text = "PLACE YOUR CARD IN THE CENTER"
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction.custom_minimum_size = Vector2(0, 35)
	box.add_child(instruction)
	var board_center := CenterContainer.new()
	board_center.custom_minimum_size = Vector2(0, 300)
	box.add_child(board_center)
	var board := GridContainer.new()
	board.name = "TrainingBoard"
	board.columns = 3
	board.custom_minimum_size = Vector2(360, 270)
	board.add_theme_constant_override("h_separation", 4)
	board.add_theme_constant_override("v_separation", 4)
	board_center.add_child(board)
	for y in range(3):
		for x in range(3):
			var cell := Button.new()
			cell.custom_minimum_size = Vector2(115, 85)
			cell.text = ""
			cell.pressed.connect(
				_on_training_board_cell_pressed.bind(
					cell,
					Vector2i(x, y),
					instruction
				)
			)
			board.add_child(cell)
	example_container.add_child(panel)


func _on_training_board_cell_pressed(cell: Button, position: Vector2i, instruction: Label) -> void:
	if board_placed_count > 0:
		return
	if position != Vector2i(1, 1):
		instruction.text = "Try placing your card in the CENTER."
		return
	cell.text = "YOU\n7"
	cell.disabled = true
	board_cards[position] = "player"
	board_placed_count = 1
	instruction.text = "✓ CARD PLACED!"
	tip_label.text = (
		"Excellent! Now see how one card can attack "
		+ "multiple adjacent cards."
	)
	await get_tree().create_timer(0.5).timeout
	create_multiple_capture_demo()


func create_multiple_capture_demo() -> void:
	# Prevent creating the demonstration more than once.
	if multiple_capture_completed:
		return
	var demo_panel := PanelContainer.new()
	demo_panel.custom_minimum_size = Vector2(600, 130)
	var demo_box := VBoxContainer.new()
	demo_box.add_theme_constant_override("separation", 8)
	demo_panel.add_child(demo_box)
	var demo_label := Label.new()
	demo_label.text = (
		"ONE CARD CAN CHECK MULTIPLE DIRECTIONS!\n\n"
		+ "↑  UP     →  RIGHT     ↓  DOWN     ←  LEFT"
	)
	demo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	demo_label.custom_minimum_size = Vector2(0, 55)
	demo_box.add_child(demo_label)
	var capture_button := Button.new()
	capture_button.text = "DEMONSTRATE MULTIPLE CAPTURE"
	capture_button.custom_minimum_size = Vector2(350, 45)
	capture_button.pressed.connect(
		_on_multiple_capture_pressed.bind(
			capture_button,
			demo_label
		)
	)
	demo_box.add_child(capture_button)
	example_container.add_child(demo_panel)


func _on_multiple_capture_pressed(button: Button, label: Label) -> void:
	if multiple_capture_completed:
		return
	multiple_capture_completed = true
	button.text = "✓ MULTIPLE CAPTURE DEMONSTRATED"
	button.disabled = true
	label.text = (
		"✓ YOUR CARD CAN CHECK ALL FOUR DIRECTIONS!\n\n"
		+ "UP • RIGHT • DOWN • LEFT"
	)
	tip_label.text = (
		"Great! Positioning your cards carefully can let "
		+ "you capture multiple enemy cards."
	)
	complete_page()



# ============================================================
# TUTORIAL 4
# BATTLE
# ============================================================


func show_tutorial_4() -> void:
	title_label.text = "HOW TO PLAY"
	section_title.text = "4. BATTLE"
	description_label.text = (
		"Choose five cards for your battle hand, then place "
		+ "cards against the tutorial opponent."
	)
	battle_selected_cards.clear()
	battle_turn = 0
	battle_board.clear()
	battle_player_cards = 0
	battle_enemy_cards = 0
	create_battle_training()
	tip_label.text = "Choose 5 cards."


func create_battle_training() -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(650, 450)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var hand_title := Label.new()
	hand_title.name = "HandTitle"
	hand_title.text = "CHOOSE 5 CARDS"
	hand_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hand_title)
	var hand := HBoxContainer.new()
	hand.name = "TrainingHand"
	hand.alignment = BoxContainer.ALIGNMENT_CENTER
	var card_names: Array[String] = [
		"DRAGON",
		"KNIGHT",
		"MAGE",
		"GOLEM",
		"WOLF"
	]
	for card_name in card_names:
		var button := Button.new()
		button.text = card_name
		button.custom_minimum_size = Vector2(110, 80)
		button.pressed.connect(
			_on_battle_card_selected.bind(
				card_name,
				button,
				hand_title
			)
		)
		hand.add_child(button)
	box.add_child(hand)
	var board_title := Label.new()
	board_title.text = "BATTLE BOARD"
	board_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(board_title)
	var board := GridContainer.new()
	board.name = "BattleBoard"
	board.columns = 3
	for y in range(3):
		for x in range(3):
			var cell := Button.new()
			cell.custom_minimum_size = Vector2(110, 80)
			cell.pressed.connect(
				_on_battle_board_pressed.bind(
					cell,
					Vector2i(x, y),
					hand_title
				)
			)
			board.add_child(cell)
	box.add_child(board)
	example_container.add_child(panel)


func _on_battle_card_selected(card_name: String, button: Button, hand_title: Label) -> void:
	if battle_selected_cards.size() >= 5:
		return
	if card_name in battle_selected_cards:
		return
	battle_selected_cards.append(card_name)
	button.disabled = true
	button.text = "✓ " + card_name
	hand_title.text = (
		"CARDS SELECTED: "
		+ str(battle_selected_cards.size())
		+ " / 5"
	)
	if battle_selected_cards.size() == 5:
		tip_label.text = "Great! Now place your first card on the board."


func _on_battle_board_pressed(cell: Button, position: Vector2i, hand_title: Label) -> void:
	if battle_selected_cards.size() < 5:
		tip_label.text = "Choose all 5 cards first."
		return
	if battle_turn >= 5:
		return
	if battle_board.has(position):
		return
	# Player places a card.
	var card_name: String = battle_selected_cards[battle_turn]
	cell.text = "YOU\n" + card_name
	cell.disabled = true
	battle_board[position] = "player"
	battle_player_cards += 1
	battle_turn += 1
	hand_title.text = (
		"YOUR TURN — "
		+ str(battle_turn)
		+ " / 5"
	)
	await get_tree().create_timer(0.5).timeout
	if battle_turn < 5:
		create_enemy_response()
	else:
		finish_battle_training()


func create_enemy_response() -> void:
	# Find an empty board location.
	var possible_positions: Array[Vector2i] = []
	for y in range(3):
		for x in range(3):
			var position := Vector2i(x, y)
			if not battle_board.has(position):
				possible_positions.append(position)
	if possible_positions.is_empty():
		return
	var position: Vector2i = possible_positions[0]
	battle_board[position] = "enemy"
	battle_enemy_cards += 1
	var board: GridContainer = null
	for child: Node in example_container.get_children():
		if child is PanelContainer:
			var found := child.find_child(
				"BattleBoard",
				true,
				false
			)
			if found is GridContainer:
				board = found
				break
	if board == null:
		return
	var index: int = position.y * 3 + position.x
	if index < board.get_child_count():
		var cell: Button = board.get_child(index) as Button
		if cell != null:
			cell.text = "ENEMY"
			cell.disabled = true
	tip_label.text = "The enemy has taken a turn. Your turn!"


func finish_battle_training() -> void:
	tip_label.text = (
		"Battle complete! The real game continues until the board is full."
	)
	complete_page()



# ============================================================
# TUTORIAL 5
# ROGUELITE RUN
# ============================================================


func show_tutorial_5() -> void:
	title_label.text = "YOUR RUN"
	section_title.text = "5. THE ROGUELITE RUN"
	description_label.text = (
		"Your run takes you through different room types. "
		+ "Click each room to learn what it does."
	)
	visited_rooms = {
		"combat": false,
		"elite": false,
		"healing": false,
		"card": false,
		"buff": false,
		"boss": false
	}
	create_room_training()
	tip_label.text = "Visit every room type."


func create_room_training() -> void:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.custom_minimum_size = Vector2(600, 350)
	create_room_button(
		grid,
		"⚔ COMBAT",
		"Fight a normal enemy.",
		"combat"
	)
	create_room_button(
		grid,
		"⚔ ELITE",
		"Fight a stronger enemy. Requires 2 victories.",
		"elite"
	)
	create_room_button(
		grid,
		"❤️ HEALING",
		"Restore health before continuing.",
		"healing"
	)
	create_room_button(
		grid,
		"🃏 CARD",
		"Choose a new card for your collection.",
		"card"
	)
	create_room_button(
		grid,
		"💎 BUFF",
		"Choose a temporary run advantage.",
		"buff"
	)
	create_room_button(
		grid,
		"👑 BOSS",
		"Face a powerful boss. Requires 3 victories.",
		"boss"
	)
	example_container.add_child(grid)


func create_room_button(grid: GridContainer, button_text: String, description: String, room_id: String) -> void:
	var button := Button.new()
	button.text = button_text
	button.tooltip_text = description
	button.custom_minimum_size = Vector2(280, 90)
	button.pressed.connect(
		_on_room_training_pressed.bind(
			button,
			description,
			room_id
		)
	)
	grid.add_child(button)


func _on_room_training_pressed(button: Button, description: String, room_id: String) -> void:
	if visited_rooms[room_id]:
		return
	visited_rooms[room_id] = true
	button.text = "✓ " + button.text
	tip_label.text = description
	var all_visited := true
	for room_id_check: String in visited_rooms.keys():
		if not visited_rooms[room_id_check]:
			all_visited = false
			break
	if all_visited:
		complete_page()



# ============================================================
# TUTORIAL 6
# DIFFICULTY
# ============================================================


func show_tutorial_6() -> void:
	title_label.text = "DIFFICULTY"
	section_title.text = "6. DIFFICULTY PROGRESSION"
	description_label.text = (
		"Complete each difficulty to unlock the next one. "
		+ "Click the difficulties in order."
	)
	tutorial_normal_unlocked = false
	tutorial_hard_unlocked = false
	create_difficulty_training()
	tip_label.text = "Complete EASY first."


func create_difficulty_training() -> void:
	var box := VBoxContainer.new()
	var easy_button := Button.new()
	easy_button.text = "🟢 EASY — AVAILABLE"
	easy_button.custom_minimum_size = Vector2(400, 70)
	easy_button.pressed.connect(_on_tutorial_easy_pressed.bind(easy_button))
	box.add_child(easy_button)
	var normal_button := Button.new()
	normal_button.name = "TutorialNormalButton"
	normal_button.text = "🔒 NORMAL — BEAT EASY FIRST"
	normal_button.custom_minimum_size = Vector2(400, 70)
	normal_button.disabled = true
	normal_button.pressed.connect(_on_tutorial_normal_pressed.bind(normal_button))
	box.add_child(normal_button)
	var hard_button := Button.new()
	hard_button.name = "TutorialHardButton"
	hard_button.text = "🔒 HARD — BEAT NORMAL FIRST"
	hard_button.custom_minimum_size = Vector2(400, 70)
	hard_button.disabled = true
	hard_button.pressed.connect(_on_tutorial_hard_pressed.bind(hard_button))
	box.add_child(hard_button)
	example_container.add_child(box)


func _on_tutorial_easy_pressed(button: Button) -> void:
	if tutorial_normal_unlocked:
		return
	tutorial_normal_unlocked = true
	button.text = "✓ EASY COMPLETED"
	var normal_button := find_tutorial_button("TutorialNormalButton")
	if normal_button != null:
		normal_button.disabled = false
		normal_button.text = "🔵 NORMAL — UNLOCKED"
	tip_label.text = ("Easy completed! Normal is now unlocked.")


func _on_tutorial_normal_pressed(button: Button) -> void:
	if not tutorial_normal_unlocked:
		return
	if tutorial_hard_unlocked:
		return
	tutorial_hard_unlocked = true
	button.text = "✓ NORMAL COMPLETED"
	var hard_button := find_tutorial_button("TutorialHardButton")
	if hard_button != null:
		hard_button.disabled = false
		hard_button.text = "🔴 HARD — UNLOCKED"
	tip_label.text = ("Normal completed! Hard is now unlocked.")


func _on_tutorial_hard_pressed(button: Button) -> void:
	if not tutorial_hard_unlocked:
		return
	button.text = "✓ HARD UNLOCKED"
	tip_label.text = ("Excellent! You understand the difficulty progression.")
	complete_page()


func find_tutorial_button(button_name: String) -> Button:
	var result := example_container.find_child(button_name, true, false)
	if result is Button:
		return result as Button
	return null


# ============================================================
# BUTTONS
# ============================================================

func _on_back_pressed() -> void:
	if current_page > 0:
		show_page(current_page - 1)


func _on_next_pressed() -> void:
	if not page_completed:
		return
	if current_page < TOTAL_PAGES - 1:
		show_page(current_page + 1)
	else:
		finish_tutorial()


func _on_skip_pressed() -> void:
	finish_tutorial()


# ============================================================
# FINISH
# ============================================================

func finish_tutorial() -> void:
	get_tree().change_scene_to_file("res://menus/PreRun.tscn")
