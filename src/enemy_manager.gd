class_name EnemyManager extends Node2D

## 敌人预制体列表
@export var enemy_list: Array[PackedScene] = []

# 刷新相关参数
@export var spawn_interval: float = Constants.EnemyConstants.DEFAULT_SPAWN_INTERVAL
@export var current_difficulty: int = Constants.EnemyConstants.DEFAULT_DIFFICULTY
@export var min_spawn_distance: float = Constants.EnemyConstants.MIN_SPAWN_DISTANCE

@export var is_start_spwn : bool = true

# 内部变量
var _spawn_timer: float = 0.0
var _crystal_position: Vector2 = Vector2.ZERO
var _max_spawn_attempts: int = 10  # 最大位置生成尝试次数

# 时间相关变量
var _game_time: float = 0.0  # 游戏运行时间（秒）
var _max_unlock_time: float = Constants.EnemyConstants.MAX_SIZE_UNLOCK_TIME  # 完全解锁所有体型所需时间
var _time_scale_factor: float = Constants.EnemyConstants.TIME_SCALE_FACTOR  # 时间缩放因子

# 波次系统变量
var _wave_timer: float = 0.0  # 波次计时器
var _current_wave: int = 0  # 当前波次
var _is_wave_active: bool = false  # 波次是否激活
var _wave_enemies_spawned: int = 0  # 波次已生成敌人数量

func _ready() -> void:
	# 查找水晶位置
	_find_crystal_position()
	
	# 验证敌人列表
	if enemy_list.is_empty():
		push_warning("EnemyManager: 敌人列表为空，无法生成敌人")
	
	# 验证难度等级
	current_difficulty = clamp(current_difficulty, 
		Constants.EnemyConstants.MIN_DIFFICULTY, 
		Constants.EnemyConstants.MAX_DIFFICULTY)
	
	print("EnemyManager 初始化完成 - 难度等级: ", current_difficulty, " 刷新间隔: ", spawn_interval)

func _process(delta: float) -> void:
	# 更新游戏时间
	_game_time += delta
	
	# 动态调整刷新间隔
	_update_spawn_interval()
	
	# 更新刷新计时器
	_spawn_timer += delta
	
	# 波次系统处理
	_update_wave_system(delta)
	
	# 检查是否达到刷新间隔
	if _spawn_timer >= spawn_interval:
		_spawn_timer = 0.0
		if is_start_spwn:
			_try_spawn_enemy()
			
			# 波次期间额外生成敌人
			if _is_wave_active and _wave_enemies_spawned < Constants.EnemyConstants.WAVE_ENEMY_COUNT:
				_try_spawn_enemy()
				_wave_enemies_spawned += 1
				if _wave_enemies_spawned >= Constants.EnemyConstants.WAVE_ENEMY_COUNT:
					_is_wave_active = false
					print("波次 ", _current_wave, " 结束")

