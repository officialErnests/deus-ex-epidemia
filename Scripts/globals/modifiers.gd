extends Node

var curent_mask : String

func getCurentMask() -> String:
    return curent_mask

#* Think of dmg modifers and so on
func getCurentAtributes() -> Dictionary[String, float]:
    #TODO make so it looks up dict of curent modifier and returns that
    #Aka hude match statment or smthing, or dict
    return {}

func setCurrent(p_name):
    curent_mask = p_name
    return mask_atributes[p_name]

var mask_atributes = {
	"beetle": {
		"desc": "Endurance and strenght based mask, said to be able to wistand the strongest wepons not even leaving a scatch on it.",
		"modifiers": {
			"defence": 2
		},
		#This is like scope creep section ;PP
		"cards": {
			"unlocked": [
				"name goes here"
			],
			"buffed": {
				"name goes here": {
					"str" : -2,
					"hp" : 10
				}	
			}
		}
	}
}