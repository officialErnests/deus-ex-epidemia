extends Node2D

@onready var camera=$Camera2D
@onready var shop_slots=$"Shop/Shop Slots".get_children()
@onready var warbrand_slots=$"Shop/Warbrand Slots".get_children()
@onready var drag_to_sell_popup=$Shop/G
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Game.root=self
	if Game.UI["Type"]=="Battle":
		for i in Game.UI["Party Friendly"]:
			$"Shop/Warbrand Slots".get_node(str(i)).card_held=Game.raw_create_card(Game.UI["Party Friendly"][i])
		Game.card_piles["Hand"].card_pile=[]
		for i in Game.UI["Hand Data"]:
			var new_card=Game.raw_create_card(i)
			Game.card_piles["Hand"].card_pile.append(new_card)
			new_card.belongs_to_pile="Hand"
			new_card.changed_card_pile()
	if Game.will_start_new_game:
		Game.start_new_game()
	else:
		Game.new_shop()
	
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
	$Shop/MoneyCounter.text=str(Game.variable["Gold"])+"$"


func _on_refresh_shop_button_down() -> void:
	if Game.variable["Gold"]>=1:
		Game.variable["Gold"]-=1
		Game.refresh_shop()
