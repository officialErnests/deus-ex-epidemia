extends Node2D


# Called when the node enters the scene tree for the first time.
var friendly_team=[]
var enemy_team=[]
var sample_enemy_team={ 4: { "Type": 1.0, "Name": "Psyche", "Description": "Whenever she is attacked, she gains +2 health", "Cost": 3.0, "Attack": 3.0, "Health": 7.0, "Pool": "Greek Heroes", "Effects": [{ "Trigger": "Defending", "Effect List": [{ "Type": "Modify Variable", "Target": "self", "Variable Name": "Health", "Operation": "+", "Value": 2.0 }] }], "Dev Comment": "Gets +2 health whenever she is attacked. ", "Playable": 1.0 } }
func load_teams(friendly,enemy):
	friendly_team=[]
	for iterated_card_id in friendly:
		friendly_team.append(Game.raw_create_card(friendly[iterated_card_id]))
	for iterated_child in $"Warbrand Slots".get_children():
		if int(iterated_child.name)<=len(friendly_team):
			iterated_child.card_held=friendly_team[int(iterated_child.name)-1]
			friendly_team[int(iterated_child.name)-1].holder=iterated_child
	enemy_team=[]
	for iterated_card_id in enemy:
		enemy_team.append(Game.raw_create_card(enemy[iterated_card_id]))
	for iterated_child in $"Enemy Slots".get_children():
		if int(iterated_child.name)<=len(enemy_team):
			iterated_child.card_held=enemy_team[int(iterated_child.name)-1]
			enemy_team[int(iterated_child.name)-1].holder=iterated_child
func _ready() -> void:
	pass # Replace with function body.
	Game.battle=self
	load_teams(Game.UI["Party Friendly"],sample_enemy_team)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
