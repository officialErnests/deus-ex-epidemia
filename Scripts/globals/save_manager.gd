extends Node

var unlocked_masks: Dictionary[String, bool]= {
	"beetle" = true,
	"dragon" = false,
	"eagle" = false,
	"fox" = false,
	"rabbit" = false,
	"whale" = false,
}

func getUnlocked() -> Dictionary[String, bool]:
	return unlocked_masks

func unlock(p_name) -> void:
	unlocked_masks[p_name] = true
