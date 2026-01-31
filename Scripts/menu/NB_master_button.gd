extends Button

@export var to_scene: PackedScene
@export var exit: bool
@export var main_menu: bool
@export var root: bool = false
@export var settings: bool = false
func _ready() -> void:
	connect("pressed", buttonPressed)

func buttonPressed():
	Game.fuck_this_shit()
	if exit:
		get_tree().quit()
		return
	if main_menu:
		get_tree().change_scene_to_file("res://Scenes/menus/main_menu.tscn")
		return
	if settings:
		get_node("Settings").visible = true
		return
	get_tree().change_scene_to_packed(to_scene)
	if root:
		Game.will_start_new_game=true
	
