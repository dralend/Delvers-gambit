extends Node

const PAUSE_MENU_SCENE: PackedScene = preload("res://menus/PauseMenu.tscn")

var pause_menu: Control = null


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().scene_changed.connect(_on_scene_changed)
    call_deferred("_on_scene_changed")


func _on_scene_changed() -> void:
    var scene := get_tree().current_scene
    if scene == null:
        return

    if _scene_allows_pause(scene):
        _ensure_pause_menu(scene)
    else:
        _remove_pause_menu()


func _scene_allows_pause(scene: Node) -> bool:
    var path: String = scene.scene_file_path

    if path == "res://menus/MainMenu.tscn":
        return false
    if path == "res://menus/GameOver.tscn":
        return false

    return path.begins_with("res://GameManager/")


func _ensure_pause_menu(scene: Node) -> void:
    var existing := scene.get_node_or_null("PauseMenu") as Control
    if existing != null:
        pause_menu = existing
        pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
        return

    pause_menu = PAUSE_MENU_SCENE.instantiate() as Control
    if pause_menu == null:
        return

    pause_menu.name = "PauseMenu"
    pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
    scene.add_child(pause_menu)


func _remove_pause_menu() -> void:
    if is_instance_valid(pause_menu):
        pause_menu.queue_free()
    pause_menu = null
