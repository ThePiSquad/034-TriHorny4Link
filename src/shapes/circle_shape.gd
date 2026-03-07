extends BaseShape

const BaseShape = preload("res://src/shapes/base_shape.gd")

func _draw() -> void:
	draw_circle(Vector2(size/2,size/2),size/2,color,true)
