# scripts/GameManager.gd
extends Node

enum Choice { ROCK, PAPER, SCISSORS }
enum GameState { WAITING_TO_START, ROUND_IN_PROGRESS, ROUND_FINISHED }

var player1_choice = null
var player2_choice = null
var player1_score = 0
var player2_score = 0
var player1_round_wins = 0
var player2_round_wins = 0
var current_game_state = GameState.WAITING_TO_START
var rounds_to_win = 3

func evaluate_round() -> int:
	if player1_choice == player2_choice:
		return 0  # Remíza
	elif ((player1_choice == Choice.ROCK and player2_choice == Choice.SCISSORS) or
		(player1_choice == Choice.SCISSORS and player2_choice == Choice.PAPER) or
		(player1_choice == Choice.PAPER and player2_choice == Choice.ROCK)):
		player1_score += 1
		return 1  # Hráč 1 vyhrál
	else:
		player2_score += 1
		return 2  # Hráč 2 vyhrál

func check_round_winner() -> int:
	if player1_round_wins >= rounds_to_win:
		return 1  # Hráč 1 vyhrál kolo
	elif player2_round_wins >= rounds_to_win:
		return 2  # Hráč 2 vyhrál kolo
	else:
		return 0  # Kolo pokračuje

func start_new_round():
	player1_round_wins = 0
	player2_round_wins = 0
	current_game_state = GameState.ROUND_IN_PROGRESS
	reset_choices()

func finish_round():
	current_game_state = GameState.ROUND_FINISHED

func reset_choices():
	player1_choice = null
	player2_choice = null

func reset_game():
	player1_score = 0
	player2_score = 0
	player1_round_wins = 0
	player2_round_wins = 0
	current_game_state = GameState.WAITING_TO_START
	reset_choices()
