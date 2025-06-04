# scripts/GameManager.gd
extends Node

enum Choice { ROCK, PAPER, SCISSORS }

var player1_choice = null
var player2_choice = null
var player1_score = 0
var player2_score = 0

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

func reset_choices():
	player1_choice = null
	player2_choice = null
