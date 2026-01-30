extends Node2D

#Card Internal Data
@onready var TextDisplay=preload("res://Cards/display.tscn")
var variable={}
var activated_on_triggers={}
var card_type=null
var linked_display_variable={}
var belongs_to_pile=null
var holder=null
var immovable=true
var location="Void"
func setup(data):
	variable=data
	card_type=variable["Type"]
	
	#Makes sure all the required variables exist, (returning to default if they don't)
	for iter_req_variable in Game.card_types[card_type]["Required Variables"]:
		if not iter_req_variable in variable:
			variable[iter_req_variable]=Game.card_types[card_type]["Required Variables"][iter_req_variable]
	
	#Creates all of the displays needed to display text on the card
	for iter_display_data in Game.card_types[card_type]["Displays"]:
		if iter_display_data["Type"]=="Text Display":
			var new_text_display=TextDisplay.instantiate()
			add_child(new_text_display)
			linked_display_variable[iter_display_data["Display Variable"]]=new_text_display
			new_text_display.setup(iter_display_data)
	
	#Links all of the cards effects in an easy to access matrix
	for iter_card_effect in variable["Effects"]:
		if not iter_card_effect["Trigger"] in activated_on_triggers:
			activated_on_triggers[iter_card_effect["Trigger"]]=[]
		activated_on_triggers[iter_card_effect["Trigger"]].append(iter_card_effect["Effect List"])
	
	#Adds all of the default effects to the end of the card, if they do not already exist. 
	for iter_default_card_effect in Game.card_types[card_type]["Default Triggers"]:
		if not iter_default_card_effect["Trigger"] in activated_on_triggers:
			activated_on_triggers[iter_default_card_effect["Trigger"]]=[iter_default_card_effect["Effect List"]]
	#print(activated_on_triggers)
	update_visually()
func update_visually():
	for i in linked_display_variable:
		if i in variable:
			linked_display_variable[i].update(variable[i])
func deload_card():
	var deloaded_data=variable
	#print(deloaded_data)
	return deloaded_data
	
#Card logic
#Is called whenever a card is tested for a trigger
func trigger(_trig):
	if _trig in activated_on_triggers:
		for iter_effect_list in activated_on_triggers[_trig]:
			for iter_effect in iter_effect_list: #These effects should also be added to Game.effect_stack
				iter_effect["Card Parent"]=self
				Game.effect_stack.append(iter_effect)
				Game.chl("Added Effect to stack: "+str(iter_effect),debug_c.EFFECT_DATA)
		if _trig=="ETB":
			trigger("On End")
func play():
	trigger("ETB")
func changed_card_pile():
	if belongs_to_pile=="Hand":
		immovable=false
var animations=[]

func unique_animation(animation_data):
	for i in animations:
		if i["Type"]==animation_data["Type"]:
			return null
	animations.append(animation_data)
	

var selected=false
var hovered_over=false

var original_y=0 #used to see if instants get played
var distance_from_mouse=99999

func _on_area_2d_mouse_entered() -> void:
	hovered_over=true

func _on_area_2d_mouse_exited() -> void:
	hovered_over=false
	
var selection_color_fade=0
func attack(target_card):
	variable["Health"]-=target_card.variable["Attack"]
	target_card.variable["Health"]-=variable["Attack"]
	animations.append({
							"Type":"Damaged",
							"Damage":target_card.variable["Attack"],
							"TTL":0,
							"MAX TTL":0.4
							})
	target_card.animations.append({
							"Type":"Damaged",
							"Damage":variable["Attack"],
							"TTL":0,
							"MAX TTL":0.4
							})
	update_visually()
	target_card.update_visually()
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if Game.UI["Type"]=="Targeting":
				if Game.UI["Targeted Card"]==self:
					Game.finish_targeting()
			if hovered_over:
				if not selected:
					if Game.selected_card==null: #Only if the player isn't selecting another card already
						if Game.closest_card==self and not immovable:
							selected=true #Then and only then this card is selected
							Game.selected_card=self
							animations.append({
								"Type":"Selected",
								"TTL":0,
								"MAX TTL":0.12
							}) #let's say, it grows by 10 %
				else:
					if Game.selected_card==self: #Only if the player isn't selecting another card already
						selected=false #Then and only then this card is selected
						Game.selected_card_nullify_trig=true
						if Game.a_card_is_being_placed_on_a_holder:
							if variable["Type"]==0:
								return
							Game.card_piles[belongs_to_pile].card_pile.erase(self)
							immovable=true
							belongs_to_pile=null
							Game.card_holder_where_a_card_is_placed.card_held=self
							Game.card_holder_where_a_card_is_placed.placeable=false
							play()
							changed_card_pile()
						else:
							
							animations.append({
							"Type":"Deselected",
							"TTL":0,
							"MAX TTL":0.12
							}) #let's say, it gets smaller by 10 %



var just_was_selected=false

