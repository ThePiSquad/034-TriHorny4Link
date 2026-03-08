class_name EnergyLevel
extends Resource

var red: int = 0
var blue: int = 0
var yellow: int = 0


func add(other: EnergyLevel) -> void:
	red += other.red
	blue += other.blue
	yellow += other.yellow


func decay() -> EnergyLevel:
	var result: EnergyLevel = EnergyLevel.new()
	result.red = max(red - 1, 0)
	result.blue = max(blue - 1, 0)
	result.yellow = max(yellow - 1, 0)
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
	if yellow + blue == 0:
		return Enums.ColorType.BLUE

	return Enums.ColorType.WHITE
