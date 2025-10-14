# GameScene.gd
# Multiplayer arena flow for the SnarkScissors duel
extends Control

# Header & controls
@onready var back_to_lobby_btn: Button = $MainMargin/MainVBox/HeaderBar/BackToLobbyButton
@onready var settings_btn: Button = $MainMargin/MainVBox/HeaderBar/HeaderButtons/SettingsButton
@onready var disconnect_btn: Button = $MainMargin/MainVBox/HeaderBar/HeaderButtons/DisconnectButton

# Round summary
@onready var round_info: Label = $MainMargin/MainVBox/RoundSummary/SummaryMargin/SummaryHBox/RoundInfoLabel
@onready var countdown_label: Label = $MainMargin/MainVBox/RoundSummary/SummaryMargin/SummaryHBox/CountdownLabel
@onready var countdown_headline: Label = $MainMargin/MainVBox/Arena/CenterStage/CenterMargin/CenterVBox/CountdownHeadline
@onready var choice_hint: Label = $MainMargin/MainVBox/Arena/CenterStage/CenterMargin/CenterVBox/ChoiceHint

# Choice buttons
@onready var choices_container: HBoxContainer = $MainMargin/MainVBox/Arena/CenterStage/CenterMargin/CenterVBox/ChoiceButtons
@onready var rock_btn: Button = $MainMargin/MainVBox/Arena/CenterStage/CenterMargin/CenterVBox/ChoiceButtons/RockButton
@onready var paper_btn: Button = $MainMargin/MainVBox/Arena/CenterStage/CenterMargin/CenterVBox/ChoiceButtons/PaperButton
@onready var scissors_btn: Button = $MainMargin/MainVBox/Arena/CenterStage/CenterMargin/CenterVBox/ChoiceButtons/ScissorsButton

# Player cards
@onready var player_name_label: Label = $MainMargin/MainVBox/Arena/PlayerCard/PlayerMargin/PlayerVBox/PlayerNameLabel
@onready var player_score_label: Label = $MainMargin/MainVBox/Arena/PlayerCard/PlayerMargin/PlayerVBox/PlayerScoreLabel
@onready var player_last_choice_label: Label = $MainMargin/MainVBox/Arena/PlayerCard/PlayerMargin/PlayerVBox/PlayerLastChoice

@onready var opponent_name_label: Label = $MainMargin/MainVBox/Arena/OpponentCard/OpponentMargin/OpponentVBox/OpponentNameLabel
@onready var opponent_score_label: Label = $MainMargin/MainVBox/Arena/OpponentCard/OpponentMargin/OpponentVBox/OpponentScoreLabel
@onready var opponent_last_choice_label: Label = $MainMargin/MainVBox/Arena/OpponentCard/OpponentMargin/OpponentVBox/OpponentLastChoice

# Score and results
@onready var score_label: Label = $MainMargin/MainVBox/ScoreBar/ScoreMargin/ScoreLabel
@onready var result_panel: Panel = $MainMargin/MainVBox/ResultsCard
@onready var result_label: Label = $MainMargin/MainVBox/ResultsCard/ResultMargin/ResultVBox/ResultLabel
@onready var players_choices: VBoxContainer = $MainMargin/MainVBox/ResultsCard/ResultMargin/ResultVBox/PlayersChoices
@onready var next_round_btn: Button = $MainMargin/MainVBox/ResultsCard/ResultMargin/ResultVBox/NextRoundButton

# Game State
var current_round: int = 1
var max_rounds: int = 5
var player_scores: Dictionary = {}
var player_choices: Dictionary = {}
var local_choice: String = ""
var round_active: bool = false
var countdown_time: float = 0.0
var countdown_timer: Timer
var game_phase: String = "waiting"  # waiting, countdown, choosing, results

# Constants
const CHOICE_TIME = 10.0
const COUNTDOWN_TIME = 3.0

