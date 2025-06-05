extends Control

const COUNTDOWN_TIME := 10.0
const RESULT_DISPLAY_TIME := 3.0
const FIGHT_BEGIN_TIME := 2.0

var countdown_timer := COUNTDOWN_TIME
var countdown_active := false
var result_display_active := false
var fight_begin_active := false
var phase_timer := 0.0

func _ready():
	connect_buttons()
	initialize_ui()

func _process(delta):
	if fight_begin_active:
		phase_timer -= delta
		if phase_timer <= 0:
			fight_begin_active = false
			start_countdown()
	elif countdown_active:
		countdown_timer -= delta
		update_countdown_label()
		if countdown_timer <= 0:
			countdown_active = false
			handle_timeout()
	elif result_display_active:
		phase_timer -= delta
		if phase_timer <= 0:
			result_display_active = false
			check_round_status()

func connect_buttons():
	# Připojíme tlačítka pro výběr
	$GameUI/panPlayer1/btnRock.connect("pressed", func(): set_choice(1, GameManager.Choice.ROCK))
	$GameUI/panPlayer1/btnPaper.connect("pressed", func(): set_choice(1, GameManager.Choice.PAPER))
	$GameUI/panPlayer1/btnScissors.connect("pressed", func(): set_choice(1, GameManager.Choice.SCISSORS))
	$GameUI/panPlayer2/btnRock.connect("pressed", func(): set_choice(2, GameManager.Choice.ROCK))
	$GameUI/panPlayer2/btnPaper.connect("pressed", func(): set_choice(2, GameManager.Choice.PAPER))
	$GameUI/panPlayer2/btnScissors.connect("pressed", func(): set_choice(2, GameManager.Choice.SCISSORS))
	
	# Připojíme tlačítko Start
	$GameUI/panControl/btnStart.connect("pressed", start_new_round)

func initialize_ui():
	update_score_display()
	show_start_screen()

func show_start_screen():
	$GameUI/panCenter/lblResult.text = "Připraveni na nové kolo?"
	$GameUI/panCenter/lblCountDown.text = ""
	$GameUI/panControl/btnStart.visible = true
	set_buttons_disabled(true)
	unselect_buttons($GameUI/panPlayer1)
	unselect_buttons($GameUI/panPlayer2)

func start_new_round():
	GameManager.start_new_round()
	$GameUI/panControl/btnStart.visible = false
	start_fight_begin()

func start_fight_begin():
	fight_begin_active = true
	phase_timer = FIGHT_BEGIN_TIME
	$GameUI/panCenter/lblResult.text = "Fight begin!"
	$GameUI/panCenter/lblCountDown.text = ""
	
	# Zablokujeme tlačítka během "Fight begin"
	set_buttons_disabled(true)

func set_choice(player: int, choice):
	# Povolujeme výběr pouze během aktivního odpočtu
	if not countdown_active or GameManager.current_game_state != GameManager.GameState.ROUND_IN_PROGRESS:
		return
		
	if player == 1 and GameManager.player1_choice == null:
		GameManager.player1_choice = choice
		highlight_selected_button(1, choice)
	elif player == 2 and GameManager.player2_choice == null:
		GameManager.player2_choice = choice
		highlight_selected_button(2, choice)
	
	# Pokud oba hráči vybrali, okamžitě vyhodnotíme
	if GameManager.player1_choice != null and GameManager.player2_choice != null:
		countdown_active = false
		evaluate_game()

func highlight_selected_button(player: int, choice):
	var panel_path = "GameUI/panPlayer" + str(player)
	var panel = get_node(panel_path)
	
	# Resetujeme všechna tlačítka v panelu
	unselect_buttons(panel)
	
	# Zvýrazníme vybrané tlačítko
	var button_name = ""
	match choice:
		GameManager.Choice.ROCK:
			button_name = "btnRock"
		GameManager.Choice.PAPER:
			button_name = "btnPaper"
		GameManager.Choice.SCISSORS:
			button_name = "btnScissors"
	
	if button_name != "":
		var button = panel.get_node(button_name)
		button.button_pressed = true

func update_countdown_label():
	$GameUI/panCenter/lblCountDown.text = "Čas: %.1f" % max(0, countdown_timer)

