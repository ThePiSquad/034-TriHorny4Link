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

# MonoCrystal基础能量值
const MONO_CRYSTAL_BASE_ENERGY: int = 10

# 能量每格衰减值
const ENERGY_DECAY_PER_TILE: int = 1

# 最大能量传播距离
const MAX_ENERGY_RANGE: int = 10

# 相机相关常量
class CameraConstants:
	const ZOOM_SPEED: float = 0.1
	const MIN_ZOOM: float = 0.2
	const MAX_ZOOM: float = 2.0
	const MOVE_SPEED: float = 500.0
	const ACCELERATION: float = 5.0
	const MIN_X: float = -1000.0
	const MAX_X: float = 1000.0
	const MIN_Y: float = -1000.0
	const MAX_Y: float = 1000.0

# 输入相关常量
class InputConstants:
	const PLACE_INTERVAL: float = 0.1

# 敌人相关常量
class EnemyConstants:
	const default_size: float = 1.0
	const default_color: Color = Color.CYAN
	const MIN_DIFFICULTY: int = 1
	const MAX_DIFFICULTY: int = 5
	const DEFAULT_DIFFICULTY: int = 2
	const MIN_SPAWN_DISTANCE: float = 300.0  # 距离水晶的最小生成距离
	const DEFAULT_SPAWN_INTERVAL: float = 5.0  # 默认刷新间隔（秒）

# 碰撞层常量
const STRUCTURE_LAYER: int = 2  # 结构层
const ENEMY_LAYER: int = 4      # 敌人层

static var COLOR_MAP = {
	Enums.ColorType.WHITE: Color.WHITE,
	Enums.ColorType.BLACK: Color.BLACK,
	Enums.ColorType.RED: Color("ff4545ff"),
	Enums.ColorType.BLUE: Color("4587ffff"),
	Enums.ColorType.YELLOW: Color("ffde45ff"),
	Enums.ColorType.GREEN: Color("#62B245ff"),
	Enums.ColorType.ORANGE: Color("FF9225ff"),
	Enums.ColorType.PURPLE: Color("#A245A2"),
}

static func get_color(type: Enums.ColorType) -> Color:
	if COLOR_MAP.has(type):
		return COLOR_MAP[type]
	return Color.MAGENTA # 如果找不到，返回一个显眼的紫色提醒出错了

static var TURRET_CONFIG = {
	Enums.ColorType.RED: {
		"fire_rate": 0.75,
		"bullet_speed": 300.0,
		"bullet_damage": 30.0,
		"detection_range": 5 * grid_size,
		"bullet_lifetime": 1.5,
		"shotgun_enabled": true,
		"shotgun_count": 3,
		"shotgun_angle_spread": 15.0
	},
	Enums.ColorType.BLUE: {
		"fire_rate": 2.0,
		"bullet_speed": 500.0,
		"bullet_damage": 20.0,
		"detection_range": 7 * grid_size,
		"bullet_lifetime": 2.0
	},
	Enums.ColorType.YELLOW: {
		"fire_rate": 1.0,
		"bullet_speed": 800.0,
		"bullet_damage": 10.0,
		"detection_range": 9 * grid_size,
		"bullet_lifetime": 0.8,
		"magic_enabled": true,
		"magic_beam_width": 8.0,
		"magic_beam_duration": 0.2
	},
	Enums.ColorType.GREEN: {
		"fire_rate": 1.0,
		"bullet_speed": 550.0,
		"bullet_damage": 25.0,
		"detection_range": 8 * grid_size,
		"bullet_lifetime": 2.0,
		"homing_enabled": true,
		"homing_detection_range": 150.0,
		"homing_turn_speed": 5.0
	},
	Enums.ColorType.ORANGE: {
		"fire_rate": 0.5,
		"bullet_speed": 550.0,
		"bullet_damage": 22.0,
		"detection_range": 6 * grid_size,
		"bullet_lifetime": 1.0,
		"lightning_enabled": true,
		"lightning_chain_range": 384.0,
		"lightning_max_chain": 3
	},
	Enums.ColorType.PURPLE: {
		"fire_rate": 0.5,
		"bullet_speed": 380.0,
		"bullet_damage": 40.0,
		"detection_range": 4 * grid_size,
		"bullet_lifetime": 3.8
	},
	Enums.ColorType.BLACK: {
		"fire_rate": 0.25,
		"bullet_speed": 400.0,
		"bullet_damage": 10.0,
		"detection_range": 4 * grid_size,
		"bullet_lifetime": 3.0
	}
}
