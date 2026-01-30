extends Node2D

@onready var camera=$Camera2D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Game.root=self

func get_warbrand():
	var warbrand_cards={}
	var children=$"Shop/Warbrand Slots".get_children()
	for card_holder_id in range(len(children)):
		var card_holder=children[card_holder_id]
		if card_holder.card_held!=null:
			warbrand_cards[card_holder_id]=card_holder.card_held
	return warbrand_cards

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
