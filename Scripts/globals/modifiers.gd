extends Node

var curent_mask : String

func getCurentMask() -> String:
	return curent_mask

#* Think of dmg modifers and so on
func getCurentAtributes():
	return mask_atributes[curent_mask]

func setCurrent(p_name):
	curent_mask = p_name
	return mask_atributes[p_name]

var mask_atributes = {
	"beetle": {
		"desc": "Beetles mask is said to be able to wistand the strongest wepons not even leaving a scatch on it.",
		#Add shit here
	},
	"dragon": {
		"desc": "Dragons mask is filled with menecing aura of wester dragon breed.",
		#Add shit here
	},
	"eagle": {
		"desc": "Eagle mask is light as an feather yet quick and deadly.",
		#Add shit here
	},
	"fox": {
		"desc": "Fox mask is fast and sly, always seeking new opertunities",
		#Add shit here
	},
	"rabbit": {
		"desc": "Rabbit mask is agile and fast paced, waving and jumping around",
		#Add shit here
	},
	"whale": {
		"desc": "Whale mask is fearcome as the great big whale, untouchable by anything.",
		#Add shit here
	}
}