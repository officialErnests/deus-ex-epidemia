extends Node

var root=null
var battle=null

var existing_cards=[]
var effect_stack=[]
var card_index={}
var card_types={}
var card_piles={}

@onready var card_scene=preload("res://Cards/card.tscn")
#Debug functions:

var log_index=0
#Cool Hacker Log
func chl(message,is_shown=false):
	if is_shown:
		print("<A-"+str(log_index)+"> "+str(message))
	log_index+=1
	
#File reading and writing functions:
#Returns all files in a folder, including subfolder contents. 
func Rsearch(path): 
	var dir = DirAccess.open(path)
	var files=[]
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				chl("R-SEARCH DEBUG: ("+path+") - Found Directory: "+file_name+", loading contents",debug_c.R_SEARCH_RESULTS)
				files=files+Rsearch(path+"/"+file_name)
			else:
				chl("R-SEARCH DEBUG: ("+path+") - Found File: "+file_name,debug_c.R_SEARCH_RESULTS)
				files.append(path+"/"+file_name)
			file_name = dir.get_next()
	else:
		chl("Error Loading Rsearch Contents",1)
	return files
	
#Loads all the cards within Cards/Cardlib, and puts them into the card_index dict, with their name as the key
func load_card_index():
	var file_list=Rsearch("Cards/Cardlib")
	for i in file_list:
		var json=JSON.parse_string(FileAccess.get_file_as_string(i))
		card_index[json["Name"]]=json
	chl("Loaded "+str(file_list.size())+" Cards",1)
	
#Loads all the card types within Cards/CardTypes, and just stacks them in a list
func load_card_types():
	var file_list=Rsearch("Cards/CardTypes")
	for i in file_list:
		var json=JSON.parse_string(FileAccess.get_file_as_string(i))
		card_types[json["ID"]]=json
	chl("Loaded "+str(file_list.size())+" Card Types",1)

#Mainloop functions:
var GlobalVariables={}
var selected_card=null
var selected_card_nullify_trig=false

var process_on_hold=false
#Main function that processes the next action in the stack, before deleting it. 
func process_stack():
	if process_on_hold:
		return
	var processed_effect=effect_stack[0]
	chl("Processing Effect: "+str(processed_effect),debug_c.PROCESS_STACK)
	#print(existing_cards)
	#Effects that affect cards
	if processed_effect["Type"]=="Target": #The game begins the sequence where a card is being targeted. 
		#If no card can be targeted, game skips this and all further effects
		#This also means that we need to process effects recursively, and as a stack and a queue, not one or the other 
		var targeted_cards=filter_cards()
		if "Target Filter" in processed_effect:
			targeted_cards=filter_cards(processed_effect["Target Filter"])
		process_on_hold=true
		UI={
			"Type":"Targeting",
			"Targeted Card":null,
			"Possible Targets":targeted_cards,
			"Assigning To Variable":"#"+processed_effect["Assign Variable"],
			"Focusing On Card":processed_effect["Card Parent"],
			"Animation Time":0,
			"Max Animation Time":0.3/debug_c.GAME_SPEED,
			#Starts at scale of 1, ends on scale of 4
			"Start Position":processed_effect["Card Parent"].global_position,
			#ends on the right side at the right scale
		}
	if processed_effect["Type"]=="Move Card To":
		var affected_cards=processed_effect["Card Parent"]
		if processed_effect["Card"]=="$self":
			affected_cards=processed_effect["Card Parent"]
		affected_cards=ilina(affected_cards)
		for affected_card in affected_cards:
			affected_card.belongs_to_pile=processed_effect["Card Pile ID"]
			card_piles[processed_effect["Card Pile ID"]].card_pile.append(affected_card)
			affected_card.changed_card_pile()
	if processed_effect["Type"]=="Modify Variable":
		var affected_cards=[]
		
		if processed_effect["Target"][0]=="#": #Trying to access a global variable
			affected_cards=ilina(GlobalVariables[processed_effect["Target"]])
		if processed_effect["Target"]=="self": #Trying to access a local variable
			affected_cards=ilina(processed_effect["Card Parent"])
		for affected_card in affected_cards:
			if not processed_effect["Variable Name"] in affected_card.variable:
				affected_card.variable[processed_effect["Variable Name"]]=0
		
			if processed_effect["Operation"]=="+":
				affected_card.variable[processed_effect["Variable Name"]]+=get_value(processed_effect["Value"])
			affected_card.update_visually()
	
	#Game based effects
	if processed_effect["Type"]=="Begin Battle Phase":
		
		UI={
			"Type":"Battle",
			"Action":{
				"Type":"Wait",
				"Time Left":2, #counted in seconds	
			},
			"Team":randi_range(0,1),
			"Friendly Index":-1,
			"Enemy Index":-1,
			"Queued Actions":[],
			"Party Friendly":deload_party_data()
		}
		#print(existing_cards)
		for card in existing_cards:
			card.queue_free()
		existing_cards.clear()
		print(UI["Party Friendly"])
		get_tree().change_scene_to_file("res://Battle.tscn")
	effect_stack.pop_at(0)
