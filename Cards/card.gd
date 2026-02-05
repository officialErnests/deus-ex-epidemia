extends Node2D

#Card Internal Data
@onready var TextDisplay=preload("res://Cards/display.tscn")
@onready var Area=$Area2D
var variable={}
var activated_on_triggers={}
var card_type=null
var linked_display_variable={}
var belongs_to_pile=null
var holder=null
var immovable=true
var location="Void"
var will_die=false
var team=0 #used only in battles
func setup(data:Dictionary):
	variable=data.duplicate(true)
	card_type=variable["Type"]
	print(data)
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
	var trigger_key=randi()
	if _trig in activated_on_triggers:
		for iter_effect_list in activated_on_triggers[_trig]:
			for iter_effect in iter_effect_list: #These effects should also be added to Game.effect_stack
				iter_effect["Card Parent"]=self
				iter_effect["Trigger Key"]=trigger_key
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
	if location=="Shop":
		for i in animations:
			if i["Type"]=="Shop Deselected":
				animations.erase(i)
		unique_animation({
								"Type":"Shop Selected",
								"TTL":0,
								"MAX TTL":0.2
							})
				
func _on_area_2d_mouse_exited() -> void:
	hovered_over=false
	if location=="Shop":
		for i in animations:
			if i["Type"]=="Shop Selected":
				animations.erase(i)
		unique_animation({
								"Type":"Shop Deselected",
								"TTL":0,
								"MAX TTL":0.2
							})
var selection_color_fade=0
func attack(target_card):
	trigger("Attacking")
	target_card.trigger("Defending")
	take_damage(target_card.variable["Attack"])
	target_card.take_damage(variable["Attack"])
	Game.battle.screen_shake_left=variable["Attack"]+target_card.variable["Attack"]
	if target_card.variable["Health"]<=0:
		target_card.will_die=true
	
	update_visually()
	target_card.update_visually()
func take_damage(damage):
	if "Buffer" in variable:
		if variable["Buffer"]>0:
			variable["Buffer"]-=1
			get_hit(0)
			return
	get_node("HitSfx").play()
	variable["Health"]-=damage
	get_hit(damage)
	update_visually()
	if variable["Health"]<=0:
		will_die=true
func get_hit(damage):
	animations.append({
		"Type":"Damaged",
		#"Damage":target_card.variable["Attack"],
		"TTL":0,
		"MAX TTL":0.4
		})
	$HitFx.visible=true
	$HitFx/Label.text="-"+str(int(damage))
func die_in_battle():
	if "Reborn" in variable:
		if variable["Reborn"]>0:
			variable["Health"]=1
			variable["Reborn"]-=1
			update_visually()
			return false
	for i in Game.existing_cards:
		if i!=self:
			if i.team==team:
				i.trigger("Avenge")
	animations.append({
							"Type":"Die In Battle",
							#"Damage":variable["Attack"],
							"TTL":0,
							"MAX TTL":0.7
							})
	return true
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if Game.UI["Type"]=="Targeting":
				if Game.UI["Targeted Card"]==self:
					Game.finish_targeting()
			if hovered_over:
				if location=="Shop":
					if variable["Cost"]<=Game.global_card.variable["Gold"]:
						Game.global_card.variable["Gold"]-=variable["Cost"]
						Game.global_card.variable["Gold"]=int(Game.global_card.variable["Gold"])
						location="Void"
						belongs_to_pile="Hand"
						holder.card_held=null
						holder.scale=Vector2(0.7,0.7)
						Area.scale=Vector2(1,1)
						holder=null
						Game.card_piles["Hand"].card_pile.append(self)
						changed_card_pile()
						if not "Food I" in Game.shop_pools:
							Game.shop_add_pool("Food I")
					return
				#print(1)
				#print(selected," ",Game.selected_card==null," ",Game.closest_card==self)
				#if Game.closest_card!=null:
			#		print(Game.closest_card.variable["Name"])
				if not selected:
					if Game.selected_card==null: #Only if the player isn't selecting another card already
						if Game.closest_card==self:
							print(2)
							selected=true #Then and only then this card is selected
							Game.selected_card=self
							animations.append({
								"Type":"Selected",
								"TTL":0,
								"MAX TTL":0.12
							}) #let's say, it grows by 10 %
							if immovable:
								Game.WeHaveSelectedACardOnField=true
								var passed=false
								for iter_card_holder in Game.root.warbrand_slots:
									if iter_card_holder==holder:
										passed=true
										continue
									iter_card_holder.original_position=iter_card_holder.global_position+Vector2(50-100*int(passed),0)
				else:				
					deselect()
