extends Control

@export var img_size: int = 100
@export var masks: Array[CompressedTexture2D]
@export var offset_speed : float = 1
var mask: TextureRect
var time: float = 0
var center: Vector2
var half_size: Vector2
var prev_time: float = 0

func _ready() -> void:
	mask = TextureRect.new()
	mask.texture = masks.pick_random()
	mask.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	mask.size = Vector2.ONE * img_size
	add_child(mask)
	
	half_size = size / 2.0
	center = global_position

func _process(delta: float) -> void:
	time += delta
	if (center == Vector2.ZERO): center = global_position 
	mask.global_position = center + Vector2(sin(time * 1 * offset_speed) * 30, cos(time * 0.9) * 50) + Vector2(-50, 100)
	# mask.global_position = center + Vector2(sin(time * 0.5) * half_size.x, cos(time * 0.5) * half_size.y) * 1000
	if (prev_time < time):
		prev_time += randf_range(0.5,1)
		mask.texture = masks.pick_random()
	
