class_name Constants
extends Resource

const grid_size: int = 64
static var generator_reserved_coords:Array[GridCoord]=[
	GridCoord.new(-1,-1),
	GridCoord.new(0,-1),
	GridCoord.new(-1,0),
	GridCoord.new(0,0),
]

const default_crystal_energy_level: int = 2

class EnemyConstants:
	const default_size: float = 1.0
	const default_color: Color = Color.CYAN

static var COLOR_MAP = {
	Enums.ColorType.WHITE: Color.WHITE,
	Enums.ColorType.BLACK: Color.BLACK,
	Enums.ColorType.RED: Color("ff4545ff"),
	Enums.ColorType.BLUE: Color("4587ffff"),
	Enums.ColorType.YELLOW: Color("ffde45ff"),
	Enums.ColorType.GREEN: Color.GREEN,
	Enums.ColorType.ORANGE: Color.ORANGE,
	Enums.ColorType.PURPLE: Color.PURPLE,
}

static func get_color(type: Enums.ColorType) -> Color:
	if COLOR_MAP.has(type):
		return COLOR_MAP[type]
	return Color.MAGENTA # 如果找不到，返回一个显眼的紫色提醒出错了
