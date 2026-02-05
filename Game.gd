extends Node

var root=null
var battle=null

var existing_cards=[]
var effect_stack=[]
var card_index={}
var card_types={}
var card_piles={}
var card_pools={}
var default_variable={
	"Max Gold":2,
	"Max Gold Gain Left":8,
	"Gold":0,
	"Candles":3,
	"Shop Card Count":3, #change to 3 later
	"Floor":-1,
}
var attack_stack=[] #An array of all the cards that should attack right after this one

var variable=default_variable.duplicate()
var shop_card_pool=[]
var shop_pools=[]
@onready var card_scene=preload("res://Cards/card.tscn")

var global_card = null #(usually is a card, that you can save and load global variables from, and interact with in cards. )

@onready var card_lib=preload("res://Cards/card_library.json")
@onready var card_types_lib=preload("res://Cards/card_types.json")
@onready var battle_pools_json=preload("res://Save Data/Player Runs/alpha.json")
#Debug functions:

var battle_pools=[]
#Array of arrays of arrays of card_data

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
	#var file_list=Rsearch("Cards/Cardlib")
	var json=JSON.parse_string(FileAccess.get_file_as_string("res://Cards/card_library.json"))
	#for i in file_list:
	#	var json=JSON.parse_string(FileAccess.get_file_as_string(i))
	#		card_index[json["Name"]]=json
	#	if not json["Pool"] in card_pools:
#			card_pools[json["Pool"]]=[]
#		card_pools[json["Pool"]].append(json["Name"])
#	chl("Loaded "+str(file_list.size())+" Cards",1)
	for iter_card_id in json:
		var card_data=json[iter_card_id]
		card_index[card_data["Name"]]=card_data
		if not card_data["Pool"] in card_pools:
			card_pools[card_data["Pool"]]=[]
		card_pools[card_data["Pool"]].append(card_data["Name"])
	chl("Loaded "+str(len(json))+" Cards",1)
#Loads all the card types within Cards/CardTypes, and just stacks them in a list
func load_card_types():
	#var file_list=Rsearch("Cards/CardTypes")
	var json=JSON.parse_string(FileAccess.get_file_as_string("res://Cards/card_types.json"))
	for iter_card_id in json:
		var card_type_data=json[iter_card_id]
		card_types[card_type_data["ID"]]=card_type_data
	#for i in file_list:
	#	var json=JSON.parse_string(FileAccess.get_file_as_string(i))
	#	card_types[json["ID"]]=json
	chl("Loaded "+str(len(json))+" Card Types",1)

var tsd=0
func load_battle_pools():
	var save_location="res://Save Data/Player Runs/alpha.json"
	if tsd==0:
		tsd=1
	else:
		save_location="res://Save Data/Player Runs/alpha.json"
		
	#var default_location="res://Save Data/Default/enemy_list.json"
	battle_pools=JSON.parse_string(FileAccess.get_file_as_string(save_location))["Battles"]
	#var default_battle_data=JSON.parse_string(FileAccess.get_file_as_string(default_location))["Battles"]
	for floor_pool in battle_pools:
		for individual_battle in floor_pool:
			var new_battle={}
			for individual_fighter in individual_battle:
				new_battle[int(individual_fighter)]=individual_battle[individual_fighter]