func _update_spawn_interval() -> void:
	"""根据游戏时间和玩家表现动态调整刷新间隔 - 前期压力大，后期平缓"""
	# 计算时间进度（0.0 - 1.0），使用幂函数控制曲线
	# TIME_PROGRESS_POWER < 1 使前期变化快，后期变化慢
	var raw_progress = min(_game_time / _max_unlock_time, 1.0)
	var time_progress = pow(raw_progress, Constants.EnemyConstants.TIME_PROGRESS_POWER)
	
	# 获取玩家表现数据
	var player_performance = _get_player_performance()
	
	# 综合时间和玩家表现调整难度
	var performance_factor = 1.0
	if player_performance > Constants.EnemyConstants.PERFORMANCE_HIGH_THRESHOLD:
		performance_factor = Constants.EnemyConstants.PERFORMANCE_HIGH_FACTOR
	elif player_performance > Constants.EnemyConstants.PERFORMANCE_MED_THRESHOLD:
		performance_factor = Constants.EnemyConstants.PERFORMANCE_MED_FACTOR
	
	# 波次加成（降低影响，使后期不会太快）
	var wave_factor = 1.0 + (_current_wave * Constants.EnemyConstants.WAVE_BONUS_PER_WAVE * 0.7)
	
	# 前期额外压力 - 游戏开始时额外降低间隔
	var early_game_bonus = 0.0
	if _game_time < Constants.EnemyConstants.EARLY_GAME_DURATION:
		# 前期逐渐降低压力，从最大加成到0
		early_game_bonus = Constants.EnemyConstants.EARLY_GAME_SPAWN_BONUS * (1.0 - _game_time / Constants.EnemyConstants.EARLY_GAME_DURATION)
	
	# 计算目标刷新间隔
	var interval_range = Constants.EnemyConstants.SPAWN_INTERVAL_MAX - Constants.EnemyConstants.SPAWN_INTERVAL_MIN
	var target_interval = Constants.EnemyConstants.SPAWN_INTERVAL_MAX - (interval_range * time_progress * performance_factor * wave_factor)
	
	# 应用前期压力加成
	target_interval = target_interval * (1.0 - early_game_bonus)
	
	# 确保最小间隔
	target_interval = max(target_interval, Constants.EnemyConstants.SPAWN_INTERVAL_MIN)
	
	# 限制后期增长 - 如果超过中期目标，减缓下降速度
	if target_interval < Constants.EnemyConstants.SPAWN_INTERVAL_MID:
		var mid_to_min_range = Constants.EnemyConstants.SPAWN_INTERVAL_MID - Constants.EnemyConstants.SPAWN_INTERVAL_MIN
		var current_in_mid_range = Constants.EnemyConstants.SPAWN_INTERVAL_MID - target_interval
		var slowed_progress = pow(current_in_mid_range / mid_to_min_range, 0.7) * mid_to_min_range
		target_interval = Constants.EnemyConstants.SPAWN_INTERVAL_MID - slowed_progress
	
	# 平滑过渡
	spawn_interval = lerp(spawn_interval, target_interval, Constants.EnemyConstants.SPAWN_LERP_SPEED)

func _get_player_performance() -> int:
	"""获取玩家表现数据"""
	# 尝试获取GameManager实例
	var game_manager = get_tree().get_root().get_node_or_null("GameManager")
	if game_manager and game_manager.has_method("get_score_data"):
		var score_data = game_manager.get_score_data()
		return score_data.get("enemy_score", 0)
	return 0

func _update_wave_system(delta: float) -> void:
	"""更新波次系统"""
	# 更新波次计时器
	_wave_timer += delta
	
	# 检查是否达到波次间隔
	if _wave_timer >= Constants.EnemyConstants.WAVE_INTERVAL:
		_wave_timer = 0.0
		_current_wave += 1
		_is_wave_active = true
		_wave_enemies_spawned = 0
		
		# 波次开始，提升难度
		var difficulty_increase = Constants.EnemyConstants.WAVE_DIFFICULTY_INCREASE + int(_current_wave / Constants.EnemyConstants.WAVE_EXTRA_DIFFICULTY_INTERVAL)
		current_difficulty = min(current_difficulty + difficulty_increase, Constants.EnemyConstants.MAX_DIFFICULTY)
		
		# 波次期间降低刷新间隔
		spawn_interval = max(spawn_interval * Constants.EnemyConstants.WAVE_SPAWN_INTERVAL_MULTIPLIER, Constants.EnemyConstants.SPAWN_INTERVAL_MIN)
		
		print("波次 ", _current_wave, " 开始！难度提升到: ", current_difficulty, " 刷新间隔: ", spawn_interval)

func _find_crystal_position() -> void:
	"""查找水晶的位置"""
	# 在场景中查找水晶
	var crystals = get_tree().get_nodes_in_group("crystal")
	if crystals.size() > 0:
		_crystal_position = crystals[0].global_position
		print("找到水晶位置: ", _crystal_position)
	else:
		# 如果没有找到水晶，使用默认位置
		_crystal_position = Vector2.ZERO
		push_warning("未找到水晶，将使用默认位置 (0, 0)")

