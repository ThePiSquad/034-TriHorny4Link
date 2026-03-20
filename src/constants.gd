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
	const PRODUCTION_RATE: float = 1.5  # 每秒生产资源量
	const MAX_STORAGE: int = 50  # 最大存储上限
	const MONO_CRYSTAL_COST: int = 5  # 单色水晶消耗
	const CONDUIT_COST: int = 1  # 导管消耗（每种颜色）
	const TURRET_COST: int = 2  # 炮塔消耗（每种颜色）

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
	# ============================================
	# 基础敌人属性
	# ============================================
	const default_size: float = 1.0  ## 默认敌人尺寸缩放
	const default_color: Color = Color.CYAN  ## 默认敌人颜色
	
	# ============================================
	# 难度等级系统
	# ============================================
	const MIN_DIFFICULTY: int = 1  ## 最小难度等级（决定可用敌人类型数量）
	const MAX_DIFFICULTY: int = 5  ## 最大难度等级
	const DEFAULT_DIFFICULTY: int = 2  ## 初始难度等级
	
	# ============================================
	# 敌人生成位置配置
	# ============================================
	const MIN_SPAWN_DISTANCE: float = 25 * grid_size  ## 最小生成距离（防止贴脸生成）
	const MAX_SPAWN_DISTANCE: float = 60 * grid_size  ## 最大生成距离（越远越有四面八方涌来的感觉）
	const SPAWN_DISTANCE_BIAS: float = 0.7  ## 距离偏向系数（0-1），越高=越倾向于在远处生成
	const DEFAULT_SPAWN_INTERVAL: float = 3.0  ## 默认刷新间隔（秒），游戏开始时的初始值
	
	# ============================================
	# 体型等级系统（1-20级）
	# ============================================
	## 体型等级越高，敌人越大、血量越多、速度越慢
	## 体型等级通过游戏时间和波次进度解锁
	## 1-10级：常规体型（32-128像素）
	## 11-20级：巨型体型（160-512像素），需要更长时间解锁
	const SIZE_LEVEL_1: int = 1
	const SIZE_LEVEL_2: int = 2
	const SIZE_LEVEL_3: int = 3
	const SIZE_LEVEL_4: int = 4
	const SIZE_LEVEL_5: int = 5
	const SIZE_LEVEL_6: int = 6
	const SIZE_LEVEL_7: int = 7
	const SIZE_LEVEL_8: int = 8
	const SIZE_LEVEL_9: int = 9
	const SIZE_LEVEL_10: int = 10
	const SIZE_LEVEL_11: int = 11
	const SIZE_LEVEL_12: int = 12
	const SIZE_LEVEL_13: int = 13
	const SIZE_LEVEL_14: int = 14
	const SIZE_LEVEL_15: int = 15
	const SIZE_LEVEL_16: int = 16
	const SIZE_LEVEL_17: int = 17
	const SIZE_LEVEL_18: int = 18
	const SIZE_LEVEL_19: int = 19
	const SIZE_LEVEL_20: int = 20
	const MAX_SIZE_LEVEL: int = 20  ## 最大体型等级
	
	# ============================================
	# 体型尺寸映射表（像素）
	# ============================================
	## 每个体型等级对应的碰撞框和绘制尺寸
	## 尺寸影响：碰撞检测、被击中概率、视觉表现
	## 大体型敌人（11级以上）会在更远的地方生成
	static var SIZE_MAP = {
		SIZE_LEVEL_1: Vector2(32, 32),   ## 32×32 - 小型敌人，难以击中
		SIZE_LEVEL_2: Vector2(40, 40),   ## 40×40
		SIZE_LEVEL_3: Vector2(48, 48),   ## 48×48
		SIZE_LEVEL_4: Vector2(56, 56),   ## 56×56
		SIZE_LEVEL_5: Vector2(64, 64),   ## 64×64 - 中等体型
		SIZE_LEVEL_6: Vector2(72, 72),   ## 72×72
		SIZE_LEVEL_7: Vector2(80, 80),   ## 80×80
		SIZE_LEVEL_8: Vector2(96, 96),   ## 96×96
		SIZE_LEVEL_9: Vector2(112, 112), ## 112×112
		SIZE_LEVEL_10: Vector2(128, 128), ## 128×128 - 大型敌人
		SIZE_LEVEL_11: Vector2(136, 136), ## 136×136 - 大型敌人开始
		SIZE_LEVEL_12: Vector2(144, 144), ## 144×144
		SIZE_LEVEL_13: Vector2(152, 152), ## 152×152
		SIZE_LEVEL_14: Vector2(160, 160), ## 160×160
		SIZE_LEVEL_15: Vector2(168, 168), ## 168×168
		SIZE_LEVEL_16: Vector2(176, 176), ## 176×176
		SIZE_LEVEL_17: Vector2(184, 184), ## 184×184
		SIZE_LEVEL_18: Vector2(192, 192), ## 192×192
		SIZE_LEVEL_19: Vector2(224, 224), ## 224×224
		SIZE_LEVEL_20: Vector2(256, 256)  ## 256×256 - 最大敌人
	}
	
	# ============================================
	# 体型属性调整系数
	# ============================================
	## 每个体型等级的属性乘数
	## health: 血量乘数（基于场景设置的max_health）
	## speed: 速度乘数（基于场景设置的move_speed）
	## 设计思路：体型越大，血量越多，但速度越慢
	## 11级以上：血量增长更快，速度更慢，成为真正的"Boss"级敌人
	static var SIZE_ATTRIBUTE_MULTIPLIERS = {
		SIZE_LEVEL_1: {"health": 1.0, "speed": 1.0},   ## 1级：基础属性
		SIZE_LEVEL_2: {"health": 1.2, "speed": 0.95},  ## 2级：+20%血量，-5%速度
		SIZE_LEVEL_3: {"health": 1.4, "speed": 0.9},   ## 3级：+40%血量，-10%速度
		SIZE_LEVEL_4: {"health": 1.7, "speed": 0.85},  ## 4级：+70%血量，-15%速度
		SIZE_LEVEL_5: {"health": 2.0, "speed": 0.8},   ## 5级：+100%血量，-20%速度
		SIZE_LEVEL_6: {"health": 2.5, "speed": 0.75},  ## 6级：+150%血量，-25%速度
		SIZE_LEVEL_7: {"health": 3.0, "speed": 0.7},   ## 7级：+200%血量，-30%速度
		SIZE_LEVEL_8: {"health": 4.0, "speed": 0.65},  ## 8级：+300%血量，-35%速度
		SIZE_LEVEL_9: {"health": 5.0, "speed": 0.6},   ## 9级：+400%血量，-40%速度
		SIZE_LEVEL_10: {"health": 6.5, "speed": 0.55}, ## 10级：+550%血量，-45%速度
		SIZE_LEVEL_11: {"health": 8.0, "speed": 0.5},  ## 11级：+700%血量，-50%速度 - 巨型开始
		SIZE_LEVEL_12: {"health": 10.0, "speed": 0.45}, ## 12级：+900%血量，-55%速度
		SIZE_LEVEL_13: {"health": 12.0, "speed": 0.42}, ## 13级：+1100%血量，-58%速度
		SIZE_LEVEL_14: {"health": 15.0, "speed": 0.38}, ## 14级：+1400%血量，-62%速度
		SIZE_LEVEL_15: {"health": 18.0, "speed": 0.35}, ## 15级：+1700%血量，-65%速度
		SIZE_LEVEL_16: {"health": 22.0, "speed": 0.32}, ## 16级：+2100%血量，-68%速度
		SIZE_LEVEL_17: {"health": 28.0, "speed": 0.28}, ## 17级：+2700%血量，-72%速度
		SIZE_LEVEL_18: {"health": 35.0, "speed": 0.25}, ## 18级：+3400%血量，-75%速度
		SIZE_LEVEL_19: {"health": 45.0, "speed": 0.22}, ## 19级：+4400%血量，-78%速度
		SIZE_LEVEL_20: {"health": 60.0, "speed": 0.18}  ## 20级：+5900%血量，-82%速度 - 终极Boss
	}
	
	# ============================================
	# 敌人生成配置（固定波次系统）
	# ============================================
	## 游戏使用固定波次系统，共 11 波（10 波常规 + 1 波 Boss）
	## 每波敌人体型递增：第 1 波体型 1 → 第 10 波体型 10 → Boss 波体型 20
	const SPAWN_INTERVAL: float = 0.8  ## 【核心参数】波次内敌人生成间隔（秒）。越小=波次内出怪越快=越难
	
	# ============================================
	# 体型属性配置
	# ============================================
	## 体型等级影响敌人的血量、速度等属性
	## 体型越大，血量越高，速度越慢
	
	# ============================================
	# 敌人分数映射表（击杀奖励）
	# ============================================
	## 击杀不同体型敌人获得的分数
	## 分数用于玩家表现评估和最终得分计算
	## 11级以上：巨型敌人，分数大幅提升
	static var ENEMY_SCORE_MAP = {
		SIZE_LEVEL_1: 10,    ## 1级：10分 - 容易击杀，分数低
		SIZE_LEVEL_2: 15,    ## 2级：15分
		SIZE_LEVEL_3: 20,    ## 3级：20分
		SIZE_LEVEL_4: 28,    ## 4级：28分
		SIZE_LEVEL_5: 38,    ## 5级：38分
		SIZE_LEVEL_6: 50,    ## 6级：50分
		SIZE_LEVEL_7: 65,    ## 7级：65分
		SIZE_LEVEL_8: 85,    ## 8级：85分
		SIZE_LEVEL_9: 110,   ## 9级：110分
		SIZE_LEVEL_10: 150,  ## 10级：150分 - 大型敌人
		SIZE_LEVEL_11: 220,  ## 11级：220分 - 巨型开始
		SIZE_LEVEL_12: 320,  ## 12级：320分
		SIZE_LEVEL_13: 450,  ## 13级：450分
		SIZE_LEVEL_14: 600,  ## 14级：600分
		SIZE_LEVEL_15: 800,  ## 15级：800分
		SIZE_LEVEL_16: 1050, ## 16级：1050分
		SIZE_LEVEL_17: 1400, ## 17级：1400分
		SIZE_LEVEL_18: 1800, ## 18级：1800分
		SIZE_LEVEL_19: 2400, ## 19级：2400分
		SIZE_LEVEL_20: 3200  ## 20级：3200分 - 终极Boss
	}

