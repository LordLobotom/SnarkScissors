extends Control

signal closed

@onready var master_slider: HSlider = $Center/SettingsCard/CardMargin/Content/AudioPanel/AudioMargin/AudioStack/MasterRow/MasterSlider
@onready var master_value: Label = $Center/SettingsCard/CardMargin/Content/AudioPanel/AudioMargin/AudioStack/MasterRow/MasterValue
@onready var music_slider: HSlider = $Center/SettingsCard/CardMargin/Content/AudioPanel/AudioMargin/AudioStack/MusicRow/MusicSlider
@onready var music_value: Label = $Center/SettingsCard/CardMargin/Content/AudioPanel/AudioMargin/AudioStack/MusicRow/MusicValue
@onready var sfx_slider: HSlider = $Center/SettingsCard/CardMargin/Content/AudioPanel/AudioMargin/AudioStack/SFXRow/SFXSlider
@onready var sfx_value: Label = $Center/SettingsCard/CardMargin/Content/AudioPanel/AudioMargin/AudioStack/SFXRow/SFXValue
@onready var mode_option: OptionButton = $Center/SettingsCard/CardMargin/Content/DisplayPanel/DisplayMargin/DisplayStack/ModeRow/ModeOption
@onready var resolution_option: OptionButton = $Center/SettingsCard/CardMargin/Content/DisplayPanel/DisplayMargin/DisplayStack/ResolutionRow/ResolutionOption
@onready var resolution_note: Label = $Center/SettingsCard/CardMargin/Content/DisplayPanel/DisplayMargin/DisplayStack/ResolutionNote
@onready var close_button: Button = $Center/SettingsCard/CardMargin/Content/Header/CloseButton
@onready var reset_button: Button = $Center/SettingsCard/CardMargin/Content/Footer/ResetButton
@onready var cancel_button: Button = $Center/SettingsCard/CardMargin/Content/Footer/CancelButton
@onready var apply_button: Button = $Center/SettingsCard/CardMargin/Content/Footer/ApplyButton


func _ready() -> void:
	mode_option.add_item("Windowed")
	mode_option.add_item("Borderless (native)")
	mode_option.add_item("Fullscreen")
	for index in SettingsManager.RESOLUTIONS.size():
		resolution_option.add_item(SettingsManager.get_resolution_label(index))

	master_slider.value_changed.connect(_on_audio_slider_changed)
	music_slider.value_changed.connect(_on_audio_slider_changed)
	sfx_slider.value_changed.connect(_on_audio_slider_changed)
	mode_option.item_selected.connect(_on_mode_selected)
	close_button.pressed.connect(_cancel)
	cancel_button.pressed.connect(_cancel)
	reset_button.pressed.connect(_reset_controls)
	apply_button.pressed.connect(_apply)
	visibility_changed.connect(_on_visibility_changed)
	visible = false


func open(play_sound: bool = true) -> void:
	_sync_from_settings()
	visible = true
	if play_sound:
		AudioManager.play_sfx(&"open")
	apply_button.grab_focus()


func close() -> void:
	SettingsManager.apply_audio_settings()
	visible = false
	closed.emit()


func _sync_from_settings() -> void:
	master_slider.value = SettingsManager.master_volume * 100.0
	music_slider.value = SettingsManager.music_volume * 100.0
	sfx_slider.value = SettingsManager.sfx_volume * 100.0
	mode_option.select(SettingsManager.display_mode)
	resolution_option.select(SettingsManager.resolution_index)
	_update_audio_labels()
	_update_resolution_state()


func _on_audio_slider_changed(_value: float) -> void:
	_update_audio_labels()
	SettingsManager.preview_audio_levels(
		master_slider.value / 100.0,
		music_slider.value / 100.0,
		sfx_slider.value / 100.0
	)


func _on_mode_selected(_index: int) -> void:
	_update_resolution_state()


func _update_audio_labels() -> void:
	master_value.text = "%d%%" % int(master_slider.value)
	music_value.text = "%d%%" % int(music_slider.value)
	sfx_value.text = "%d%%" % int(sfx_slider.value)


func _update_resolution_state() -> void:
	var borderless := mode_option.selected == 1
	resolution_option.disabled = borderless
	resolution_note.text = (
		"Borderless uses the desktop resolution."
		if borderless
		else "Changes apply immediately and are saved locally."
	)


func _reset_controls() -> void:
	master_slider.value = SettingsManager.DEFAULT_MASTER_VOLUME * 100.0
	music_slider.value = SettingsManager.DEFAULT_MUSIC_VOLUME * 100.0
	sfx_slider.value = SettingsManager.DEFAULT_SFX_VOLUME * 100.0
	mode_option.select(SettingsManager.DEFAULT_DISPLAY_MODE)
	resolution_option.select(SettingsManager.DEFAULT_RESOLUTION_INDEX)
	_update_audio_labels()
	_update_resolution_state()
	AudioManager.play_sfx(&"ui")


func _apply() -> void:
	SettingsManager.set_audio_levels(
		master_slider.value / 100.0,
		music_slider.value / 100.0,
		sfx_slider.value / 100.0
	)
	SettingsManager.set_display_options(resolution_option.selected, mode_option.selected)
	SettingsManager.save()
	AudioManager.play_sfx(&"ui")
	visible = false
	closed.emit()


func _cancel() -> void:
	AudioManager.play_sfx(&"ui")
	close()


func _on_visibility_changed() -> void:
	get_tree().paused = visible
