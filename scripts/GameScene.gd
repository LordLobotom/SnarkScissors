extends Control

@onready var back_to_lobby_button: Button = $MainMargin/MainVBox/HeaderBar/BackToLobbyButton
@onready var settings_button: Button = $MainMargin/MainVBox/HeaderBar/HeaderButtons/SettingsButton
@onready var disconnect_button: Button = $MainMargin/MainVBox/HeaderBar/HeaderButtons/DisconnectButton
@onready var round_info: Label = $MainMargin/MainVBox/RoundSummary/SummaryMargin/SummaryHBox/RoundInfoLabel
@onready var countdown_label: Label = $MainMargin/MainVBox/RoundSummary/SummaryMargin/SummaryHBox/CountdownLabel
@onready var countdown_headline: Label = $MainMargin/MainVBox/Arena/CenterStage/CenterMargin/CenterVBox/CountdownHeadline
@onready var choice_hint: Label = $MainMargin/MainVBox/Arena/CenterStage/CenterMargin/CenterVBox/ChoiceHint
@onready var lock_status: Label = $MainMargin/MainVBox/Arena/CenterStage/CenterMargin/CenterVBox/LockStatus
@onready var rock_button: Button = $MainMargin/MainVBox/Arena/CenterStage/CenterMargin/CenterVBox/ChoiceButtons/RockButton
@onready var paper_button: Button = $MainMargin/MainVBox/Arena/CenterStage/CenterMargin/CenterVBox/ChoiceButtons/PaperButton
@onready var scissors_button: Button = $MainMargin/MainVBox/Arena/CenterStage/CenterMargin/CenterVBox/ChoiceButtons/ScissorsButton
@onready var player_name_label: Label = $MainMargin/MainVBox/Arena/PlayerCard/PlayerMargin/PlayerVBox/PlayerNameLabel
@onready var player_score_label: Label = $MainMargin/MainVBox/Arena/PlayerCard/PlayerMargin/PlayerVBox/PlayerScoreLabel
@onready var player_last_choice_label: Label = $MainMargin/MainVBox/Arena/PlayerCard/PlayerMargin/PlayerVBox/PlayerLastChoice
@onready var opponent_name_label: Label = $MainMargin/MainVBox/Arena/OpponentCard/OpponentMargin/OpponentVBox/OpponentNameLabel
@onready var opponent_score_label: Label = $MainMargin/MainVBox/Arena/OpponentCard/OpponentMargin/OpponentVBox/OpponentScoreLabel
@onready var opponent_last_choice_label: Label = $MainMargin/MainVBox/Arena/OpponentCard/OpponentMargin/OpponentVBox/OpponentLastChoice
@onready var score_label: Label = $MainMargin/MainVBox/ScoreBar/ScoreMargin/ScoreLabel
@onready var result_overlay: Control = $ResultOverlay
@onready var result_label: Label = $ResultOverlay/Center/ResultsCard/ResultMargin/ResultVBox/ResultLabel
@onready var players_choices: VBoxContainer = $ResultOverlay/Center/ResultsCard/ResultMargin/ResultVBox/PlayersChoices
@onready var result_hint: Label = $ResultOverlay/Center/ResultsCard/ResultMargin/ResultVBox/ResultHint
@onready var next_round_button: Button = $ResultOverlay/Center/ResultsCard/ResultMargin/ResultVBox/NextRoundButton
@onready var settings_overlay: Control = $SettingsOverlay

const CHOICE_TIME := 10.0
const COUNTDOWN_TIME := 3.0
const NEXT_ROUND_DELAY := 4.0
const MAX_ROUNDS := 5

var current_round := 1
var player_scores: Dictionary = {}
var player_choices: Dictionary = {}
var local_choice := ""
var countdown_time := 0.0
var game_phase := "waiting"
var countdown_timer: Timer
var next_round_timer: Timer


func _ready() -> void:
	NetworkManager.game_scene_ref = self
	_connect_ui_signals()
	_connect_network_signals()
	_create_timers()
	_initialize_scores()

	result_overlay.visible = false
	_set_choice_buttons_enabled(false)
	player_name_label.text = _get_player_name(NetworkManager.local_player_id)
	player_last_choice_label.text = "LAST THROW // NONE"
	opponent_last_choice_label.text = "LAST THROW // NONE"
	_refresh_opponent_card()

	if NetworkManager.is_host:
		call_deferred("_begin_host_match")


