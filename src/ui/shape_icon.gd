@tool
@icon("res://icon.svg")

extends Control

class_name ShapeIcon

enum ShapeType {
	RECTANGLE,
	TRIANGLE
}

@export var shape_type: ShapeType = ShapeType.RECTANGLE:
	set(value):
		shape_type = value
		queue_redraw()

@export var is_active: bool = false:
	set(value):
		is_active = value
		queue_redraw()

@export var is_selected: bool = false:
	set(value):
		is_selected = value
		queue_redraw()

@export var inactive_color: Color = Color(0.4, 0.4, 0.45, 0.6)
@export var active_color: Color = Color(0.9, 0.9, 0.95, 1.0)
@export var outline_color: Color = Color(0.6, 0.6, 0.65, 0.8)
@export var selection_ring_color: Color = Color.WHITE

const OUTLINE_WIDTH: float = 2.0
const SELECTION_RING_WIDTH: float = 3.0
const PADDING: float = 4.0


func _ready() -> void:
	custom_minimum_size = Vector2(64, 64)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _draw() -> void:
	var center = size / 2
	var shape_size = min(size.x, size.y) - PADDING * 4
	
	var fill_color = active_color if is_active else inactive_color
	
	# 绘制形状
	match shape_type:
		ShapeType.RECTANGLE:
			_draw_rectangle(center, shape_size, fill_color)
		ShapeType.TRIANGLE:
			_draw_triangle(center, shape_size, fill_color)
	
	# 绘制选中状态的高亮描边（使用对应形状的边框）
	if is_selected:
		match shape_type:
			ShapeType.RECTANGLE:
				_draw_selected_rectangle(center, shape_size + 4, selection_ring_color)
			ShapeType.TRIANGLE:
				_draw_selected_triangle(center, shape_size + 4, selection_ring_color)


func _draw_rectangle(center: Vector2, shape_size: float, color: Color) -> void:
	var half_size = shape_size / 2
	var rect = Rect2(center.x - half_size, center.y - half_size, shape_size, shape_size)
	
	# 绘制填充
	draw_rect(rect, color, true)
	
	# 绘制边框
	draw_rect(rect, outline_color, false, OUTLINE_WIDTH)


func _draw_triangle(center: Vector2, shape_size: float, color: Color) -> void:
	var half_size = shape_size / 2
	var height = shape_size * sqrt(3) / 2
	
	# 计算三角形三个顶点（指向上方）
	var top = Vector2(center.x, center.y - height / 2)
	var bottom_left = Vector2(center.x - half_size, center.y + height / 2)
	var bottom_right = Vector2(center.x + half_size, center.y + height / 2)
	
	var points = PackedVector2Array([top, bottom_right, bottom_left])
	var colors = PackedColorArray([color, color, color])
	
	# 绘制填充
	draw_polygon(points, colors)
	
	# 绘制边框
	draw_line(top, bottom_right, outline_color, OUTLINE_WIDTH, true)
	draw_line(bottom_right, bottom_left, outline_color, OUTLINE_WIDTH, true)
	draw_line(bottom_left, top, outline_color, OUTLINE_WIDTH, true)


func _draw_circle_outline(center: Vector2, radius: float, color: Color, width: float) -> void:
	draw_arc(center, radius, 0, TAU, 64, color, width, true)


func _draw_selected_rectangle(center: Vector2, shape_size: float, color: Color) -> void:
	var half_size = shape_size / 2
	var rect = Rect2(center.x - half_size, center.y - half_size, shape_size, shape_size)
	draw_rect(rect, color, false, SELECTION_RING_WIDTH)


func _draw_selected_triangle(center: Vector2, shape_size: float, color: Color) -> void:
	var half_size = shape_size / 2
	var height = shape_size * sqrt(3) / 2
	
	# 计算三角形三个顶点（指向上方）
	var top = Vector2(center.x, center.y - height / 2)
	var bottom_left = Vector2(center.x - half_size, center.y + height / 2)
	var bottom_right = Vector2(center.x + half_size, center.y + height / 2)
	
	draw_line(top, bottom_right, color, SELECTION_RING_WIDTH, true)
	draw_line(bottom_right, bottom_left, color, SELECTION_RING_WIDTH, true)
	draw_line(bottom_left, top, color, SELECTION_RING_WIDTH, true)


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
