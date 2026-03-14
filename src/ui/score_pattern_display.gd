extends PanelContainer
class_name ScorePatternDisplay

var shape_display: UIShapeDisplay

# 图案数据
var pattern_data: ScoreDisplayUtils.ScorePattern

func _ready() -> void:
	# 设置最小尺寸
	custom_minimum_size = Vector2(50, 50)
	
	# 获取 UIShapeDisplay 引用
	shape_display = $UIShapeDisplay
	
	if shape_display == null:
		print("严重错误：无法找到 UIShapeDisplay 子节点！")
		print("子节点列表：")
		for child in get_children():
			print("  - ", child.name, " (", child.get_class(), ")")
	else:
		print("成功获取 UIShapeDisplay：", shape_display.name)
	
	# 如果已经设置了图案数据，更新显示
	if pattern_data:
		_update_display()

func set_pattern(pattern: ScoreDisplayUtils.ScorePattern) -> void:
	"""设置图案数据"""
	pattern_data = pattern
	
	# 如果已经准备好，立即更新显示
	if shape_display:
		_update_display()

func _update_display() -> void:
	"""更新显示"""
	if not shape_display or not pattern_data:
		return
	
	# 设置图形类型（使用 UI 组件的枚举）
	match pattern_data.shape:
		ScoreDisplayUtils.ShapeType.TRIANGLE:
			shape_display.shape_type = UIShapeDisplay.ShapeType.TRIANGLE
		ScoreDisplayUtils.ShapeType.SQUARE:
			shape_display.shape_type = UIShapeDisplay.ShapeType.RECTANGLE
		ScoreDisplayUtils.ShapeType.CIRCLE:
			shape_display.shape_type = UIShapeDisplay.ShapeType.CIRCLE
	
	# 设置颜色
	var color = _get_color_for_pattern()
	shape_display.fill_color = color
	shape_display.stroke_color = color.lightened(0.3)
	
	# 根据颜色倍率设置大小
	var size_multiplier = _get_size_multiplier()
	shape_display.shape_size = Vector2(40 * size_multiplier, 40 * size_multiplier)

func _get_color_for_pattern() -> Color:
	"""获取图案对应的颜色"""
	match pattern_data.color:
		ScoreDisplayUtils.ColorType.RED:
			return Color("#ff4545ff")
		ScoreDisplayUtils.ColorType.BLUE:
			return Color("#4587ffff")
		ScoreDisplayUtils.ColorType.YELLOW:
			return Color("#ffde45ff")
	return Color.WHITE

func _get_size_multiplier() -> float:
	"""根据分数价值获取大小倍率"""
	if pattern_data.value >= 1000:
		return 1.5
	elif pattern_data.value >= 100:
		return 1.2
	else:
		return 1.0