func _exit_tree() -> void:
	if NetworkManager.game_scene_ref == self:
		NetworkManager.game_scene_ref = null


func _connect_ui_signals() -> void:
	rock_button.pressed.connect(func(): _on_choice_selected("rock"))
	paper_button.pressed.connect(func(): _on_choice_selected("paper"))
	scissors_button.pressed.connect(func(): _on_choice_selected("scissors"))
	next_round_button.pressed.connect(_on_next_round_pressed)
	back_to_lobby_button.pressed.connect(_on_back_to_lobby_pressed)
	disconnect_button.pressed.connect(_on_disconnect_pressed)
	settings_button.pressed.connect(settings_overlay.open)


func _connect_network_signals() -> void:
	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)


func _create_timers() -> void:
	countdown_timer = Timer.new()
	countdown_timer.wait_time = 1.0
	countdown_timer.timeout.connect(_on_countdown_tick)
	add_child(countdown_timer)

	next_round_timer = Timer.new()
	next_round_timer.one_shot = true
	next_round_timer.wait_time = NEXT_ROUND_DELAY
	next_round_timer.timeout.connect(_on_next_round_timer_timeout)
	add_child(next_round_timer)


func _initialize_scores() -> void:
	player_scores[NetworkManager.local_player_id] = 0
	for player in NetworkManager.get_connected_players():
		player_scores[player.id] = 0
	_update_score_display()


func _begin_host_match() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	start_new_round()


func start_new_round() -> void:
	if not NetworkManager.is_host:
		return
	NetworkManager.sync_round_start.rpc(current_round)
	NetworkManager.start_countdown_for_all(COUNTDOWN_TIME)


func sync_start_new_round(round_number: int) -> void:
	current_round = round_number
	player_choices.clear()
	local_choice = ""
	game_phase = "waiting"
	result_overlay.visible = false
	next_round_button.text = "Next round"


func sync_countdown_phase(duration: float) -> void:
	game_phase = "countdown"
	countdown_time = duration
	player_choices.clear()
	local_choice = ""
	result_overlay.visible = false
	countdown_label.visible = true
	_set_choice_buttons_enabled(false)
	round_info.text = "ROUND %02d / %02d" % [current_round, MAX_ROUNDS]
	countdown_label.text = "GET READY"
	countdown_headline.text = "WAIT FOR THE SIGNAL"
	choice_hint.text = "Throws unlock once the countdown finishes."
	lock_status.text = "LOCKED // COUNTDOWN"
	AudioManager.play_sfx(&"countdown")
	countdown_timer.start()


func sync_choice_phase(duration: float) -> void:
	game_phase = "choosing"
	countdown_time = duration
	countdown_label.text = "CHOOSE NOW"
	countdown_headline.text = "PICK YOUR THROW"
	choice_hint.text = "Rock beats scissors. Paper beats rock. Scissors beat paper."
	lock_status.text = "OPEN // TEN SECONDS"
	_set_choice_buttons_enabled(true)
	AudioManager.play_sfx(&"ready")
	countdown_timer.start()


func sync_round_end(winner_id: int, results: Dictionary) -> void:
	game_phase = "results"
	countdown_timer.stop()
	if winner_id in player_scores:
		player_scores[winner_id] += 1

	_show_round_results(winner_id, results)
	if _is_game_finished():
		_show_game_results()
	elif NetworkManager.is_host:
		current_round += 1


func _on_countdown_tick() -> void:
	countdown_time -= 1.0
	if game_phase == "countdown":
		if countdown_time > 0:
			countdown_label.text = "%d" % int(countdown_time)
			AudioManager.play_sfx(&"countdown")
		else:
			countdown_timer.stop()
			if NetworkManager.is_host:
				NetworkManager.start_choice_phase_for_all(CHOICE_TIME)
	elif game_phase == "choosing":
		if countdown_time > 0:
			countdown_label.text = "%d SEC" % int(countdown_time)
		else:
			countdown_timer.stop()
			if local_choice.is_empty():
				var choices := ["rock", "paper", "scissors"]
				_on_choice_selected(choices[randi() % choices.size()])
			countdown_label.text = "RESOLVING"
			lock_status.text = "LOCKED // AUTO-PICKED"


