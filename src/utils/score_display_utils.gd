class_name ScoreDisplayUtils
extends RefCounted

# 基础图形分值
const TRIANGLE_SCORE: int = 30
const SQUARE_SCORE: int = 40
const CIRCLE_SCORE: int = 50

# 颜色倍率
const RED_MULTIPLIER: int = 1      # x1
const BLUE_MULTIPLIER: int = 10    # x10
const YELLOW_MULTIPLIER: int = 100 # x100

# 图形类型枚举
enum ShapeType {
	TRIANGLE,
	SQUARE,
	CIRCLE
}

# 颜色类型枚举
enum ColorType {
	RED,
	BLUE,
	YELLOW
}

# 图案分数单元
class ScorePattern:
	var shape: ShapeType
	var color: ColorType
	var value: int
	
	func _init(s: ShapeType, c: ColorType) -> void:
		shape = s
		color = c
		value = _calculate_value()
	
	func _calculate_value() -> int:
		var base_score = 0
		match shape:
			ShapeType.TRIANGLE:
				base_score = TRIANGLE_SCORE
			ShapeType.SQUARE:
				base_score = SQUARE_SCORE
			ShapeType.CIRCLE:
				base_score = CIRCLE_SCORE
		
		var multiplier = 1
		match color:
			ColorType.RED:
				multiplier = RED_MULTIPLIER
			ColorType.BLUE:
				multiplier = BLUE_MULTIPLIER
			ColorType.YELLOW:
				multiplier = YELLOW_MULTIPLIER
		
		return base_score * multiplier
	
	func get_shape_name() -> String:
		match shape:
			ShapeType.TRIANGLE:
				return "triangle"
			ShapeType.SQUARE:
				return "square"
			ShapeType.CIRCLE:
				return "circle"
		return "unknown"
	
	func get_color_name() -> String:
		match color:
			ColorType.RED:
				return "red"
			ColorType.BLUE:
				return "blue"
			ColorType.YELLOW:
				return "yellow"
		return "unknown"

static func get_pattern_value(shape: ShapeType, color: ColorType) -> int:
	var pattern = ScorePattern.new(shape, color)
	return pattern.value

static func decompose_score(total_score: int) -> Array[ScorePattern]:
	"""
	将总分分解为图案组合
	返回 ScorePattern 数组，按价值从高到低排序
	"""
	var patterns: Array[ScorePattern] = []
	var remaining = total_score
	
	# 定义所有可能的图案组合（按价值从高到低）
	var all_patterns = [
		ScorePattern.new(ShapeType.CIRCLE, ColorType.YELLOW),    # 5000
		ScorePattern.new(ShapeType.SQUARE, ColorType.YELLOW),    # 4000
		ScorePattern.new(ShapeType.TRIANGLE, ColorType.YELLOW),  # 3000
		ScorePattern.new(ShapeType.CIRCLE, ColorType.BLUE),      # 500
		ScorePattern.new(ShapeType.SQUARE, ColorType.BLUE),      # 400
		ScorePattern.new(ShapeType.TRIANGLE, ColorType.BLUE),    # 300
		ScorePattern.new(ShapeType.CIRCLE, ColorType.RED),       # 50
		ScorePattern.new(ShapeType.SQUARE, ColorType.RED),       # 40
		ScorePattern.new(ShapeType.TRIANGLE, ColorType.RED),     # 30
	]
	
	# 贪心算法：从大到小选择图案
	for pattern in all_patterns:
		while remaining >= pattern.value:
			patterns.append(pattern)
			remaining -= pattern.value
	
	# 处理剩余的小分数（用红色图形表示）
	if remaining > 0:
		# 尝试用红色图形组合表示剩余分数
		var small_patterns = [
			ScorePattern.new(ShapeType.CIRCLE, ColorType.RED),   # 50
			ScorePattern.new(ShapeType.SQUARE, ColorType.RED),   # 40
			ScorePattern.new(ShapeType.TRIANGLE, ColorType.RED), # 30
		]
		
		for pattern in small_patterns:
			if remaining >= pattern.value:
				patterns.append(pattern)
				remaining -= pattern.value
		
		# 如果还有剩余，说明无法精确表示，向上取整
		if remaining > 0:
			# 添加一个三角形来表示余数
			if remaining <= 10:
				patterns.append(ScorePattern.new(ShapeType.TRIANGLE, ColorType.RED))
	
	return patterns

static func get_color_for_multiplier(multiplier: int) -> Color:
	match multiplier:
		RED_MULTIPLIER:
			return Color.RED
		BLUE_MULTIPLIER:
			return Color.BLUE
		YELLOW_MULTIPLIER:
			return Color.YELLOW
	return Color.WHITE

static func get_shape_type_for_score(score: int) -> ShapeType:
	if score == TRIANGLE_SCORE or score == TRIANGLE_SCORE * BLUE_MULTIPLIER or score == TRIANGLE_SCORE * YELLOW_MULTIPLIER:
		return ShapeType.TRIANGLE
	elif score == SQUARE_SCORE or score == SQUARE_SCORE * BLUE_MULTIPLIER or score == SQUARE_SCORE * YELLOW_MULTIPLIER:
		return ShapeType.SQUARE
	else:
		return ShapeType.CIRCLE