func deselect():
	if Game.selected_card==self: #Only if the player isn't selecting another card already
		selected=false #Then and only then this card is selected
		Game.selected_card_nullify_trig=true
		Game.WeHaveSelectedACardOnField=false
		if not self.immovable:
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
		else:
			var sold=holder.global_position.y==100
			var old_place=Game.root.warbrand_slots.find(holder)
			var new_place=0
			var new_order=[]
			for iter_card_holder_id in range(len(Game.root.warbrand_slots)):
				var iter_card_holder=Game.root.warbrand_slots[iter_card_holder_id]
				iter_card_holder.global_position=iter_card_holder.og_pos
				iter_card_holder.scale=Vector2(0.7,0.7)
				if iter_card_holder==holder:
					continue
				if iter_card_holder.is_behind:
					new_place=iter_card_holder_id
				
				new_order.append(iter_card_holder.card_held)
			if old_place<new_place or new_place==0:
				new_order.insert(new_place,self)
			else:
				new_order.insert(new_place+1,self)
			if not sold:
				for i in range(7):
					Game.root.warbrand_slots[i].card_held=new_order[i]
			else:
				holder.card_held=null
				Game.remove_card(self)
				Game.global_card.variable["Gold"]+=1
			return 
			
			#holder.global_position=holder.og_pos

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
					if holder!=null:
						holder.scale=scale*0.7
				else:
					progress_q=sin(progress_q*PI/2)
					scale=Vector2(1+progress_q/10,1+progress_q/10)
					if holder!=null:
						holder.scale=scale*0.7
			elif iter_animation["Type"]=="Deselected":
				iter_animation["TTL"]+=delta
				var progress_q=iter_animation["TTL"]/iter_animation["MAX TTL"]
				if progress_q>1:
					animations.erase(iter_animation)
					scale=Vector2(1,1)
					if holder!=null:
						holder.scale=scale*0.7
				else:
					progress_q=1-sin(progress_q*PI/2)
					scale=Vector2(1+progress_q/10,1+progress_q/10)
					if holder!=null:
						holder.scale=scale*0.7
			elif iter_animation["Type"]=="Move Towards Pile":
				iter_animation["Progress"]+=delta*10
				if iter_animation["Progress"]<=iter_animation["Max Progress"]:
					global_position=iter_animation["Start Position"]*(1-ease(iter_animation["Progress"]/iter_animation["Max Progress"],-2))+iter_animation["End Position"]*(ease(iter_animation["Progress"]/iter_animation["Max Progress"],-2))
				else:
					global_position=iter_animation["End Position"]
					animations.erase(iter_animation)
			elif iter_animation["Type"]=="Damaged":
				iter_animation["TTL"]+=delta
				
				if iter_animation["TTL"]>iter_animation["MAX TTL"]:
					$HitFx.visible=false
					$HitFx/Label.text=""
					animations.erase(iter_animation)
			elif iter_animation["Type"]=="Die In Battle":
				iter_animation["TTL"]+=delta
				var progress_q=max(0,iter_animation["TTL"]-0.3)/0.4
				modulate=Color(1.,1.,1., 1-progress_q)
				if iter_animation["TTL"]>iter_animation["MAX TTL"]:
					animations.erase(iter_animation)
					Game.existing_cards.erase(self)
					queue_free()
					return
			elif iter_animation["Type"]=="Shop Selected":
				if holder==null:
					animations.erase(iter_animation)
					break
				iter_animation["TTL"]+=delta
				var progress_q=iter_animation["TTL"]/iter_animation["MAX TTL"]
				if progress_q>1:
					animations.erase(iter_animation)
					holder.scale=Vector2(1.3,1.3)
					Area.scale=Vector2(0.7/holder.scale[0],0.7/holder.scale[1])
				else:
					progress_q=sin(progress_q*PI/2)
					holder.scale=Vector2(0.7+progress_q/10*6,0.7+progress_q/10*6)
					Area.scale=Vector2(0.7/holder.scale[0],0.7/holder.scale[1])
			elif iter_animation["Type"]=="Shop Deselected":
				if holder==null:
					animations.erase(iter_animation)
					break
				iter_animation["TTL"]+=delta
				var progress_q=iter_animation["TTL"]/iter_animation["MAX TTL"]
				if progress_q>1:
					animations.erase(iter_animation)
					holder.scale=Vector2(0.7,0.7)
					Area.scale=Vector2(0.7/holder.scale[0],0.7/holder.scale[1])
				else:
					progress_q=1-sin(progress_q*PI/2)
					holder.scale=Vector2(0.7+progress_q/10*6,0.7+progress_q/10*6)
					Area.scale=Vector2(0.7/holder.scale[0],0.7/holder.scale[1])
	if selected:
		if not immovable:
			global_position=get_viewport().get_mouse_position()
			just_was_selected=true
		else:
			holder.global_position.x=get_viewport().get_mouse_position().x
			holder.global_position.y=clamp(get_viewport().get_mouse_position().y,100,holder.og_pos.y)
			if holder.global_position.y==100:
				deselect()
			just_was_selected=true
	else: #Card flies towards it's card pile
		if holder!=null and location=="On Field":
			pass
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
	elif Game.UI["Type"]!="Battle":
		modulate=Color(1.,1.,1.,1.)
	$HitFx.visible=hovered_over
