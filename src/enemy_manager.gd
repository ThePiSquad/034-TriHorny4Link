class_name EnemyManager extends Node2D

## 敌人预制体列表
@export var enemy_list: Array[PackedScene] = []
@export var boss_enemy_scene: PackedScene  # Boss 敌人预制体

# 刷新相关参数
@export var spawn_interval: float = 0.8
@export var min_spawn_distance: float = Constants.EnemyConstants.MIN_SPAWN_DISTANCE

# 内部变量
var _spawn_timer: float = 0.0
var _crystal_position: Vector2 = Vector2.ZERO
var _max_spawn_attempts: int = 10

# 波次系统
var wave_system: WaveSystem = null

# 游戏状态
var game_started: bool = false

func _ready() -> void:
	# 验证敌人列表
	if enemy_list.is_empty():
		push_warning("EnemyManager: 敌人列表为空，无法生成敌人")
	
	# 初始化波次系统
	wave_system = WaveSystem.new()
	
	# 连接波次信号
	wave_system.wave_preparing.connect(_on_wave_preparing)
	wave_system.wave_started.connect(_on_wave_started)
	wave_system.wave_completed.connect(_on_wave_completed)
	wave_system.all_waves_completed.connect(_on_all_waves_completed)
	wave_system.boss_wave_started.connect(_on_boss_wave_started)
	wave_system.boss_defeated.connect(_on_boss_defeated)

func _process(delta: float) -> void:
	if not game_started:
		return
	
	# 更新波次系统
	if wave_system:
		wave_system.update(delta)
		
		# 如果波次系统正在生成敌人
		if wave_system.current_state == WaveSystem.WaveState.SPAWNING:
			_spawn_timer += delta
			if _spawn_timer >= wave_system.wave_intervals.spawn_interval:
				_spawn_timer = 0.0
				_spawn_wave_enemy()

func start_game() -> void:
	"""开始游戏"""
	# 确保水晶位置已设置
	_find_crystal_position()
	
	game_started = true
	wave_system.reset()
	# 开始第一波
	wave_system.advance_to_next_wave()

func _spawn_wave_enemy() -> void:
	"""生成波次敌人"""
	if not wave_system:
		push_warning("EnemyManager: wave_system 为空！")
		return
	
	var wave_info = wave_system.get_current_wave_info()
	if wave_info.is_empty():
		push_warning("EnemyManager: wave_info 为空！")
		return
	
	# 检查是否已经生成了足够的敌人
	if wave_info.spawned_count >= wave_info.total_count:
		return
	
	# Boss 波次特殊处理
	if wave_info.is_boss:
		_spawn_boss_enemy()
	else:
		_spawn_normal_enemy(wave_info.size)

func _spawn_normal_enemy(size_level: int) -> void:
	"""生成普通敌人"""
	if enemy_list.is_empty():
		push_warning("EnemyManager: 敌人列表为空！")
		return
	
	# 随机选择敌人类型
	var enemy_index = randi() % enemy_list.size()
	var enemy_scene = enemy_list[enemy_index]
	
	var enemy = enemy_scene.instantiate()
	if enemy:
		var spawn_position = _generate_spawn_position_for_size(size_level)
		enemy.global_position = spawn_position
		
		# 设置基地位置
		if enemy.has_method("set_base_position"):
			enemy.set_base_position(_crystal_position)
		
		# 设置敌人体型
		if enemy.has_method("set_size_level"):
			enemy.set_size_level(size_level)
		
		add_child(enemy)
	else:
		push_error("EnemyManager: 敌人实例化失败")

func _spawn_boss_enemy() -> void:
	"""生成 Boss 敌人"""
	var boss_to_spawn = boss_enemy_scene
	if not boss_to_spawn:
		# 如果没有指定 Boss 场景，使用第一个敌人
		boss_to_spawn = enemy_list[0] if not enemy_list.is_empty() else null
	
	if not boss_to_spawn:
		push_error("EnemyManager: Boss 场景未设置！")
		return
	
	var boss = boss_to_spawn.instantiate()
	if boss:
		# Boss 生成在边缘
		var spawn_position = _generate_spawn_position_for_size(20)
		boss.global_position = spawn_position
		
		# 设置基地位置
		if boss.has_method("set_base_position"):
			boss.set_base_position(_crystal_position)
		
		# 设置 Boss 体型 (256x256)
		if boss.has_method("set_size_level"):
			boss.set_size_level(20)
		
		add_child(boss)
		
		# 连接 Boss 死亡信号
		if boss.has_signal("died"):
			boss.died.connect(_on_boss_died)
	else:
		push_error("EnemyManager: Boss 实例化失败")

