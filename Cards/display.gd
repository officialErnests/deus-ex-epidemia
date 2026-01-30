extends Node2D

#Yup, all it needs to do for now
func update(text):
	if text is float:
		text=int(text)
	$Label.text=str(text)

func setup(data):
	$Label.position=Vector2(data["Position"]["X"]-60,data["Position"]["Y"])
	$Label.size=Vector2(data["Size"]["X"],data["Size"]["Y"])