func ilina(x): #In List If Not Already: Places the item into a list if it isn't in one already
	if x is Array:
		return x
	return [x]
func get_target(target,activator=null):
	if target=="$self":
		return activator
func get_value(x):
	if x is int:
		return x
	if x is float:
		return x
func filter_cards(filter_data={}):
	var all_cards=existing_cards.duplicate()
	var removed_cards=[]
	if "Location" in filter_data:
		for i in all_cards:
			if i.location!=filter_data["Location"]:
				removed_cards.append(i)
	for i in removed_cards:
		if i in all_cards:
			all_cards.erase(i)
	return all_cards

func create_new_card(card_name,is_in_index=true):
	var new_card=card_scene.instantiate()
	add_child(new_card)
	if is_in_index:
		new_card.setup(card_index[card_name])
	new_card.global_position=Vector2(400,200)
	existing_cards.append(new_card)
	return new_card
func raw_create_card(card_data):
	var new_card=card_scene.instantiate()
	add_child(new_card)
	new_card.setup(card_data)
	existing_cards.append(new_card)
	return new_card
@onready var card_pile=preload("res://Cards/pile.tscn")
func create_new_card_pile(card_pile_id):
	var new_card_pile=card_pile.instantiate()
	card_piles[card_pile_id]=new_card_pile
	new_card_pile.name=card_pile_id
func draw_from_pile_to_pile(from_pile,to_pile):
	var drawn_card=card_piles[from_pile].card_pile[0]
	drawn_card.belongs_to_pile=to_pile
	card_piles[from_pile].card_pile.pop_front()
	card_piles[to_pile].card_pile.append(drawn_card)
	drawn_card.changed_card_pile()
	

func _ready():
	load_card_types()
	load_card_index()
var smallest_distance_to_mouse=-1
var csd_card=null
var closest_card=null
var frame=0
var hand_is_hovered_over=false
var card_in_hand_selected=0
var card_in_hand_selected_delta=0
var i_can_turn_off_hand_is_hovered_over=false

var a_card_is_being_placed_on_a_holder=false
var i_can_turn_off_a_card_is_being_placed_on_a_holder=false

var UI={
	"Type":"Shop"
} #used to declare whether or not a card is being targeted, etc
func finish_targeting():
	GlobalVariables[UI["Assigning To Variable"]]=UI["Targeted Card"]
	UI["Focusing On Card"].scale=Vector2(1.,1.)
	process_on_hold=false
	resetUI()
func resetUI():
	UI={
	"Type":"Shop"
}
func deload_party_data():
	var card_data={}
	var warbrand=root.get_warbrand()
	for card_index in warbrand:
		var deloaded_card=warbrand[card_index].deload_card()
		card_data[card_index+1]=deloaded_card
	return card_data
