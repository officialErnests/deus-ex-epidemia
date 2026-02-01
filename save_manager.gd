extends Node

func getUnlocked() -> Dictionary[String, bool]:
	var temp_dict: Dictionary[String, bool]= {
		"beetle" = true,
		"dragon" = false,
		"eagle" = false,
		"fox" = true,
		"rabbit" = false,
		"whale" = false,
	}
	return temp_dict
