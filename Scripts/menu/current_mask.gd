extends Sprite2D

@export var masks: Dictionary[String, CompressedTexture2D]

func _ready() -> void:
	if masks.keys().has(modifiers.getCurentMask()):
		texture = masks[modifiers.getCurentMask()]
	else:
		print("WARNING, no mask found with name " + modifiers.getCurentMask())
