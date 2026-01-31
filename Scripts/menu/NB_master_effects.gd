extends Label

@export var shake: float
@export var shake_delay: float

var timer: float = 0

func _process(delta: float) -> void:
    timer += delta

    if (timer > shake_delay):
        timer = 0
        anchor_left = 0.5 + randf_range(-1,1) * shake / 100
        anchor_top = 0.5 + randf_range(-1,1) * shake / 100