extends Control

@onready var name_label: Label = $RowMargin/Row/Labels/NameLabel
@onready var meta_label: Label = $RowMargin/Row/Labels/MetaLabel
@onready var status_badge: Label = $RowMargin/Row/StatusBadge
@onready var avatar_rect: ColorRect = $RowMargin/Row/Avatar
@onready var initial_label: Label = $RowMargin/Row/Avatar/Initial

var player_id: int = -1


func setup(id: int, player_name: String, is_ready: bool) -> void:
	player_id = id
	name_label.text = player_name
	initial_label.text = player_name.left(1).to_upper()
	avatar_rect.color = _color_for_player(id)
	update_status(is_ready)


func update_status(is_ready: bool) -> void:
	status_badge.text = "READY" if is_ready else "WAITING"
	var badge_color := Color("2ebfa5") if is_ready else Color("f2c14e")
	status_badge.add_theme_color_override("font_color", badge_color)
	meta_label.text = "Throw locked" if is_ready else "Choosing stance"


func _color_for_player(id: int) -> Color:
	var palette := [
		Color("2ebfa5"),
		Color("f15b4f"),
		Color("f2c14e"),
		Color("6f8fea"),
	]
	return palette[id % palette.size()]