func _try_spawn_enemy() -> void:
	"""尝试生成敌人"""
	# 检查敌人列表是否为空
	if enemy_list.is_empty():
		push_warning("EnemyManager: 敌人列表为空，跳过生成")
		return
	
	# 获取可用的敌人类型（根据难度等级）
	var available_enemies = _get_available_enemies()
	if available_enemies.is_empty():
		push_warning("EnemyManager: 没有可用的敌人类型")
		return
	
	# 生成随机位置
	var spawn_position = _generate_spawn_position()
	if spawn_position == Vector2.ZERO:
		# 位置生成失败
		push_warning("EnemyManager: 无法生成有效的敌人位置")
		return
	
	# 随机选择敌人类型
	var enemy_index = randi() % available_enemies.size()
	var enemy_scene = available_enemies[enemy_index]
	
	# 实例化敌人
	var enemy = enemy_scene.instantiate()
	if enemy:
		enemy.global_position = spawn_position
		
		# 根据游戏时间设置敌人体型
		var size_level = _select_size_level()
		if enemy.has_method("set_size_level"):
			enemy.set_size_level(size_level)
		
		add_child(enemy)
		print("生成敌人: ", enemy.name, " 位置: ", spawn_position, " 体型等级: ", size_level)
	else:
		push_error("EnemyManager: 敌人实例化失败")

func _select_size_level() -> int:
	"""根据游戏时间选择敌人体型等级 - 前期解锁快，后期平缓"""
	# 计算时间进度（0.0 - 1.0），使用幂函数控制曲线
	# SIZE_UNLOCK_POWER < 1 使前期体型解锁更快，后期平缓
	var raw_time_progress = min(_game_time / _max_unlock_time, 1.0)
	var time_progress = pow(raw_time_progress, Constants.EnemyConstants.SIZE_UNLOCK_POWER)
	
	# 计算波次加成（降低影响）
	var wave_bonus = float(_current_wave) * Constants.EnemyConstants.WAVE_BONUS_PER_WAVE * 0.6
	
	# 综合时间和波次进度
	var combined_progress = min(time_progress + wave_bonus, 1.0)
	
	# 根据综合进度计算可用的最大体型等级
	var max_unlocked_level = int(1 + combined_progress * (Constants.EnemyConstants.MAX_SIZE_LEVEL - 1))
	max_unlocked_level = clamp(max_unlocked_level, Constants.EnemyConstants.SIZE_LEVEL_1, Constants.EnemyConstants.MAX_SIZE_LEVEL)
	
	# 计算每个体型的权重（大体型权重随时间和波次增加）
	var weights = []
	var total_weight = 0.0
	
	for level in range(Constants.EnemyConstants.SIZE_LEVEL_1, max_unlocked_level + 1):
		# 基础权重
		var base_weight = 0.8
		
		# 时间加成（大体型随时间获得更高权重）
		var time_bonus = pow(float(level - 1), Constants.EnemyConstants.SIZE_WEIGHT_POWER) * combined_progress * _time_scale_factor
		
		# 波次加成（波次期间提升大体型权重）
		var wave_bonus_weight = 0.0
		if _is_wave_active:
			wave_bonus_weight = pow(float(level - 1), Constants.EnemyConstants.WAVE_SIZE_BONUS_POWER) * Constants.EnemyConstants.WAVE_SIZE_BONUS_FACTOR
		
		# 后期游戏加成 - 游戏时间越长，大体型权重越高
		var late_game_bonus = 0.0
		if _game_time > Constants.EnemyConstants.LATE_GAME_START_TIME:
			var late_game_progress = min((_game_time - Constants.EnemyConstants.LATE_GAME_START_TIME) / 60.0, 1.0)
			late_game_bonus = float(level - 1) * Constants.EnemyConstants.LATE_GAME_BONUS_FACTOR * late_game_progress
		
		# 最终权重
		var final_weight = base_weight + time_bonus + wave_bonus_weight + late_game_bonus
		weights.append(final_weight)
		total_weight += final_weight
	
	# 根据权重随机选择体型
	var random_value = randf() * total_weight
	var accumulated_weight = 0.0
	
	for i in range(weights.size()):
		accumulated_weight += weights[i]
		if random_value <= accumulated_weight:
			return Constants.EnemyConstants.SIZE_LEVEL_1 + i
	
	# 默认返回最小体型
	return Constants.EnemyConstants.SIZE_LEVEL_1

