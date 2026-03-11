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
	# 更新刷新计时器
	_spawn_timer += delta
	
	# 检查是否达到刷新间隔
	if _spawn_timer >= spawn_interval:
		_spawn_timer = 0.0
		if is_start_spwn:
			_try_spawn_enemy()

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
		add_child(enemy)
		print("生成敌人: ", enemy.name, " 位置: ", spawn_position)
	else:
		push_error("EnemyManager: 敌人实例化失败")

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
	"""生成随机位置，确保在地图范围内且距离水晶足够远"""
	var spawn_position: Vector2 = Vector2.ZERO
	var attempts: int = 0
	
	while attempts < _max_spawn_attempts:
		# 生成随机位置
		spawn_position = Vector2(
			randf_range(Constants.CameraConstants.MIN_X, Constants.CameraConstants.MAX_X),
			randf_range(Constants.CameraConstants.MIN_Y, Constants.CameraConstants.MAX_Y)
		)
		
		# 检查距离水晶是否足够远
		var distance_to_crystal = spawn_position.distance_to(_crystal_position)
		if distance_to_crystal >= min_spawn_distance:
			return spawn_position
		
		attempts += 1
	
	# 如果多次尝试都失败，返回零向量表示失败
	push_warning("EnemyManager: 位置生成失败，尝试次数: ", attempts)
	return Vector2.ZERO

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
