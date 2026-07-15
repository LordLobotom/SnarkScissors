extends Control

const PLAYER_ITEM_SCENE := preload("res://scenes/UI/PlayerListItem.tscn")

@onready var connection_panel: Control = $SafeMargin/Layout/Body/SessionPanel/SessionMargin/SessionStack/ConnectionPanel
@onready var lobby_panel: Control = $SafeMargin/Layout/Body/SessionPanel/SessionMargin/SessionStack/LobbyPanel
@onready var connection_status_label: Label = $SafeMargin/Layout/Body/SessionPanel/SessionMargin/SessionStack/ConnectionPanel/ConnectionStatusLabel
@onready var host_button: Button = $SafeMargin/Layout/Body/SessionPanel/SessionMargin/SessionStack/ConnectionPanel/ConnectionButtons/HostButton
@onready var join_button: Button = $SafeMargin/Layout/Body/SessionPanel/SessionMargin/SessionStack/ConnectionPanel/ConnectionButtons/JoinButton
@onready var ip_input: LineEdit = $SafeMargin/Layout/Body/SessionPanel/SessionMargin/SessionStack/ConnectionPanel/IPInput
@onready var port_input: SpinBox = $SafeMargin/Layout/Body/SessionPanel/SessionMargin/SessionStack/ConnectionPanel/PortRow/PortInput
@onready var lobby_status: Label = $SafeMargin/Layout/Body/SessionPanel/SessionMargin/SessionStack/LobbyPanel/LobbyHeader/LobbyStatusLabel
@onready var players_list: VBoxContainer = $SafeMargin/Layout/Body/SessionPanel/SessionMargin/SessionStack/LobbyPanel/PlayersScroll/PlayersList
@onready var ready_button: Button = $SafeMargin/Layout/Body/SessionPanel/SessionMargin/SessionStack/LobbyPanel/ButtonsContainer/ReadyButton
@onready var start_button: Button = $SafeMargin/Layout/Body/SessionPanel/SessionMargin/SessionStack/LobbyPanel/ButtonsContainer/StartButton
@onready var disconnect_button: Button = $SafeMargin/Layout/Body/SessionPanel/SessionMargin/SessionStack/LobbyPanel/DisconnectButton
@onready var settings_button: Button = $SafeMargin/Layout/TopBar/SettingsButton
@onready var quit_button: Button = $SafeMargin/Layout/Footer/QuitButton
@onready var settings_overlay: Control = $SettingsOverlay

var is_ready := false
var player_items: Dictionary = {}


func _ready() -> void:
	NetworkManager.main_menu_ref = self
	_connect_ui_signals()
	_connect_network_signals()
	port_input.value = NetworkManager.DEFAULT_PORT
	ip_input.text = "127.0.0.1"
	if NetworkManager.is_connected:
		NetworkManager.set_player_ready(false)
		show_lobby_panel()
	else:
		show_connection_panel()


func _exit_tree() -> void:
	if NetworkManager.main_menu_ref == self:
		NetworkManager.main_menu_ref = null


func _connect_ui_signals() -> void:
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	ready_button.pressed.connect(_on_ready_pressed)
	start_button.pressed.connect(_on_start_pressed)
	disconnect_button.pressed.connect(_on_disconnect_pressed)
	settings_button.pressed.connect(settings_overlay.open)
	quit_button.pressed.connect(_on_quit_pressed)


func _connect_network_signals() -> void:
	NetworkManager.connection_established.connect(_on_connection_established)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	NetworkManager.server_created.connect(_on_server_created)
	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)


func show_connection_panel() -> void:
	connection_panel.visible = true
	lobby_panel.visible = false
	connection_status_label.text = "Ready for a direct connection."
	connection_status_label.remove_theme_color_override("font_color")
	host_button.disabled = false
	join_button.disabled = false
	is_ready = false
	ready_button.text = "Ready up"


func show_lobby_panel() -> void:
	connection_panel.visible = false
	lobby_panel.visible = true
	start_button.visible = NetworkManager.is_host
	start_button.disabled = true
	update_lobby_status()
	refresh_players_list()