func _get_available_enemies() -> Array[PackedScene]:
	"""根据当前难度等级获取可用的敌人类型"""
	var available_enemies: Array[PackedScene] = []
	
	# 限制难度等级不超过敌人列表长度
	var max_enemy_index = min(current_difficulty, enemy_list.size()) - 1
	
	# 获取前N个敌人（N为当前难度等级）
	for i in range(max_enemy_index + 1):
		available_enemies.append(enemy_list[i])
	
	return available_enemies

func _generate_spawn_position() -> Vector2:
	"""生成随机位置，敌人在远处生成，从四面八方涌来"""
	var spawn_position: Vector2 = Vector2.ZERO
	var attempts: int = 0
	
	while attempts < _max_spawn_attempts:
		# 使用环形分布生成位置 - 在最小和最大距离之间随机选择距离
		# 使用幂函数使敌人更倾向于在远处生成（更有涌来的感觉）
		var distance_bias = pow(randf(), Constants.EnemyConstants.SPAWN_DISTANCE_BIAS)
		var spawn_distance = lerp(
			Constants.EnemyConstants.MIN_SPAWN_DISTANCE,
			Constants.EnemyConstants.MAX_SPAWN_DISTANCE,
			distance_bias
		)
		
		# 随机角度（0-360度，四面八方）
		var spawn_angle = randf() * 2.0 * PI
		
		# 计算生成位置（基于水晶位置）
		spawn_position = _crystal_position + Vector2(
			cos(spawn_angle) * spawn_distance,
			sin(spawn_angle) * spawn_distance
		)
		
		# 检查是否在地图范围内
		if spawn_position.x >= Constants.CameraConstants.MIN_X and \
		   spawn_position.x <= Constants.CameraConstants.MAX_X and \
		   spawn_position.y >= Constants.CameraConstants.MIN_Y and \
		   spawn_position.y <= Constants.CameraConstants.MAX_Y:
			return spawn_position
		
		attempts += 1
	
	# 如果多次尝试都失败，使用备选方案：在最小距离处生成
	var fallback_angle = randf() * 2.0 * PI
	spawn_position = _crystal_position + Vector2(
		cos(fallback_angle) * Constants.EnemyConstants.MIN_SPAWN_DISTANCE,
		sin(fallback_angle) * Constants.EnemyConstants.MIN_SPAWN_DISTANCE
	)
	return spawn_position

func set_difficulty(difficulty: int) -> void:
	"""设置难度等级"""
	current_difficulty = clamp(difficulty, 
		Constants.EnemyConstants.MIN_DIFFICULTY, 
		Constants.EnemyConstants.MAX_DIFFICULTY)
	print("设置难度等级: ", current_difficulty)

func set_spawn_interval(interval: float) -> void:
	"""设置刷新间隔"""
	spawn_interval = max(0.5, interval)  # 最小间隔0.5秒
	print("设置刷新间隔: ", spawn_interval, " 秒")

func set_min_spawn_distance(distance: float) -> void:
	"""设置最小生成距离"""
	min_spawn_distance = max(100.0, distance)  # 最小距离100像素
	print("设置最小生成距离: ", min_spawn_distance)

func stop_spawning() -> void:
	"""停止生成敌人"""
	spawn_interval = 0.0  # 设置为0表示停止
	print("停止生成敌人")

func start_spawning() -> void:
	"""开始生成敌人"""
	if spawn_interval <= 0:
		spawn_interval = Constants.EnemyConstants.DEFAULT_SPAWN_INTERVAL
	print("开始生成敌人，间隔: ", spawn_interval, " 秒")

func get_game_time() -> float:
	"""获取游戏运行时间"""
	return _game_time

func get_current_spawn_interval() -> float:
	"""获取当前刷新间隔"""
	return spawn_interval
