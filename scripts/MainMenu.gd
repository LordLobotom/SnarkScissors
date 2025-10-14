# MainMenu.gd
# Orchestrates the landing experience and multiplayer lobby flow
extends Control

const PLAYER_ITEM_SCENE := preload("res://scenes/UI/PlayerListItem.tscn")

# Panels
@onready var connection_panel: Panel = $MainMargin/MainVBox/Content/InteractionPanel/InteractionMargin/InteractionStack/ConnectionPanel
@onready var lobby_panel: Panel = $MainMargin/MainVBox/Content/InteractionPanel/InteractionMargin/InteractionStack/LobbyPanel

# Connection UI
@onready var connection_status_label: Label = $MainMargin/MainVBox/Content/InteractionPanel/InteractionMargin/InteractionStack/ConnectionPanel/ConnectionMargin/ConnectionVBox/ConnectionStatusLabel
@onready var host_button: Button = $MainMargin/MainVBox/Content/InteractionPanel/InteractionMargin/InteractionStack/ConnectionPanel/ConnectionMargin/ConnectionVBox/ConnectionButtons/HostButton
@onready var join_button: Button = $MainMargin/MainVBox/Content/InteractionPanel/InteractionMargin/InteractionStack/ConnectionPanel/ConnectionMargin/ConnectionVBox/ConnectionButtons/JoinButton
@onready var ip_input: LineEdit = $MainMargin/MainVBox/Content/InteractionPanel/InteractionMargin/InteractionStack/ConnectionPanel/ConnectionMargin/ConnectionVBox/FormGrid/IPInput
@onready var port_input: SpinBox = $MainMargin/MainVBox/Content/InteractionPanel/InteractionMargin/InteractionStack/ConnectionPanel/ConnectionMargin/ConnectionVBox/FormGrid/PortInput

# Lobby UI
@onready var lobby_status: Label = $MainMargin/MainVBox/Content/InteractionPanel/InteractionMargin/InteractionStack/LobbyPanel/LobbyMargin/LobbyVBox/LobbyStatusLabel
@onready var players_list: VBoxContainer = $MainMargin/MainVBox/Content/InteractionPanel/InteractionMargin/InteractionStack/LobbyPanel/LobbyMargin/LobbyVBox/PlayersFrame/PlayersMargin/PlayersScroll/PlayersList
@onready var ready_button: Button = $MainMargin/MainVBox/Content/InteractionPanel/InteractionMargin/InteractionStack/LobbyPanel/LobbyMargin/LobbyVBox/ButtonsContainer/ReadyButton
@onready var start_button: Button = $MainMargin/MainVBox/Content/InteractionPanel/InteractionMargin/InteractionStack/LobbyPanel/LobbyMargin/LobbyVBox/ButtonsContainer/StartButton
@onready var disconnect_button: Button = $MainMargin/MainVBox/Content/InteractionPanel/InteractionMargin/InteractionStack/LobbyPanel/LobbyMargin/LobbyVBox/ButtonsContainer/DisconnectButton

# Primary actions
@onready var multiplayer_btn: Button = $MainMargin/MainVBox/Content/HeroPanel/HeroMargin/HeroVBox/ActionButtons/MultiplayerButton
@onready var settings_btn: Button = $MainMargin/MainVBox/Header/HeaderButtons/SettingsButton
@onready var quit_btn: Button = $MainMargin/MainVBox/Footer/QuitButton
@onready var back_btn: Button = $MainMargin/MainVBox/Footer/BackButton
@onready var next_btn: Button = $MainMargin/MainVBox/Footer/NextButton

var current_panel := "connection"
var is_ready := false
var player_items: Dictionary = {}

func _ready():
	NetworkManager.main_menu_ref = self
	_connect_ui_signals()
	_connect_network_signals()
	port_input.value = NetworkManager.DEFAULT_PORT
	ip_input.text = "127.0.0.1"
	ready_button.text = "Ready Up"
	show_connection_panel()

func _connect_ui_signals():
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	ready_button.pressed.connect(_on_ready_pressed)
	start_button.pressed.connect(_on_start_pressed)
	disconnect_button.pressed.connect(_on_disconnect_pressed)
	multiplayer_btn.pressed.connect(_on_multiplayer_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	back_btn.pressed.connect(_on_back_pressed)
	next_btn.pressed.connect(_on_next_pressed)

func _connect_network_signals():
	NetworkManager.connection_established.connect(_on_connection_established)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	NetworkManager.server_created.connect(_on_server_created)
	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)

