# MainMenu.gd
# Hlavní menu s multiplayer funkcionalitou
extends Control

# UI Reference
@onready var left_menu: VBoxContainer = $LeftMenu
@onready var bottom_bar: HBoxContainer = $BottomBar
@onready var main_window: Panel = $MainWindow

# Menu states
@onready var connection_panel: Panel = $MainWindow/ConnectionPanel
@onready var lobby_panel: Panel = $MainWindow/LobbyPanel

# Connection Panel UI
@onready var host_button: Button = $MainWindow/ConnectionPanel/VBox/HostButton
@onready var join_button: Button = $MainWindow/ConnectionPanel/VBox/JoinButton
@onready var ip_input: LineEdit = $MainWindow/ConnectionPanel/VBox/IPContainer/IPInput
@onready var port_input: SpinBox = $MainWindow/ConnectionPanel/VBox/PortContainer/PortInput

# Lobby Panel UI
@onready var players_list: VBoxContainer = $MainWindow/LobbyPanel/VBox/PlayersContainer/PlayersList
@onready var ready_button: Button = $MainWindow/LobbyPanel/VBox/ButtonsContainer/ReadyButton
@onready var start_button: Button = $MainWindow/LobbyPanel/VBox/ButtonsContainer/StartButton
@onready var disconnect_button: Button = $MainWindow/LobbyPanel/VBox/ButtonsContainer/DisconnectButton
@onready var lobby_status: Label = $MainWindow/LobbyPanel/VBox/LobbyStatusLabel

# Left Menu Buttons
@onready var multiplayer_btn: Button = $LeftMenu/MultiplayerButton
@onready var settings_btn: Button = $LeftMenu/SettingsButton
@onready var quit_btn: Button = $LeftMenu/QuitButton

# Bottom Bar Buttons
@onready var back_btn: Button = $BottomBar/BackButton
@onready var next_btn: Button = $BottomBar/NextButton

# Stav
var current_panel: String = "connection"
var is_ready: bool = false
var player_items: Dictionary = {}
var connection_status_label: Label

func _ready():
	# Vytvořit status label pro connection panel
	connection_status_label = Label.new()
	connection_status_label.text = "Připraveno k připojení"
	connection_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	$MainWindow/ConnectionPanel/VBox.add_child(connection_status_label)
	
	# Nastavit NetworkManager referenci
	NetworkManager.main_menu_ref = self
	
	# Připojit signály
	_connect_ui_signals()
	_connect_network_signals()
	
	# Nastavit výchozí hodnoty
	port_input.value = NetworkManager.DEFAULT_PORT
	ip_input.text = "127.0.0.1"
	
	# Zobrazit connection panel
	show_connection_panel()

func _connect_ui_signals():
	"""Připojí všechny UI signály"""
	# Connection Panel
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	
	# Lobby Panel  
	ready_button.pressed.connect(_on_ready_pressed)
	start_button.pressed.connect(_on_start_pressed)
	disconnect_button.pressed.connect(_on_disconnect_pressed)
	
	# Left Menu
	multiplayer_btn.pressed.connect(_on_multiplayer_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	
	# Bottom Bar
	back_btn.pressed.connect(_on_back_pressed)
	next_btn.pressed.connect(_on_next_pressed)

func _connect_network_signals():
	"""Připojí network signály"""
	NetworkManager.connection_established.connect(_on_connection_established)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	NetworkManager.server_created.connect(_on_server_created)
	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)

# ========================================
# UI MANAGEMENT
# ========================================

func show_connection_panel():
	"""Zobrazí panel pro připojení"""
	current_panel = "connection"
	connection_panel.visible = true
	lobby_panel.visible = false
	
	connection_status_label.text = "Připraveno k připojení"
	back_btn.visible = false
	next_btn.visible = false

func show_lobby_panel():
	"""Zobrazí lobby panel"""
	current_panel = "lobby" 
	connection_panel.visible = false
	lobby_panel.visible = true
	
	# Skrýt start button pokud není host
	start_button.visible = NetworkManager.is_host
	
	back_btn.visible = true
	next_btn.visible = false
	
	update_lobby_status()
	refresh_players_list()

func update_lobby_status():
	"""Aktualizuje status v lobby"""
	var role = "Host" if NetworkManager.is_host else "Klient"
	var player_count = NetworkManager.get_player_count()
	lobby_status.text = role + " | Hráči: " + str(player_count) + "/2"

func refresh_players_list():
	"""Obnoví seznam hráčů v lobby"""
	# Vyčistit existující položky
	for item in player_items.values():
		if is_instance_valid(item):
			item.queue_free()
	player_items.clear()
	
	# Přidat lokálního hráče
	add_player_to_list(NetworkManager.local_player_id, "Vy", is_ready)
	
	# Přidat ostatní hráče
	for player in NetworkManager.get_connected_players():
		add_player_to_list(player.id, player.name, player.ready)

