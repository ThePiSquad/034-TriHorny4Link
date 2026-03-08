@tool
class_name ShapeDrawer
extends Node2D

@export_group("Shape")
@export var shape_type: Enums.ShapeType = Enums.ShapeType.CIRCLE
@export var shape_size: Vector2 = Vector2(Constants.grid_size, Constants.grid_size)
@export var corner_radius: float = 8.0

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
	var center = Vector2.ZERO
	var radius = min(shape_size.x, shape_size.y) / 2
	if fill_enabled:
		draw_circle(center, radius, fill_color)
	if stroke_enabled:
		draw_arc(center, radius, 0, TAU, 64, stroke_color, stroke_width, true)

func _draw_triangle() -> void:
	var points = PackedVector2Array([
		Vector2(-shape_size.x / 2, shape_size.y / 2),
		Vector2(0, -shape_size.y / 2),
		Vector2(shape_size.x / 2, shape_size.y / 2)
	])
	if fill_enabled:
		var colors = PackedColorArray([fill_color, fill_color, fill_color])
		draw_polygon(points, colors)
	if stroke_enabled:
		var closed_points = PackedVector2Array(points)
		closed_points.append(points[0])
		draw_polyline(closed_points, stroke_color, stroke_width, true)

func _draw_rectangle() -> void:
	if fill_enabled:
		_draw_rounded_rectangle_fill()
	if stroke_enabled:
		_draw_rounded_rectangle_stroke()

func _draw_rounded_rectangle_fill() -> void:
	var half_width = shape_size.x / 2
	var half_height = shape_size.y / 2
	var temp_r = min(half_width, half_height)
	var r = min(corner_radius, temp_r)
	
	var points = PackedVector2Array()
	var colors = PackedColorArray()
	
	# 左上角圆弧
	for i in range(8):
		var angle = PI + i * PI / 16
		points.append(Vector2(
			-half_width + r + cos(angle) * r,
			-half_height + r + sin(angle) * r
		))
		colors.append(fill_color)
	
	# 右上角圆弧
	for i in range(8):
		var angle = -PI / 2 + i * PI / 16
		points.append(Vector2(
			half_width - r + cos(angle) * r,
			-half_height + r + sin(angle) * r
		))
		colors.append(fill_color)
	
	# 右下角圆弧
	for i in range(8):
		var angle = 0 + i * PI / 16
		points.append(Vector2(
			half_width - r + cos(angle) * r,
			half_height - r + sin(angle) * r
		))
		colors.append(fill_color)
	
	# 左下角圆弧
	for i in range(8):
		var angle = PI / 2 + i * PI / 16
		points.append(Vector2(
			-half_width + r + cos(angle) * r,
			half_height - r + sin(angle) * r
		))
		colors.append(fill_color)
	
	draw_polygon(points, colors)

func _draw_rounded_rectangle_stroke() -> void:
	var half_width = shape_size.x / 2
	var half_height = shape_size.y / 2
	var r = min(corner_radius, min(half_width, half_height))
	
	var points = PackedVector2Array()
	
	# 左上角圆弧
	for i in range(8):
		var angle = PI + i * PI / 16
		points.append(Vector2(
			-half_width + r + cos(angle) * r,
			-half_height + r + sin(angle) * r
		))
	
	# 右上角圆弧
	for i in range(8):
		var angle = -PI / 2 + i * PI / 16
		points.append(Vector2(
			half_width - r + cos(angle) * r,
			-half_height + r + sin(angle) * r
		))
	
	# 右下角圆弧
	for i in range(8):
		var angle = 0 + i * PI / 16
		points.append(Vector2(
			half_width - r + cos(angle) * r,
			half_height - r + sin(angle) * r
		))
	
	# 左下角圆弧
	for i in range(8):
		var angle = PI / 2 + i * PI / 16
		points.append(Vector2(
			-half_width + r + cos(angle) * r,
			half_height - r + sin(angle) * r
		))
	
	# 闭合路径
	points.append(points[0])
	
	draw_polyline(points, stroke_color, stroke_width, true)
