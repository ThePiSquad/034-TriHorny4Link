class_name ResourceManager extends Node

## 资源管理器
## 负责加载、缓存和管理关卡及波次配置资源

# 单例实例
static var instance: ResourceManager

# 资源缓存
var _level_cache: Dictionary = {}  ## 关卡数据缓存 {level_id: LevelData}
var _enemy_scene_cache: Dictionary = {}  ## 敌人场景缓存 {path: PackedScene}

# 配置文件路径
const LEVEL_CONFIG_DIR: String = "res://config/levels/"  ## 关卡配置文件目录
const LEVEL_CONFIG_EXT: String = ".json"  ## 关卡配置文件扩展名

# 信号
signal level_loaded(level_id: String)
signal level_load_failed(level_id: String, error: String)
signal cache_cleared()

func _ready() -> void:
	# 设置单例
	if instance == null:
		instance = self
	else:
		queue_free()
		return
	
	# 预加载默认关卡
	_preload_default_levels()

## 预加载默认关卡
func _preload_default_levels() -> void:
	var default_levels = ["level_1", "level_2", "level_3"]
	for level_id in default_levels:
		load_level(level_id)

## 加载关卡数据
## 参数:
## level_id: 关卡唯一标识符
## force_reload: 是否强制重新加载（忽略缓存）
## 返回: LevelData 对象，失败返回 null
func load_level(level_id: String, force_reload: bool = false) -> LevelData:
	# 检查缓存
	if not force_reload and _level_cache.has(level_id):
		print("从缓存加载关卡: ", level_id)
		return _level_cache[level_id]
	
	# 构建配置文件路径
	var config_path = LEVEL_CONFIG_DIR + level_id + LEVEL_CONFIG_EXT
	
	# 检查文件是否存在
	if not FileAccess.file_exists(config_path):
		push_error("关卡配置文件不存在: " + config_path)
		level_load_failed.emit(level_id, "配置文件不存在")
		return null
	
	# 读取并解析 JSON 文件
	var file = FileAccess.open(config_path, FileAccess.READ)
	if not file:
		push_error("无法打开关卡配置文件: " + config_path)
		level_load_failed.emit(level_id, "文件读取失败")
		return null
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	
	if parse_result != OK:
		push_error("关卡配置 JSON 解析失败: " + json.get_error_message())
		level_load_failed.emit(level_id, "JSON 解析失败")
		return null
	
	# 创建 LevelData 对象
	var level_data = _parse_level_data(json.data, level_id)
	
	if level_data:
		# 添加到缓存
		_level_cache[level_id] = level_data
		print("关卡加载成功: ", level_id, " (", level_data.waves.size(), " 个波次)")
		level_loaded.emit(level_id)
	else:
		level_load_failed.emit(level_id, "数据解析失败")
	
	return level_data

## 解析关卡数据
func _parse_level_data(json_data: Dictionary, level_id: String) -> LevelData:
	var level_data = LevelData.new()
	
	# 基本属性
	level_data.level_id = json_data.get("level_id", level_id)
	level_data.level_name = json_data.get("level_name", "")
	level_data.level_description = json_data.get("level_description", "")
	level_data.difficulty = json_data.get("difficulty", 1)
	level_data.recommended_level = json_data.get("recommended_level", 1)
	level_data.boss_wave_index = json_data.get("boss_wave_index", -1)
	
	# 解析波次数据
	var waves_array = json_data.get("waves", [])
	for wave_json in waves_array:
		var wave_data = _parse_wave_data(wave_json)
		if wave_data:
			level_data.waves.append(wave_data)
	
	return level_data