func _process(delta: float) -> void:
	if len(animations)>0:
		for iter_animation in animations:
			if iter_animation["Type"]=="Selected":
				iter_animation["TTL"]+=delta
				var progress_q=iter_animation["TTL"]/iter_animation["MAX TTL"]
				if progress_q>1:
					animations.erase(iter_animation)
					scale=Vector2(1.1,1.1)
				else:
					progress_q=sin(progress_q*PI/2)
					scale=Vector2(1+progress_q/10,1+progress_q/10)
			elif iter_animation["Type"]=="Deselected":
				iter_animation["TTL"]+=delta
				var progress_q=iter_animation["TTL"]/iter_animation["MAX TTL"]
				if progress_q>1:
					animations.erase(iter_animation)
					scale=Vector2(1,1)
				else:
					progress_q=1-sin(progress_q*PI/2)
					scale=Vector2(1+progress_q/10,1+progress_q/10)
			elif iter_animation["Type"]=="Move Towards Pile":
				iter_animation["Progress"]+=delta*10
				if iter_animation["Progress"]<=iter_animation["Max Progress"]:
					global_position=iter_animation["Start Position"]*(1-ease(iter_animation["Progress"]/iter_animation["Max Progress"],-2))+iter_animation["End Position"]*(ease(iter_animation["Progress"]/iter_animation["Max Progress"],-2))
				else:
					global_position=iter_animation["End Position"]
					animations.erase(iter_animation)
	
	if selected:
		global_position=get_viewport().get_mouse_position()
		just_was_selected=true
	else: #Card flies towards it's card pile
		if belongs_to_pile!=null:
			if !is_instance_valid(Game.card_piles[belongs_to_pile]):
				belongs_to_pile=null
				return
			if belongs_to_pile=="Hand":
				if "Play On Drag" in Game.card_types[card_type]:
					if abs(global_position.y-original_y)>100 and just_was_selected:
						Game.card_piles[belongs_to_pile].card_pile.erase(self)
						belongs_to_pile=null
						play()
						
						return
				var hand_card_pile=Game.card_piles[belongs_to_pile].card_pile
				var x_offset=hand_card_pile.find(self)-((len(hand_card_pile)-1)/2.)
				var extra_y=abs(x_offset)**2.7
				if Game.hand_is_hovered_over:
					extra_y=0
				var pos_in_hand=Vector2(x_offset*110,extra_y)+Game.card_piles[belongs_to_pile].global_position
				if Game.hand_is_hovered_over:
					var offset=ease(min(1,Game.card_in_hand_selected_delta/0.2),-2.6)*15
					if hand_card_pile.find(self)<Game.card_in_hand_selected:
						pos_in_hand+=Vector2(-offset,0)
					elif hand_card_pile.find(self)>Game.card_in_hand_selected:
						pos_in_hand+=Vector2(offset,0)
				if hovered_over:
					if Game.UI["Type"]=="Shop":
						if global_position!=pos_in_hand+Vector2(0,-50):
							unique_animation({
								"Type":"Move Towards Pile",
								"Start Position":global_position,
								"End Position":pos_in_hand+Vector2(0,-110-extra_y),
								"Progress":0,
								"Max Progress":0.6,
								"Cancel Rot":1
							})
							rotation_degrees=0
							Game.i_can_turn_off_hand_is_hovered_over=true
							Game.hand_is_hovered_over=true
							Game.card_in_hand_selected=hand_card_pile.find(self)
							Game.card_in_hand_selected_delta+=delta
				else:
					if global_position!=pos_in_hand:
						unique_animation({
						"Type":"Move Towards Pile",
						"Start Position":global_position,
						"End Position":pos_in_hand,
						"Progress":0,
						"Max Progress":0.34,
						"Cancel Rot":0
					})
					if not Game.hand_is_hovered_over:
						rotation_degrees=x_offset*3
					else:
						rotation_degrees=0
				#print(hovered_over)
			elif !is_instance_valid(Game.card_piles[belongs_to_pile]):
				belongs_to_pile=null
			elif global_position!=Game.card_piles[belongs_to_pile].global_position:
				unique_animation({
					"Type":"Move Towards Pile",
					"Start Position":global_position,
					"End Position":Game.card_piles[belongs_to_pile].global_position,
					"Progress":0,
					"Max Progress":0.34
				})
		distance_from_mouse=get_viewport().get_mouse_position().distance_to(global_position)
		if distance_from_mouse<Game.smallest_distance_to_mouse:
			Game.smallest_distance_to_mouse=distance_from_mouse
			Game.csd_card=self
			original_y=global_position.y
		if just_was_selected:
			just_was_selected=false
	if Game.closest_card==self or hovered_over:
		z_index=2
	else:
		z_index=0
	if Game.UI["Type"]=="Targeting":
		if Game.closest_card==self:
			if self in Game.UI["Possible Targets"]:
				Game.UI["Targeted Card"]=self
		if Game.UI["Targeted Card"]==self:
			selection_color_fade=min(1,selection_color_fade+delta*15)
			modulate=Color(1.0-selection_color_fade, 1.0, 1.0, 1.0)
		else:
			selection_color_fade=max(0,selection_color_fade-delta*15)
			modulate=Color(1.0-selection_color_fade, 1.0, 1.0, 1.0)
	else:
		modulate=Color(1.,1.,1.,1.)
