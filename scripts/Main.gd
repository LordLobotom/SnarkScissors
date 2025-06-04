extends Control

const COUNTDOWN_TIME := 10.0
const RESULT_DISPLAY_TIME := 2.0
const FIGHT_BEGIN_TIME := 2.0

var countdown_timer := COUNTDOWN_TIME
var countdown_active := false
var result_display_active := false
var fight_begin_active := false
var phase_timer := 0.0

func _ready():
	connect_buttons()
	initialize_score_display()
	start_fight_begin()

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
			reset_ui()
			start_fight_begin()

func connect_buttons():
	$GameUI/panPlayer1/btnRock.connect("pressed", func(): set_choice(1, GameManager.Choice.ROCK))
	$GameUI/panPlayer1/btnPaper.connect("pressed", func(): set_choice(1, GameManager.Choice.PAPER))
	$GameUI/panPlayer1/btnScissors.connect("pressed", func(): set_choice(1, GameManager.Choice.SCISSORS))
	$GameUI/panPlayer2/btnRock.connect("pressed", func(): set_choice(2, GameManager.Choice.ROCK))
	$GameUI/panPlayer2/btnPaper.connect("pressed", func(): set_choice(2, GameManager.Choice.PAPER))
	$GameUI/panPlayer2/btnScissors.connect("pressed", func(): set_choice(2, GameManager.Choice.SCISSORS))

func initialize_score_display():
	$GameUI/panPlayer1/btnScore.text = "Score: %d" % GameManager.player1_score
	$GameUI/panPlayer2/btnScore.text = "Score: %d" % GameManager.player2_score

func start_fight_begin():
	fight_begin_active = true
	phase_timer = FIGHT_BEGIN_TIME
	$GameUI/panCenter/lblResult.text = "Fight begin!"
	$GameUI/panCenter/lblCountDown.text = ""
	
	# Zablokujeme tlačítka během "Fight begin"
	set_buttons_disabled(true)

func set_choice(player: int, choice):
	# Povolujeme výběr pouze během aktivního odpočtu
	if not countdown_active:
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
	
	# Zobrazíme výsledek
	match winner:
		0:
			$GameUI/panCenter/lblResult.text = "Remíza!"
		1:
			$GameUI/panCenter/lblResult.text = "Vyhrál hráč 1!"
		2:
			$GameUI/panCenter/lblResult.text = "Vyhrál hráč 2!"
	
	# Aktualizujeme skóre
	update_score_display()
	
	# Schováme odpočet
	$GameUI/panCenter/lblCountDown.text = ""
	
	# Resetujeme choices v GameManageru
	GameManager.reset_choices()
	
	# Spustíme timer pro zobrazení výsledku
	start_result_display()

func handle_timeout():
	# Vyhodnotíme situaci při timeoutu
	if GameManager.player1_choice == null and GameManager.player2_choice == null:
		$GameUI/panCenter/lblResult.text = "Nikdo nevybral – kolo zrušeno."
	elif GameManager.player1_choice == null:
		GameManager.player2_score += 1
		$GameUI/panCenter/lblResult.text = "Hráč 1 nestihl – vyhrál hráč 2!"
	elif GameManager.player2_choice == null:
		GameManager.player1_score += 1
		$GameUI/panCenter/lblResult.text = "Hráč 2 nestihl – vyhrál hráč 1!"
	else:
		# Oba stihli vybrat, ale čas vypršel
		evaluate_game()
		return
	
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