## 解析波次数据
func _parse_wave_data(wave_json: Dictionary) -> WaveData:
	var wave_data = WaveData.new()
	
	# 基本属性
	wave_data.wave_index = wave_json.get("wave_index", 0)
	wave_data.wave_name = wave_json.get("wave_name", "")
	wave_data.is_boss_wave = wave_json.get("is_boss_wave", false)
	
	# 间隔参数
	wave_data.preparation_time = wave_json.get("preparation_time", 3.0)
	wave_data.spawn_interval = wave_json.get("spawn_interval", 0.8)
	wave_data.wave_interval = wave_json.get("wave_interval", 2.0)
	
	# 触发条件
	wave_data.require_clear_previous = wave_json.get("require_clear_previous", false)
	wave_data.min_enemies_alive = wave_json.get("min_enemies_alive", 0)
	
	# 刷怪区域
	var spawn_center_array = wave_json.get("spawn_center", [0, 0])
	wave_data.spawn_center = Vector2(spawn_center_array[0], spawn_center_array[1])
	wave_data.min_spawn_radius = wave_json.get("min_spawn_radius", 400.0)
	wave_data.max_spawn_radius = wave_json.get("max_spawn_radius", 800.0)
	
	# 波次倍数
	wave_data.difficulty_multiplier = wave_json.get("difficulty_multiplier", 1.0)
	wave_data.speed_multiplier = wave_json.get("speed_multiplier", 1.0)
	wave_data.health_multiplier = wave_json.get("health_multiplier", 1.0)
	
	# 解析敌人生成配置
	var enemies_array = wave_json.get("enemies", [])
	for enemy_json in enemies_array:
		var enemy_config = _parse_enemy_config(enemy_json)
		if enemy_config and enemy_config.is_valid():
			wave_data.enemy_configs.append(enemy_config)
	
	return wave_data

## 解析敌人生成配置
func _parse_enemy_config(enemy_json: Dictionary) -> EnemySpawnConfig:
	var config = EnemySpawnConfig.new()
	
	# 基本属性
	config.enemy_type = enemy_json.get("enemy_type", "")
	config.enemy_scene_path = enemy_json.get("enemy_scene_path", "")
	
	# 数量配置
	config.count = enemy_json.get("count", 1)
	config.count_min = enemy_json.get("count_min", 1)
	config.count_max = enemy_json.get("count_max", 1)
	config.use_random_count = enemy_json.get("use_random_count", false)
	
	# 体型配置
	config.size_level = enemy_json.get("size_level", 1)
	config.size_level_min = enemy_json.get("size_level_min", 1)
	config.size_level_max = enemy_json.get("size_level_max", 1)
	config.use_random_size = enemy_json.get("use_random_size", false)
	
	# 属性倍数
	config.health_multiplier = enemy_json.get("health_multiplier", 1.0)
	config.speed_multiplier = enemy_json.get("speed_multiplier", 1.0)
	config.damage_multiplier = enemy_json.get("damage_multiplier", 1.0)
	
	# 优先级和权重
	config.spawn_priority = enemy_json.get("spawn_priority", 0)
	config.spawn_weight = enemy_json.get("spawn_weight", 1.0)
	
	# 特殊标记
	config.is_elite = enemy_json.get("is_elite", false)
	config.is_boss = enemy_json.get("is_boss", false)
	
	return config

## 加载敌人场景
## 参数:
## scene_path: 场景文件路径
## 返回: PackedScene 对象，失败返回 null
func load_enemy_scene(scene_path: String) -> PackedScene:
	# 检查缓存
	if _enemy_scene_cache.has(scene_path):
		return _enemy_scene_cache[scene_path]
	
	# 加载场景
	if not ResourceLoader.exists(scene_path):
		push_warning("敌人场景文件不存在: " + scene_path)
		return null
	
	var scene = load(scene_path)
	if scene:
		# 添加到缓存
		_enemy_scene_cache[scene_path] = scene
	
	return scene

## 清除关卡缓存
func clear_level_cache(level_id: String = "") -> void:
	if level_id.is_empty():
		# 清除所有缓存
		_level_cache.clear()
		print("已清除所有关卡缓存")
	else:
		# 清除指定关卡缓存
		_level_cache.erase(level_id)
		print("已清除关卡缓存: ", level_id)
	
	cache_cleared.emit()

