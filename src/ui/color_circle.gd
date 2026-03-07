@tool
@icon("res://icon.svg")

extends Control

class_name ColorCircle

@export var circle_color: Color = Color.RED
@export var fill_ratio: float = 0.5
@export var is_selected: bool = false:
	set(value):
		is_selected = value
		queue_redraw()

@export var selection_ring_color: Color = Color.WHITE

const PADDING: float = 4.0

@onready var hud: CanvasLayer = $"../../.."


func _ready() -> void:
	custom_minimum_size = Vector2(64, 64)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _draw() -> void:
	var center = size / 2
	var radius = min(size.x, size.y) / 2 - PADDING
	
	if fill_ratio > 0.001:
		_draw_fill(center, radius, fill_ratio)
	
	var outline_width = 2.0
	draw_arc(center, radius, 0, TAU, 64, circle_color, outline_width, true)
	
	if is_selected:
		var selection_radius = radius + PADDING / 2
		draw_arc(center, selection_radius, 0, TAU, 64, selection_ring_color, 3.0, true)


func _draw_fill(center: Vector2, radius: float, ratio: float) -> void:
	if ratio >= 1.0:
		draw_circle(center, radius, circle_color)
		return
	
	var fill_bottom = center.y + radius
	var fill_top = fill_bottom - radius * 2 * ratio
	
	var segments = 64
	var points = PackedVector2Array()
	
	for i in range(segments + 1):
		var t = float(i) / segments
		var y = lerp(fill_top, fill_bottom, t)
		var dy = y - center.y
		if abs(dy) <= radius:
			var half_width = sqrt(radius * radius - dy * dy)
			points.append(Vector2(center.x - half_width, y))
	
	for i in range(segments, -1, -1):
		var t = float(i) / segments
		var y = lerp(fill_top, fill_bottom, t)
		var dy = y - center.y
		if abs(dy) <= radius:
			var half_width = sqrt(radius * radius - dy * dy)
			points.append(Vector2(center.x + half_width, y))
	
	if points.size() >= 3:
		var colors = PackedColorArray()
		colors.resize(points.size())
		for i in range(points.size()):
			colors[i] = circle_color
		draw_polygon(points, colors)


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
