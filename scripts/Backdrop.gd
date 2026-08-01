extends Control

@export var accent_left := Color("6c5ce733")
@export var accent_right := Color("2ed8b633")


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    resized.connect(queue_redraw)
    queue_redraw()


func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color("10142b"))
    var radius := maxf(size.x, size.y) * 0.34
    draw_circle(Vector2(size.x * 0.08, size.y * 0.14), radius, accent_left)
    draw_circle(Vector2(size.x * 0.92, size.y * 0.86), radius * 0.86, accent_right)
    draw_circle(
        Vector2(size.x * 0.72, size.y * 0.08), radius * 0.32, Color("ffd16614")
    )