func auto_save_battles():
	var saveable_data=JSON.stringify({"Battles":battle_pools},"\t")
	var file = FileAccess.open("res://Save Data/Player Runs/alpha.json", FileAccess.WRITE)
	if file:
		file.store_string(saveable_data)
		file.close()
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
	if "Card Parent" in processed_effect:
		global_card.variable["@Parent"]=processed_effect["Card Parent"]
	#print(existing_cards)
	#Effects that affect cards
	if processed_effect["Type"]=="Target": #The game begins the sequence where a card is being targeted. 
		#If no card can be targeted, game skips this and all further effects
		#This also means that we need to process effects recursively, and as a stack and a queue, not one or the other 
		var targeted_cards=filter_cards()
		if "Target Filter" in processed_effect:
			targeted_cards=filter_cards(processed_effect["Target Filter"])
		if len(targeted_cards)>0:
			process_on_hold=true
			UI={
				"Type":"Targeting",
				"Targeted Card":null,
				"Possible Targets":targeted_cards,
				"Assigning To Variable":processed_effect["Assign Variable"],
				"Focusing On Card":processed_effect["Card Parent"],
				"Animation Time":0,
				"Global":"Global" in processed_effect,
				"Max Animation Time":0.3/debug_c.GAME_SPEED,
				#Starts at scale of 1, ends on scale of 4
				"Start Position":processed_effect["Card Parent"].global_position,
				#ends on the right side at the right scale
			}
		else:
			chl("Target Effect Failed, 0 targettable creatures")
			negate_effect(processed_effect["Trigger Key"])
	elif processed_effect["Type"]=="Move Card To":
		var affected_cards=processed_effect["Card Parent"]
		if processed_effect["Card"]=="$self":
			affected_cards=processed_effect["Card Parent"]
		affected_cards=ilina(affected_cards)
		for affected_card in affected_cards:
			affected_card.belongs_to_pile=processed_effect["Card Pile ID"]
			card_piles[processed_effect["Card Pile ID"]].card_pile.append(affected_card)
			affected_card.changed_card_pile()
	elif processed_effect["Type"]=="Modify Variable":
		var affected_cards=ilina(get_target(processed_effect["Target"]))
		for affected_card in affected_cards:
			if not processed_effect["Variable Name"] in affected_card.variable:
				affected_card.variable[processed_effect["Variable Name"]]=0
		
			if processed_effect["Operation"]=="+":
				affected_card.variable[processed_effect["Variable Name"]]+=get_value(processed_effect["Value"])
			if processed_effect["Operation"]=="-":
				affected_card.variable[processed_effect["Variable Name"]]-=get_value(processed_effect["Value"])
			if processed_effect["Operation"]=="*":
				affected_card.variable[processed_effect["Variable Name"]]*=get_value(processed_effect["Value"])
			if processed_effect["Operation"]=="/":
				affected_card.variable[processed_effect["Variable Name"]]/=get_value(processed_effect["Value"])
			if processed_effect["Operation"]=="=":
				affected_card.variable[processed_effect["Variable Name"]]=get_value(processed_effect["Value"])
			
			affected_card.update_visually()
	
	#Game based effects
	elif processed_effect["Type"]=="Begin Battle Phase":
		
		UI={
			"Type":"Battle",
			"Action":{
				"Type":"Wait",
				"Time Left":2, #counted in seconds	
			},
			"Team":randi_range(0,1),
			"Friendly Index":-1,
			"Enemy Index":-1,
			"Party Friendly":deload_party_data(),
			"Hand Data":deload_hand_data()
		}
		#print(existing_cards)
		for card in existing_cards:
			card.queue_free()
		existing_cards.clear()
		#print(UI["Party Friendly"])
		get_tree().change_scene_to_file("res://Battle.tscn")
	elif processed_effect["Type"]=="Summon Creature":
		
		if UI["Type"]=="Battle":
			var new_card=raw_create_card(processed_effect["Creature Data"])
			var selected_place=[]
			var _team=[]
			if processed_effect["Card Parent"].team==0:
				selected_place=battle.warbrand_slots
				_team=battle.friendly_team
			else:
				selected_place=battle.enemy_slots
				_team=battle.enemy_team
			var start_pos=-1
			for i in range(7):
				if processed_effect["Card Parent"]==selected_place[i].card_held:
					start_pos=i
			
			if start_pos==-1:
				negate_effect(processed_effect["Trigger Key"])
				return
			
			var placed=false
			for i in range(7):
				if selected_place[(start_pos+i)%7].card_held==null:
					selected_place[(start_pos+i)%7].card_held=new_card
					new_card.holder=selected_place[(start_pos+i)%7]
					_team.append(new_card)
					new_card.team=processed_effect["Card Parent"].team
					print("placed at: ",i)
					placed=true
					break
			if not placed:
				chl("Card Not Summoned")
				remove_card(new_card)
			else:
				global_card.variable["@Created"]=new_card
		elif UI["Type"]=="Shop":
			var start_pos=0
			for i in range(len(root.warbrand_slots)):
				if root.warbrand_slots[i].card_held==processed_effect["Card Parent"]:
					start_pos=i
			
			
			for i in range(7):
				if root.warbrand_slots[(start_pos+i)%7].card_held==null:
					var new_card=raw_create_card(processed_effect["Creature Data"])
					root.warbrand_slots[(start_pos+i)%7].card_held=new_card
					new_card.holder=root.warbrand_slots[(start_pos+i)%7]
					
					break
			#for iter_child in root.warbrand_slots:
	elif processed_effect["Type"]=="Destroy Card":
		for iter_card in ilina(get_target(processed_effect["Card"])):
			remove_card(get_value(iter_card))
	elif processed_effect["Type"]=="Variable From":
		var target=get_value(processed_effect["Target"])
		save_at(processed_effect["Name"],target.variable[processed_effect["Variable"]])
	elif processed_effect["Type"]=="Get Neighbours":
		var neighbours=[]
		if UI["Type"]=="Battle":
			#var team=-1
			var t=false
			var last_minion=null
			for i in battle.warbrand_slots:
				i=i.card_held
				if len(neighbours)>0:
					neighbours.append(i)
					break
				if get_target(processed_effect["Target"])==i:
					if last_minion!=null:
						neighbours.append(last_minion)
					t=true
				last_minion=i
			if not t:
				for i in battle.enemy_slots:
					i=i.card_held
					if len(neighbours)>0:
						neighbours.append(i)
						break
					if get_target(processed_effect["Target"])==i:
						if last_minion!=null:
							neighbours.append(last_minion)
					last_minion=i
		if UI["Type"]=="Shop":
			var last_minion=null
			for i in root.warbrand_slots:
				i=i.card_held
				if len(neighbours)>0:
					neighbours.append(i)
					break
				if get_target(processed_effect["Target"])==i:
					neighbours.append(last_minion)
				last_minion=i
		save_at(processed_effect["Variable Name"],neighbours)
	elif processed_effect["Type"]=="Deal Damage":
		for iter_card in ilina(get_target(processed_effect["Target"])):
			if is_instance_valid(iter_card):
				iter_card.take_damage(get_value(processed_effect["Value"]))
	elif processed_effect["Type"]=="If":
		var condition_success=false
		if processed_effect["Condition"]=="Value Comparison":
			if processed_effect["Comparison"]==">=":
				if get_value(processed_effect["Value 1"])>=get_value(processed_effect["Value 2"]):
					condition_success=true
			if processed_effect["Comparison"]=="<=":
				if get_value(processed_effect["Value 1"])<=get_value(processed_effect["Value 2"]):
					condition_success=true
			if processed_effect["Comparison"]=="==":
				if get_value(processed_effect["Value 1"])==get_value(processed_effect["Value 2"]):
					condition_success=true
			if processed_effect["Comparison"]==">":
				if get_value(processed_effect["Value 1"])>get_value(processed_effect["Value 2"]):
					condition_success=true
			if processed_effect["Comparison"]=="<":
				if get_value(processed_effect["Value 1"])<get_value(processed_effect["Value 2"]):
					condition_success=true
		if condition_success:
			processed_effect["Card Parent"].trigger(processed_effect["Trigger"])
	elif processed_effect["Type"]=="Force Attack":
		attack_stack.append(get_target(processed_effect["Target"]))
		print(attack_stack)
	else:
		chl("Unknown Effect: "+processed_effect,debug_c.BUG_REPORT)
	effect_stack.pop_at(0)
