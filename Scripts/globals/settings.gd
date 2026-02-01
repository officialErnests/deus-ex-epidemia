extends Node

var music_volume = 1
var sfx_volume = 1
signal  music_volume_changed(music_volume)

func setMusicVolume(p_value) -> void:
    music_volume = p_value
    music_volume_changed.emit(p_value)

func setSfxVolume(music_volume) -> void:
    sfx_volume = music_volume

func getSfxVolume():
    return sfx_volume

func getMusicVolume() -> float:
    return music_volume
