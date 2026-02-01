extends Node

var unlocked_masks: Dictionary[String, bool] = {
					"beetle" = true,
					"dragon" = false,
					"eagle" = false,
					"fox" = false,
					"rabbit" = false,
					"whale" = false,
				}

func _ready() -> void:
	loadGame()

func getUnlocked() -> Dictionary[String, bool]:
	return unlocked_masks

func unlock(p_name) -> void:
	unlocked_masks[p_name] = true
	saveGame()

func saveGame():
	var save_file = FileAccess.open("user://NB_save_mask.dat", FileAccess.WRITE)
	save_file.store_string(JSON.stringify(unlocked_masks))

func loadGame():
	if not FileAccess.file_exists("user://NB_save_mask.dat"): return
	var save_file = FileAccess.open("user://NB_save_mask.dat", FileAccess.READ)
	var returned = JSON.parse_string(save_file.get_as_text())
	for key in returned.keys():
		unlocked_masks[key] = returned[key]
