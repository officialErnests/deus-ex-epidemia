extends Node2D

#Holds a single card, has a single type
var card_held=null
@export var _type="NONE"
var can_place_card_on=true
var hovered_over=false
@export var location="On Field"
#This is used to determine which slots are a part of players warbrand. 
@export var placeable=false
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$Panel.visible=card_held==null
	if card_held!=null:
		card_held.global_position=global_position
		card_held.holder=self
		card_held.scale=Vector2(0.7,0.7)
		card_held.z_index-=1
		card_held.location=location
	if hovered_over:
		if placeable:
			Game.a_card_is_being_placed_on_a_holder=true
			Game.i_can_turn_off_a_card_is_being_placed_on_a_holder=true
			Game.card_holder_where_a_card_is_placed=self
func _on_area_2d_mouse_entered() -> void:
	hovered_over=true


func _on_area_2d_mouse_exited() -> void:
	hovered_over=false
