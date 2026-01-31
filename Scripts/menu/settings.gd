extends Button

@export var rooted: CanvasLayer

func _ready() -> void:
	rooted.visible = false
	connect("pressed", pressed)


func pressed() -> void: 
	rooted.visible = false