func negate_effect(effect_key):
	chl("Negating Effect With Key: ",effect_key)
	for effect in effect_stack:
		if effect["Trigger Key"]==effect_key:
			effect_stack.erase(effect)
func ilina(x): #In List If Not Already: Places the item into a list if it isn't in one already
	if x is Array:
		return x
	return [x]
func get_target(target,activator=null):
	if target is Dictionary:
		return filter_cards(target)
	if target=="$self":
		return activator
	if target=="self":
		return global_card.variable["@Parent"]
	if target[0]=="@":
		return global_card.variable[target]
	if target=="global":
		return global_card
	return global_card.variable["@Parent"].variable[target]
func get_value(x):
	if x is int:
		return x
	if x is float:
		return x
	if x is String:
		if x[0]=="!":
			return global_card.variable["@Parent"].variable[x.substr(1)]
		if x[0]=="#":
			return global_card.variable[x.substr(1)]
		if x[0]=="@":
			return global_card.variable[x]
func save_at(x,y):
	if x is String:
		if x[0]=="#":
			global_card.variable[x]=y
			return	
		
		global_card.variable["@Parent"].variable[x]=y
func filter_cards(filter_data={}):
	var all_cards=existing_cards.duplicate()
	var removed_cards=[]
	if "Location" in filter_data:
		for i in all_cards:
			if i.location!=filter_data["Location"]:
				removed_cards.append(i)
	if "Tribe" in filter_data:
		for i in all_cards:
			if i.variable["Tribe"]!=filter_data["Tribe"]:
				removed_cards.append(i)
	if "Name" in filter_data:
		for i in all_cards:
			if i.variable["Name"]!=filter_data["Name"]:
				removed_cards.append(i)
	if "Team" in filter_data:
		if filter_data["Team"]=="Friendly":
			for i in all_cards:
				if i.team!=global_card.variable["@Parent"].team:
					removed_cards.append(i)
		else: #Enemy
			for i in all_cards:
				if i.team==global_card.variable["@Parent"].team:
					removed_cards.append(i)
	for i in removed_cards:
		if i in all_cards:
			all_cards.erase(i)
	if "Count" in filter_data:
		all_cards.shuffle()
		all_cards=all_cards.slice(0,filter_data["Count"])
	return all_cards

