@tool
@icon("res://icon.svg")

extends Control

class_name ColorCircle

@export var circle_color: Color = Color.RED
@export var fill_ratio: float = 0.5:
	set(value):
		# 存储目标值
		target_fill_ratio = clamp(value, 0.0, 1.0)

@export var is_selected: bool = false:
	set(value):
		is_selected = value
		# 如果被选中，停止高亮动画
		if value and highlight_animation:
			highlight_animation = false
		queue_redraw()

@export var selection_ring_color: Color = Color.WHITE

@export var disabled: bool = false:
	set(value):
		disabled = value
		queue_redraw()

@export var highlight_animation: bool = false:
	set(value):
		highlight_animation = value
		print("设置highlight_animation为：", value, "，节点是否准备好：", is_inside_tree())
		if value:
			# 等待下一帧再启动动画，确保节点已准备好
			call_deferred("_start_highlight_animation")
		else:
			_stop_highlight_animation()

const PADDING: float = 4.0
const ANIMATION_SPEED: float = 2.0  # 降低动画速度，使其更平滑
const MIN_DIFFERENCE: float = 0.01  # 增加最小差值，避免频繁波动

@onready var hud: CanvasLayer = $"../../.."
var target_fill_ratio: float = 0.5
var current_fill_ratio: float = 0.5:
	set(value):
		current_fill_ratio = value
		queue_redraw()

var _highlight_tween: Tween
var _last_trigger_time: float = 0.0
const TRIGGER_COOLDOWN: float = 0.1


func _ready() -> void:
	custom_minimum_size = Vector2(64, 64)
	mouse_filter = Control.MOUSE_FILTER_STOP
	# 初始化填充值
	current_fill_ratio = fill_ratio
	target_fill_ratio = fill_ratio

func _process(delta: float) -> void:
	"""处理每帧的填充动画"""
	# 如果在编辑器中运行，跳过动画逻辑
	if Engine.is_editor_hint():
		current_fill_ratio = target_fill_ratio
		return
	
	# 检查动画是否启用
	if not hud or not hud.has_method("is_animation_enabled") or not hud.is_animation_enabled():
		# 如果动画禁用，直接设置值
		current_fill_ratio = target_fill_ratio
		return
	# 平滑过渡到目标值
	if abs(current_fill_ratio - target_fill_ratio) > MIN_DIFFERENCE:
		# 使用平滑插值
		current_fill_ratio = lerp(current_fill_ratio, target_fill_ratio, delta * ANIMATION_SPEED)
		# 确保值在范围内
		current_fill_ratio = clamp(current_fill_ratio, 0.0, 1.0)
	elif abs(current_fill_ratio - target_fill_ratio) > 0.001:
		# 当差值很小时，直接设置为目标值，避免波动
		current_fill_ratio = target_fill_ratio


func _draw() -> void:
	var center = size / 2
	var radius = min(size.x, size.y) / 2 - PADDING
	
	# 如果禁用，显示灰色
	var draw_color = circle_color
	if disabled:
		draw_color = Color(0.3, 0.3, 0.3, 0.5)
	
	if current_fill_ratio > 0.001:
		_draw_fill(center, radius, current_fill_ratio, draw_color)
	
	var outline_width = 2.0
	draw_arc(center, radius, 0, TAU, 64, draw_color, outline_width, true)
	
	if is_selected:
		var selection_radius = radius + PADDING / 2
		draw_arc(center, selection_radius, 0, TAU, 64, selection_ring_color, 3.0, true)


func _draw_fill(center: Vector2, radius: float, ratio: float, color: Color = circle_color) -> void:
	if ratio >= 1.0:
		draw_circle(center, radius, color)
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
			colors[i] = color
		draw_polygon(points, colors)


func _gui_input(event: InputEvent) -> void:
	if disabled:
		return
	
	if _is_selection_trigger(event):
		var current_time = Time.get_ticks_msec() / 1000.0
		if current_time - _last_trigger_time < TRIGGER_COOLDOWN:
			return
		
		_last_trigger_time = current_time
		if hud and hud.has_method("select_icon"):
			hud.select_icon(self)
		else:
			is_selected = !is_selected
		accept_event()

func _mouse_entered() -> void:
	"""鼠标进入时的效果"""
	if not is_selected and hud and hud.has_method("is_animation_enabled") and hud.is_animation_enabled():
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.2)

func _mouse_exited() -> void:
	"""鼠标离开时的效果"""
	if not is_selected and hud and hud.has_method("is_animation_enabled") and hud.is_animation_enabled():
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)

func _is_selection_trigger(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	elif event is InputEventScreenTouch:
		return event.pressed
	return false

func _start_highlight_animation() -> void:
	"""开始循环的高亮动画"""
	if _highlight_tween:
		_highlight_tween.kill()
	
	_highlight_tween = create_tween()
	
	if not _highlight_tween:
		print("错误：无法创建tween")
		return
	
	# 设置无限循环
	_highlight_tween.set_loops(0)
	_highlight_tween.set_parallel(false)
	_highlight_tween.set_trans(Tween.TRANS_SINE)
	_highlight_tween.set_ease(Tween.EASE_IN_OUT)
	
	# 循环缩放动画：1.0 -> 1.2 -> 1.0
	_highlight_tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.5)
	_highlight_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.5)
	
	print("开始高亮动画，tween已创建")

func _stop_highlight_animation() -> void:
	"""停止高亮动画"""
	if _highlight_tween:
		_highlight_tween.kill()
		_highlight_tween = null
	
	# 回到原样
	scale = Vector2(1.0, 1.0)
