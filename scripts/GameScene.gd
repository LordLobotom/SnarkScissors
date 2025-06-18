# GameScene.gd
# Hlavní herní scéna pro multiplayer RPS
extends Control

# UI Reference
@onready var left_menu: VBoxContainer = $LeftMenu
@onready var bottom_bar: HBoxContainer = $BottomBar
@onready var main_window: Panel = $MainWindow

# Game UI
@onready var game_panel: Panel = $MainWindow/GamePanel
@onready var countdown_label: Label = $MainWindow/GamePanel/VBox/CountdownLabel
@onready var round_info: Label = $MainWindow/GamePanel/VBox/RoundInfoLabel
@onready var choices_container: HBoxContainer = $MainWindow/GamePanel/VBox/ChoicesContainer

# Choice Buttons
@onready var rock_btn: Button = $MainWindow/GamePanel/VBox/ChoicesContainer/RockButton
@onready var paper_btn: Button = $MainWindow/GamePanel/VBox/ChoicesContainer/PaperButton
@onready var scissors_btn: Button = $MainWindow/GamePanel/VBox/ChoicesContainer/ScissorsButton

# Result Display
@onready var result_panel: Panel = $MainWindow/GamePanel/VBox/ResultPanel
@onready var result_label: Label = $MainWindow/GamePanel/VBox/ResultPanel/VBox/ResultLabel
@onready var players_choices: VBoxContainer = $MainWindow/GamePanel/VBox/ResultPanel/VBox/PlayersChoices
@onready var next_round_btn: Button = $MainWindow/GamePanel/VBox/ResultPanel/VBox/NextRoundButton

# Score Display
@onready var score_panel: Panel = $MainWindow/GamePanel/VBox/ScorePanel
@onready var score_label: Label = $MainWindow/GamePanel/VBox/ScorePanel/ScoreLabel

# Left Menu
@onready var back_to_lobby_btn: Button = $LeftMenu/BackToLobbyButton
@onready var settings_btn: Button = $LeftMenu/SettingsButton

# Bottom Bar
@onready var disconnect_btn: Button = $BottomBar/DisconnectButton

# Game State
var current_round: int = 1
var max_rounds: int = 5
var player_scores: Dictionary = {}
var player_choices: Dictionary = {}
var local_choice: String = ""
var round_active: bool = false
var countdown_time: float = 0.0
var countdown_timer: Timer

# Constants
const CHOICE_TIME = 10.0  # Čas na výběr v sekundách
const COUNTDOWN_TIME = 3.0  # Odpočítávání před kolen

enum Choice {
	ROCK,
	PAPER, 
	SCISSORS
}

func _ready():
	# Nastavit NetworkManager referenci
	NetworkManager.game_scene_ref = self
	
	# Připojit signály
	_connect_ui_signals()
	_connect_network_signals()
	
	# Inicializovat scores
	_initialize_scores()
	
	# Vytvořit timer pro countdown
	countdown_timer = Timer.new()
	countdown_timer.wait_time = 1.0
	countdown_timer.timeout.connect(_on_countdown_tick)
	add_child(countdown_timer)
	
	# Skrýt result panel
	result_panel.visible = false
	
	# Spustit první kolo
	if NetworkManager.is_host:
		call_deferred("start_new_round")

func _connect_ui_signals():
	"""Připojí UI signály"""
	rock_btn.pressed.connect(func(): _on_choice_selected("rock"))
	paper_btn.pressed.connect(func(): _on_choice_selected("paper"))
	scissors_btn.pressed.connect(func(): _on_choice_selected("scissors"))
	
	next_round_btn.pressed.connect(_on_next_round_pressed)
	back_to_lobby_btn.pressed.connect(_on_back_to_lobby_pressed)
	disconnect_btn.pressed.connect(_on_disconnect_pressed)

func _connect_network_signals():
	"""Připojí network signály"""
	NetworkManager.player_disconnected.connect(_on_player_disconnected)

func _initialize_scores():
	"""Inicializuje skóre pro všechny hráče"""
	player_scores[NetworkManager.local_player_id] = 0
	
	for player in NetworkManager.get_connected_players():
		player_scores[player.id] = 0
	
	_update_score_display()

# ========================================
# GAME FLOW
# ========================================

func start_new_round():
	"""Spustí nové kolo"""
	print("Spouštím kolo ", current_round)
	
	# Reset stavu
	player_choices.clear()
	local_choice = ""
	round_active = false
	result_panel.visible = false
	
	# Aktualizovat UI
	round_info.text = "Kolo " + str(current_round) + " z " + str(max_rounds)
	countdown_label.text = "Připravte se..."
	
	# Zakázat tlačítka
	_set_choice_buttons_enabled(false)
	
	# Spustit countdown
	countdown_time = COUNTDOWN_TIME
	countdown_timer.start()
	countdown_label.visible = true