func _ready():
	NetworkManager.game_scene_ref = self
	
	_connect_ui_signals()
	_connect_network_signals()
	_initialize_scores()
	
	# Create the countdown timer once
	countdown_timer = Timer.new()
	countdown_timer.wait_time = 1.0
	countdown_timer.timeout.connect(_on_countdown_tick)
	add_child(countdown_timer)

	result_panel.visible = false
	_set_choice_buttons_enabled(false)
	player_name_label.text = _get_player_name(NetworkManager.local_player_id)
	player_last_choice_label.text = "Last throw: —"
	opponent_last_choice_label.text = "Last throw: —"
	_refresh_opponent_card()

	# Only the host should kick off the opening round
	if NetworkManager.is_host:
		call_deferred("start_new_round")

func _connect_ui_signals():
	rock_btn.pressed.connect(func(): _on_choice_selected("rock"))
	paper_btn.pressed.connect(func(): _on_choice_selected("paper"))
	scissors_btn.pressed.connect(func(): _on_choice_selected("scissors"))
	
	next_round_btn.pressed.connect(_on_next_round_pressed)
	back_to_lobby_btn.pressed.connect(_on_back_to_lobby_pressed)
	disconnect_btn.pressed.connect(_on_disconnect_pressed)

func _connect_network_signals():
	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)

func _initialize_scores():
	player_scores[NetworkManager.local_player_id] = 0
	
	for player in NetworkManager.get_connected_players():
		player_scores[player.id] = 0
	
	_update_score_display()

# ========================================
# GAME FLOW - HOST-DRIVEN
# ========================================

func start_new_round():
	"""Starts a new round (host only)"""
	if not NetworkManager.is_host:
		return
	
	print("HOST: Starting round ", current_round)
	
	# Broadcast start to all peers
	NetworkManager.start_countdown_for_all(COUNTDOWN_TIME)
	player_choices.clear()

# ========================================
# SYNCED EVENTS FOR ALL PEERS
# ========================================

func sync_start_new_round(round_number: int):
	"""Syncs the start of a new round"""
	print("SYNC: Beginning round ", round_number)
	current_round = round_number
	_reset_round_state()

func sync_countdown_phase(countdown_time_param: float):
	"""Syncs the countdown phase"""
	print("SYNC: Countdown phase - ", countdown_time_param, "s")
	
	game_phase = "countdown"
	countdown_time = countdown_time_param
	
	# Reset UI
	result_panel.visible = false
	countdown_label.visible = true
	_set_choice_buttons_enabled(false)
	
	# Update copy for the countdown phase
	round_info.text = "Round " + str(current_round) + " of " + str(max_rounds)
	countdown_label.text = "Get ready..."
	countdown_headline.text = "Countdown"
	choice_hint.text = "Throws unlock once the countdown finishes."
	
	# Start the countdown ticking
	countdown_timer.start()

func sync_choice_phase(choice_time_param: float):
	"""Syncs the choice phase"""
	print("SYNC: Choice phase - ", choice_time_param, "s")
	
	game_phase = "choosing"
	countdown_time = choice_time_param
	round_active = true
	
	# Update copy for the choice phase
	countdown_label.text = "Lock in your throw!"
	countdown_headline.text = "Your move"
	choice_hint.text = "Rock beats scissors. Paper beats rock. Scissors beat paper."
	_set_choice_buttons_enabled(true)
	
	# Restart the timer for the choice duration
	countdown_timer.start()

func sync_round_end(winner_id: int, results: Dictionary):
	"""Syncs the end of the round"""
	print("SYNC: Round finished, winner: ", winner_id)
	
	game_phase = "results"
	round_active = false
	countdown_timer.stop()
	
	# Update score bookkeeping
	if winner_id in player_scores:
		player_scores[winner_id] += 1
	
	# Display results locally
	_show_round_results(winner_id, results)
	
	# Check if the match is over
	if _is_game_finished():
		_show_game_results()
	else:
		if NetworkManager.is_host:
			current_round += 1

func _reset_round_state():
	"""Resets transient round state"""
	player_choices.clear()
	local_choice = ""
	round_active = false
	game_phase = "waiting"

# ========================================
# TIMER A COUNTDOWN
# ========================================

