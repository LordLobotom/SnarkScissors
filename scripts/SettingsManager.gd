extends Node

signal settings_changed

const SETTINGS_PATH := "user://snarkscissors_settings.cfg"
const DEFAULT_MASTER_VOLUME := 0.85
const DEFAULT_MUSIC_VOLUME := 0.45
const DEFAULT_SFX_VOLUME := 0.90

var master_volume: float = DEFAULT_MASTER_VOLUME
var music_volume: float = DEFAULT_MUSIC_VOLUME
var sfx_volume: float = DEFAULT_SFX_VOLUME


func _ready() -> void:
    _load_settings()
    apply_audio_settings()


func set_audio_levels(master: float, music: float, sfx: float) -> void:
    master_volume = clampf(master, 0.0, 1.0)
    music_volume = clampf(music, 0.0, 1.0)
    sfx_volume = clampf(sfx, 0.0, 1.0)
    apply_audio_settings()


func preview_audio_levels(master: float, music: float, sfx: float) -> void:
    _set_bus_volume(&"Master", clampf(master, 0.0, 1.0))
    _set_bus_volume(&"Music", clampf(music, 0.0, 1.0))
    _set_bus_volume(&"SFX", clampf(sfx, 0.0, 1.0))


func apply_audio_settings() -> void:
    _set_bus_volume(&"Master", master_volume)
    _set_bus_volume(&"Music", music_volume)
    _set_bus_volume(&"SFX", sfx_volume)


func save() -> void:
    var config := ConfigFile.new()
    config.set_value("audio", "master", master_volume)
    config.set_value("audio", "music", music_volume)
    config.set_value("audio", "sfx", sfx_volume)
    var error := config.save(SETTINGS_PATH)
    if error != OK:
        push_warning("Could not save settings: %s" % error_string(error))
    settings_changed.emit()


func reset_to_defaults() -> void:
    set_audio_levels(DEFAULT_MASTER_VOLUME, DEFAULT_MUSIC_VOLUME, DEFAULT_SFX_VOLUME)
    save()


func _load_settings() -> void:
    var config := ConfigFile.new()
    if config.load(SETTINGS_PATH) != OK:
        return

    master_volume = clampf(
        float(config.get_value("audio", "master", DEFAULT_MASTER_VOLUME)), 0.0, 1.0
    )
    music_volume = clampf(
        float(config.get_value("audio", "music", DEFAULT_MUSIC_VOLUME)), 0.0, 1.0
    )
    sfx_volume = clampf(
        float(config.get_value("audio", "sfx", DEFAULT_SFX_VOLUME)), 0.0, 1.0
    )


func _set_bus_volume(bus_name: StringName, linear_value: float) -> void:
    var bus_index := AudioServer.get_bus_index(bus_name)
    if bus_index == -1:
        return
    var volume_db := -80.0 if linear_value <= 0.001 else linear_to_db(linear_value)
    AudioServer.set_bus_volume_db(bus_index, volume_db)
