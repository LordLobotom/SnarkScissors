extends Control

signal round_finished(result: StringName)

const CHOICES: Array[StringName] = [&"rock", &"paper", &"scissors"]
const CHOICE_TEXTURES := {
    &"rock": preload("res://ui/throw_rock.svg"),
    &"paper": preload("res://ui/throw_paper.svg"),
    &"scissors": preload("res://ui/throw_scissors.svg"),
}
const WINNING_MATCHUPS := {
    &"rock": &"scissors",
    &"paper": &"rock",
    &"scissors": &"paper",
}

@onready var safe_margin: MarginContainer = $SafeMargin
@onready var header: HBoxContainer = $SafeMargin/Layout/Header
@onready var menu_button: Button = %MenuButton
@onready var score_panel: Panel = %ScorePanel
@onready var score_label: Label = %ScoreLabel
@onready var player_score_label: Label = %PlayerScoreLabel
@onready var computer_score_label: Label = %ComputerScoreLabel
@onready var arena: GridContainer = %Arena
@onready var player_card: Panel = $SafeMargin/Layout/Arena/PlayerCard
@onready var versus_label: Label = $SafeMargin/Layout/Arena/Versus
@onready var computer_card: Panel = $SafeMargin/Layout/Arena/ComputerCard
@onready var player_choice_icon: TextureRect = %PlayerChoiceIcon
@onready var player_unknown: Label = %PlayerUnknown
@onready var player_choice_name: Label = %PlayerChoiceName
@onready var computer_choice_icon: TextureRect = %ComputerChoiceIcon
@onready var computer_unknown: Label = %ComputerUnknown
@onready var computer_choice_name: Label = %ComputerChoiceName
@onready var result_label: Label = %ResultLabel
@onready var prompt_label: Label = %PromptLabel
@onready var choice_buttons: HBoxContainer = %ChoiceButtons
@onready var rock_button: Button = %RockButton
@onready var paper_button: Button = %PaperButton
@onready var scissors_button: Button = %ScissorsButton

var player_score := 0
var computer_score := 0
var round_in_progress := false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
    _rng.randomize()
    menu_button.pressed.connect(_return_to_menu)
    rock_button.pressed.connect(func(): play_round(&"rock"))
    paper_button.pressed.connect(func(): play_round(&"paper"))
    scissors_button.pressed.connect(func(): play_round(&"scissors"))
    resized.connect(_apply_responsive_layout)
    _reset_round_display()
    _update_score_display()
    _apply_responsive_layout()
    _clear_choice_focus()


func play_round(player_choice: StringName, computer_choice_override: StringName = &"") -> void:
    if round_in_progress or not CHOICES.has(player_choice):
        return

    round_in_progress = true
    _clear_choice_focus()
    _set_choice_buttons_enabled(false)
    var computer_choice := computer_choice_override
    if not CHOICES.has(computer_choice):
        computer_choice = CHOICES[_rng.randi_range(0, CHOICES.size() - 1)]

    _show_locked_choice(player_choice)
    AudioManager.play_sfx(player_choice)
    await _play_reveal_animation(computer_choice)
    if not is_inside_tree():
        return

    var outcome := _get_round_outcome(player_choice, computer_choice)
    var result := _show_round_result(outcome)
    _update_score_display()
    await get_tree().create_timer(0.35).timeout
    if not is_inside_tree():
        return

    round_in_progress = false
    _set_choice_buttons_enabled(true)
    prompt_label.text = "Choose again"
    round_finished.emit(result)


func _show_locked_choice(player_choice: StringName) -> void:
    result_label.text = "Revealing..."
    result_label.add_theme_color_override("font_color", Color("aab2d5"))
    prompt_label.text = ""
    player_choice_icon.texture = CHOICE_TEXTURES[player_choice]
    player_choice_icon.visible = true
    player_unknown.visible = false
    player_choice_name.text = _choice_title(player_choice)
    computer_choice_icon.visible = false
    computer_unknown.visible = true
    computer_unknown.text = "..."
    computer_choice_name.text = "Hidden"


func _play_reveal_animation(computer_choice: StringName) -> void:
    player_choice_icon.pivot_offset = player_choice_icon.size * 0.5
    computer_choice_icon.pivot_offset = computer_choice_icon.size * 0.5
    player_choice_icon.scale = Vector2.ONE

    var anticipation := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
    anticipation.tween_property(player_choice_icon, "scale", Vector2(0.84, 0.84), 0.13)
    anticipation.tween_property(player_choice_icon, "scale", Vector2.ONE, 0.13)
    await anticipation.finished

    computer_choice_icon.texture = CHOICE_TEXTURES[computer_choice]
    computer_choice_icon.visible = true
    computer_choice_icon.scale = Vector2(0.35, 0.35)
    computer_unknown.visible = false
    computer_choice_name.text = _choice_title(computer_choice)
    AudioManager.play_sfx(&"reveal")

    var reveal := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    reveal.tween_property(computer_choice_icon, "scale", Vector2.ONE, 0.22)
    await reveal.finished


