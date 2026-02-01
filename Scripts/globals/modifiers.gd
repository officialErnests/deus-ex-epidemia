extends Node

var current_mask : String

func getCurentMask() -> String:
	return current_mask

#* Think of dmg modifers and so on
func getCurentAtributes():
	return mask_atributes[current_mask]

func setCurrent(p_name):
	current_mask = p_name
	return mask_atributes[p_name]

var mask_atributes = {
	"beetle": {
		"desc": "Beetles mask is said to be able to wistand the strongest wepons not even leaving a scratch on it.\nYou start with a Beetle Scales card, that negates damage once.",
		#Add shit here
	},
	"dragon": {
		"desc": "Dragons mask is filled with menecing aura of western dragon breed.\nYou get an extra gold each turn, and an extra card each shop, but one of your candles are burnt out. ",
		#Add shit here
	},
	"eagle": {
		"desc": "Eagle mask is light as a feather yet quick and deadly.\nYou start with an extra gold each turn.",
		#Add shit here
	},
	"fox": {
		"desc": "Fox mask is fast and sly, always seeking new opertunities.\nYou get a Fox Claws each turn, to buff your minions",
		#Add shit here
	},
	"rabbit": {
		"desc": "Rabbit mask is agile and fast paced, waving and jumping around.\nYou can buy an extra card each shop.",
		#Add shit here
	},
	"whale": {
		"desc": "Whale mask is fearsome as the great big whale, untouchable by anything.\nYou gain an extra Candle.",
		#Add shit here
	}
}
