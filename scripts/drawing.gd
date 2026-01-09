extends Node2D

func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(-100,0), Vector2(160,160), Vector2(0,160), Vector2(160,0)]), Color(1,0,0 ))
	draw_circle(Vector2(0,0), 100.0, Color(1,0,0))
