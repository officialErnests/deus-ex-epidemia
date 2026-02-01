extends Node

func getUnlocked() -> Dictionary[String, bool]:
	var temp_dict: Dictionary[String, bool]= {
		"beetle" = true,
		"dragon" = true,
		"eagle" = true,
		"fox" = true,
		"rabbit" = true,
		"whale" = true,
	}
	return temp_dict