func create_new_card(card_name,is_in_index=true):
	var new_card=card_scene.instantiate()
	add_child(new_card)
	#if is_in_index:
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
func remove_card(card):
	if card.holder!=null:
		card.holder.card_held=null
	if card.belongs_to_pile!=null:
		card_piles[card.belongs_to_pile].card_pile.erase(card)
	existing_cards.erase(card)
	card.queue_free()
func shop_add_pool(pool_name):
	if not pool_name in shop_pools:
		shop_pools.append(pool_name)
		for i in card_pools[pool_name]:
			if not i in shop_card_pool:
				shop_card_pool.append(i)
func new_shop():
	if global_card.variable["Max Gold Gain Left"]>0:
		global_card.variable["Max Gold Gain Left"]-=1
		global_card.variable["Max Gold"]+=1
	
	global_card.variable["Gold"]=int(global_card.variable["Max Gold"])
	global_card.variable["Gold"]+=int(global_card.variable["Extra Gold"])
	global_card.variable["Extra Gold"]=0
	global_card.variable["Floor"]+=1
	if global_card.variable["Floor"]==len(battle_pools):
		print("GG, game won")
		fuck_this_shit()
		get_tree().change_scene_to_file("res://Scenes/menus/victory_screen.tscn")
		return
	resetUI()
	refresh_shop()
	if modifiers.current_mask=="fox":
		var new_card=create_new_card("Claws of a Fox")
		card_piles["Hand"].card_pile.append(new_card)
		new_card.belongs_to_pile="Hand"
		new_card.changed_card_pile()
func fuck_this_shit():
	UI={
		"Type":"Fucked",
		"Where?":"IN THE ASS",
		"Action":"Nuh-uh, your mom."
	}
	for card in existing_cards.duplicate():
		remove_card(card)
var will_start_new_game=false
var selected_mask=null
func start_new_game():
	if global_card!=null:
		remove_card(global_card)
	global_card=create_new_card("Global Variable Storer")
	existing_cards.erase(global_card)
	#global_card.variable["Max Gold"]+=10
	global_card.global_position=Vector2(-100000,-100000)
	#variable=default_variable.duplicate()
	process_on_hold=false
	effect_stack=[]
	resetUI()
	
	shop_card_pool=[]
	shop_pools=[]
	shop_add_pool("I")
	mask_setup()
	shop_add_pool("II")
	shop_add_pool("III")
	new_shop()
	will_start_new_game=false