func _on_countdown_tick():
	"""Handler pro countdown timer"""
	countdown_time -= 1.0
	
	if countdown_time > 0:
		countdown_label.text = str(int(countdown_time))
	else:
		countdown_timer.stop()
		_start_choice_phase()

func _start_choice_phase():
	"""Spustí fázi výběru"""
	print("Spouštím fázi výběru")
	
	countdown_label.text = "Vyberte svoji volbu!"
	round_active = true
	
	# Povolit tlačítka
	_set_choice_buttons_enabled(true)
	
	# Spustit timer pro výběr
	countdown_time = CHOICE_TIME
	countdown_timer.start()

func _on_choice_selected(choice: String):
	"""Handler pro výběr volby hráčem"""
	if not round_active or local_choice != "":
		return
	
	print("Hráč vybral: ", choice)
	local_choice = choice
	
	# Zakázat tlačítka
	_set_choice_buttons_enabled(false)
	
	# Poslat volbu ostatním hráčům
	NetworkManager.send_player_choice(choice)
	
	# Aktualizovat UI
	countdown_label.text = "Čekáme na ostatní hráče..."

func receive_player_choice(player_id: int, choice: String):
	"""Přijme volbu od hráče"""
	print("Přijal volbu od hráče ", player_id, ": ", choice)
	player_choices[player_id] = choice
	
	# Zkontrolovat jestli všichni hráči volili
	if _all_players_chose():
		countdown_timer.stop()
		if NetworkManager.is_host:
			_evaluate_round()

func _all_players_chose() -> bool:
	"""Zkontroluje jestli všichni hráči udělali volbu"""
	var total_players = NetworkManager.get_player_count()
	return player_choices.size() == total_players

func _evaluate_round():
	"""Vyhodnotí kolo (pouze host)"""
	if not NetworkManager.is_host:
		return
	
	print("Vyhodnocuji kolo...")
	
	# Určit výsledky
	var results = _calculate_results()
	var winner_id = results.winner_id
	
	# Aktualizovat skóre
	if winner_id != -1:
		player_scores[winner_id] += 1
	
	# Poslat výsledky všem hráčům
	NetworkManager.end_round.rpc(winner_id, results)

func _calculate_results() -> Dictionary:
	"""Vypočítá výsledky kola"""
	var results = {
		"winner_id": -1,
		"winner_name": "Remíza",
		"choices": player_choices.duplicate()
	}
	
	# Pro 2 hráče RPS logika
	if player_choices.size() == 2:
		var players = player_choices.keys()
		var player1_id = players[0]
		var player2_id = players[1]
		var choice1 = player_choices[player1_id]
		var choice2 = player_choices[player2_id]
		
		var winner = _get_rps_winner(choice1, choice2)
		
		if winner == 1:
			results.winner_id = player1_id
			results.winner_name = _get_player_name(player1_id)
		elif winner == 2:
			results.winner_id = player2_id
			results.winner_name = _get_player_name(player2_id)
	
	return results

func _get_rps_winner(choice1: String, choice2: String) -> int:
	"""Vrátí výherce RPS (1 = první hráč, 2 = druhý hráč, 0 = remíza)"""
	if choice1 == choice2:
		return 0
	
	var winning_combinations = {
		"rock": "scissors",
		"paper": "rock", 
		"scissors": "paper"
	}
	
	if winning_combinations[choice1] == choice2:
		return 1
	else:
		return 2

func end_round(winner_id: int, results: Dictionary):
	"""Ukončí kolo s výsledky"""
	print("Ukončuji kolo, výherce: ", winner_id)
	
	round_active = false
	countdown_timer.stop()
	
	# Aktualizovat skóre
	if winner_id in player_scores:
		player_scores[winner_id] += 1
	
	# Zobrazit výsledky
	_show_round_results(winner_id, results)
	
	# Zkontrolovat konec hry
	if _is_game_finished():
		_show_game_results()
	else:
		current_round += 1

func _show_round_results(winner_id: int, results: Dictionary):
	"""Zobrazí výsledky kola"""
	countdown_label.visible = false
	result_panel.visible = true
	
	# Nastavit result text
	if winner_id == -1:
		result_label.text = "REMÍZA!"
		result_label.modulate = Color.YELLOW
	elif winner_id == NetworkManager.local_player_id:
		result_label.text = "VYHRÁLI JSTE!"
		result_label.modulate = Color.GREEN
	else:
		result_label.text = "PROHRÁLI JSTE!"
		result_label.modulate = Color.RED
	
	# Zobrazit volby hráčů
	_display_player_choices(results.choices)
	
	# Aktualizovat skóre
	_update_score_display()
	
	# Zobrazit next round button pouze pro hosta
	next_round_btn.visible = NetworkManager.is_host and not _is_game_finished()

