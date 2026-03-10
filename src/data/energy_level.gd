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
	print("【EnergyLevel】当前色彩分布：Red:{red} Blue:{blue} Yellow:{yellow}".format({
	"red": red,
	"blue": blue,
	"yellow": yellow
	}))

	# 所有颜色都为0，返回白色
	if blue == 0 and red == 0 and yellow == 0:
		return Enums.ColorType.WHITE

	# 三个颜色数值相同，返回黑色
	if blue == red and blue == yellow and blue > 0:
		return Enums.ColorType.BLACK

	# 混色逻辑：两个颜色数值相同且都大于第三个颜色时进行混色
	# 红色 + 蓝色 = 紫色（红色和蓝色数值相同且都大于黄色）
	if red == blue and red > yellow and red > 0:
		return Enums.ColorType.PURPLE

	# 红色 + 黄色 = 橙色（红色和黄色数值相同且都大于蓝色）
	if red == yellow and red > blue and red > 0:
		return Enums.ColorType.ORANGE

	# 蓝色 + 黄色 = 绿色（蓝色和黄色数值相同且都大于红色）
	if blue == yellow and blue > red and blue > 0:
		return Enums.ColorType.GREEN

	# 单一颜色判断
	# 只有红色最大
	if red > max(blue, yellow):
		return Enums.ColorType.RED

	# 只有蓝色最大
	if blue > max(red, yellow):
		return Enums.ColorType.BLUE

	# 只有黄色最大
	if yellow > max(blue, red):
		return Enums.ColorType.YELLOW

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
