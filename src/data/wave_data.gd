class_name WaveData extends Resource

## 波次数据类
## 定义单个波次的所有配置信息

@export var wave_index: int = 0  ## 波次索引
@export var wave_name: String = ""  ## 波次名称
@export var is_boss_wave: bool = false  ## 是否是 Boss 波次
@export var enemy_configs: Array[EnemySpawnConfig] = []  ## 敌人生成配置列表

## 波次间隔参数
@export var preparation_time: float = 3.0  ## 波次准备时间（秒）
@export var spawn_interval: float = 0.8  ## 敌人生成间隔（秒）
@export var wave_interval: float = 2.0  ## 波次间隔时间（秒）

## 波次触发条件
@export var require_clear_previous: bool = false  ## 是否需要清除上一波所有敌人
@export var min_enemies_alive: int = 0  ## 最小存活敌人数（低于此值才触发下一波）

## 刷怪区域参数
@export var spawn_center: Vector2 = Vector2.ZERO  ## 刷怪中心点（默认为水晶位置）
@export var min_spawn_radius: float = 400.0  ## 最小生成半径
@export var max_spawn_radius: float = 800.0  ## 最大生成半径

## 波次特殊属性
@export var difficulty_multiplier: float = 1.0  ## 难度倍数（影响敌人属性）
@export var speed_multiplier: float = 1.0  ## 速度倍数
@export var health_multiplier: float = 1.0  ## 血量倍数

## 计算该波次的总敌人数量
func get_total_enemy_count() -> int:
	var total = 0
	for config in enemy_configs:
		total += config.count
	return total

## 获取指定类型的敌人生成配置
func get_enemy_config(enemy_type: String) -> EnemySpawnConfig:
	for config in enemy_configs:
		if config.enemy_type == enemy_type:
			return config
	return null

## 添加敌人生成配置
func add_enemy_config(config: EnemySpawnConfig) -> void:
	enemy_configs.append(config)

## 清空敌人生成配置
func clear_enemy_configs() -> void:
	enemy_configs.clear()