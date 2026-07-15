extends Control

@export_enum("Menu", "Arena") var variant := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var canvas_size := size
	var base_color := Color("111516") if variant == 0 else Color("141313")
	var grid_color := Color("263031") if variant == 0 else Color("312725")
	var accent_color := Color("2ebfa5") if variant == 0 else Color("f15b4f")
	var warm_color := Color("f2c14e")
	draw_rect(Rect2(Vector2.ZERO, canvas_size), base_color)

	for x in range(-200, int(canvas_size.x) + 240, 64):
		draw_line(Vector2(x, 0), Vector2(x + 360, canvas_size.y), grid_color, 1.0)
	for y in range(20, int(canvas_size.y), 64):
		draw_line(Vector2(0, y), Vector2(canvas_size.x, y), grid_color, 1.0)

	var right_band := PackedVector2Array([
		Vector2(canvas_size.x * 0.73, 0),
		Vector2(canvas_size.x, 0),
		Vector2(canvas_size.x, canvas_size.y),
		Vector2(canvas_size.x * 0.91, canvas_size.y),
	])
	draw_colored_polygon(right_band, Color(accent_color, 0.12))

	var slash_band := PackedVector2Array([
		Vector2(0, canvas_size.y * 0.80),
		Vector2(canvas_size.x * 0.36, canvas_size.y),
		Vector2(0, canvas_size.y),
	])
	draw_colored_polygon(slash_band, Color(warm_color, 0.10))

	for row in range(8):
		for column in range(14):
			var dot_position := Vector2(
				canvas_size.x - 26.0 - column * 18.0,
				28.0 + row * 18.0
			)
			draw_circle(dot_position, 2.0 + float(row % 3), Color(accent_color, 0.38))

	for slash in range(5):
		var start := Vector2(36.0 + slash * 22.0, canvas_size.y - 44.0)
		draw_line(start, start + Vector2(74.0, -74.0), Color(warm_color, 0.50), 4.0)
