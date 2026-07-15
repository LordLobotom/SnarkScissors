extends Node

const SFX_POOL_SIZE := 5

@export_group("Music")
@export var music_stream: AudioStreamWAV

@export_group("Sound Effects")
@export var ui_sfx: AudioStream
@export var rock_sfx: AudioStream
@export var paper_sfx: AudioStream
@export var scissors_sfx: AudioStream
@export var reveal_sfx: AudioStream
@export var win_sfx: AudioStream
@export var lose_sfx: AudioStream
@export var draw_sfx: AudioStream

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _next_sfx_player := 0


func _enter_tree() -> void:
    _ensure_audio_bus(&"Music")
    _ensure_audio_bus(&"SFX")


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _music_player = AudioStreamPlayer.new()
    _music_player.name = "MusicPlayer"
    _music_player.bus = &"Music"
    add_child(_music_player)

    for index in SFX_POOL_SIZE:
        var player := AudioStreamPlayer.new()
        player.name = "SFXPlayer%d" % index
        player.bus = &"SFX"
        add_child(player)
        _sfx_players.append(player)

    start_music()


func start_music() -> void:
    if _is_qa_run() or not is_instance_valid(_music_player):
        return
    if music_stream == null:
        push_warning("Background music stream is missing")
        return
    _music_player.stream = music_stream
    if not _music_player.playing:
        _music_player.play()


func is_music_playing() -> bool:
    return is_instance_valid(_music_player) and _music_player.playing


func get_music_playback_position() -> float:
    if not is_instance_valid(_music_player):
        return 0.0
    return _music_player.get_playback_position()


func play_sfx(cue: StringName) -> void:
    if _is_qa_run():
        return
    var stream := _stream_for_cue(cue)
    if stream == null or _sfx_players.is_empty():
        return

    var player := _sfx_players[_next_sfx_player]
    _next_sfx_player = (_next_sfx_player + 1) % _sfx_players.size()
    player.stream = stream
    player.play()


func stop_all() -> void:
    if is_instance_valid(_music_player):
        _music_player.stop()
        _music_player.stream = null
        _music_player.free()
    _music_player = null

    for player in _sfx_players:
        if is_instance_valid(player):
            player.stop()
            player.stream = null
            player.free()
    _sfx_players.clear()


func _exit_tree() -> void:
    stop_all()


func _is_qa_run() -> bool:
    return OS.get_environment("SNARK_QA") == "1"


func _ensure_audio_bus(bus_name: StringName) -> void:
    if AudioServer.get_bus_index(bus_name) >= 0:
        return
    AudioServer.add_bus()
    var bus_index := AudioServer.bus_count - 1
    AudioServer.set_bus_name(bus_index, bus_name)
    AudioServer.set_bus_send(bus_index, &"Master")


func _stream_for_cue(cue: StringName) -> AudioStream:
    match cue:
        &"ui":
            return ui_sfx
        &"rock":
            return rock_sfx
        &"paper":
            return paper_sfx
        &"scissors":
            return scissors_sfx
        &"reveal":
            return reveal_sfx
        &"win":
            return win_sfx
        &"lose":
            return lose_sfx
        &"draw":
            return draw_sfx
        _:
            return null
