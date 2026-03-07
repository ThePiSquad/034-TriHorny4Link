@tool
@icon("res://icon.svg")

extends Control

class_name ShapeIcon

enum ShapeType { RECTANGLE, TRIANGLE }

@export var shape_type: ShapeType = ShapeType.RECTANGLE:
	set(value):
		shape_type = value
		queue_redraw()

@export var is_selected: bool = false:
	set(value):
		is_selected = value
		queue_redraw()

@export var inactive_color: Color = Color(0.4, 0.4, 0.45, 0.6)
@export var selection_ring_color: Color = Color.WHITE

const SELECTION_RING_WIDTH: float = 3.0
const PADDING: float = 4.0

@onready var hud: CanvasLayer = $"../../.."


func _ready() -> void:
	custom_minimum_size = Vector2(64, 64)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _draw() -> void:
	var center = size / 2
	var shape_size = min(size.x, size.y) - PADDING * 4
	
	match shape_type:
		ShapeType.RECTANGLE:
			_draw_rectangle(center, shape_size)
		ShapeType.TRIANGLE:
			_draw_triangle(center, shape_size)
	
	if is_selected:
		match shape_type:
			ShapeType.RECTANGLE:
				_draw_selection_rectangle(center, shape_size + 4)
			ShapeType.TRIANGLE:
				_draw_selection_triangle(center, shape_size + 4)


func _draw_rectangle(center: Vector2, shape_size: float) -> void:
	var half_size = shape_size / 2
	var rect = Rect2(center.x - half_size, center.y - half_size, shape_size, shape_size)
	draw_rect(rect, inactive_color, true)


func _draw_triangle(center: Vector2, shape_size: float) -> void:
	var half_size = shape_size / 2
	var height = shape_size * sqrt(3) / 2
	var top = Vector2(center.x, center.y - height / 2)
	var bottom_left = Vector2(center.x - half_size, center.y + height / 2)
	var bottom_right = Vector2(center.x + half_size, center.y + height / 2)
	var points = PackedVector2Array([top, bottom_right, bottom_left])
	var colors = PackedColorArray([inactive_color, inactive_color, inactive_color])
	draw_polygon(points, colors)


func _draw_selection_rectangle(center: Vector2, shape_size: float) -> void:
	var half_size = shape_size / 2
	var rect = Rect2(center.x - half_size, center.y - half_size, shape_size, shape_size)
	draw_rect(rect, selection_ring_color, false, SELECTION_RING_WIDTH)


func _draw_selection_triangle(center: Vector2, shape_size: float) -> void:
	var half_size = shape_size / 2
	var height = shape_size * sqrt(3) / 2
	var top = Vector2(center.x, center.y - height / 2)
	var bottom_left = Vector2(center.x - half_size, center.y + height / 2)
	var bottom_right = Vector2(center.x + half_size, center.y + height / 2)
	draw_line(top, bottom_right, selection_ring_color, SELECTION_RING_WIDTH, true)
	draw_line(bottom_right, bottom_left, selection_ring_color, SELECTION_RING_WIDTH, true)
	draw_line(bottom_left, top, selection_ring_color, SELECTION_RING_WIDTH, true)


func _gui_input(event: InputEvent) -> void:
	if _is_selection_trigger(event):
		if hud and hud.has_method("select_icon"):
			hud.select_icon(self)
		else:
			is_selected = !is_selected


func _is_selection_trigger(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	elif event is InputEventScreenTouch:
		return event.pressed
	return false
