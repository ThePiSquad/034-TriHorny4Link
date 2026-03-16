class_name EnergyLevel
extends Resource

var red: int = 0
var blue: int = 0
var yellow: int = 0

# 能量来源距离（分别记录三个颜色的能量来源距离）
var red_source_distance: int = 0
var blue_source_distance: int = 0
var yellow_source_distance: int = 0


func add(other: EnergyLevel) -> void:
	red += other.red
	blue += other.blue
	yellow += other.yellow
	# 添加能量时，保留较近的距离
	if other.red > 0 and (red_source_distance == 0 or other.red_source_distance < red_source_distance):
		red_source_distance = other.red_source_distance
	if other.blue > 0 and (blue_source_distance == 0 or other.blue_source_distance < blue_source_distance):
		blue_source_distance = other.blue_source_distance
	if other.yellow > 0 and (yellow_source_distance == 0 or other.yellow_source_distance < yellow_source_distance):
		yellow_source_distance = other.yellow_source_distance



func decay(distance: int = 1) -> EnergyLevel:
	"""计算经过distance距离后的衰减能量，每个颜色独立计算衰减"""
	var result: EnergyLevel = EnergyLevel.new()
	var decay_amount = distance * Constants.ENERGY_DECAY_PER_TILE
	
	# 分别计算每个颜色的衰减
	result.red = max(red - decay_amount, 0)
	result.blue = max(blue - decay_amount, 0)
	result.yellow = max(yellow - decay_amount, 0)
	
	# 分别更新每个颜色的来源距离
	result.red_source_distance = red_source_distance + distance
	result.blue_source_distance = blue_source_distance + distance
	result.yellow_source_distance = yellow_source_distance + distance
	
	return result

func equal(other: EnergyLevel) -> bool:
	return blue == other.blue and red == other.red and yellow == other.yellow

func get_color() -> Enums.ColorType:
	# 所有颜色都为0，返回白色
	if blue == 0 and red == 0 and yellow == 0:
		return Enums.ColorType.WHITE

	# 三个颜色数值相同，返回黑色
	if blue == red and blue == yellow and blue > 0:
		return Enums.ColorType.BLACK

	# 找出三个颜色的最大值和次大值
	var colors = [
		{"type": Enums.ColorType.RED, "value": red},
		{"type": Enums.ColorType.BLUE, "value": blue},
		{"type": Enums.ColorType.YELLOW, "value": yellow}
	]
	
	# 按数值降序排序
	colors.sort_custom(func(a, b): return a["value"] > b["value"])
	
	var first = colors[0]
	var second = colors[1]
	var third = colors[2]
	
	# 如果最大值是0，返回白色
	if first["value"] == 0:
		return Enums.ColorType.WHITE
	
	# 特殊情况：次强和第三相等，且都大于最强的一半
	var threshold = first["value"] / 2.0
	if second["value"] == third["value"] and second["value"] > threshold:
		return Enums.ColorType.BLACK
	
	# 找出所有"有效"颜色（值 > 最强的一半）
	var effective_colors = []
	for c in colors:
		if c["value"] > threshold:
			effective_colors.append(c)
	
	# 情况1：只有一种有效颜色
	if effective_colors.size() == 1:
		return effective_colors[0]["type"]
	
	# 情况2：两种有效颜色
	if effective_colors.size() == 2:
		var c1 = effective_colors[0]
		var c2 = effective_colors[1]
		
		# 如果两色相等，返回普通混色
		if abs(c1["value"] - c2["value"]) < 0.1:
			match [c1["type"], c2["type"]]:
				[Enums.ColorType.RED, Enums.ColorType.BLUE], [Enums.ColorType.BLUE, Enums.ColorType.RED]:
					return Enums.ColorType.PURPLE
				[Enums.ColorType.RED, Enums.ColorType.YELLOW], [Enums.ColorType.YELLOW, Enums.ColorType.RED]:
					return Enums.ColorType.ORANGE
				[Enums.ColorType.BLUE, Enums.ColorType.YELLOW], [Enums.ColorType.YELLOW, Enums.ColorType.BLUE]:
					return Enums.ColorType.GREEN
		
		# 否则返回偏向强色的混合色
		match [c1["type"], c2["type"]]:
			[Enums.ColorType.RED, Enums.ColorType.BLUE]:
				return Enums.ColorType.PURPLE_RED
			[Enums.ColorType.BLUE, Enums.ColorType.RED]:
				return Enums.ColorType.PURPLE_BLUE
			[Enums.ColorType.RED, Enums.ColorType.YELLOW]:
				return Enums.ColorType.ORANGE_RED
			[Enums.ColorType.YELLOW, Enums.ColorType.RED]:
				return Enums.ColorType.ORANGE_YELLOW
			[Enums.ColorType.BLUE, Enums.ColorType.YELLOW]:
				return Enums.ColorType.GREEN_BLUE
			[Enums.ColorType.YELLOW, Enums.ColorType.BLUE]:
				return Enums.ColorType.GREEN_YELLOW
	
	# 情况3：三种有效颜色
	if effective_colors.size() == 3:
		# 检查是否两色相等
		if first["value"] == second["value"]:
			if first["type"] == Enums.ColorType.RED and second["type"] == Enums.ColorType.BLUE:
				return Enums.ColorType.PURPLE
			if first["type"] == Enums.ColorType.RED and second["type"] == Enums.ColorType.YELLOW:
				return Enums.ColorType.ORANGE
			if first["type"] == Enums.ColorType.BLUE and second["type"] == Enums.ColorType.YELLOW:
				return Enums.ColorType.GREEN
		# 否则返回最强色
		return first["type"]
	
	# 默认返回白色
	return Enums.ColorType.WHITE

func get_intensity() -> float:
	"""获取能量强度（0.0 - 1.0）"""
	var total = red + blue + yellow
	var max_energy = Constants.MONO_CRYSTAL_BASE_ENERGY * 3
	return clamp(float(total) / float(max_energy), 0.0, 1.0)

func get_energy_level() -> EnergyLevel:
	"""获取具体颜色数值"""
	var temp_el : EnergyLevel = EnergyLevel.new()
	temp_el.red = self.red
	temp_el.blue = self.blue
	temp_el.yellow = self.yellow
	return temp_el

func is_empty() -> bool:
	"""检查能量是否为空"""
	return red == 0 and blue == 0 and yellow == 0


func copy() -> EnergyLevel:
	"""创建能量副本"""
	var result = EnergyLevel.new()
	result.red = red
	result.blue = blue
	result.yellow = yellow
	result.red_source_distance = red_source_distance
	result.blue_source_distance = blue_source_distance
	result.yellow_source_distance = yellow_source_distance
	return result