func add_player_to_list(player_id: int, player_name: String, ready: bool):
	"""Přidá hráče do seznamu"""
	var player_item = preload("res://scenes/UI/PlayerListItem.tscn").instantiate()
	
	player_item.get_node("HBox/NameLabel").text = player_name
	player_item.get_node("HBox/StatusLabel").text = "Připraven" if ready else "Nepřipraven"
	player_item.get_node("HBox/StatusLabel").modulate = Color.GREEN if ready else Color.RED
	
	players_list.add_child(player_item)
	player_items[player_id] = player_item

func update_player_ready_status(player_id: int, ready: bool):
	"""Aktualizuje ready status hráče"""
	if player_id in player_items and is_instance_valid(player_items[player_id]):
		var status_label = player_items[player_id].get_node("HBox/StatusLabel")
		status_label.text = "Připraven" if ready else "Nepřipraven"
		status_label.modulate = Color.GREEN if ready else Color.RED
	
	# Aktualizovat start button pro hosta
	if NetworkManager.is_host:
		var can_start = NetworkManager.is_all_players_ready() and NetworkManager.get_player_count() >= 2
		start_button.disabled = not can_start

# ========================================
# BUTTON HANDLERS
# ========================================

func _on_host_pressed():
	"""Handler pro Host button"""
	connection_status_label.text = "Vytvářím server..."
	host_button.disabled = true
	join_button.disabled = true
	
	var port = int(port_input.value)
	var success = NetworkManager.create_server(port)
	
	if not success:
		connection_status_label.text = "Chyba při vytváření serveru!"
		host_button.disabled = false
		join_button.disabled = false

func _on_join_pressed():
	"""Handler pro Join button"""
	connection_status_label.text = "Připojuji se..."
	host_button.disabled = true
	join_button.disabled = true
	
	var ip = ip_input.text
	var port = int(port_input.value)
	var success = NetworkManager.join_server(ip, port)
	
	if not success:
		connection_status_label.text = "Chyba při připojování!"
		host_button.disabled = false
		join_button.disabled = false

func _on_ready_pressed():
	"""Handler pro Ready button"""
	is_ready = not is_ready
	ready_button.text = "Zrušit připravenost" if is_ready else "Připraven"
	NetworkManager.set_player_ready(is_ready)
	
	# Aktualizovat lokální zobrazení
	update_player_ready_status(NetworkManager.local_player_id, is_ready)

func _on_start_pressed():
	"""Handler pro Start button (pouze host)"""
	if NetworkManager.is_host and NetworkManager.is_all_players_ready():
		NetworkManager.start_game.rpc()

func _on_disconnect_pressed():
	"""Handler pro Disconnect button"""
	NetworkManager.disconnect_from_server()
	show_connection_panel()

func _on_multiplayer_pressed():
	"""Handler pro Multiplayer button v levém menu"""
	show_connection_panel()

func _on_settings_pressed():
	"""Handler pro Settings button"""
	# TODO: Implementovat settings panel
	print("Settings - TODO")

func _on_quit_pressed():
	"""Handler pro Quit button"""
	get_tree().quit()

func _on_back_pressed():
	"""Handler pro Back button"""
	if current_panel == "lobby":
		NetworkManager.disconnect_from_server()
		show_connection_panel()

func _on_next_pressed():
	"""Handler pro Next button"""
	# TODO: Implementovat podle potřeby
	pass

# ========================================
# NETWORK EVENT HANDLERS
# ========================================

func _on_connection_established():
	"""Volá se když klient úspěšně připojí"""
	connection_status_label.text = "Připojeno k serveru!"
	await get_tree().process_frame
	show_lobby_panel()

func _on_connection_failed():
	"""Volá se když připojení selže"""
	connection_status_label.text = "Připojení selhalo!"
	host_button.disabled = false
	join_button.disabled = false

func _on_server_created():
	"""Volá se když je server úspěšně vytvořen"""
	connection_status_label.text = "Server vytvořen! Čekání na hráče..."
	await get_tree().process_frame
	show_lobby_panel()

func _on_player_connected(peer_id: int):
	"""Volá se když se připojí nový hráč"""
	print("Nový hráč připojen: ", peer_id)
	update_lobby_status()
	refresh_players_list()

func _on_player_disconnected(peer_id: int):
	"""Volá se když se hráč odpojí"""
	print("Hráč se odpojil: ", peer_id)
	update_lobby_status()
	refresh_players_list()
	
	# Pokud jsme v lobby a hráč se odpojil, zakázat start
	if NetworkManager.is_host:
		start_button.disabled = true