# ========================================
# UI MANAGEMENT
# ========================================

func show_connection_panel():
	current_panel = "connection"
	connection_panel.visible = true
	lobby_panel.visible = false
	connection_status_label.text = "Ready to connect"
	back_btn.visible = false
	next_btn.visible = false
	is_ready = false
	ready_button.text = "Ready Up"

func show_lobby_panel():
	current_panel = "lobby"
	connection_panel.visible = false
	lobby_panel.visible = true
	start_button.visible = NetworkManager.is_host
	start_button.disabled = true
	back_btn.visible = true
	next_btn.visible = false
	update_lobby_status()
	refresh_players_list()

func update_lobby_status():
	var role = "Host" if NetworkManager.is_host else "Guest"
	var player_count = NetworkManager.get_player_count()
	lobby_status.text = role + " • Players: " + str(player_count) + "/2"

func refresh_players_list():
	for item in player_items.values():
		if is_instance_valid(item):
			item.queue_free()
	player_items.clear()

	add_player_to_list(NetworkManager.local_player_id, "You", is_ready)

	for player in NetworkManager.get_connected_players():
		add_player_to_list(player.id, player.name, player.ready)

func add_player_to_list(player_id: int, player_name: String, ready: bool):
	var player_item: Control = PLAYER_ITEM_SCENE.instantiate()
	players_list.add_child(player_item)
	player_item.setup(player_id, player_name, ready)
	player_items[player_id] = player_item

func update_player_ready_status(player_id: int, ready: bool):
	if player_id in player_items and is_instance_valid(player_items[player_id]):
		player_items[player_id].update_status(ready)

	if NetworkManager.is_host:
		var can_start = NetworkManager.is_all_players_ready() and NetworkManager.get_player_count() >= 2
		start_button.disabled = not can_start

# ========================================
# BUTTON HANDLERS
# ========================================

func _on_host_pressed():
	connection_status_label.text = "Starting lobby..."
	host_button.disabled = true
	join_button.disabled = true

	var port = int(port_input.value)
	var success = NetworkManager.create_server(port)

	if not success:
		connection_status_label.text = "Failed to create lobby."
		host_button.disabled = false
		join_button.disabled = false

func _on_join_pressed():
	connection_status_label.text = "Connecting..."
	host_button.disabled = true
	join_button.disabled = true

	var ip = ip_input.text
	var port = int(port_input.value)
	var success = NetworkManager.join_server(ip, port)

	if not success:
		connection_status_label.text = "Failed to connect."
		host_button.disabled = false
		join_button.disabled = false

func _on_ready_pressed():
	is_ready = not is_ready
	ready_button.text = "Cancel Ready" if is_ready else "Ready Up"
	NetworkManager.set_player_ready(is_ready)
	update_player_ready_status(NetworkManager.local_player_id, is_ready)

func _on_start_pressed():
	if NetworkManager.is_host and NetworkManager.is_all_players_ready():
		NetworkManager.start_game.rpc()

func _on_disconnect_pressed():
	NetworkManager.disconnect_from_server()
	show_connection_panel()

func _on_multiplayer_pressed():
	show_connection_panel()

func _on_settings_pressed():
	print("Settings panel is not wired up yet.")

func _on_quit_pressed():
	get_tree().quit()

func _on_back_pressed():
	if current_panel == "lobby":
		NetworkManager.disconnect_from_server()
		show_connection_panel()

func _on_next_pressed():
	pass

# ========================================
# NETWORK EVENT HANDLERS
# ========================================

func _on_connection_established():
	connection_status_label.text = "Connected!"
	await get_tree().process_frame
	show_lobby_panel()

func _on_connection_failed():
	connection_status_label.text = "Connection failed."
	host_button.disabled = false
	join_button.disabled = false

func _on_server_created():
	connection_status_label.text = "Lobby created. Waiting for players..."
	await get_tree().process_frame
	show_lobby_panel()

func _on_player_connected(peer_id: int):
	print("Player joined lobby: ", peer_id)
	update_lobby_status()
	refresh_players_list()

func _on_player_disconnected(peer_id: int):
	print("Player left lobby: ", peer_id)
	update_lobby_status()
	refresh_players_list()
	if NetworkManager.is_host:
		start_button.disabled = true
