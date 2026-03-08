@tool
class_name ShapeDrawer
extends Node2D

@export_group("Shape")
@export var shape_type: Enums.ShapeType = Enums.ShapeType.CIRCLE
@export var shape_size: Vector2 = Vector2(Constants.grid_size, Constants.grid_size)

@export_group("Fill")
@export var fill_color: Color = Color.RED
@export var fill_enabled: bool = true

@export_group("Stroke")
@export var stroke_color: Color = Color.WHITE
@export var stroke_width: float = 2.0
@export var stroke_enabled: bool = true

func _draw() -> void:
	match shape_type:
		Enums.ShapeType.CIRCLE:
			_draw_circle()
		Enums.ShapeType.TRIANGLE:
			_draw_triangle()
		Enums.ShapeType.RECTANGLE:
			_draw_rectangle()

func _draw_circle() -> void:
	var center = shape_size / 2
	var radius = min(shape_size.x, shape_size.y) / 2
	if fill_enabled:
		draw_circle(center, radius, fill_color)
	if stroke_enabled:
		draw_arc(center, radius, 0, TAU, 64, stroke_color, stroke_width, true)

func _draw_triangle() -> void:
	var points = PackedVector2Array([
		Vector2(shape_size.x / 2, 0),
		Vector2(shape_size.x, shape_size.y),
		Vector2(0, shape_size.y)
	])
	if fill_enabled:
		var colors = PackedColorArray([fill_color, fill_color, fill_color])
		draw_polygon(points, colors)
	if stroke_enabled:
		var closed_points = PackedVector2Array(points)
		closed_points.append(points[0])
		draw_polyline(closed_points, stroke_color, stroke_width, true)

func _draw_rectangle() -> void:
	var rect = Rect2(Vector2.ZERO, shape_size)
	if fill_enabled:
		draw_rect(rect, fill_color, true)
	if stroke_enabled:
		draw_rect(rect, stroke_color, false, stroke_width)
