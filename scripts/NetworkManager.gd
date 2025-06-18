# NetworkManager.gd
# Singleton pro správu multiplayer připojení a synchronizaci
extends Node

signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
signal connection_failed()
signal connection_established()
signal server_created()

# Síťové konstanty
const DEFAULT_PORT = 7777
const MAX_PLAYERS = 2

# Stav hry
var is_host: bool = false
var is_connected: bool = false
var connected_peers: Dictionary = {}
var local_player_id: int = 1

# Reference na UI
var main_menu_ref: Node = null
var game_scene_ref: Node = null

func _ready():
	# Nastavení multiplayer signálů
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	print("NetworkManager ready - Local Player ID: ", local_player_id)

# ========================================
# ZÁKLADNÍ SÍŤOVÉ FUNKCE
# ========================================

func create_server(port: int = DEFAULT_PORT) -> bool:
	"""Vytvoří server pro hostování hry"""
	print("Vytvářím server na portu: ", port)
	
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, MAX_PLAYERS)
	
	if error != OK:
		print("Chyba při vytváření serveru: ", error)
		return false
	
	multiplayer.multiplayer_peer = peer
	is_host = true
	is_connected = true
	local_player_id = multiplayer.get_unique_id()
	
	print("Server vytvořen! ID: ", local_player_id)
	server_created.emit()
	return true

func join_server(ip: String, port: int = DEFAULT_PORT) -> bool:
	"""Připojí se k existujícímu serveru"""
	print("Připojuji se k serveru: ", ip, ":", port)
	
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, port)
	
	if error != OK:
		print("Chyba při připojování: ", error)
		return false
	
	multiplayer.multiplayer_peer = peer
	is_host = false
	
	return true

func disconnect_from_server():
	"""Odpojí se od serveru nebo ukončí hostování"""
	print("Odpojuji se od serveru...")
	
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	
	is_host = false
	is_connected = false
	connected_peers.clear()
	
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

# ========================================
# SÍŤOVÉ EVENT HANDLERY
# ========================================

func _on_peer_connected(peer_id: int):
	"""Volá se když se připojí nový hráč"""
	print("Hráč se připojil: ", peer_id)
	connected_peers[peer_id] = {
		"id": peer_id,
		"name": "Hráč " + str(peer_id),
		"ready": false
	}
	player_connected.emit(peer_id)

func _on_peer_disconnected(peer_id: int):
	"""Volá se když se hráč odpojí"""
	print("Hráč se odpojil: ", peer_id)
	connected_peers.erase(peer_id)
	player_disconnected.emit(peer_id)

func _on_connected_to_server():
	"""Pro klienta - úspěšně se připojil k serveru"""
	print("Úspěšně připojen k serveru!")
	is_connected = true
	local_player_id = multiplayer.get_unique_id()
	connection_established.emit()

func _on_connection_failed():
	"""Pro klienta - připojení selhalo"""
	print("Připojení k serveru selhalo!")
	connection_failed.emit()

func _on_server_disconnected():
	"""Pro klienta - server se odpojil"""
	print("Server se odpojil!")
	disconnect_from_server()

# ========================================
# GAME STATE SYNCHRONIZACE - OPRAVENO
# ========================================

@rpc("any_peer", "call_remote", "reliable")
func sync_player_choice(player_id: int, choice: String):
	"""Synchronizuje volbu hráče"""
	print("Přijata volba od hráče ", player_id, ": ", choice)
	if game_scene_ref:
		game_scene_ref.receive_player_choice(player_id, choice)

@rpc("any_peer", "call_local", "reliable") 
func sync_player_ready(player_id: int, ready: bool):
	"""Synchronizuje ready stav hráče"""
	print("Aktualizace ready stavu hráče ", player_id, ": ", ready)
	if player_id in connected_peers:
		connected_peers[player_id]["ready"] = ready
	
	if main_menu_ref:
		main_menu_ref.update_player_ready_status(player_id, ready)

@rpc("authority", "call_local", "reliable")
func start_game():
	"""Host spustí hru pro všechny hráče"""
	print("Spouštím hru pro všechny hráče!")
	get_tree().change_scene_to_file("res://scenes/GameScene.tscn")

# NOVÉ RPC FUNKCE PRO SYNCHRONIZACI KOLA
@rpc("authority", "call_local", "reliable")
func sync_round_start(round_number: int):
	"""Synchronizuje začátek kola"""
	print("Synchronizuji začátek kola: ", round_number)
	if game_scene_ref:
		game_scene_ref.sync_start_new_round(round_number)

@rpc("authority", "call_local", "reliable")
func sync_countdown_phase(countdown_time: float):
	"""Synchronizuje countdown fázi"""
	print("Synchronizuji countdown: ", countdown_time)
	if game_scene_ref:
		game_scene_ref.sync_countdown_phase(countdown_time)

@rpc("authority", "call_local", "reliable")
func sync_choice_phase(choice_time: float):
	"""Synchronizuje fázi výběru"""
	print("Synchronizuji fázi výběru: ", choice_time)
	if game_scene_ref:
		game_scene_ref.sync_choice_phase(choice_time)

@rpc("authority", "call_local", "reliable") 
func sync_round_end(winner_id: int, results: Dictionary):
	"""Synchronizuje konec kola"""
	print("Synchronizuji konec kola, výherce: ", winner_id)
	if game_scene_ref:
		game_scene_ref.sync_round_end(winner_id, results)

# ========================================
# UTILITY FUNKCE
# ========================================

func get_connected_players() -> Array:
	"""Vrátí seznam připojených hráčů"""
	var players = []
	for peer_id in connected_peers:
		players.append(connected_peers[peer_id])
	return players

func get_player_count() -> int:
	"""Vrátí počet připojených hráčů"""
	return connected_peers.size() + 1

func is_all_players_ready() -> bool:
	"""Zkontroluje jestli jsou všichni hráči připraveni"""
	for peer_id in connected_peers:
		if not connected_peers[peer_id]["ready"]:
			return false
	return true

func send_player_choice(choice: String):
	"""Pošle volbu hráče všem ostatním"""
	print("Posílám volbu: ", choice)
	sync_player_choice.rpc(local_player_id, choice)

func set_player_ready(ready: bool):
	"""Nastaví ready stav lokálního hráče"""
	print("Nastavuji ready stav: ", ready)
	sync_player_ready.rpc(local_player_id, ready)

# NOVÉ FUNKCE PRO SYNCHRONIZACI
func start_round_for_all():
	"""Host spustí kolo pro všechny hráče"""
	if is_host and game_scene_ref:
		var round_num = game_scene_ref.current_round
		sync_round_start.rpc(round_num)

func start_countdown_for_all(time: float):
	"""Host spustí countdown pro všechny"""
	if is_host:
		sync_countdown_phase.rpc(time)

func start_choice_phase_for_all(time: float):
	"""Host spustí fázi výběru pro všechny"""
	if is_host:
		sync_choice_phase.rpc(time)

func end_round_for_all(winner_id: int, results: Dictionary):
	"""Host ukončí kolo pro všechny"""
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
		return "Vy"
	elif player_id in connected_peers:
		return connected_peers[player_id]["name"]
	else:
		return "Neznámý hráč"