func _on_choice_selected(choice: String) -> void:
	if game_phase != "choosing" or not local_choice.is_empty():
		return

	local_choice = choice
	player_choices[NetworkManager.local_player_id] = choice
	player_last_choice_label.text = "LAST THROW // " + _get_choice_display_name(choice).to_upper()
	AudioManager.play_sfx(StringName(choice))
	_set_choice_buttons_enabled(false)
	NetworkManager.send_player_choice(choice)
	countdown_label.text = "LOCKED IN"
	choice_hint.text = "Waiting for the rival to lock in."
	lock_status.text = "LOCKED // CHOICE SENT"

	if NetworkManager.is_host and _all_players_chose():
		countdown_timer.stop()
		_evaluate_round()


func receive_player_choice(player_id: int, choice: String) -> void:
	if choice not in ["rock", "paper", "scissors"]:
		return
	player_choices[player_id] = choice

	if NetworkManager.is_host and _all_players_chose():
		countdown_timer.stop()
		_evaluate_round()


func _all_players_chose() -> bool:
	for player_id in _get_active_players():
		if player_id not in player_choices:
			return false
	return true


func _get_active_players() -> Array:
	var active_players := [NetworkManager.local_player_id]
	for peer_id in NetworkManager.connected_peers:
		if peer_id != NetworkManager.local_player_id:
			active_players.append(peer_id)
	return active_players


func _evaluate_round() -> void:
	if not NetworkManager.is_host:
		return
	var results := _calculate_results()
	NetworkManager.end_round_for_all(results.winner_id, results)


func _calculate_results() -> Dictionary:
	var results := {
		"winner_id": -1,
		"winner_name": "Draw",
		"choices": player_choices.duplicate(),
	}
	if player_choices.size() != 2:
		return results

	var players := player_choices.keys()
	var first_id = players[0]
	var second_id = players[1]
	var outcome := _get_rps_winner(player_choices[first_id], player_choices[second_id])
	if outcome == 1:
		results.winner_id = first_id
		results.winner_name = _get_player_name(first_id)
	elif outcome == 2:
		results.winner_id = second_id
		results.winner_name = _get_player_name(second_id)
	return results


func _get_rps_winner(first_choice: String, second_choice: String) -> int:
	if first_choice == second_choice:
		return 0
	var winning_combinations := {
		"rock": "scissors",
		"paper": "rock",
		"scissors": "paper",
	}
	return 1 if winning_combinations[first_choice] == second_choice else 2


func _show_round_results(winner_id: int, results: Dictionary) -> void:
	countdown_label.visible = false
	result_overlay.visible = true
	if winner_id == -1:
		result_label.text = "ROUND TIED"
		result_label.modulate = Color("f2c14e")
		AudioManager.play_sfx(&"draw")
	elif winner_id == NetworkManager.local_player_id:
		result_label.text = "YOU WIN THE ROUND"
		result_label.modulate = Color("2ebfa5")
		AudioManager.play_sfx(&"win")
	else:
		result_label.text = "RIVAL TAKES THE ROUND"
		result_label.modulate = Color("f15b4f")
		AudioManager.play_sfx(&"lose")

	var choices: Dictionary = results.get("choices", {})
	_reveal_round_choices(choices)
	_display_player_choices(choices)
	_update_score_display()
	var game_finished := _is_game_finished()
	next_round_button.visible = NetworkManager.is_host and not game_finished
	next_round_button.text = "Next round"
	result_hint.text = "The next round begins automatically."
	if NetworkManager.is_host and not game_finished:
		next_round_timer.start()


func _reveal_round_choices(choices: Dictionary) -> void:
	for player_id in choices:
		var display_name := _get_choice_display_name(choices[player_id]).to_upper()
		if player_id == NetworkManager.local_player_id:
			player_last_choice_label.text = "LAST THROW // " + display_name
		else:
			opponent_last_choice_label.text = "LAST THROW // " + display_name


func _display_player_choices(choices: Dictionary) -> void:
	for child in players_choices.get_children():
		child.queue_free()
	for player_id in choices:
		var choice_label := Label.new()
		choice_label.theme = theme
		choice_label.theme_type_variation = &"subtitle"
		choice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		choice_label.text = "%s  //  %s" % [
			_get_player_name(player_id).to_upper(),
			_get_choice_display_name(choices[player_id]).to_upper(),
		]
		players_choices.add_child(choice_label)