# 碰撞层常量
const STRUCTURE_LAYER: int = 2  # 结构层
const ENEMY_LAYER: int = 4      # 敌人层

static var COLOR_MAP = {
	Enums.ColorType.WHITE: Color("#CCCCCCFF"),
	Enums.ColorType.BLACK: Color("#444444ff"),
	Enums.ColorType.RED: Color("#ff4545ff"),
	Enums.ColorType.ORANGE_RED: Color("#FF6C35ff"),
	Enums.ColorType.ORANGE: Color("#FF9225ff"),
	Enums.ColorType.ORANGE_YELLOW: Color("#FFB835ff"),
	Enums.ColorType.YELLOW: Color("#ffde45ff"),
	Enums.ColorType.GREEN_YELLOW: Color("#B1C845ff"),
	Enums.ColorType.GREEN: Color("#62B245ff"),
	Enums.ColorType.GREEN_BLUE: Color("#549DA2ff"),
	Enums.ColorType.BLUE: Color("#4587ffff"),
	Enums.ColorType.PURPLE_BLUE: Color("#7466D1ff"),
	Enums.ColorType.PURPLE: Color("#A245A2ff"),
	Enums.ColorType.PURPLE_RED: Color("#D14574ff"),
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
		"detection_range": 12 * grid_size,
		"bullet_lifetime": 2.0,
		"shotgun_enabled": true,
		"shotgun_count": 3,
		"shotgun_angle_spread": 15.0
	},
	Enums.ColorType.BLUE: {
		"fire_rate": 2.0,
		"bullet_speed": 1200.0,
		"bullet_damage": 30.0,
		"detection_range": 14 * grid_size,
		"bullet_lifetime": 1.2
	},
	Enums.ColorType.YELLOW: {
		"fire_rate": 1.0,
		"bullet_speed": 800.0,
		"bullet_damage": 28,
		"detection_range": 18 * grid_size,
		"bullet_lifetime": 0.5,
		"magic_enabled": true,
		"magic_beam_width": 8.0,
		"magic_beam_duration": 0.2
	},
	Enums.ColorType.GREEN: {
		"fire_rate": 1.5,
		"bullet_speed": 1000.0,
		"bullet_damage": 29.0,
		"detection_range": 17 * grid_size,
		"bullet_lifetime": 1.6,
		"homing_enabled": true,
		"homing_detection_range": 8 * grid_size,
		"homing_turn_speed": 12.0
	},
	Enums.ColorType.ORANGE: {
		"fire_rate": 0.75,
		"bullet_speed": 550.0,
		"bullet_damage": 28.0,
		"detection_range": 16 * grid_size,
		"bullet_lifetime": 1.6,
		"lightning_enabled": true,
		"lightning_chain_range": 16 * grid_size,
		"lightning_max_chain": 5
	},
	Enums.ColorType.PURPLE: {
		"fire_rate": 0.5,
		"bullet_speed": 600.0,
		"bullet_damage": 60.0,
		"detection_range": 11 * grid_size,
		"bullet_lifetime": 2.0,
		"explosive_enabled": true,
		"explosion_radius": 7 * grid_size,
		"explosion_particle_duration": 1.0
	},
	Enums.ColorType.BLACK: {
		"fire_rate": 0.1,
		"bullet_speed": 400.0,
		"bullet_damage": 10.0,
		"detection_range": 4 * grid_size,
		"bullet_lifetime": 3.0
	},
	Enums.ColorType.GREEN_BLUE: {
		"fire_rate": 1.2,
		"bullet_speed": 750.0,
		"bullet_damage": 10.0,
		"detection_range": 15 * grid_size,
		"bullet_lifetime": 1.8,
		"splitting_homing_enabled": true,
		"splitting_homing_detection_range": 5 * grid_size,
		"splitting_homing_turn_speed": 7.0,
		"splitting_count": 3,
		"splitting_angle_spread": 45.0,
		"splitting_bullet_damage": 10.0,
		"splitting_bullet_lifetime": 1.8,
		"splitting_bullet_homing_detection_range": 6 * grid_size,
		"splitting_bullet_homing_turn_speed": 10.0,
		"splitting_bullet_attack_delay": 0.15
	},
	Enums.ColorType.GREEN_YELLOW: {
		"fire_rate": 1.3,
		"bullet_speed": 1900.0,
		"bullet_damage": 28.0,
		"detection_range": 15 * grid_size,
		"bullet_lifetime": 3.0,
		"penetrating_enabled": true,
		"penetrating_homing_enabled": true,
		"penetrating_homing_detection_range": 5 * grid_size,
		"penetrating_homing_turn_speed": 5.0,
		"penetrating_max_targets": 4,
		"penetrating_damage_decay": 0.85
	},
	Enums.ColorType.ORANGE_RED: {
		"fire_rate": 0.8,
		"bullet_speed": 1600.0,
		"bullet_damage": 28.0,
		"detection_range": 16 * grid_size,
		"bullet_lifetime": 2.5,
		"bouncing_lightning_enabled": true,
		"bouncing_lightning_chain_range": 8 * grid_size,
		"bouncing_lightning_max_bounces": 5,
		"bouncing_lightning_damage_decay": 0.2
	},
	Enums.ColorType.ORANGE_YELLOW: {
		"fire_rate": 0.5,
		"bullet_speed": 800.0,
		"bullet_damage": 15.0,
		"detection_range": 16 * grid_size,
		"bullet_lifetime": 0.8,
		"charging_laser_enabled": true,
		"charging_laser_beam_width": 3.0,
		"charging_laser_beam_duration": 0.3,
		"charging_laser_damage_increment": 3.0,
		"charging_laser_max_damage_multiplier": 3.0
	},
	Enums.ColorType.PURPLE_RED: {
		"fire_rate": 0.7,
		"bullet_speed": 600.0,
		"bullet_damage": 35.0,
		"detection_range": 14 * grid_size,
		"bullet_lifetime": 1.5,
		"cluster_bomb_enabled": true,
		"cluster_bomb_explosion_radius": 5 * grid_size,
		"cluster_bomb_cluster_count": 4,
		"cluster_bomb_angle_spread": 15.0,
		"cluster_bomb_bullet_damage": 15.0,
		"cluster_bomb_bullet_lifetime": 0.8,
		"cluster_bomb_bullet_speed": 600.0
	},
	Enums.ColorType.PURPLE_BLUE: {
		"fire_rate": 1.0,
		"bullet_speed": 700.0,
		"bullet_damage": 40.0,
		"detection_range": 14 * grid_size,
		"bullet_lifetime": 1.2,
		"continuous_explosive_enabled": true,
		"continuous_explosive_explosion_radius": 3 * grid_size,
		"continuous_explosive_slow_duration": 2.0,
		"continuous_explosive_slow_multiplier": 0.5
	}
}
