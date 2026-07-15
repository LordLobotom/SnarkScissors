extends Node

const MUSIC_STREAM := preload("res://audio/music/Fantasy Snark.wav")
const SFX_STREAMS := {
	&"ui": preload("res://sfx/menu_select_00.wav"),
	&"open": preload("res://sfx/turn_page.wav"),
	&"connect": preload("res://sfx/sell_buy_item.wav"),
	&"ready": preload("res://sfx/shield_ding.wav"),
	&"start": preload("res://sfx/level_up.wav"),
	&"countdown": preload("res://sfx/bubble.wav"),
	&"rock": preload("res://sfx/big_punch.wav"),
	&"paper": preload("res://sfx/bow.wav"),
	&"scissors": preload("res://sfx/swish_sword_2.wav"),
	&"win": preload("res://sfx/cure8.wav"),
	&"lose": preload("res://sfx/blub_hurt2.wav"),
	&"draw": preload("res://sfx/metal_clash.wav"),
	&"disconnect": preload("res://sfx/ceramic_destroy.wav"),
}
const SFX_POOL_SIZE := 6

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _next_sfx_player := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = &"Music"
	add_child(_music_player)

	for index in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.name = "SFXPlayer%d" % index
		player.bus = &"SFX"
		add_child(player)
		_sfx_players.append(player)

	var looped_music := MUSIC_STREAM.duplicate() as AudioStreamWAV
	looped_music.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_music_player.stream = looped_music
	_music_player.play()


func play_sfx(cue: StringName) -> void:
	var stream := SFX_STREAMS.get(cue) as AudioStream
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
