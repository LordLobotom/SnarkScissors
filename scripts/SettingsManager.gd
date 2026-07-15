extends Node

signal settings_changed

const SETTINGS_PATH := "user://snarkscissors_settings.cfg"
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1024, 576),
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
]
const DEFAULT_MASTER_VOLUME := 0.80
const DEFAULT_MUSIC_VOLUME := 0.55
const DEFAULT_SFX_VOLUME := 0.85
const DEFAULT_RESOLUTION_INDEX := 1
const DEFAULT_DISPLAY_MODE := 0

var master_volume: float = DEFAULT_MASTER_VOLUME
var music_volume: float = DEFAULT_MUSIC_VOLUME
var sfx_volume: float = DEFAULT_SFX_VOLUME
var resolution_index: int = DEFAULT_RESOLUTION_INDEX
var display_mode: int = DEFAULT_DISPLAY_MODE


func _ready() -> void:
	_load_settings()
	apply_audio_settings()
	call_deferred("apply_display_settings")


func set_audio_levels(master: float, music: float, sfx: float) -> void:
	master_volume = clampf(master, 0.0, 1.0)
	music_volume = clampf(music, 0.0, 1.0)
	sfx_volume = clampf(sfx, 0.0, 1.0)
	apply_audio_settings()


func set_display_options(new_resolution_index: int, new_display_mode: int) -> void:
	resolution_index = clampi(new_resolution_index, 0, RESOLUTIONS.size() - 1)
	display_mode = clampi(new_display_mode, 0, 2)
	apply_display_settings()


func save() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master", master_volume)
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "sfx", sfx_volume)
	config.set_value("display", "resolution_index", resolution_index)
	config.set_value("display", "mode", display_mode)
	var error := config.save(SETTINGS_PATH)
	if error != OK:
		push_warning("Could not save settings: %s" % error_string(error))
	settings_changed.emit()


func reset_to_defaults() -> void:
	set_audio_levels(DEFAULT_MASTER_VOLUME, DEFAULT_MUSIC_VOLUME, DEFAULT_SFX_VOLUME)
	set_display_options(DEFAULT_RESOLUTION_INDEX, DEFAULT_DISPLAY_MODE)
	save()


func apply_audio_settings() -> void:
	_set_bus_volume(&"Master", master_volume)
	_set_bus_volume(&"Music", music_volume)
	_set_bus_volume(&"SFX", sfx_volume)


func preview_audio_levels(master: float, music: float, sfx: float) -> void:
	_set_bus_volume(&"Master", clampf(master, 0.0, 1.0))
	_set_bus_volume(&"Music", clampf(music, 0.0, 1.0))
	_set_bus_volume(&"SFX", clampf(sfx, 0.0, 1.0))


func apply_display_settings() -> void:
	var target_size := RESOLUTIONS[resolution_index]
	var screen := DisplayServer.window_get_current_screen()
	var usable_rect := DisplayServer.screen_get_usable_rect(screen)

	match display_mode:
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			DisplayServer.window_set_size(usable_rect.size)
			DisplayServer.window_set_position(usable_rect.position)
		2:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_size(target_size)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		_:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			var fitted_size := Vector2i(
				mini(target_size.x, usable_rect.size.x),
				mini(target_size.y, usable_rect.size.y)
			)
			DisplayServer.window_set_size(fitted_size)
			DisplayServer.window_set_position(
				usable_rect.position + (usable_rect.size - fitted_size) / 2
			)


func get_resolution_label(index: int) -> String:
	var resolution := RESOLUTIONS[clampi(index, 0, RESOLUTIONS.size() - 1)]
	return "%d x %d" % [resolution.x, resolution.y]


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return

	master_volume = clampf(float(config.get_value("audio", "master", DEFAULT_MASTER_VOLUME)), 0.0, 1.0)
	music_volume = clampf(float(config.get_value("audio", "music", DEFAULT_MUSIC_VOLUME)), 0.0, 1.0)
	sfx_volume = clampf(float(config.get_value("audio", "sfx", DEFAULT_SFX_VOLUME)), 0.0, 1.0)
	resolution_index = clampi(
		int(config.get_value("display", "resolution_index", DEFAULT_RESOLUTION_INDEX)),
		0,
		RESOLUTIONS.size() - 1
	)
	display_mode = clampi(int(config.get_value("display", "mode", DEFAULT_DISPLAY_MODE)), 0, 2)


func _set_bus_volume(bus_name: StringName, linear_value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return
	var volume_db := -80.0 if linear_value <= 0.001 else linear_to_db(linear_value)
	AudioServer.set_bus_volume_db(bus_index, volume_db)
