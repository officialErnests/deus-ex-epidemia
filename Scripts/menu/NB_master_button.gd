extends Button

@export var to_scene: PackedScene
@export var exit: bool
@export var main_menu: bool

func _ready() -> void:
    connect("pressed", buttonPressed)

func buttonPressed():
    if exit:
        get_tree().quit()
        return
    if main_menu:
        get_tree().change_scene_to_file("res://Scenes/menus/main_menu.tscn")
        return
    get_tree().change_scene_to_packed(to_scene)