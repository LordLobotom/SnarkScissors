extends Node

const MAIN_MENU_SCENE := preload("res://scenes/MainMenu.tscn")
const GAME_SCENE := preload("res://scenes/GameScene.tscn")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	assert(AudioServer.get_bus_index(&"Music") >= 0, "Music bus is missing")
	assert(AudioServer.get_bus_index(&"SFX") >= 0, "SFX bus is missing")

	var menu := MAIN_MENU_SCENE.instantiate()
	add_child(menu)
	await get_tree().process_frame

	var overlay: Control = menu.get_node("SettingsOverlay")
	overlay.open(false)
	await get_tree().process_frame
	assert(overlay.visible, "Settings overlay did not open")
	var resolution_option: OptionButton = overlay.get_node(
		"Center/SettingsCard/CardMargin/Content/DisplayPanel/DisplayMargin/DisplayStack/ResolutionRow/ResolutionOption"
	)
	assert(
		resolution_option.item_count == SettingsManager.RESOLUTIONS.size(),
		"Resolution options are incomplete"
	)

	var capture_path := OS.get_environment("SNARK_CAPTURE_PATH")
	if not capture_path.is_empty():
		await RenderingServer.frame_post_draw
		var screenshot := get_viewport().get_texture().get_image()
		var error := screenshot.save_png(capture_path)
		assert(error == OK, "Could not save UI smoke screenshot")

	overlay.close()
	menu.queue_free()
	await get_tree().process_frame

	var game := GAME_SCENE.instantiate()
	add_child(game)
	await get_tree().process_frame
	assert(game.get_node("ResultOverlay") != null, "Result overlay is missing")
	assert(
		game.get_node("MainMargin/MainVBox/Arena/CenterStage/CenterMargin/CenterVBox/ChoiceButtons/RockButton").disabled,
		"Choice buttons should start locked"
	)
	assert(game._get_rps_winner("rock", "scissors") == 1, "Rock should beat scissors")
	assert(game._get_rps_winner("paper", "scissors") == 2, "Scissors should beat paper")
	assert(game._get_rps_winner("rock", "rock") == 0, "Matching throws should draw")

	game.queue_free()
	await get_tree().process_frame
	AudioManager.stop_all()
	await get_tree().process_frame
	print("UI_SMOKE_OK")
	get_tree().quit()
