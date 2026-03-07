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
		_target_fill_ratio = clamp(value, 0.0, 1.0)
		queue_redraw()

@export var is_selected: bool = false:
	set(value):
		is_selected = value
		queue_redraw()

@export var outline_color: Color = Color.WHITE
@export var selection_ring_color: Color = Color.WHITE
@export var animation_speed: float = 5.0

const OUTLINE_WIDTH: float = 2.0
const SELECTION_RING_WIDTH: float = 3.0
const PADDING: float = 4.0

var _current_fill_ratio: float = 0.0
var _target_fill_ratio: float = 0.5


func _ready() -> void:
	custom_minimum_size = Vector2(64, 64)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_current_fill_ratio = _target_fill_ratio


func _process(delta: float) -> void:
	# 平滑动画：当前值向目标值插值
	if abs(_current_fill_ratio - _target_fill_ratio) > 0.001:
		_current_fill_ratio = lerp(_current_fill_ratio, _target_fill_ratio, animation_speed * delta)
		queue_redraw()


func _draw() -> void:
	var center = size / 2
	var radius = min(size.x, size.y) / 2 - PADDING
	
	# 绘制填充部分（盈满度）- 使用当前动画值
	if _current_fill_ratio > 0:
		_draw_fill(center, radius, _current_fill_ratio)
	
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
	
	# 处理特殊情况：完全空或完全满
	if ratio <= 0.001:
		return  # 完全空，不绘制
	elif ratio >= 0.999:
		# 完全填满，绘制完整圆形
		draw_circle(center, radius, circle_color)
		return
	
	# 创建填充区域的多边形
	var points = PackedVector2Array()
	var colors = PackedColorArray()
	
	# 从圆底部开始，向上填充
	var segments = 32
	for i in range(segments + 1):
		var angle = PI + (PI * i / segments)  # 从左侧到右侧（底部半圆）
		var x = center.x + cos(angle) * radius
		var y = center.y + sin(angle) * radius
		
		# 只添加在填充高度内的点
		if y >= fill_top:
			points.append(Vector2(x, clamp(y, fill_top, fill_bottom)))
			colors.append(circle_color)
	
	# 确保有足够的点来创建多边形
	if points.size() < 2:
		return  # 点太少，无法创建多边形
	
	# 创建填充区域的多边形（梯形）
	var leftmost = points[0]
	var rightmost = points[points.size() - 1]
	
	# 构建梯形的四个顶点
	var trapezoid = PackedVector2Array()
	trapezoid.append(Vector2(leftmost.x, fill_top))  # 左上
	trapezoid.append(Vector2(rightmost.x, fill_top))  # 右上
	trapezoid.append(rightmost)  # 右下
	trapezoid.append(leftmost)  # 左下
	
	# 确保点的顺序是顺时针或逆时针，避免自相交
	var trapezoid_colors = PackedColorArray()
	for i in range(4):
		trapezoid_colors.append(circle_color)
	
	# 绘制梯形
	draw_polygon(trapezoid, trapezoid_colors)


func _draw_circle_outline(center: Vector2, radius: float, color: Color, width: float) -> void:
	draw_arc(center, radius, 0, TAU, 64, color, width, true)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# 调用父级 HUD 的 select_icon 方法实现单选
			var hud = get_parent().get_parent().get_parent()
			if hud and hud.has_method("select_icon"):
				hud.select_icon(self)
			else:
				# 如果没有 HUD，则使用本地选中逻辑
				is_selected = !is_selected
