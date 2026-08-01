extends Node

const MAIN_MENU_SCENE := preload("res://scenes/MainMenu.tscn")
const GAME_SCENE := preload("res://scenes/GameScene.tscn")


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_run")


func _run() -> void:
    await _apply_requested_window_size()
    assert(AudioServer.get_bus_index(&"Music") >= 0, "Music bus is missing")
    assert(AudioServer.get_bus_index(&"SFX") >= 0, "SFX bus is missing")

    var capture_path := OS.get_environment("SNARK_CAPTURE_PATH")
    var capture_view := OS.get_environment("SNARK_CAPTURE_VIEW")
    if capture_view.is_empty():
        capture_view = "menu"

    var menu := MAIN_MENU_SCENE.instantiate()
    add_child(menu)
    await get_tree().process_frame
    assert(menu.get_node("%PlayButton") is Button, "Play button is missing")
    assert(menu.get_node("%SettingsButton") is Button, "Settings button is missing")
    assert(menu.get_node("%QuitButton") is Button, "Quit button is missing")
    assert(_count_menu_buttons(menu) == 3, "Main menu should expose exactly three buttons")
    assert(menu.GAME_SCENE is PackedScene, "Play target scene is missing")
    assert(
        not menu.get_node("%PlayButton").get_signal_connection_list("pressed").is_empty(),
        "Play button is not connected"
    )

    if not capture_path.is_empty() and capture_view == "menu":
        await _save_capture(capture_path)

    var overlay: Control = menu.get_node("SettingsOverlay")
    overlay.open(false)
    await get_tree().process_frame
    assert(overlay.visible, "Settings overlay did not open")
    assert(get_tree().paused, "Settings should pause the current scene")
    assert(overlay.get_node("%MasterSlider") is HSlider, "Master volume control is missing")
    assert(overlay.get_node("%MusicSlider") is HSlider, "Music volume control is missing")
    assert(overlay.get_node("%SFXSlider") is HSlider, "Effects volume control is missing")
    if not capture_path.is_empty() and capture_view == "settings":
        await _save_capture(capture_path)
    overlay.close()
    assert(not get_tree().paused, "Closing settings should resume the scene")

    menu.queue_free()
    await get_tree().process_frame

    var game := GAME_SCENE.instantiate()
    add_child(game)
    await get_tree().process_frame
    assert(
        game.get_node_or_null("%SettingsButton") == null,
        "Settings should only be available from the main menu"
    )
    var rock_button: Button = game.get_node("%RockButton")
    var paper_button: Button = game.get_node("%PaperButton")
    var scissors_button: Button = game.get_node("%ScissorsButton")
    assert(not rock_button.disabled, "Rock should be ready immediately")
    assert(not paper_button.disabled, "Paper should be ready immediately")
    assert(not scissors_button.disabled, "Scissors should be ready immediately")
    assert(not rock_button.has_focus(), "Rock should not start highlighted")
    assert(not paper_button.has_focus(), "Paper should not start highlighted")
    assert(not scissors_button.has_focus(), "Scissors should not start highlighted")
    assert(rock_button.custom_minimum_size.y >= 48.0, "Rock touch target is too small")
    var arena: GridContainer = game.get_node("%Arena")
    if game.size.y > game.size.x:
        assert(arena.get_child(0).name == "ComputerCard", "Portrait should put CPU on top")
        assert(arena.get_child(2).name == "PlayerCard", "Portrait should put player below")
    else:
        assert(arena.get_child(0).name == "PlayerCard", "Landscape should put player left")
        assert(arena.get_child(2).name == "ComputerCard", "Landscape should put CPU right")
    _assert_all_rps_outcomes(game)

    game.play_round(&"rock", &"scissors")
    assert(game.round_in_progress, "Round should lock while choices reveal")
    assert(not rock_button.has_focus(), "Playing a round should clear the choice highlight")
    assert(rock_button.disabled, "Choice buttons should lock during reveal")
    assert(not game.get_node("%ComputerChoiceIcon").visible, "CPU choice leaked before reveal")
    var result = await game.round_finished
    assert(result == &"win", "Injected rock versus scissors should win")
    assert(game.player_score == 1, "Player score should increment once")
    assert(game.computer_score == 0, "Computer score should not increment on a player win")
    assert(not rock_button.disabled, "Choice buttons should unlock after the round")
    assert(not rock_button.has_focus(), "Rock should stay neutral after the round")
    assert(game.get_node("%ComputerChoiceIcon").visible, "CPU choice should be revealed")
    assert(game.get_node("%ResultLabel").text == "You win!", "Round result is not visible")

    if not capture_path.is_empty() and capture_view == "game":
        await _save_capture(capture_path)

    game.queue_free()
    await get_tree().process_frame
    AudioManager.stop_all()
    await get_tree().process_frame
    print("UI_SMOKE_OK")
    get_tree().quit()


func _count_menu_buttons(menu: Node) -> int:
    var count := 0
    var overlay := menu.get_node("SettingsOverlay")
    for node in menu.find_children("*", "Button", true, false):
        if not overlay.is_ancestor_of(node):
            count += 1
    return count


func _assert_all_rps_outcomes(game: Node) -> void:
    assert(game._get_round_outcome(&"rock", &"rock") == 0)
    assert(game._get_round_outcome(&"rock", &"paper") == -1)
    assert(game._get_round_outcome(&"rock", &"scissors") == 1)
    assert(game._get_round_outcome(&"paper", &"rock") == 1)
    assert(game._get_round_outcome(&"paper", &"paper") == 0)
    assert(game._get_round_outcome(&"paper", &"scissors") == -1)
    assert(game._get_round_outcome(&"scissors", &"rock") == -1)
    assert(game._get_round_outcome(&"scissors", &"paper") == 1)
    assert(game._get_round_outcome(&"scissors", &"scissors") == 0)


func _apply_requested_window_size() -> void:
    var requested := OS.get_environment("SNARK_CAPTURE_SIZE")
    if requested.is_empty():
        return
    var parts := requested.to_lower().split("x")
    if parts.size() != 2:
        return
    DisplayServer.window_set_size(Vector2i(int(parts[0]), int(parts[1])))
    await get_tree().process_frame
    await get_tree().process_frame


func _save_capture(path: String) -> void:
    await get_tree().process_frame
    await get_tree().process_frame
    await RenderingServer.frame_post_draw
    var screenshot := get_viewport().get_texture().get_image()
    screenshot.convert(Image.FORMAT_RGB8)
    var error := screenshot.save_png(path)
    assert(error == OK, "Could not save UI smoke screenshot")