var card_holder_where_a_card_is_placed=null
func _process(delta: float) -> void:
	if not i_can_turn_off_a_card_is_being_placed_on_a_holder:
		a_card_is_being_placed_on_a_holder=false
	i_can_turn_off_a_card_is_being_placed_on_a_holder=false
	if hand_is_hovered_over==false:
		card_in_hand_selected_delta=0
	if not i_can_turn_off_hand_is_hovered_over:
		hand_is_hovered_over=false
	i_can_turn_off_hand_is_hovered_over=false
	frame+=1
	if frame==1:
		var card_deck=[]
		card_deck.append("Banana")
		for i in range(4):
			card_deck.append(["Hercules","Perseus","Psyche"][randi_range(0,2)])
		card_piles["Deck"].load_cards(card_deck)
		for i in range(5):
			draw_from_pile_to_pile("Deck","Hand")
	if len(effect_stack)>0: #Does one effect per frame, 
		process_stack()
	if smallest_distance_to_mouse>=0:
		closest_card=csd_card
	smallest_distance_to_mouse=INF
	if selected_card_nullify_trig:
		selected_card_nullify_trig=false
		selected_card=null
	if UI["Type"]=="Targeting":
		UI["Animation Time"]+=delta
		UI["Animation Q"]=ease(UI["Animation Time"]/UI["Max Animation Time"],-2.0)
		UI["Focusing On Card"].scale=Vector2(1+1.5*UI["Animation Q"],1+1.5*UI["Animation Q"])
		UI["Focusing On Card"].position=(1-UI["Animation Q"])*UI["Start Position"]+UI["Animation Q"]*Vector2(937,322)
	if UI["Type"]=="Battle":
		if UI["Action"]["Type"]=="Wait":
			UI["Action"]["Time Left"]-=delta
			if UI["Action"]["Time Left"]<0:
				var Ui=UI["Action"]
				var defenders=[]
				var attacker=null
				if UI["Team"]==0:
					var attackers=battle.friendly_team
					defenders=battle.enemy_team
					for i in range(7):
						UI["Friendly Index"]+=1
						if UI["Friendly Index"]>=len(attackers):
							UI["Friendly Index"]=0
						if attackers[UI["Friendly Index"]].variable["Attack"]>0:
							attacker=attackers[UI["Friendly Index"]]
				else:
					var attackers=battle.enemy_team
					defenders=battle.friendly_team
					for i in range(7):
						UI["Enemy Index"]+=1
						if UI["Enemy Index"]>=len(attackers):
							UI["Enemy Index"]=0
						if attackers[UI["Enemy Index"]].variable["Attack"]>0:
							attacker=attackers[UI["Enemy Index"]]
				var possible_defenders=[]
				var max_taunt=0
				for iter_defender in defenders:
					var taunt_level=0
					if "Taunt" in iter_defender.variable:
						if iter_defender.variable["Taunt"]>max_taunt:
							max_taunt=iter_defender.variable["Taunt"]
							possible_defenders=[]
						taunt_level=iter_defender.variable["Taunt"]
					if taunt_level==max_taunt:
						possible_defenders.append(iter_defender)
				var defender=possible_defenders.pick_random()
				UI["Team"]=1-UI["Team"]
				UI["Action"]={
					"Type":"Attack",
					"Time":0,
					"Attacker":attacker,
					"Defender":defender,
					"Alpha Pos":attacker.holder.global_position,
					"Beta Pos":defender.holder.global_position,
				}
		elif UI["Action"]["Type"]=="Attack":
			var Ui=UI["Action"]
			Ui["Time"]+=delta
			#So, we have 4 stages in the attack stage, which will be reduced to three, after which the waiting is called again.
			if Ui["Time"]>0.25 and Ui["Time"]<0.5:
				var movement_q=(Ui["Time"]-0.25)/0.25
				movement_q=pow(movement_q,2)
				Ui["Attacker"].holder.global_position=Ui["Alpha Pos"]*(1-movement_q)+Ui["Beta Pos"]*movement_q
				#print(Ui["Attacker"].global_position)
			elif 0.5<Ui["Time"] and Ui["Time"]<0.75:
				var movement_q=(Ui["Time"]-0.5)/0.25
				movement_q=pow(movement_q,0.5)
				Ui["Attacker"].holder.global_position=Ui["Alpha Pos"]*(movement_q)+Ui["Beta Pos"]*(1-movement_q)
			elif Ui["Time"]>0.75:
				UI["Action"]={
					"Type":"Wait",
					"Time Left":0.25
				}
