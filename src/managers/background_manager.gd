class_name BackgroundManager
extends Node2D

## 背景管理器
## 负责渲染可自定义的背景和网格点

@export var background_color: Color = Color(0.1, 0.1, 0.1, 1.0)
@export var dot_size: float = 2.0  # 点大小
@export var dot_color: Color = Color(0.5, 0.5, 0.5, 0.3)  # 点颜色和不透明度

var background_rect: Rect2
var grid_spacing: int = Constants.grid_size  # 使用 Constants 中的 grid_size

func _ready() -> void:
	"""初始化"""
	# 设置背景大小为摄像机限制范围
	background_rect = Rect2(
		Constants.CameraConstants.MIN_X * 4,
		Constants.CameraConstants.MIN_Y * 3,
		(Constants.CameraConstants.MAX_X - Constants.CameraConstants.MIN_X) * 4,
		(Constants.CameraConstants.MAX_Y - Constants.CameraConstants.MIN_Y) * 3
	)
	
	# 监听视口大小变化
	get_viewport().size_changed.connect(_on_viewport_size_changed)

func _on_viewport_size_changed() -> void:
	"""视口大小变化时更新"""
	queue_redraw()

func _draw() -> void:
	"""绘制背景和网格点"""
	# 绘制背景
	draw_rect(background_rect, background_color)
	
	# 绘制网格点
	_draw_grid_dots()

func _draw_grid_dots() -> void:
	"""绘制网格交叉点的点"""
	# 从背景矩形的左上角开始
	var start_x = background_rect.position.x
	var start_y = background_rect.position.y
	var end_x = background_rect.end.x
	var end_y = background_rect.end.y
	
	# 绘制网格点
	for y in range(int(start_y), int(end_y) + 1, grid_spacing):
		for x in range(int(start_x), int(end_x) + 1, grid_spacing):
			# 在网格交叉点绘制点
			draw_circle(Vector2(x, y), dot_size, dot_color)

func set_background_color(color: Color) -> void:
	"""设置背景颜色"""
	background_color = color
	queue_redraw()

func set_dot_size(size: float) -> void:
	"""设置点大小"""
	dot_size = max(1.0, size)  # 最小大小 1
	queue_redraw()

func set_dot_color(color: Color) -> void:
	"""设置点颜色"""
	dot_color = color
	queue_redraw()
