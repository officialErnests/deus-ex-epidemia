extends Node2D

#Yup, all it needs to do for now
@export var starting_data=""
func update(text):
	if text is float:
		text=int(text)
	$Label.text=str(text)

func setup(data):
	$Label.position=Vector2(data["Position"]["X"]-60,data["Position"]["Y"])
	$Label.size=Vector2(data["Size"]["X"],data["Size"]["Y"])
	if "Scale" in data:
		$Label.label_settings.font_size=data["Scale"]*8
		$Label.label_settings.outline_size=data["Scale"]*2
		
func _ready() -> void:
	update(starting_data)
