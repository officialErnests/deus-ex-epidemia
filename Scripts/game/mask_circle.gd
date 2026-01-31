extends Control

@export var masks: Dictionary[String, CompressedTexture2D]
@export var gray: ShaderMaterial
@export_category("desc_boxes")
@export var desc_container : Control
@export var desc_title : Label
@export var desc_text : RichTextLabel

var loaded_masks: Array[TextureButton] = []
var aquired_masks = []
var locked_masks = []
var locked_masks_textures = []
var mul_number = 0
var time = 0
var time_till_swtich = 0.25
var atributes

func _ready() -> void:
	desc_container.visible = false
	aquired_masks = save_manager.getUnlocked()
	for mask_name in masks.keys():
		if (aquired_masks.keys().has(mask_name)):
			var mask = masks[mask_name]
			if (aquired_masks[mask_name]):
				var temp_mask = TextureButton.new()
				temp_mask.texture_normal = mask
				temp_mask.ignore_texture_size = true
				temp_mask.stretch_mode = TextureButton.STRETCH_SCALE
				temp_mask.size = Vector2.ONE * 100
				add_child(temp_mask)
				loaded_masks.append(temp_mask)
				temp_mask.connect("pressed", clicked.bind(mask_name))
			else:
				var temp_mask = TextureButton.new()
				temp_mask.texture_normal = mask
				temp_mask.ignore_texture_size = true
				temp_mask.stretch_mode = TextureButton.STRETCH_SCALE
				temp_mask.size = Vector2.ONE * 100
				loaded_masks.append(temp_mask)
				add_child(temp_mask)
				locked_masks.append(temp_mask)
				locked_masks_textures.append(mask)
				temp_mask.material = gray
		else:
			print("Warn - mask not found!")
	mul_number = PI * 2 / loaded_masks.size()
	updatePositions()

func clicked(p_name) -> void:
	global_position.x = 300
	atributes = modifiers.setCurrent(p_name)
	desc_container.visible = true
	desc_title.text = p_name
	desc_text.text = atributes["desc"]


func _process(delta: float) -> void:
	time += delta
	updatePositions()
	time_till_swtich -= delta
	if (time_till_swtich < 0):
		time_till_swtich = 0.25
		swithcMask()

func swithcMask() -> void:
	for i in locked_masks:
		i.texture_normal = locked_masks_textures.pick_random()

func updatePositions() -> void:
	for mask_index in range(loaded_masks.size()):
		var mask = loaded_masks[mask_index]
		mask.global_position = global_position + getPosition(mask_index) * 180 - Vector2.ONE * 90 + Vector2(sin(time * 0.1) * 100, 0)

func getPosition(p_id) -> Vector2:
	var result = Vector2(sin(p_id * mul_number - time * 0.1), cos(p_id * mul_number - time * 0.1))
	return result