func evaluate_game():
	var winner = GameManager.evaluate_round()
	var result_text = ""
	
	# Aktualizujeme počet výher v kole
	match winner:
		0:
			result_text = "Remíza!"
		1:
			GameManager.player1_round_wins += 1
			result_text = "Vyhrál hráč 1!"
		2:
			GameManager.player2_round_wins += 1
			result_text = "Vyhrál hráč 2!"
	
	# Přidáme informaci o skóre v kole
	result_text += "\nSkóre kola: %d - %d" % [GameManager.player1_round_wins, GameManager.player2_round_wins]
	
	# Zobrazíme výsledek
	$GameUI/panCenter/lblResult.text = result_text
	
	# Aktualizujeme celkové skóre
	update_score_display()
	
	# Schováme odpočet
	$GameUI/panCenter/lblCountDown.text = ""
	
	# Resetujeme choices v GameManageru
	GameManager.reset_choices()
	
	# Spustíme timer pro zobrazení výsledku
	start_result_display()

func handle_timeout():
	var result_text = ""
	
	# Vyhodnotíme situaci při timeoutu
	if GameManager.player1_choice == null and GameManager.player2_choice == null:
		result_text = "Nikdo nevybral – kolo zrušeno."
	elif GameManager.player1_choice == null:
		GameManager.player2_round_wins += 1
		result_text = "Hráč 1 nestihl – vyhrál hráč 2!"
	elif GameManager.player2_choice == null:
		GameManager.player1_round_wins += 1
		result_text = "Hráč 2 nestihl – vyhrál hráč 1!"
	else:
		# Oba stihli vybrat, ale čas vypršel
		evaluate_game()
		return
	
	# Přidáme informaci o skóre v kole
	result_text += "\nSkóre kola: %d - %d" % [GameManager.player1_round_wins, GameManager.player2_round_wins]
	
	# Zobrazíme výsledek
	$GameUI/panCenter/lblResult.text = result_text
	
	# Aktualizujeme skóre
	update_score_display()
	
	# Schováme odpočet
	$GameUI/panCenter/lblCountDown.text = ""
	
	# Resetujeme choices
	GameManager.reset_choices()
	
	# Spustíme timer pro zobrazení výsledku
	start_result_display()

func update_score_display():
	$GameUI/panPlayer1/btnScore.text = "Score: %d" % GameManager.player1_score
	$GameUI/panPlayer2/btnScore.text = "Score: %d" % GameManager.player2_score

func start_result_display():
	result_display_active = true
	phase_timer = RESULT_DISPLAY_TIME
	
	# Zablokujeme tlačítka během zobrazení výsledku
	set_buttons_disabled(true)

func check_round_status():
	var round_winner = GameManager.check_round_winner()
	
	if round_winner > 0:
		# Někdo vyhrál celé kolo
		var winner_text = ""
		if round_winner == 1:
			winner_text = "🎉 HRÁČ 1 VYHRÁL KOLO! 🎉"
		else:
			winner_text = "🎉 HRÁČ 2 VYHRÁL KOLO! 🎉"
		
		$GameUI/panCenter/lblResult.text = winner_text
		GameManager.finish_round()
		
		# Po chvíli zobrazíme tlačítko pro nové kolo
		await get_tree().create_timer(2.0).timeout
		show_start_screen()
	else:
		# Kolo pokračuje, resetujeme UI a začínáme další hru
		reset_ui()
		start_fight_begin()

func reset_ui():
	$GameUI/panCenter/lblResult.text = ""
	$GameUI/panCenter/lblCountDown.text = ""
	
	# Resetujeme všechna tlačítka
	unselect_buttons($GameUI/panPlayer1)
	unselect_buttons($GameUI/panPlayer2)

func start_countdown():
	countdown_timer = COUNTDOWN_TIME
	countdown_active = true
	result_display_active = false
	fight_begin_active = false
	
	# Vymažeme "Fight begin" text
	$GameUI/panCenter/lblResult.text = ""
	
	# Povolíme tlačítka pro výběr
	set_buttons_disabled(false)

func unselect_buttons(panel: Node):
	for child in panel.get_children():
		if child is Button and child.name.begins_with("btn") and not child.name.contains("Score"):
			child.button_pressed = false

func set_buttons_disabled(disabled: bool):
	# Zablokujeme/povolíme tlačítka pro oba hráče
	for panel_name in ["GameUI/panPlayer1", "GameUI/panPlayer2"]:
		var panel = get_node(panel_name)
		for child in panel.get_children():
			if child is Button and child.name.begins_with("btn") and not child.name.contains("Score"):
				child.disabled = disabled
				if disabled:
					child.button_pressed = false
