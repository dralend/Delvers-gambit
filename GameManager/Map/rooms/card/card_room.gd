extends Control

@onready var card_choices: HBoxContainer = $CardChoices
@onready var description_label: Label = $DescriptionLabel
@onready var skip_button: Button = $SkipButton

const CARD_SCENE: PackedScene = preload("res://GameManager/Card/card.tscn")
const CARD_SIZE := Vector2(160, 220)

var card_pool: Array[String] = [
	"res://GameManager/Card/Type/vermin/Birds.tres",
	"res://GameManager/Card/Type/vermin/Insects.tres",
	"res://GameManager/Card/Type/vermin/Rats.tres",
	"res://GameManager/Card/Type/vermin/Squirrel.tres",
	"res://GameManager/Card/Type/undead/Skeleton(Armored).tres",
	"res://GameManager/Card/Type/undead/Skeleton(Normal).tres",
	"res://GameManager/Card/Type/undead/Zombie.tres",
	"res://GameManager/Card/Type/plants/Mandrake.tres",
	"res://GameManager/Card/Type/plants/Pincher.tres",
	"res://GameManager/Card/Type/plants/Trap.tres",
	"res://GameManager/Card/Type/outsider/Angel.tres",
	"res://GameManager/Card/Type/outsider/Devil.tres",
	"res://GameManager/Card/Type/outsider/Fiend.tres",
	"res://GameManager/Card/Type/monstrosity/Bulette.tres",
	"res://GameManager/Card/Type/monstrosity/Gorgon.tres",
	"res://GameManager/Card/Type/monstrosity/Hydra.tres",
	"res://GameManager/Card/Type/monstrosity/Manticore.tres",
	"res://GameManager/Card/Type/humanoid/Dwarf.tres",
	"res://GameManager/Card/Type/humanoid/Elf(high).tres",
	"res://GameManager/Card/Type/humanoid/Elf(wild).tres",
	"res://GameManager/Card/Type/humanoid/Human.tres",
	"res://GameManager/Card/Type/dragons/BlackDragon.tres",
	"res://GameManager/Card/Type/dragons/BlueDragon.tres",
	"res://GameManager/Card/Type/dragons/GreenDragon.tres",
	"res://GameManager/Card/Type/dragons/RedDragon.tres",
	"res://GameManager/Card/Type/aberrations/Abalith.tres",
	"res://GameManager/Card/Type/aberrations/EyeGaser.tres",
	"res://GameManager/Card/Type/aberrations/Ropper.tres"
]

var offered_cards: Array[CardData] = []
var choice_buttons: Array[Button] = []
var offered_card_paths: Array[String] = []


func _ready() -> void:
	generate_card_choices()


func generate_card_choices() -> void:
	offered_cards.clear()
	offered_card_paths.clear()
	var available_pool: Array[String] = card_pool.duplicate()
	available_pool.shuffle()
	var amount: int = min(3, available_pool.size())
	for i in range(amount):
		var card_path: String = available_pool[i]
		var original_card := load(card_path) as CardData
		if original_card == null:
			continue
		var card_data := original_card.duplicate() as CardData
		card_data.rarity = roll_rarity()
		apply_rarity_bonus(card_data)
		offered_cards.append(card_data)
		offered_card_paths.append(card_path)
	create_choice_buttons()


func roll_rarity() -> CardData.Rarity:
	var roll: float = randf()
	if roll < 0.70:
		return CardData.Rarity.NORMAL
	if roll < 0.95:
		return CardData.Rarity.RARE
	return CardData.Rarity.MYTHIC


func apply_rarity_bonus(card_data: CardData) -> void:
	if card_data == null:
		return
	match card_data.rarity:
		CardData.Rarity.NORMAL:
			pass
		CardData.Rarity.RARE:
			card_data.up = mini(card_data.up + 1, 10)
			card_data.right = mini(card_data.right + 1, 10)
			card_data.down = mini(card_data.down + 1, 10)
			card_data.left = mini(card_data.left + 1, 10)
		CardData.Rarity.MYTHIC:
			card_data.up = mini(card_data.up + 2, 10)
			card_data.right = mini(card_data.right + 2, 10)
			card_data.down = mini(card_data.down + 2, 10)
			card_data.left = mini(card_data.left + 2, 10)
			apply_random_mythic_ability(card_data)


func apply_random_mythic_ability(card_data: CardData) -> void:
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
	card_data.mythic_ability = ability["id"]
	card_data.mythic_description = ability["description"]


func create_choice_buttons() -> void:
	for i in range(offered_cards.size()):
		var card_data: CardData = offered_cards[i]
		var choice_container: VBoxContainer = VBoxContainer.new()
		choice_container.custom_minimum_size = Vector2(220, 380)
		card_choices.add_child(choice_container)
		var card_instance: GameCard = CARD_SCENE.instantiate() as GameCard
		if card_instance == null:
			continue
		card_instance.custom_minimum_size = Vector2(220, 300)
		choice_container.add_child(card_instance)
		card_instance.set_card_data(card_data)
		var choose_button: Button = Button.new()
		choose_button.text = "Choose"
		choose_button.custom_minimum_size = Vector2(220, 50)
		choose_button.pressed.connect(_on_card_chosen.bind(i))
		choice_container.add_child(choose_button)


func _on_card_chosen(index: int) -> void:
	if index < 0:
		return
	if index >= offered_card_paths.size():
		return
	var selected_path: String = offered_card_paths[index]
	var selected_card: CardData = offered_cards[index]
	print("Selected card: ", selected_card.card_name, " | Rarity: ", selected_card.rarity)
	RunManager.add_card_variant(selected_path, selected_card.rarity, selected_card)
	finish_card_room()


func finish_card_room() -> void:
	RunManager.complete_selected_room()
	get_tree().change_scene_to_file("res://GameManager/Map/RunMap.tscn")


func _on_skip_button_pressed() -> void:
	print("Player skipped card reward.")
	finish_card_room()




























#
