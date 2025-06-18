# PlayerListItem.gd
extends Control

@onready var name_label: Label = $HBox/NameLabel
@onready var status_label: Label = $HBox/StatusLabel

var player_id: int = -1

func setup(id: int, player_name: String, ready: bool):
	player_id = id
	name_label.text = player_name
	update_status(ready)

func update_status(ready: bool):
	status_label.text = "Připraven" if ready else "Nepřipraven"
	status_label.modulate = Color.GREEN if ready else Color.RED
