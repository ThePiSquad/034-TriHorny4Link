@abstract

extends Node2D

@export var size:float = Constants.Enermy.default_size
# A minimal-sized squad that can engulf the shape
@export var color:Color = Constants.Enermy.default_color

@abstract
func _draw() -> void

func draw_polygon_from_points(points:PackedVector2Array)->void:
	draw_colored_polygon(points,color)
