class_name EnemySpawnConfig extends Resource

## 敌人生成配置类
## 定义单个波次中某种敌人的生成参数

@export var enemy_type: String = ""  ## 敌人类型标识符（如 "rect_enemy", "circle_enemy"）
@export var enemy_scene_path: String = ""  ## 敌人场景文件路径（用于加载）

## 敌人数量配置
@export var count: int = 1  ## 敌人数量（精确值）
@export var count_min: int = 1  ## 最小敌人数量（随机范围）
@export var count_max: int = 1  ## 最大敌人数量（随机范围）
@export var use_random_count: bool = false  ## 是否使用随机数量

## 敌人体型配置
@export var size_level: int = 1  ## 敌人体型等级（1-20）
@export var size_level_min: int = 1  ## 最小体型等级
@export var size_level_max: int = 1  ## 最大体型等级
@export var use_random_size: bool = false  ## 是否使用随机体型

## 敌人属性调整
@export var health_multiplier: float = 1.0  ## 血量倍数
@export var speed_multiplier: float = 1.0  ## 速度倍数
@export var damage_multiplier: float = 1.0  ## 伤害倍数

## 生成优先级和权重
@export var spawn_priority: int = 0  ## 生成优先级（数值越大越优先）
@export var spawn_weight: float = 1.0  ## 生成权重（影响随机选择概率）

## 特殊标记
@export var is_elite: bool = false  ## 是否是精英敌人
@export var is_boss: bool = false  ## 是否是 Boss

## 运行时状态（不持久化）
var spawned_count: int = 0  ## 已生成的敌人数量

## 重置生成计数
func reset_spawned_count() -> void:
	spawned_count = 0

## 检查是否还有未生成的敌人
func has_remaining() -> bool:
	return spawned_count < get_actual_count()

## 获取剩余可生成数量
func get_remaining_count() -> int:
	return get_actual_count() - spawned_count

## 标记已生成一个敌人
func increment_spawned_count() -> void:
	spawned_count += 1

## 计算实际生成的敌人数量
func get_actual_count() -> int:
	if use_random_count:
		return randi_range(count_min, count_max + 1)
	return count

## 计算实际的体型等级
func get_actual_size_level() -> int:
	if use_random_size:
		return randi_range(size_level_min, size_level_max + 1)
	return size_level

## 加载敌人场景
func load_enemy_scene() -> PackedScene:
	if enemy_scene_path.is_empty():
		return null
	
	if ResourceLoader.exists(enemy_scene_path):
		return load(enemy_scene_path)
	
	push_warning("敌人场景文件不存在: " + enemy_scene_path)
	return null

## 验证配置有效性
func is_valid() -> bool:
	if enemy_type.is_empty():
		push_warning("敌人生成配置：enemy_type 不能为空")
		return false
	
	if count <= 0 and count_min <= 0:
		push_warning("敌人生成配置：count 或 count_min 必须大于 0")
		return false
	
	if size_level < 1 or size_level > 20:
		push_warning("敌人生成配置：size_level 必须在 1-20 之间")
		return false
	
	return true