func mask_setup():
	if modifiers.current_mask=="beetle":
		var new_card=create_new_card("Beetle Scales")
		card_piles["Hand"].card_pile.append(new_card)
		new_card.belongs_to_pile="Hand"
		new_card.changed_card_pile()
	if modifiers.current_mask=="whale":
		global_card.variable["Candles"]+=1
	if modifiers.current_mask=="dragon":
		global_card.variable["Max Gold"]+=1
		global_card.variable["Shop Card Count"]+=1
		global_card.variable["Candles"]-=1
	if modifiers.current_mask=="rabbit":
		global_card.variable["Shop Card Count"]+=1
	if modifiers.current_mask=="eagle":
		global_card.variable["Max Gold"]+=1
func _ready():
	load_card_types()
	load_card_index()
	shop_add_pool("I")
	
	
	#shop_add_pool("Food I")
	load_battle_pools()
	
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
	if UI["Global"]:
		global_card.variable[UI["Assigning To Variable"]]=UI["Targeted Card"]
	else:
		UI["Focusing On Card"].variable[UI["Assigning To Variable"]]=UI["Targeted Card"]
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

func deload_hand_data():
	var card_data=[]
	var warbrand=card_piles["Hand"].card_pile
	for card in warbrand:
		var deloaded_card=card.deload_card()
		card_data.append(deloaded_card)
	return card_data
var roots=0
func end_battle():
	for card in existing_cards:
		card.queue_free()
	existing_cards.clear()
	if UI["Action"]["Result"]=="Lose":
		global_card.variable["Candles"]-=1
		if global_card.variable["Candles"]==0: #TODO: REPLACE WITH GAME OVER SCENE
			get_tree().change_scene_to_file("res://Scenes/menus/game_over.tscn")
			return
	if UI["Action"]["Result"]=="Win":
		if len(battle_pools)==global_card.variable["Floor"]+1:
			battle_pools.append([UI["Party Friendly"]])
			global_card.variable["Floor"]+=1
		else:
			battle_pools[global_card.variable["Floor"]].append(UI["Party Friendly"])
		auto_save_battles()
	get_tree().change_scene_to_file("res://Root.tscn")
func refresh_shop():
	for i in range(7):
		if root.shop_slots[i].card_held!=null:
			remove_card(root.shop_slots[i].card_held)
	for i in range(min(7,global_card.variable["Shop Card Count"])):
		var new_card=create_new_card(shop_card_pool[randi_range(0,len(shop_card_pool)-1)])
		new_card.location="Shop"
		root.shop_slots[i].card_held=new_card
func afterbattle():
	var removed_friendly=[]
	for i in battle.friendly_team:
		if i.variable["Health"]<=0:
			removed_friendly.append(i)
	for i in removed_friendly:
		if i.die_in_battle(): battle.friendly_team.erase(i)
	var removed_enemy=[]
	for i in battle.enemy_team:
		if i.variable["Health"]<=0:
			removed_enemy.append(i)
	for i in removed_enemy:
		if i.die_in_battle(): battle.enemy_team.erase(i)
