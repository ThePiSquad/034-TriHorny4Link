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

# 资源系统常量
class ResourceConstants:
	const PRODUCTION_RATE: float = 2.0  # 每秒生产资源量
	const MAX_STORAGE: int = 100  # 最大存储上限
	const MONO_CRYSTAL_COST: int = 10  # 单色水晶消耗
	const CONDUIT_COST: int = 2  # 导管消耗（每种颜色）
	const TURRET_COST: int = 4  # 炮塔消耗（每种颜色）

# 相机相关常量
class CameraConstants:
	const ZOOM_SPEED: float = 0.1
	const MIN_ZOOM: float = 0.2
	const MAX_ZOOM: float = 2.0
	const MOVE_SPEED: float = 500.0
	const ACCELERATION: float = 5.0
	const MIN_X: float = -1024.0
	const MAX_X: float = 1024.0
	const MIN_Y: float = -1024.0
	const MAX_Y: float = 1024.0

# 输入相关常量
class InputConstants:
	const PLACE_INTERVAL: float = 0.05

# 敌人相关常量
class EnemyConstants:
	const default_size: float = 1.0
	const default_color: Color = Color.CYAN
	const MIN_DIFFICULTY: int = 1
	const MAX_DIFFICULTY: int = 5
	const DEFAULT_DIFFICULTY: int = 2
	const MIN_SPAWN_DISTANCE: float = 15 * grid_size  # 距离水晶的最小生成距离
	const DEFAULT_SPAWN_INTERVAL: float = 3.0  # 默认刷新间隔（秒）
	
	# 体型系统
	const SIZE_LEVEL_1: int = 1
	const SIZE_LEVEL_2: int = 2
	const SIZE_LEVEL_3: int = 3
	const SIZE_LEVEL_4: int = 4
	const SIZE_LEVEL_5: int = 5
	const SIZE_LEVEL_6: int = 6
	const SIZE_LEVEL_7: int = 7
	const MAX_SIZE_LEVEL: int = 7
	
	# 体型尺寸映射表（像素）
	static var SIZE_MAP = {
		SIZE_LEVEL_1: Vector2(32, 32),   # 32×32
		SIZE_LEVEL_2: Vector2(48, 48),   # 48×48
		SIZE_LEVEL_3: Vector2(64, 64),   # 64×64
		SIZE_LEVEL_4: Vector2(80, 80),   # 80×80
		SIZE_LEVEL_5: Vector2(96, 96),   # 96×96
		SIZE_LEVEL_6: Vector2(112, 112), # 112×112
		SIZE_LEVEL_7: Vector2(128, 128)  # 128×128
	}
	
	# 体型属性调整系数
	static var SIZE_ATTRIBUTE_MULTIPLIERS = {
		SIZE_LEVEL_1: {"health": 1.0, "speed": 1.0},
		SIZE_LEVEL_2: {"health": 1.5, "speed": 0.9},
		SIZE_LEVEL_3: {"health": 2.0, "speed": 0.8},
		SIZE_LEVEL_4: {"health": 2.5, "speed": 0.7},
		SIZE_LEVEL_5: {"health": 3.0, "speed": 0.6},
		SIZE_LEVEL_6: {"health": 3.5, "speed": 0.5},
		SIZE_LEVEL_7: {"health": 4.0, "speed": 0.4}
	}
	
	# 时间相关生成配置
	const TIME_SCALE_FACTOR: float = 0.5  # 时间缩放因子（每秒增加的概率）
	const MAX_SIZE_UNLOCK_TIME: float = 100.0  # 完全解锁所有体型所需时间（秒）
	const SPAWN_INTERVAL_MIN: float = 0.5  # 最小刷新间隔（秒）
	const SPAWN_INTERVAL_MAX: float = 3.0  # 最大刷新间隔（秒）
	
	# 敌人分数映射表（体型越大分数越高）
	static var ENEMY_SCORE_MAP = {
		SIZE_LEVEL_1: 10,    # 最小体型：10 分
		SIZE_LEVEL_2: 20,    # 20 分
		SIZE_LEVEL_3: 35,    # 35 分
		SIZE_LEVEL_4: 55,    # 55 分
		SIZE_LEVEL_5: 80,    # 80 分
		SIZE_LEVEL_6: 110,   # 110 分
		SIZE_LEVEL_7: 150    # 最大体型：150 分
	}

# 碰撞层常量
const STRUCTURE_LAYER: int = 2  # 结构层
const ENEMY_LAYER: int = 4      # 敌人层

static var COLOR_MAP = {
	Enums.ColorType.WHITE: Color("#CCCCCCFF"),
	Enums.ColorType.BLACK: Color("#444444ff"),
	Enums.ColorType.RED: Color("#ff4545ff"),
	Enums.ColorType.BLUE: Color("#4587ffff"),
	Enums.ColorType.YELLOW: Color("#ffde45ff"),
	Enums.ColorType.GREEN: Color("#62B245ff"),
	Enums.ColorType.ORANGE: Color("#FF9225ff"),
	Enums.ColorType.PURPLE: Color("#A245A2ff"),
}

static func get_color(type: Enums.ColorType) -> Color:
	if COLOR_MAP.has(type):
		return COLOR_MAP[type]
	return Color.MAGENTA # 如果找不到，返回一个显眼的紫色提醒出错了

static var TURRET_CONFIG = {
	Enums.ColorType.RED: {
		"fire_rate": 0.75,
		"bullet_speed": 550.0,
		"bullet_damage": 30.0,
		"detection_range": 10 * grid_size,
		"bullet_lifetime": 2.0,
		"shotgun_enabled": true,
		"shotgun_count": 3,
		"shotgun_angle_spread": 15.0
	},
	Enums.ColorType.BLUE: {
		"fire_rate": 2.0,
		"bullet_speed": 1100.0,
		"bullet_damage": 20.0,
		"detection_range": 12 * grid_size,
		"bullet_lifetime": 1.2
	},
	Enums.ColorType.YELLOW: {
		"fire_rate": 1.0,
		"bullet_speed": 800.0,
		"bullet_damage": 22.0,
		"detection_range": 16 * grid_size,
		"bullet_lifetime": 0.5,
		"magic_enabled": true,
		"magic_beam_width": 8.0,
		"magic_beam_duration": 0.2
	},
	Enums.ColorType.GREEN: {
		"fire_rate": 1.5,
		"bullet_speed": 850.0,
		"bullet_damage": 25.0,
		"detection_range": 15 * grid_size,
		"bullet_lifetime": 1.6,
		"homing_enabled": true,
		"homing_detection_range": 5 * grid_size,
		"homing_turn_speed": 12.0
	},
	Enums.ColorType.ORANGE: {
		"fire_rate": 0.75,
		"bullet_speed": 550.0,
		"bullet_damage": 25.0,
		"detection_range": 13 * grid_size,
		"bullet_lifetime": 0.6,
		"lightning_enabled": true,
		"lightning_chain_range": 6 * grid_size,
		"lightning_max_chain": 4
	},
	Enums.ColorType.PURPLE: {
		"fire_rate": 0.5,
		"bullet_speed": 600.0,
		"bullet_damage": 50.0,
		"detection_range": 8 * grid_size,
		"bullet_lifetime": 2.0,
		"explosive_enabled": true,
		"explosion_radius": 5 * grid_size,
		"explosion_particle_duration": 1.0
	},
	Enums.ColorType.BLACK: {
		"fire_rate": 0.1,
		"bullet_speed": 400.0,
		"bullet_damage": 10.0,
		"detection_range": 4 * grid_size,
		"bullet_lifetime": 3.0
	}
}