## 清除敌人场景缓存
func clear_enemy_scene_cache(scene_path: String = "") -> void:
	if scene_path.is_empty():
		# 清除所有缓存
		_enemy_scene_cache.clear()
		print("已清除所有敌人场景缓存")
	else:
		# 清除指定场景缓存
		_enemy_scene_cache.erase(scene_path)
		print("已清除敌人场景缓存: ", scene_path)
	
	cache_cleared.emit()

## 获取已缓存的关卡列表
func get_cached_levels() -> Array:
	return _level_cache.keys()

## 保存关卡配置到文件
## 参数:
## level_data: LevelData 对象
## 返回: 是否保存成功
func save_level_config(level_data: LevelData) -> bool:
	var config_path = LEVEL_CONFIG_DIR + level_data.level_id + LEVEL_CONFIG_EXT
	
	# 确保目录存在
	DirAccess.make_dir_absolute(LEVEL_CONFIG_DIR)
	
	# 构建 JSON 数据
	var json_data = _serialize_level_data(level_data)
	
	# 写入文件
	var file = FileAccess.open(config_path, FileAccess.WRITE)
	if not file:
		push_error("无法创建关卡配置文件: " + config_path)
		return false
	
	file.store_string(JSON.stringify(json_data, "\t"))
	file.close()
	
	print("关卡配置已保存: ", config_path)
	return true

## 序列化关卡数据为 JSON
func _serialize_level_data(level_data: LevelData) -> Dictionary:
	var json_data = {
		"level_id": level_data.level_id,
		"level_name": level_data.level_name,
		"level_description": level_data.level_description,
		"difficulty": level_data.difficulty,
		"recommended_level": level_data.recommended_level,
		"boss_wave_index": level_data.boss_wave_index,
		"waves": []
	}
	
	# 序列化波次
	for wave in level_data.waves:
		json_data["waves"].append(_serialize_wave_data(wave))
	
	return json_data

## 序列化波次数据为 JSON
func _serialize_wave_data(wave_data: WaveData) -> Dictionary:
	var json_data = {
		"wave_index": wave_data.wave_index,
		"wave_name": wave_data.wave_name,
		"is_boss_wave": wave_data.is_boss_wave,
		"preparation_time": wave_data.preparation_time,
		"spawn_interval": wave_data.spawn_interval,
		"wave_interval": wave_data.wave_interval,
		"require_clear_previous": wave_data.require_clear_previous,
		"min_enemies_alive": wave_data.min_enemies_alive,
		"spawn_center": [wave_data.spawn_center.x, wave_data.spawn_center.y],
		"min_spawn_radius": wave_data.min_spawn_radius,
		"max_spawn_radius": wave_data.max_spawn_radius,
		"difficulty_multiplier": wave_data.difficulty_multiplier,
		"speed_multiplier": wave_data.speed_multiplier,
		"health_multiplier": wave_data.health_multiplier,
		"enemies": []
	}
	
	# 序列化敌人生成配置
	for enemy_config in wave_data.enemy_configs:
		json_data["enemies"].append(_serialize_enemy_config(enemy_config))
	
	return json_data

## 序列化敌人生成配置为 JSON
func _serialize_enemy_config(config: EnemySpawnConfig) -> Dictionary:
	return {
		"enemy_type": config.enemy_type,
		"enemy_scene_path": config.enemy_scene_path,
		"count": config.count,
		"count_min": config.count_min,
		"count_max": config.count_max,
		"use_random_count": config.use_random_count,
		"size_level": config.size_level,
		"size_level_min": config.size_level_min,
		"size_level_max": config.size_level_max,
		"use_random_size": config.use_random_size,
		"health_multiplier": config.health_multiplier,
		"speed_multiplier": config.speed_multiplier,
		"damage_multiplier": config.damage_multiplier,
		"spawn_priority": config.spawn_priority,
		"spawn_weight": config.spawn_weight,
		"is_elite": config.is_elite,
		"is_boss": config.is_boss
	}
