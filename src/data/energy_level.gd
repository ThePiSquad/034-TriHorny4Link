class_name EnergyLevel
extends Resource

var red: int = 0
var blue: int = 0
var yellow: int = 0

# 能量来源距离（用于计算衰减）
var source_distance: int = 0


func add(other: EnergyLevel) -> void:
	red += other.red
	blue += other.blue
	yellow += other.yellow


func decay(distance: int = 1) -> EnergyLevel:
	"""计算经过distance距离后的衰减能量"""
	var result: EnergyLevel = EnergyLevel.new()
	var decay_amount = distance * Constants.ENERGY_DECAY_PER_TILE
	result.red = max(red - decay_amount, 0)
	result.blue = max(blue - decay_amount, 0)
	result.yellow = max(yellow - decay_amount, 0)
	result.source_distance = source_distance + distance
	return result


func equal(other: EnergyLevel) -> bool:
	return blue == other.blue and red == other.red and yellow == other.yellow


func get_color() -> Enums.ColorType:
	if blue == 0 and red == 0 and yellow == 0:
		return Enums.ColorType.WHITE
	if blue == red and blue == yellow:
		return Enums.ColorType.BLACK

	if blue < red and blue < yellow:
		return Enums.ColorType.ORANGE
	if red < blue and red < yellow:
		return Enums.ColorType.GREEN
	if yellow < blue and yellow < red:
		return Enums.ColorType.PURPLE

	if blue + yellow == 0:
		return Enums.ColorType.RED
	if red + blue == 0:
		return Enums.ColorType.YELLOW
	if yellow + red == 0:
		return Enums.ColorType.BLUE

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
	result.source_distance = source_distance
	return result
