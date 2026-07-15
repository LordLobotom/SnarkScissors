extends Control

signal closed

@onready var settings_card: PanelContainer = %SettingsCard
@onready var master_slider: HSlider = %MasterSlider
@onready var master_value: Label = %MasterValue
@onready var music_slider: HSlider = %MusicSlider
@onready var music_value: Label = %MusicValue
@onready var sfx_slider: HSlider = %SFXSlider
@onready var sfx_value: Label = %SFXValue
@onready var close_button: Button = %CloseButton
@onready var reset_button: Button = %ResetButton
@onready var done_button: Button = %DoneButton


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    master_slider.value_changed.connect(_on_audio_slider_changed)
    music_slider.value_changed.connect(_on_audio_slider_changed)
    sfx_slider.value_changed.connect(_on_audio_slider_changed)
    close_button.pressed.connect(close)
    reset_button.pressed.connect(_reset_controls)
    done_button.pressed.connect(_apply)
    visibility_changed.connect(_on_visibility_changed)
    resized.connect(_apply_responsive_layout)
    _apply_responsive_layout()


func open(play_sound: bool = true) -> void:
    _sync_from_settings()
    visible = true
    if play_sound:
        AudioManager.play_sfx(&"ui")
    done_button.grab_focus()


func close() -> void:
    SettingsManager.apply_audio_settings()
    visible = false
    closed.emit()


func _sync_from_settings() -> void:
    master_slider.value = SettingsManager.master_volume * 100.0
    music_slider.value = SettingsManager.music_volume * 100.0
    sfx_slider.value = SettingsManager.sfx_volume * 100.0
    _update_audio_labels()


func _on_audio_slider_changed(_value: float) -> void:
    _update_audio_labels()
    SettingsManager.preview_audio_levels(
        master_slider.value / 100.0,
        music_slider.value / 100.0,
        sfx_slider.value / 100.0
    )


func _update_audio_labels() -> void:
    master_value.text = "%d%%" % int(master_slider.value)
    music_value.text = "%d%%" % int(music_slider.value)
    sfx_value.text = "%d%%" % int(sfx_slider.value)


func _reset_controls() -> void:
    master_slider.value = SettingsManager.DEFAULT_MASTER_VOLUME * 100.0
    music_slider.value = SettingsManager.DEFAULT_MUSIC_VOLUME * 100.0
    sfx_slider.value = SettingsManager.DEFAULT_SFX_VOLUME * 100.0
    AudioManager.play_sfx(&"ui")


func _apply() -> void:
    SettingsManager.set_audio_levels(
        master_slider.value / 100.0,
        music_slider.value / 100.0,
        sfx_slider.value / 100.0
    )
    SettingsManager.save()
    AudioManager.play_sfx(&"ui")
    visible = false
    closed.emit()


func _apply_responsive_layout() -> void:
    if not is_node_ready():
        return
    settings_card.custom_minimum_size.x = clampf(size.x - 28.0, 320.0, 520.0)


func _on_visibility_changed() -> void:
    get_tree().paused = visible


func _unhandled_input(event: InputEvent) -> void:
    if visible and event.is_action_pressed("ui_cancel"):
        close()
        get_viewport().set_input_as_handled()


func _exit_tree() -> void:
    if get_tree().paused:
        get_tree().paused = false