func _on_countdown_tick():
	"""Handles countdown ticks on every peer"""
	countdown_time -= 1.0
	
	if game_phase == "countdown":
		if countdown_time > 0:
			countdown_label.text = str(int(countdown_time))
		else:
			countdown_timer.stop()
			# Host triggers choice phase for everyone
			if NetworkManager.is_host:
				NetworkManager.start_choice_phase_for_all(CHOICE_TIME)
	
	elif game_phase == "choosing":
		if countdown_time > 0:
			countdown_label.text = "Time left: " + str(int(countdown_time)) + "s"
		else:
			countdown_timer.stop()
			# Auto-pick when the player has not selected
			if local_choice == "":
				var choices = ["rock", "paper", "scissors"]
				local_choice = choices[randi() % choices.size()]
				NetworkManager.send_player_choice(local_choice)
			
			countdown_label.text = "Waiting for resolution..."

# ========================================
# PLAYER ACTIONS
# ========================================

func _on_choice_selected(choice: String):
	"""Handles when the local player picks a throw"""
	if game_phase != "choosing" or local_choice != "":
		return
	
	print("Local player chose: ", choice)
	local_choice = choice
	player_choices[NetworkManager.local_player_id] = choice
	player_last_choice_label.text = "Last throw: " + _get_choice_display_name(choice)
	
	_set_choice_buttons_enabled(false)
	NetworkManager.send_player_choice(choice)
	countdown_label.text = "Waiting for opponents..."
	choice_hint.text = "Hang tight while everyone locks in."
	
	if _all_players_chose():
		countdown_timer.stop()
		if NetworkManager.is_host:
			_evaluate_round()

func receive_player_choice(player_id: int, choice: String):
	"""Processes a received throw from a peer"""
	print("Received choice from player ", player_id, ": ", choice)
	player_choices[player_id] = choice
	
	if player_id == NetworkManager.local_player_id:
		player_last_choice_label.text = "Last throw: " + _get_choice_display_name(choice)
	else:
		opponent_last_choice_label.text = "Last throw: " + _get_choice_display_name(choice)
	
	# Host checks if every peer has committed
	if NetworkManager.is_host and _all_players_chose():
		countdown_timer.stop()
		_evaluate_round()

func _all_players_chose() -> bool:
	"""Checks whether every active player has locked in"""
	var expected_players = _get_active_players()
	for player_id in expected_players:
		if player_id not in player_choices:
			return false
	return true

func _get_active_players() -> Array:
	"""Returns the peer IDs expected to submit a choice"""
	var active_players = []
	# Start with the local peer
	active_players.append(NetworkManager.local_player_id)
	# Append remote peers tracked by the NetworkManager
	for peer_id in NetworkManager.connected_peers:
		if peer_id != NetworkManager.local_player_id:
			active_players.append(peer_id)
	
	return active_players

func _evaluate_round():
	"""Evaluates the round outcome (host only)"""
	if not NetworkManager.is_host:
		return
	
	print("HOST: Evaluating round...")
	
	var results = _calculate_results()
	var winner_id = results.winner_id
	
	# Broadcast the results to every peer
	NetworkManager.end_round_for_all(winner_id, results)

func _calculate_results() -> Dictionary:
	"""Calculates the round outcome data"""
	var results = {
		"winner_id": -1,
		"winner_name": "Draw",
		"choices": player_choices.duplicate()
	}
	
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
	"""Resolves a simple rock-paper-scissors duel"""
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

# ========================================
# UI HELPERS
# ========================================

func _show_round_results(winner_id: int, results: Dictionary):
	"""Updates the round summary card with latest results"""
	countdown_label.visible = false
	result_panel.visible = true
	
	if winner_id == -1:
		result_label.text = "Round tied!"
		result_label.modulate = Color(0.94, 0.83, 0.39)
	elif winner_id == NetworkManager.local_player_id:
		result_label.text = "You win the round!"
		result_label.modulate = Color(0.55, 0.9, 0.61)
	else:
		result_label.text = "You lose the round!"
		result_label.modulate = Color(0.93, 0.45, 0.45)
	
	_display_player_choices(results.choices)
	_update_score_display()
	
	next_round_btn.visible = NetworkManager.is_host and not _is_game_finished()

func _display_player_choices(choices: Dictionary):
	"""Builds a quick summary of each throw"""
	for child in players_choices.get_children():
		child.queue_free()
	
	for player_id in choices:
		var choice_item = HBoxContainer.new()
		choice_item.alignment = BoxContainer.ALIGNMENT_CENTER_LEFT
		choice_item.theme = theme
		choice_item.add_theme_constant_override("separation", 12)
		
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

