extends Control

const GAME_SCENE := preload("res://scenes/GameScene.tscn")

@onready var play_button: Button = %PlayButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton
@onready var settings_overlay: Control = $SettingsOverlay
@onready var safe_margin: MarginContainer = $SafeMargin
@onready var menu_card: PanelContainer = %MenuCard
@onready var card_margin: MarginContainer = %CardMargin
@onready var brand_icon: TextureRect = %BrandIcon
@onready var title_label: Label = %TitleLabel


func _ready() -> void:
    play_button.pressed.connect(_on_play_pressed)
    settings_button.pressed.connect(settings_overlay.open)
    quit_button.pressed.connect(_on_quit_pressed)
    resized.connect(_apply_responsive_layout)
    _apply_responsive_layout()
    play_button.grab_focus()


func _on_play_pressed() -> void:
    AudioManager.play_sfx(&"ui")
    get_tree().change_scene_to_packed(GAME_SCENE)


func _on_quit_pressed() -> void:
    AudioManager.play_sfx(&"ui")
    AudioManager.stop_all()
    get_tree().quit()


func _apply_responsive_layout() -> void:
    if not is_node_ready():
        return
    var compact := size.y < 500.0
    var safe := 6 if compact else 16
    var inner := 15 if compact else 28
    for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
        safe_margin.add_theme_constant_override(side, safe)
        card_margin.add_theme_constant_override(side, inner)
    menu_card.custom_minimum_size.x = clampf(size.x - 28.0, 330.0, 400.0)
    var icon_size := 48.0 if compact else 72.0
    brand_icon.custom_minimum_size = Vector2(icon_size, icon_size)
    title_label.add_theme_font_size_override("font_size", 38 if compact else 50)
    for button in [play_button, settings_button, quit_button]:
        button.custom_minimum_size.y = 48.0 if compact else 60.0


func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        AudioManager.stop_all()
        get_tree().quit()