func update_lobby_status() -> void:
	var role := "HOST" if NetworkManager.is_host else "GUEST"
	lobby_status.text = "%s  //  %d OF 2" % [role, NetworkManager.get_player_count()]


func refresh_players_list() -> void:
	for item in player_items.values():
		if is_instance_valid(item):
			item.queue_free()
	player_items.clear()

	add_player_to_list(NetworkManager.local_player_id, "You", is_ready)
	for player in NetworkManager.get_connected_players():
		add_player_to_list(player.id, player.name, player.ready)


func add_player_to_list(player_id: int, player_name: String, player_ready: bool) -> void:
	var player_item: Control = PLAYER_ITEM_SCENE.instantiate()
	players_list.add_child(player_item)
	player_item.setup(player_id, player_name, player_ready)
	player_items[player_id] = player_item


func update_player_ready_status(player_id: int, player_ready: bool) -> void:
	if player_id in player_items and is_instance_valid(player_items[player_id]):
		player_items[player_id].update_status(player_ready)

	if NetworkManager.is_host:
		var can_start := (
			is_ready
			and NetworkManager.is_all_players_ready()
			and NetworkManager.get_player_count() >= 2
		)
		start_button.disabled = not can_start


func _on_host_pressed() -> void:
	_set_connecting_state("Opening lobby...")
	AudioManager.play_sfx(&"connect")
	if not NetworkManager.create_server(int(port_input.value)):
		_show_connection_error("Could not open that port.")


func _on_join_pressed() -> void:
	var address := ip_input.text.strip_edges()
	if address.is_empty():
		_show_connection_error("Enter a host address first.")
		return

	_set_connecting_state("Contacting host...")
	AudioManager.play_sfx(&"connect")
	if not NetworkManager.join_server(address, int(port_input.value)):
		_show_connection_error("Could not start the connection.")


func _on_ready_pressed() -> void:
	is_ready = not is_ready
	ready_button.text = "Cancel ready" if is_ready else "Ready up"
	NetworkManager.set_player_ready(is_ready)
	update_player_ready_status(NetworkManager.local_player_id, is_ready)
	AudioManager.play_sfx(&"ready" if is_ready else &"ui")


func _on_start_pressed() -> void:
	if NetworkManager.is_host and NetworkManager.is_all_players_ready():
		AudioManager.play_sfx(&"start")
		NetworkManager.start_game.rpc()


func _on_disconnect_pressed() -> void:
	AudioManager.play_sfx(&"disconnect")
	NetworkManager.disconnect_from_server()


func _on_quit_pressed() -> void:
	AudioManager.play_sfx(&"ui")
	AudioManager.stop_all()
	get_tree().quit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		AudioManager.stop_all()
		get_tree().quit()


func _set_connecting_state(message: String) -> void:
	connection_status_label.text = message
	connection_status_label.add_theme_color_override("font_color", Color("f2c14e"))
	host_button.disabled = true
	join_button.disabled = true


func _show_connection_error(message: String) -> void:
	connection_status_label.text = message
	connection_status_label.add_theme_color_override("font_color", Color("f15b4f"))
	host_button.disabled = false
	join_button.disabled = false
	AudioManager.play_sfx(&"lose")


func _on_connection_established() -> void:
	AudioManager.play_sfx(&"ready")
	await get_tree().process_frame
	show_lobby_panel()


func _on_connection_failed() -> void:
	_show_connection_error("Host did not answer. Check the IP and port.")


func _on_server_created() -> void:
	await get_tree().process_frame
	show_lobby_panel()


func _on_player_connected(peer_id: int) -> void:
	print("Player joined lobby: ", peer_id)
	AudioManager.play_sfx(&"connect")
	update_lobby_status()
	refresh_players_list()


func _on_player_disconnected(peer_id: int) -> void:
	print("Player left lobby: ", peer_id)
	AudioManager.play_sfx(&"disconnect")
	update_lobby_status()
	refresh_players_list()
	if NetworkManager.is_host:
		start_button.disabled = true
