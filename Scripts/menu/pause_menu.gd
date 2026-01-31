extends CanvasLayer

@export var continue_button: Button

func _ready() -> void:
	visible = false
	continue_button.connect("pressed", settingsToggle)

func _input(_event: InputEvent) -> void:
	if (Input.is_action_just_pressed("Pause")):
		settingsToggle()

func settingsToggle() -> void:
	visible = !visible
