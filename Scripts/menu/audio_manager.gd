extends AudioStreamPlayer

@export var sfx: bool

func _ready() -> void:
    if sfx:
        volume_linear = settings.getSfxVolume()
    else:
        volume_linear = settings.getMusicVolume()
        settings.music_volume_changed.connect(updateVol)

func updateVol(p_volume):
    volume_linear = p_volume        