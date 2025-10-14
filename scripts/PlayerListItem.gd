# PlayerListItem.gd
extends Control

@onready var name_label: Label = $Panel/RowMargin/Row/Labels/NameLabel
@onready var meta_label: Label = $Panel/RowMargin/Row/Labels/MetaLabel
@onready var status_badge: Label = $Panel/RowMargin/Row/StatusBadge
@onready var avatar_rect: ColorRect = $Panel/RowMargin/Row/Avatar

var player_id: int = -1

func setup(id: int, player_name: String, ready: bool):
	player_id = id
	name_label.text = player_name
	meta_label.text = "Connected" if ready else "Waiting for ready"
	avatar_rect.color = _color_for_player(id)
	update_status(ready)

func update_status(ready: bool):
	var text = "Ready" if ready else "Not ready"
	status_badge.text = text
	var badge_color = Color(0.43, 0.85, 0.53) if ready else Color(0.89, 0.46, 0.42)
	status_badge.add_theme_color_override("font_color", badge_color)
	meta_label.text = "Ready to launch" if ready else "Needs to lock in"

func _color_for_player(id: int) -> Color:
	var palette = [
		Color(0.29, 0.37, 0.92),
		Color(0.91, 0.56, 0.29),
		Color(0.41, 0.86, 0.79),
		Color(0.86, 0.37, 0.73)
	]
	return palette[id % palette.size()]
