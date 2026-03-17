@tool
class_name ShapeDrawer
extends Node2D

# 形状配置
@export_group("Shape")
@export var shape_type: Enums.ShapeType = Enums.ShapeType.CIRCLE:
	set(s):
		shape_type = s
		_update_collision_shape()
		queue_redraw()
@export var shape_size: Vector2 = Vector2(Constants.grid_size, Constants.grid_size):
	set(s):
		shape_size = s
		_update_shader_params() 
		_update_collision_shape()
		queue_redraw()

@export var corner_radius: float = 8.0

# 填充配置
@export_group("Fill")
@export var fill_color: Color = Color.RED:
	set(s):
		fill_color = s
		queue_redraw()
@export var fill_enabled: bool = true

# 描边配置
@export_group("Stroke")
@export var stroke_color: Color = Color.WHITE
@export var stroke_width: float = 2.0
@export var stroke_enabled: bool = true

var _input_area: Area2D

func _ready() -> void:
	_setup_input_area()

func _setup_input_area() -> void:
	_input_area = Area2D.new()
	_input_area.name = "InputArea"
	_input_area.input_pickable = true
	add_child(_input_area)
	_update_collision_shape()

func _update_collision_shape() -> void:
	if not _input_area:
		return
	
	for child in _input_area.get_children():
		child.queue_free()
	
	# 使用 call_deferred 避免在物理查询刷新期间改变监控状态
	call_deferred("_add_new_collision_shape")

func _add_new_collision_shape() -> void:
	"""延迟添加新的碰撞形状"""
	if not _input_area:
		return
	
	var shape: Shape2D
	match shape_type:
		Enums.ShapeType.CIRCLE:
			var circle = CircleShape2D.new()
			circle.radius = min(shape_size.x, shape_size.y) / 2
			shape = circle
		Enums.ShapeType.TRIANGLE, Enums.ShapeType.RECTANGLE:
			var rect = RectangleShape2D.new()
			rect.size = shape_size
			shape = rect
		_:
			var rect = RectangleShape2D.new()
			rect.size = shape_size
			shape = rect
	
	var collision = CollisionShape2D.new()
	collision.shape = shape
	_input_area.add_child(collision)

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
	var r = min(corner_radius, min(half_width, half_height))
	
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
	
	points.append(points[0])
	draw_polyline(points, stroke_color, stroke_width, true)

func _update_shader_params() -> void:
	if material is ShaderMaterial:
		# 告诉 Shader 当前形状的长宽，用于计算 UV 映射
		material.set_shader_parameter("shape_size", shape_size)
