extends Button

@export var to_scene: PackedScene
@export var exit: bool

func _ready() -> void:
    connect("pressed", buttonPressed)

func buttonPressed():
    if exit:
        get_tree().quit()
        return
    get_tree().change_scene_to_packed(to_scene)