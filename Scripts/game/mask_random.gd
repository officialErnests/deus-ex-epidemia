extends Sprite2D

@export var masks: Array[CompressedTexture2D]

func _ready() -> void:
    texture = masks.pick_random()