func _set_choice_buttons_enabled(enabled: bool):
	"""Toggles the throw buttons"""
	rock_btn.disabled = not enabled
	paper_btn.disabled = not enabled
	scissors_btn.disabled = not enabled

func _update_score_display():
	"""Updates score ribbons and labels"""
	var local_score = player_scores.get(NetworkManager.local_player_id, 0)
	var opponent_id = _get_remote_player_id()
	var score_parts: Array = []
	
	player_score_label.text = "Wins: " + str(local_score)
	score_parts.append("You " + str(local_score))
	
	if opponent_id != -1:
		var opponent_score = player_scores.get(opponent_id, 0)
		opponent_score_label.text = "Wins: " + str(opponent_score)
		score_parts.append("Opponent " + str(opponent_score))
	else:
		opponent_score_label.text = "Waiting for opponent"
	
	score_label.text = "Score: " + " • ".join(score_parts)
	_refresh_opponent_card()

func _refresh_opponent_card():
	var opponent_id = _get_remote_player_id()
	if opponent_id != -1:
		var opponent_data = NetworkManager.connected_peers.get(opponent_id, null)
		if opponent_data is Dictionary and opponent_data.has("name"):
			opponent_name_label.text = str(opponent_data["name"])
		else:
			opponent_name_label.text = "Opponent"
	else:
		opponent_name_label.text = "Opponent"

func _is_game_finished() -> bool:
	"""Checks if a match-ending condition is met"""
	for score in player_scores.values():
		if score >= 3:
			return true
	return current_round > max_rounds

func _show_game_results():
	"""Displays final game banner"""
	var winner_id = _get_game_winner()
	
	if winner_id == -1:
		result_label.text = "Match ends in a draw!"
		result_label.modulate = Color(0.94, 0.83, 0.39)
	elif winner_id == NetworkManager.local_player_id:
		result_label.text = "You take the match!"
		result_label.modulate = Color(0.55, 0.9, 0.61)
	else:
		result_label.text = "Defeat this time!"
		result_label.modulate = Color(0.93, 0.45, 0.45)
	
	next_round_btn.visible = false

func _get_game_winner() -> int:
	"""Returns the overall match winner"""
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

func _get_remote_player_id() -> int:
	for player_id in player_scores:
		if player_id != NetworkManager.local_player_id:
			return player_id
	return -1

func _get_player_name(player_id: int) -> String:
	"""Returns a display name for the given player"""
	if player_id == NetworkManager.local_player_id:
		return "You"
	else:
		return "Opponent"

func _get_choice_display_name(choice: String) -> String:
	"""Returns a readable string for a throw"""
	match choice:
		"rock": return "Rock"
		"paper": return "Paper"
		"scissors": return "Scissors"
		_: return "Unknown"

func _get_choice_icon(choice: String) -> String:
	"""Returns a fun emoji for a throw"""
	match choice:
		"rock": return "🪨"
		"paper": return "📄"
		"scissors": return "✂️"
		_: return "❓"

# ========================================
# BUTTON HANDLERS
# ========================================

func _on_next_round_pressed():
	"""Host-only handler to kick off the next round"""
	if NetworkManager.is_host:
		NetworkManager.start_countdown_for_all(COUNTDOWN_TIME)

func _on_back_to_lobby_pressed():
	"""Returns to the lobby scene"""
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_disconnect_pressed():
	"""Disconnects from the current session"""
	NetworkManager.disconnect_from_server()

# ========================================
# NETWORK EVENT HANDLERS
# ========================================

func _on_player_connected(peer_id: int):
	"""Refreshes HUD when a new opponent joins mid-match"""
	print("Player connected mid-match: ", peer_id)
	_update_score_display()

func _on_player_disconnected(peer_id: int):
	"""Notifies the player when an opponent leaves mid-match"""
	print("Player disconnected mid-match: ", peer_id)
	_update_score_display()

	var notification = AcceptDialog.new()
	notification.dialog_text = "Your opponent disconnected. The match has ended."
	add_child(notification)
	notification.popup_centered()
	notification.confirmed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))

func _notification(what):
	"""Ensures we cleanly disconnect on window close"""
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		NetworkManager.disconnect_from_server()
		get_tree().quit()