var card_holder_where_a_card_is_placed=null
var apex_card_battle_flag=false
var attacks_skipped=0
var WeHaveSelectedACardOnField=false
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
		pass
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
	if is_instance_valid(root):
		root.drag_to_sell_popup.visible=WeHaveSelectedACardOnField
	if UI["Type"]=="Battle":
		if UI["Action"]["Type"]=="Wait":
			UI["Action"]["Time Left"]-=delta
			if UI["Action"]["Time Left"]<0:
				afterbattle()
				if len(battle.friendly_team)==0 and len(battle.enemy_team)==0:
					UI["Action"]={
						"Type":"Battle End",
						"Result":"Draw",
						"Letters Done":"",
						"Letters Left":"Looks like you've scored a draw. Eh, good enough, you pass.$#",
						"Time":0,
						"Letter Cooldown":0,
					}
					return
				elif len(battle.friendly_team)==0:
					UI["Action"]={
						"Type":"Battle End",
						"Result":"Lose",
						"Letters Done":"",
						"Letters Left":"Bro, Play something. I'm taking one of your candles as a lesson.$#",
						"Time":0,
						"Letter Cooldown":0,
					}
					return
				elif len(battle.enemy_team)==0:
					UI["Action"]={
						"Type":"Battle End",
						"Result":"Win",
						"Letters Done":"",
						"Letters Left":"A glorious victory, as all your opponents have fallen. You may advance.$#",
						"Time":0,
						"Letter Cooldown":0,
					}
					return
				
				var Ui=UI["Action"]
				var defenders=[]
				var attacker=null
				#print(attack_stack)
				while len(attack_stack)>0 and attacker==null:
					if is_instance_valid(attack_stack[0]):
						if attack_stack[0].variable["Health"]>0:
							attacker=attack_stack[0]
					attack_stack.remove_at(0)
				#print("->",attacker==null,attack_stack)
				if attacker!=null:
					if attacker.team==0:
						defenders=battle.enemy_team
					else:
						defenders=battle.friendly_team
				else:
					if UI["Team"]==0:
						var attackers=battle.friendly_team
						defenders=battle.enemy_team
						for i in range(7):
							UI["Friendly Index"]+=1
							if UI["Friendly Index"]>=len(attackers):
								UI["Friendly Index"]=0
							#if attackers[UI["Friendly Index"]].variable["Attack"]>0:
							attacker=attackers[UI["Friendly Index"]]
							break
					else:
						var attackers=battle.enemy_team
						defenders=battle.friendly_team
						for i in range(7):
							UI["Enemy Index"]+=1
							if UI["Enemy Index"]>=len(attackers):
								UI["Enemy Index"]=0
							#if attackers[UI["Enemy Index"]].variable["Attack"]>0:
							attacker=attackers[UI["Enemy Index"]]
							break
					
					UI["Team"]=1-UI["Team"]
					#print("--->",UI["Team"])
				var possible_defenders=[]
				var max_taunt=-20
				for iter_defender in defenders:
					var taunt_level=0
					if "Taunt" in iter_defender.variable:
						taunt_level=iter_defender.variable["Taunt"]
					if taunt_level>max_taunt:
						max_taunt=taunt_level
						possible_defenders=[]
					if taunt_level==max_taunt:
						possible_defenders.append(iter_defender)
				
				var defender=possible_defenders.pick_random()
				if attacker!=null:
					
					#print(attacker.team)
					global_card.variable["@Defender"]=defender
					global_card.variable["@Attacker"]=attacker
					if "Attackn't" in attacker.variable:
						if attacker.variable["Attackn't"]>0:
							attacker.trigger("Attacking")
							UI["Action"]={
								"Type":"Wait",
								"Time Left":0.25
							}
							afterbattle()
							return 
					if attacker.variable["Attack"]==0:
						UI["Action"]={
							"Type":"Wait",
							"Time Left":0.0
						}
						if attacks_skipped<7:
							UI["Team"]=1-UI["Team"]
						afterbattle()
						attacks_skipped+=1
						return
					attacks_skipped=0
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
			Ui["Attacker"].holder.z_index=20
			Ui["Attacker"].z_index=2
			#So, we have 4 stages in the attack stage, which will be reduced to three, after which the waiting is called again.
			if Ui["Time"]>0.25 and Ui["Time"]<0.5:
				var movement_q=(Ui["Time"]-0.25)/0.25
				var pos_diff=abs(Ui["Alpha Pos"].x-Ui["Beta Pos"].x)/100
				movement_q=pow(movement_q,2)
				var movement_x=movement_q/(pos_diff+3)*(pos_diff+1)
				Ui["Attacker"].holder.global_position.x=Ui["Alpha Pos"].x*(1-movement_x)+Ui["Beta Pos"].x*movement_x
				Ui["Attacker"].holder.global_position.y=Ui["Alpha Pos"].y*(1-movement_q/3)+Ui["Beta Pos"].y*movement_q/3
				
				#print(Ui["Attacker"].global_position)
				apex_card_battle_flag=false
			elif 0.5<Ui["Time"] and Ui["Time"]<0.75:
				if not apex_card_battle_flag:
					apex_card_battle_flag=true
					Ui["Attacker"].attack(Ui["Defender"])
				var movement_q=(Ui["Time"]-0.5)/0.25
				var pos_diff=abs(Ui["Alpha Pos"].x-Ui["Beta Pos"].x)/100
				var movement_x=1-(1-pow(movement_q,0.5))/(pos_diff+3)*(pos_diff+1)
				movement_q=1-(1-pow(movement_q,0.5))/3
				Ui["Attacker"].holder.global_position.x=Ui["Alpha Pos"].x*(movement_x)+Ui["Beta Pos"].x*(1-movement_x)
				Ui["Attacker"].holder.global_position.y=Ui["Alpha Pos"].y*(movement_q)+Ui["Beta Pos"].y*(1-movement_q)
				
			elif Ui["Time"]>0.75:
				Ui["Attacker"].holder.z_index=-10
				Ui["Attacker"].holder.global_position=Ui["Alpha Pos"]
				UI["Action"]={
					"Type":"Wait",
					"Time Left":0.25
				}
				afterbattle()
					
				if len(battle.friendly_team)==0 and len(battle.enemy_team)==0:
					UI["Action"]={
						"Type":"Battle End",
						"Result":"Draw",
						"Letters Done":"",
						"Letters Left":"Looks like you've scored a draw. Eh, good enough, you pass.$#",
						"Time":0,
						"Letter Cooldown":0,
					}
				elif len(battle.friendly_team)==0:
					UI["Action"]={
						"Type":"Battle End",
						"Result":"Lose",
						"Letters Done":"",
						"Letters Left":"All your creatures have perished in the field, and now, so will one of your candles.$#",
						"Time":0,
						"Letter Cooldown":0,
					}
				elif len(battle.enemy_team)==0:
					UI["Action"]={
						"Type":"Battle End",
						"Result":"Win",
						"Letters Done":"",
						"Letters Left":"A glorious victory, as all your opponents have fallen. You may advance.$#",
						"Time":0,
						"Letter Cooldown":0,
					}
		elif UI["Action"]["Type"]=="Battle End":
			if !is_instance_valid(battle):
				return
			var Ui=UI["Action"]
			Ui["Time"]+=delta
			var progress_q=min(max(0,Ui["Time"]-0.75)/1.5,1)
			battle.end_screen.modulate=Color(1,1,1,progress_q)
			if Ui["Time"]>2.5:
				if Ui["Letter Cooldown"]<=0:
					if Ui["Letters Left"][len(Ui["Letters Done"])]==".":
						Ui["Letter Cooldown"]=0.3+Ui["Letter Cooldown"]
						Ui["Letters Done"]+=Ui["Letters Left"][len(Ui["Letters Done"])]
					elif Ui["Letters Left"][len(Ui["Letters Done"])]=="$":
						Ui["Letter Cooldown"]=2+Ui["Letter Cooldown"]
						Ui["Letters Done"]+=" "
					elif Ui["Letters Left"][len(Ui["Letters Done"])]=="#":
						end_battle()
						
						
						return
					elif Ui["Letters Left"][len(Ui["Letters Done"])]==",":
						Ui["Letter Cooldown"]=0.13+Ui["Letter Cooldown"]
						Ui["Letters Done"]+=Ui["Letters Left"][len(Ui["Letters Done"])]
					else:
						Ui["Letter Cooldown"]=0.03+Ui["Letter Cooldown"]
						Ui["Letters Done"]+=Ui["Letters Left"][len(Ui["Letters Done"])]
					battle.end_screen_label.text=Ui["Letters Done"]
				Ui["Letter Cooldown"]-=delta
				
				
