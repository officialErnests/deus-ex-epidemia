extends Button

@export var to_scene: PackedScene
@export var exit: bool
@export var main_menu: bool
@export var root: bool = false
@export var settings_bool: bool = false
@export var click_sfx: AudioStreamMP3
var sfx_player

func _ready() -> void:
	connect("pressed", buttonPressed)
	sfx_player = AudioStreamPlayer.new()
	sfx_player.stream = click_sfx
	add_child(sfx_player)


func buttonPressed():
	Game.fuck_this_shit()
	sfx_player.volume_linear = settings.getSfxVolume()
	sfx_player.play()
	if exit:
		get_tree().quit()
		return
	if main_menu:
		get_tree().change_scene_to_file("res://Scenes/menus/main_menu.tscn")
		return
	if settings_bool:
		get_node("Settings").visible = true
		return
	get_tree().change_scene_to_packed(to_scene)
	if root:
		Game.will_start_new_game=true
