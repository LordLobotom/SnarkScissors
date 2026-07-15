extends Node

const TEST_PORT := 18777
const TIMEOUT_SECONDS := 5.0

var received_choice := ""
var received_player_id := -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")


func _run() -> void:
	var role := OS.get_environment("SNARK_NET_ROLE")
	if role == "host":
		await _run_host()
	elif role == "client":
		await _run_client()
	else:
		_fail("SNARK_NET_ROLE must be host or client")


func _run_host() -> void:
	NetworkManager.game_scene_ref = self
	if not NetworkManager.create_server(TEST_PORT):
		_fail("Host could not open the test port")
		return

	var started_at := Time.get_ticks_msec()
	while Time.get_ticks_msec() - started_at < int(TIMEOUT_SECONDS * 1000.0):
		if (
			NetworkManager.connected_peers.size() == 1
			and _remote_player_is_ready()
			and received_choice == "rock"
			and received_player_id in NetworkManager.connected_peers
		):
			await get_tree().create_timer(0.4).timeout
			_finish("NETWORK_SMOKE_HOST_OK")
			return
		await get_tree().create_timer(0.05).timeout

	_fail("Host did not receive the authenticated ready state and choice")


func _run_client() -> void:
	await get_tree().create_timer(0.3).timeout
	if not NetworkManager.join_server("127.0.0.1", TEST_PORT):
		_fail("Client could not start the connection")
		return

	var started_at := Time.get_ticks_msec()
	while Time.get_ticks_msec() - started_at < int(TIMEOUT_SECONDS * 1000.0):
		if NetworkManager.is_connected:
			NetworkManager.set_player_ready(true)
			NetworkManager.send_player_choice("rock")
			await get_tree().create_timer(0.2).timeout
			_finish("NETWORK_SMOKE_CLIENT_OK")
			return
		await get_tree().create_timer(0.05).timeout

	_fail("Client connection timed out")


func receive_player_choice(player_id: int, choice: String) -> void:
	received_player_id = player_id
	received_choice = choice


func _remote_player_is_ready() -> bool:
	for peer_id in NetworkManager.connected_peers:
		if NetworkManager.connected_peers[peer_id].ready:
			return true
	return false


func _finish(message: String) -> void:
	NetworkManager.game_scene_ref = null
	NetworkManager.disconnect_from_server(false)
	AudioManager.stop_all()
	print(message)
	get_tree().quit()


func _fail(message: String) -> void:
	push_error(message)
	NetworkManager.game_scene_ref = null
	NetworkManager.disconnect_from_server(false)
	AudioManager.stop_all()
	get_tree().quit(1)