func _set_choice_buttons_enabled(enabled: bool) -> void:
	rock_button.disabled = not enabled
	paper_button.disabled = not enabled
	scissors_button.disabled = not enabled


func _update_score_display() -> void:
	var local_score: int = player_scores.get(NetworkManager.local_player_id, 0)
	var opponent_id := _get_remote_player_id()
	player_score_label.text = "%d WINS" % local_score
	if opponent_id != -1:
		var opponent_score: int = player_scores.get(opponent_id, 0)
		opponent_score_label.text = "%d WINS" % opponent_score
		score_label.text = "YOU  %d    //    OPPONENT  %d" % [local_score, opponent_score]
	else:
		opponent_score_label.text = "WAITING"
		score_label.text = "YOU  %d    //    OPPONENT  --" % local_score
	_refresh_opponent_card()


func _refresh_opponent_card() -> void:
	var opponent_id := _get_remote_player_id()
	if opponent_id != -1:
		var opponent_data = NetworkManager.connected_peers.get(opponent_id, null)
		if opponent_data is Dictionary and opponent_data.has("name"):
			opponent_name_label.text = str(opponent_data.name)
			return
	opponent_name_label.text = "Opponent"


func _is_game_finished() -> bool:
	for score in player_scores.values():
		if score >= 3:
			return true
	return current_round >= MAX_ROUNDS


func _show_game_results() -> void:
	var winner_id := _get_game_winner()
	if winner_id == -1:
		result_label.text = "MATCH DRAWN"
		result_label.modulate = Color("f2c14e")
	elif winner_id == NetworkManager.local_player_id:
		result_label.text = "YOU TAKE THE MATCH"
		result_label.modulate = Color("2ebfa5")
		AudioManager.play_sfx(&"start")
	else:
		result_label.text = "MATCH LOST"
		result_label.modulate = Color("f15b4f")

	next_round_button.visible = true
	next_round_button.text = "Back to lobby"
	result_hint.text = "Return to the lobby for a rematch."
	if next_round_timer.time_left > 0:
		next_round_timer.stop()


func _get_game_winner() -> int:
	var best_score := -1
	var winner_id := -1
	var tied := false
	for player_id in player_scores:
		var score: int = player_scores[player_id]
		if score > best_score:
			best_score = score
			winner_id = player_id
			tied = false
		elif score == best_score:
			tied = true
	return -1 if tied else winner_id


func _get_remote_player_id() -> int:
	for player_id in player_scores:
		if player_id != NetworkManager.local_player_id:
			return player_id
	return -1


func _get_player_name(player_id: int) -> String:
	return "You" if player_id == NetworkManager.local_player_id else "Opponent"


func _get_choice_display_name(choice: String) -> String:
	match choice:
		"rock":
			return "Rock"
		"paper":
			return "Paper"
		"scissors":
			return "Scissors"
		_:
			return "Unknown"


func _on_next_round_pressed() -> void:
	if _is_game_finished():
		_on_back_to_lobby_pressed()
		return
	if NetworkManager.is_host:
		if next_round_timer.time_left > 0:
			next_round_timer.stop()
		start_new_round()


func _on_next_round_timer_timeout() -> void:
	if NetworkManager.is_host:
		start_new_round()


func _on_back_to_lobby_pressed() -> void:
	AudioManager.play_sfx(&"ui")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _on_disconnect_pressed() -> void:
	AudioManager.play_sfx(&"disconnect")
	NetworkManager.disconnect_from_server()


func _on_player_connected(peer_id: int) -> void:
	player_scores[peer_id] = 0
	_update_score_display()


func _on_player_disconnected(peer_id: int) -> void:
	player_scores.erase(peer_id)
	_update_score_display()
	AudioManager.play_sfx(&"disconnect")
	var notification := AcceptDialog.new()
	notification.dialog_text = "Your opponent disconnected. The match has ended."
	add_child(notification)
	notification.popup_centered()
	notification.confirmed.connect(
		func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		AudioManager.stop_all()
		NetworkManager.disconnect_from_server()
		get_tree().quit()
