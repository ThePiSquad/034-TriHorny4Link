@tool
@icon("res://icon.svg")

extends Control

class_name ColorCircle

@export var circle_color: Color = Color.RED:
	set(value):
		circle_color = value
		queue_redraw()

@export var fill_ratio: float = 0.5:
	set(value):
		fill_ratio = clamp(value, 0.0, 1.0)
		queue_redraw()

@export var is_selected: bool = false:
	set(value):
		is_selected = value
		queue_redraw()

@export var outline_color: Color = Color.WHITE
@export var selection_ring_color: Color = Color.WHITE

const OUTLINE_WIDTH: float = 2.0
const SELECTION_RING_WIDTH: float = 3.0
const PADDING: float = 4.0


func _ready() -> void:
	custom_minimum_size = Vector2(64, 64)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _draw() -> void:
	var center = size / 2
	var radius = min(size.x, size.y) / 2 - PADDING
	
	# 绘制填充部分（盈满度）
	if fill_ratio > 0:
		_draw_fill(center, radius, fill_ratio)
	
	# 绘制圆形轮廓
	_draw_circle_outline(center, radius, outline_color, OUTLINE_WIDTH)
	
	# 绘制选中状态的高亮圆环
	if is_selected:
		var selection_radius = radius + PADDING / 2
		_draw_circle_outline(center, selection_radius, selection_ring_color, SELECTION_RING_WIDTH)


func _draw_fill(center: Vector2, radius: float, ratio: float) -> void:
	# 计算填充高度
	var fill_height = radius * 2 * ratio
	var fill_bottom = center.y + radius
	var fill_top = fill_bottom - fill_height
	
	# 创建填充区域的多边形
	var points = PackedVector2Array()
	var colors = PackedColorArray()
	
	# 从圆底部开始，向上填充
	var segments = 32
	for i in range(segments + 1):
		var angle = PI + (PI * i / segments)  # 从左侧到右侧（底部半圆）
		if ratio < 1.0:
			# 如果未填满，截断到填充高度
			var y = center.y + sin(angle) * radius
			if y < fill_top:
				continue
			
		var x = center.x + cos(angle) * radius
		var y = clamp(center.y + sin(angle) * radius, fill_top, center.y + radius)
		points.append(Vector2(x, y))
		colors.append(circle_color)
	
	# 添加填充顶部的直线
	if ratio < 1.0 and points.size() > 0:
		# 找到左右边界
		var leftmost = points[0]
		var rightmost = points[points.size() - 1]
		
		# 添加顶部直线上的点
		var top_points = PackedVector2Array()
		var top_colors = PackedColorArray()
		
		for i in range(points.size() - 1, -1, -1):
			top_points.append(points[i])
			top_colors.append(circle_color)
		
		# 添加填充矩形的底部角点
		top_points.append(Vector2(rightmost.x, fill_bottom))
		top_colors.append(circle_color)
		top_points.append(Vector2(leftmost.x, fill_bottom))
		top_colors.append(circle_color)
		
		draw_polygon(top_points, top_colors)
	else:
		# 完全填满，绘制完整圆形
		draw_circle(center, radius, circle_color)


func _draw_circle_outline(center: Vector2, radius: float, color: Color, width: float) -> void:
	draw_arc(center, radius, 0, TAU, 64, color, width, true)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			is_selected = !is_selected
