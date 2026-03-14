extends PanelContainer
class_name ScorePatternDisplay

@onready var shape_drawer: ShapeDrawer = $ShapeDrawer

# 图案数据
var pattern_data: ScoreDisplayUtils.ScorePattern

func _ready() -> void:
	# 设置最小尺寸
	custom_minimum_size = Vector2(50, 50)

func set_pattern(pattern: ScoreDisplayUtils.ScorePattern) -> void:
	"""设置图案数据"""
	pattern_data = pattern
	_update_display()

func _update_display() -> void:
	"""更新显示"""
	if not shape_drawer or not pattern_data:
		return
	
	# 设置图形类型
	match pattern_data.shape:
		ScoreDisplayUtils.ShapeType.TRIANGLE:
			shape_drawer.shape_type = Enums.ShapeType.TRIANGLE
		ScoreDisplayUtils.ShapeType.SQUARE:
			shape_drawer.shape_type = Enums.ShapeType.RECTANGLE
		ScoreDisplayUtils.ShapeType.CIRCLE:
			shape_drawer.shape_type = Enums.ShapeType.CIRCLE
	
	# 设置颜色
	var color = _get_color_for_pattern()
	shape_drawer.fill_color = color
	shape_drawer.stroke_color = color.lightened(0.3)
	
	# 根据颜色倍率设置大小
	var size_multiplier = _get_size_multiplier()
	shape_drawer.shape_size = Vector2(40 * size_multiplier, 40 * size_multiplier)

func _get_color_for_pattern() -> Color:
	"""获取图案对应的颜色"""
	match pattern_data.color:
		ScoreDisplayUtils.ColorType.RED:
			return Color.RED
		ScoreDisplayUtils.ColorType.BLUE:
			return Color.BLUE
		ScoreDisplayUtils.ColorType.YELLOW:
			return Color.YELLOW
	return Color.WHITE

func _get_size_multiplier() -> float:
	"""根据分数价值获取大小倍率"""
	if pattern_data.value >= 1000:
		return 1.5
	elif pattern_data.value >= 100:
		return 1.2
	else:
		return 1.0
