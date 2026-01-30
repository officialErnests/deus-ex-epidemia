extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_enter_battle_button_button_down() -> void:
	Game.effect_stack.append({
		"Type":"Begin Battle Phase"
	})
