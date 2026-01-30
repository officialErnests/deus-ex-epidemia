extends Node2D

var card_pile=[]
@export var location=name
#var _name=""
func load_cards(card_list,shuffle_after=true):
	for iter_card in card_list:
		card_pile.append(Game.create_new_card(iter_card))
	for iter_card in card_pile:
		iter_card.belongs_to_pile=name
		iter_card.global_position=global_position
		iter_card.location=location
	if shuffle_after:
		shuffle()
func shuffle():
	card_pile.shuffle()
func _ready():
	Game.card_piles[name]=self
	#print(Game.card_piles)