func _on_boss_died(_source: Node) -> void:
	"""Boss 被击败"""
	# 更新波次系统状态为所有波次完成
	if wave_system:
		wave_system.current_wave = wave_system.total_wave_count + wave_system.boss_wave_count
		wave_system.current_state = WaveSystem.WaveState.COMPLETED
		wave_system.boss_defeated.emit()

func _find_crystal_position() -> void:
	"""查找水晶的位置"""
	var crystals = get_tree().get_nodes_in_group("crystal")
	if crystals.size() > 0:
		_crystal_position = crystals[0].global_position
	else:
		_crystal_position = Vector2.ZERO
		push_warning("未找到水晶，将使用默认位置 (0, 0)")

func _generate_spawn_position_for_size(size_level: int) -> Vector2:
	"""根据体型等级生成位置 - 大体型敌人生成更远"""
	var spawn_position: Vector2 = Vector2.ZERO
	var attempts: int = 0
	
	var size_ratio = float(size_level) / float(Constants.EnemyConstants.MAX_SIZE_LEVEL)
	
	var extra_distance = 0.0
	if size_level >= Constants.EnemyConstants.SIZE_LEVEL_11:
		extra_distance = (float(size_level - Constants.EnemyConstants.SIZE_LEVEL_10) / 10.0) * 0.5
	
	var min_dist = Constants.EnemyConstants.MIN_SPAWN_DISTANCE * (1.0 + size_ratio * 0.3)
	var max_dist = Constants.EnemyConstants.MAX_SPAWN_DISTANCE * (1.0 + extra_distance)
	
	max_dist = max(max_dist, min_dist * 1.5)
	
	while attempts < _max_spawn_attempts:
		var distance_bias = pow(randf(), Constants.EnemyConstants.SPAWN_DISTANCE_BIAS)
		var spawn_distance = lerp(min_dist, max_dist, distance_bias)
		
		var spawn_angle = randf() * 2.0 * PI
		
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
		cos(fallback_angle) * min_dist,
		sin(fallback_angle) * min_dist
	)
	return spawn_position

func _on_wave_preparing(wave_number: int) -> void:
	"""波次准备开始"""
	print("第 ", wave_number, " 波准备中...")
	# 播放准备音效
	if wave_number > 10:
		AudioManager.play_wave_start("boss")
	else:
		AudioManager.play_wave_start("normal")

func _on_wave_started(wave_number: int) -> void:
	"""波次开始生成敌人"""
	var wave_info = wave_system.get_current_wave_info()
	print("第 ", wave_number, " 波开始！将生成 ", wave_info.total_count, " 个敌人，体型等级：", wave_info.size)

func _on_wave_completed(wave_number: int) -> void:
	"""波次完成"""
	print("第 ", wave_number, " 波完成！")
	# Boss 波次完成后等待 Boss 被击败
	if wave_number >= 11:
		print("Boss 波次完成，等待 Boss 被击败...")
		return
	
	# 延迟进入下一波
	await get_tree().create_timer(2.0).timeout
	if wave_system and not wave_system.is_all_waves_completed():
		wave_system.advance_to_next_wave()

func _on_boss_defeated() -> void:
	"""Boss 被击败"""
	print("Boss 被击败！游戏胜利！")
	# 触发游戏胜利逻辑
	if GameManager.instance:
		GameManager.instance.end_game()

func _on_all_waves_completed() -> void:
	"""所有波次完成（胜利）"""
	print("所有波次完成！游戏胜利！")
	# 触发游戏胜利
	var game_manager = GameManager.instance
	if game_manager:
		game_manager.end_game()

func _on_boss_wave_started() -> void:
	"""Boss 波次开始"""
	print("Boss 波次开始！")
	# 播放 Boss 战音乐
	AudioManager.play_wave_start("boss")

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

func get_wave_system() -> WaveSystem:
	"""获取波次系统实例"""
	return wave_system

func get_current_wave() -> int:
	"""获取当前波次"""
	if wave_system:
		return wave_system.current_wave
	return 0

func is_game_started() -> bool:
	"""检查游戏是否已开始"""
	return game_started
