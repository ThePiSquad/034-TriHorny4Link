@tool
extends Control

class_name UIShapeDisplay

# 形状类型枚举（独立于游戏实体的 Enums.ShapeType）
enum ShapeType {
	CIRCLE,      # 圆形
	TRIANGLE,    # 三角形
	RECTANGLE    # 矩形
}

# 形状配置
@export_group("Shape")
@export var shape_type: ShapeType = ShapeType.CIRCLE:
	set(value):
		shape_type = value
		queue_redraw()

@export var shape_size: Vector2 = Vector2(40, 40):
	set(value):
		shape_size = value
		custom_minimum_size = value
		size = value
		queue_redraw()

# 颜色配置
@export_group("Color")
@export var fill_color: Color = Color.RED:
	set(value):
		fill_color = value
		queue_redraw()

@export var stroke_color: Color = Color.WHITE:
	set(value):
		stroke_color = value
		queue_redraw()

@export var stroke_width: float = 2.0:
	set(value):
		stroke_width = value
		queue_redraw()

# 填充和描边开关
@export var fill_enabled: bool = true:
	set(value):
		fill_enabled = value
		queue_redraw()

@export var stroke_enabled: bool = true:
	set(value):
		stroke_enabled = value
		queue_redraw()

func _ready() -> void:
	# 设置最小尺寸
	custom_minimum_size = shape_size
	# 强制更新尺寸
	size = shape_size

func _draw() -> void:
	match shape_type:
		ShapeType.CIRCLE:
			_draw_circle()
		ShapeType.TRIANGLE:
			_draw_triangle()
		ShapeType.RECTANGLE:
			_draw_rectangle()

func _draw_circle() -> void:
	var center = size / 2
	var radius = min(shape_size.x, shape_size.y) / 2
	
	if fill_enabled:
		draw_circle(center, radius, fill_color)
	
	if stroke_enabled:
		draw_arc(center, radius, 0, TAU, 64, stroke_color, stroke_width, true)

func _draw_triangle() -> void:
	var center = size / 2
	var half_width = shape_size.x / 2
	var half_height = shape_size.y / 2
	
	# 等边三角形顶点
	var top = Vector2(center.x, center.y - half_height)
	var bottom_left = Vector2(center.x - half_width, center.y + half_height)
	var bottom_right = Vector2(center.x + half_width, center.y + half_height)
	
	var points = PackedVector2Array([top, bottom_right, bottom_left])
	
	if fill_enabled:
		var colors = PackedColorArray([fill_color, fill_color, fill_color])
		draw_polygon(points, colors)
	
	if stroke_enabled:
		draw_polyline(points, stroke_color, stroke_width, true)
		draw_line(top, bottom_left, stroke_color, stroke_width, true)

func _draw_rectangle() -> void:
	var center = size / 2
	var half_width = shape_size.x / 2
	var half_height = shape_size.y / 2
	
	var rect = Rect2(
		center.x - half_width,
		center.y - half_height,
		shape_size.x,
		shape_size.y
	)
	
	if fill_enabled:
		draw_rect(rect, fill_color)
	
	if stroke_enabled:
		draw_rect(rect, stroke_color, false, stroke_width)
