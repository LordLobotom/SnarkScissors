extends Node


func _ready() -> void:
    call_deferred("_run")


func _run() -> void:
    await get_tree().create_timer(0.2).timeout
    assert(AudioManager.music_stream != null, "Background music stream is missing")
    assert(AudioManager.is_music_playing(), "Background music did not start")

    var initial_position := AudioManager.get_music_playback_position()
    await get_tree().create_timer(0.25).timeout
    var later_position := AudioManager.get_music_playback_position()
    assert(later_position > initial_position, "Background music playback is not advancing")

    AudioManager.stop_all()
    await get_tree().create_timer(0.5).timeout
    print("AUDIO_SMOKE_OK")
    get_tree().quit()