func _display_player_choices(choices: Dictionary):
	"""Zobrazí volby všech hráčů"""
	# Vyčistit předchozí choices
	for child in players_choices.get_children():
		child.queue_free()
	
	# Přidat volby hráčů
	for player_id in choices:
		var choice_item = HBoxContainer.new()
		var name_label = Label.new()
		var choice_label = Label.new()
		var icon_label = Label.new()
		
		name_label.text = _get_player_name(player_id) + ": "
		choice_label.text = _get_choice_display_name(choices[player_id])
		icon_label.text = _get_choice_icon(choices[player_id])
		icon_label.add_theme_font_size_override("font_size", 24)
		
		choice_item.add_child(name_label)
		choice_item.add_child(choice_label)
		choice_item.add_child(icon_label)
		
		players_choices.add_child(choice_item)

func _is_game_finished() -> bool:
	"""Zkontroluje jestli je hra ukončená"""
	for score in player_scores.values():
		if score >= 3:  # První na 3 výhry
			return true
	return current_round > max_rounds

func _show_game_results():
	"""Zobrazí finální výsledky hry"""
	var winner_id = _get_game_winner()
	
	if winner_id == -1:
		result_label.text = "HRA SKONČILA REMÍZOU!"
		result_label.modulate = Color.YELLOW
	elif winner_id == NetworkManager.local_player_id:
		result_label.text = "VYHRÁLI JSTE HRU!"
		result_label.modulate = Color.GREEN
	else:
		result_label.text = "PROHRÁLI JSTE HRU!"
		result_label.modulate = Color.RED
	
	next_round_btn.visible = false

func _get_game_winner() -> int:
	"""Vrátí ID výherce hry"""
	var max_score = 0
	var winner_id = -1
	var tied = false
	
	for player_id in player_scores:
		if player_scores[player_id] > max_score:
			max_score = player_scores[player_id]
			winner_id = player_id
			tied = false
		elif player_scores[player_id] == max_score:
			tied = true
	
	return -1 if tied else winner_id

# ========================================
# UI HELPERS
# ========================================

func _set_choice_buttons_enabled(enabled: bool):
	"""Povolí/zakáže choice buttons"""
	rock_btn.disabled = not enabled
	paper_btn.disabled = not enabled
	scissors_btn.disabled = not enabled

func _update_score_display():
	"""Aktualizuje zobrazení skóre"""
	var score_text = "SKÓRE: "
	var score_parts = []
	
	for player_id in player_scores:
		var name = _get_player_name(player_id)
		var score = player_scores[player_id]
		score_parts.append(name + ": " + str(score))
	
	score_label.text = score_text + " | ".join(score_parts)

func _get_player_name(player_id: int) -> String:
	"""Vrátí jméno hráče"""
	if player_id == NetworkManager.local_player_id:
		return "Vy"
	else:
		return "Soupeř"

func _get_choice_display_name(choice: String) -> String:
	"""Vrátí zobrazované jméno volby"""
	match choice:
		"rock":
			return "Kámen"
		"paper":
			return "Papír"
		"scissors":
			return "Nůžky"
		_:
			return "Neznámé"

func _get_choice_icon(choice: String) -> String:
	"""Vrátí ikonu pro volbu"""
	match choice:
		"rock":
			return "🪨"
		"paper":
			return "📄"
		"scissors":
			return "✂️"
		_:
			return "❓"

# ========================================
# BUTTON HANDLERS
# ========================================

func _on_next_round_pressed():
	"""Handler pro Next Round button (pouze host)"""
	if NetworkManager.is_host:
		NetworkManager.start_round.rpc()

func _on_back_to_lobby_pressed():
	"""Handler pro Back to Lobby button"""
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_disconnect_pressed():
	"""Handler pro Disconnect button"""
	NetworkManager.disconnect_from_server()

# ========================================
# NETWORK EVENT HANDLERS
# ========================================

func _on_player_disconnected(peer_id: int):
	"""Handler pro odpojení hráče"""
	print("Hráč se odpojil během hry: ", peer_id)
	
	# Ukončit hru a vrátit se do lobby
	var notification = AcceptDialog.new()
	notification.dialog_text = "Soupeř se odpojil. Hra byla ukončena."
	add_child(notification)
	notification.popup_centered()
	notification.confirmed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))

# ========================================
# UTILITY
# ========================================

func _notification(what):
	"""Handler pro systémové notifikace"""
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		NetworkManager.disconnect_from_server()
		get_tree().quit()
