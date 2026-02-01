extends HSlider

enum type {
	MUSIC_SLIDER,
	SFX_SLIDER
}

@export var this_type: type

func _ready() -> void:
	match this_type:
		type.MUSIC_SLIDER:
			value = settings.getMusicVolume()
			value_changed.connect(valueChangedMusic)
		type.SFX_SLIDER:
			value = settings.getSfxVolume()
			value_changed.connect(valueChangedSfx)

func valueChangedMusic(p_value):
	settings.setMusicVolume(p_value)

func valueChangedSfx(p_value):
	settings.setSfxVolume(p_value)