func _get_round_outcome(player_choice: StringName, computer_choice: StringName) -> int:
    if not CHOICES.has(player_choice) or not CHOICES.has(computer_choice):
        return 0
    if player_choice == computer_choice:
        return 0
    return 1 if WINNING_MATCHUPS[player_choice] == computer_choice else -1


func _show_round_result(outcome: int) -> StringName:
    if outcome > 0:
        player_score += 1
        result_label.text = "You win!"
        result_label.add_theme_color_override("font_color", Color("4fe0bd"))
        AudioManager.play_sfx(&"win")
        return &"win"
    if outcome < 0:
        computer_score += 1
        result_label.text = "Computer wins"
        result_label.add_theme_color_override("font_color", Color("ff7c8c"))
        AudioManager.play_sfx(&"lose")
        return &"lose"

    result_label.text = "Draw"
    result_label.add_theme_color_override("font_color", Color("ffd166"))
    AudioManager.play_sfx(&"draw")
    return &"draw"


func _reset_round_display() -> void:
    player_choice_icon.visible = false
    player_unknown.visible = true
    player_unknown.text = "?"
    player_choice_name.text = "Your pick"
    computer_choice_icon.visible = false
    computer_unknown.visible = true
    computer_unknown.text = "?"
    computer_choice_name.text = "Waiting"
    result_label.text = "Make your move"
    result_label.remove_theme_color_override("font_color")
    prompt_label.text = "First to the button wins the moment"
    _set_choice_buttons_enabled(true)


func _update_score_display() -> void:
    player_score_label.text = str(player_score)
    computer_score_label.text = str(computer_score)
    score_label.text = "%d  :  %d" % [player_score, computer_score]


func _set_choice_buttons_enabled(enabled: bool) -> void:
    rock_button.disabled = not enabled
    paper_button.disabled = not enabled
    scissors_button.disabled = not enabled


func _clear_choice_focus() -> void:
    rock_button.release_focus()
    paper_button.release_focus()
    scissors_button.release_focus()


func _choice_title(choice: StringName) -> String:
    match choice:
        &"rock":
            return "Rock"
        &"paper":
            return "Paper"
        &"scissors":
            return "Scissors"
        _:
            return "Unknown"


func _apply_responsive_layout() -> void:
    if not is_node_ready():
        return
    var portrait := size.y > size.x
    var compact := size.y < 500.0 and not portrait
    arena.columns = 1 if portrait else 3
    if portrait:
        arena.move_child(computer_card, 0)
        arena.move_child(versus_label, 1)
        arena.move_child(player_card, 2)
    else:
        arena.move_child(player_card, 0)
        arena.move_child(versus_label, 1)
        arena.move_child(computer_card, 2)
    arena.add_theme_constant_override("h_separation", 8)
    arena.add_theme_constant_override("v_separation", 6)
    var margin := 6 if compact else 14
    safe_margin.add_theme_constant_override("margin_left", margin)
    safe_margin.add_theme_constant_override("margin_top", margin)
    safe_margin.add_theme_constant_override("margin_right", margin)
    safe_margin.add_theme_constant_override("margin_bottom", margin)
    header.custom_minimum_size.y = 34.0 if compact else 46.0
    score_panel.custom_minimum_size.y = 38.0 if compact else 54.0
    arena.custom_minimum_size.y = 112.0 if compact else 184.0
    choice_buttons.custom_minimum_size.y = 80.0 if compact else 108.0
    prompt_label.visible = not compact
    for button in [rock_button, paper_button, scissors_button]:
        button.custom_minimum_size.y = 78.0 if compact else 106.0


func _return_to_menu() -> void:
    AudioManager.play_sfx(&"ui")
    get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        _return_to_menu()
        get_viewport().set_input_as_handled()
        return
    if round_in_progress or not event is InputEventKey:
        return

    var key_event := event as InputEventKey
    if not key_event.pressed or key_event.echo:
        return
    match key_event.physical_keycode:
        KEY_1:
            play_round(&"rock")
        KEY_2:
            play_round(&"paper")
        KEY_3:
            play_round(&"scissors")


func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        AudioManager.stop_all()
        get_tree().quit()
