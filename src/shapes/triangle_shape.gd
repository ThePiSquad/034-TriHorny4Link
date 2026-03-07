extends BaseShape

const BaseShape = preload("res://src/shapes/base_shape.gd")

func get_points()->PackedVector2Array:
	return PackedVector2Array([
		Vector2(0,0),
		Vector2(size,0),
		Vector2(size/2,size)
	]	
	)

func _draw() -> void:
	draw_polygon_from_points(get_points())
