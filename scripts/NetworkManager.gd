extends Node

signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
signal connection_failed
signal connection_established
signal server_created

const DEFAULT_PORT := 7777
const MAX_PLAYERS := 2

var is_host := false
var is_connected := false
var connected_peers: Dictionary = {}
var local_player_id := 1
var main_menu_ref: Node = null
var game_scene_ref: Node = null


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	print("NetworkManager ready - Local Player ID: ", local_player_id)


func create_server(port: int = DEFAULT_PORT) -> bool:
	if port < 1 or port > 65535:
		return false
	_close_peer()

	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(port, MAX_PLAYERS)
	if error != OK:
		push_warning("Could not create server: %s" % error_string(error))
		return false

	multiplayer.multiplayer_peer = peer
	is_host = true
	is_connected = true
	local_player_id = multiplayer.get_unique_id()
	server_created.emit()
	return true


func join_server(address: String, port: int = DEFAULT_PORT) -> bool:
	if address.strip_edges().is_empty() or port < 1 or port > 65535:
		return false
	_close_peer()

	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address, port)
	if error != OK:
		push_warning("Could not create client: %s" % error_string(error))
		return false

	multiplayer.multiplayer_peer = peer
	is_host = false
	is_connected = false
	return true


func disconnect_from_server(return_to_menu: bool = true) -> void:
	_close_peer()
	if not return_to_menu:
		return

	var current_scene := get_tree().current_scene
	if current_scene != null and current_scene.scene_file_path == "res://scenes/MainMenu.tscn":
		if is_instance_valid(main_menu_ref):
			main_menu_ref.show_connection_panel()
	else:
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _close_peer() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	is_host = false
	is_connected = false
	connected_peers.clear()
	local_player_id = 1


func _on_peer_connected(peer_id: int) -> void:
	connected_peers[peer_id] = {
		"id": peer_id,
		"name": "Player " + str(peer_id),
		"ready": false,
	}
	player_connected.emit(peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	connected_peers.erase(peer_id)
	player_disconnected.emit(peer_id)


func _on_connected_to_server() -> void:
	is_connected = true
	local_player_id = multiplayer.get_unique_id()
	connection_established.emit()


func _on_connection_failed() -> void:
	_close_peer()
	connection_failed.emit()


func _on_server_disconnected() -> void:
	disconnect_from_server()


@rpc("any_peer", "call_remote", "reliable")
func sync_player_choice(choice: String) -> void:
	var sender_id := multiplayer.get_remote_sender_id()
	if not is_host or sender_id not in connected_peers:
		return
	if choice not in ["rock", "paper", "scissors"]:
		return
	if is_instance_valid(game_scene_ref):
		game_scene_ref.receive_player_choice(sender_id, choice)


@rpc("any_peer", "call_local", "reliable")
func sync_player_ready(player_ready: bool) -> void:
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = local_player_id
	if sender_id != local_player_id and sender_id not in connected_peers:
		return
	if sender_id in connected_peers:
		connected_peers[sender_id]["ready"] = player_ready
	if is_instance_valid(main_menu_ref):
		main_menu_ref.update_player_ready_status(sender_id, player_ready)


@rpc("authority", "call_local", "reliable")
func start_game() -> void:
	get_tree().change_scene_to_file("res://scenes/GameScene.tscn")


@rpc("authority", "call_local", "reliable")
func sync_round_start(round_number: int) -> void:
	if is_instance_valid(game_scene_ref):
		game_scene_ref.sync_start_new_round(round_number)


@rpc("authority", "call_local", "reliable")
func sync_countdown_phase(countdown_time: float) -> void:
	if is_instance_valid(game_scene_ref):
		game_scene_ref.sync_countdown_phase(countdown_time)


@rpc("authority", "call_local", "reliable")
func sync_choice_phase(choice_time: float) -> void:
	if is_instance_valid(game_scene_ref):
		game_scene_ref.sync_choice_phase(choice_time)


@rpc("authority", "call_local", "reliable")
func sync_round_end(winner_id: int, results: Dictionary) -> void:
	if is_instance_valid(game_scene_ref):
		game_scene_ref.sync_round_end(winner_id, results)


func get_connected_players() -> Array:
	var players := []
	for peer_id in connected_peers:
		players.append(connected_peers[peer_id])
	return players


func get_player_count() -> int:
	return connected_peers.size() + 1


func is_all_players_ready() -> bool:
	for peer_id in connected_peers:
		if not connected_peers[peer_id].ready:
			return false
	return true


func send_player_choice(choice: String) -> void:
	if is_host:
		return
	sync_player_choice.rpc_id(1, choice)


func set_player_ready(player_ready: bool) -> void:
	if multiplayer.multiplayer_peer == null:
		return
	sync_player_ready.rpc(player_ready)


func start_round_for_all() -> void:
	if is_host and is_instance_valid(game_scene_ref):
		sync_round_start.rpc(game_scene_ref.current_round)


func start_countdown_for_all(time: float) -> void:
	if is_host:
		sync_countdown_phase.rpc(time)


func start_choice_phase_for_all(time: float) -> void:
	if is_host:
		sync_choice_phase.rpc(time)


func end_round_for_all(winner_id: int, results: Dictionary) -> void:
	if is_host:
		sync_round_end.rpc(winner_id, results)


func get_local_player_id() -> int:
	return local_player_id


func get_is_host() -> bool:
	return is_host


func get_is_connected() -> bool:
	return is_connected


func get_player_name(player_id: int) -> String:
	if player_id == local_player_id:
		return "You"
	if player_id in connected_peers:
		return connected_peers[player_id].name
	return "Unknown player"
