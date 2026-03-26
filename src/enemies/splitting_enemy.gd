class_name SplittingEnemy extends RectEnemy

@export var split_count: int = 2  # 分裂数量
@export var split_offset_distance: float = 50.0  # 分裂时子敌人的偏移距离

# 弹出效果配置
@export_group("Pop Effect")
@export var pop_initial_speed_min: float = 300.0  # 最小初始弹出速度（像素/秒）
@export var pop_initial_speed_max: float = 600.0  # 最大初始弹出速度（像素/秒）
@export var pop_duration: float = 0.3  # 弹出效果持续时间（秒）
@export var pop_fade_ratio: float = 0.5  # 弹出效果淡出比例（后半段减速）

# 弹出效果状态
var _pop_velocity: Vector2 = Vector2.ZERO
var _pop_timer: float = 0.0
var _is_popping: bool = false

func _ready() -> void:
	super._ready()
	# 连接死亡信号以在死亡时触发分裂
	died.connect(_on_splitting_enemy_died)

func _process(delta: float) -> void:
	# 更新弹出效果
	_process_pop_effect(delta)
	
	# 调用父类的_process（如果需要）
	super._process(delta)

func _on_splitting_enemy_died(source: Node) -> void:
	# 检查是否需要分裂（size_level > 1）
	# 使用 call_deferred 避免物理引擎冲突
	if size_level > Constants.EnemyConstants.SIZE_LEVEL_1 and source != self:
		_perform_split.call_deferred()
	
	# 调用父类死亡处理
	super._on_damageable_died(source)

func _physics_process(delta: float) -> void:
	# 如果正在弹出效果中，暂停正常导航移动
	if _is_popping:
		return
	
	# 否则使用父类的正常移动逻辑
	super._physics_process(delta)

func _perform_split() -> void:
	# 计算分裂后的体型等级（向下取整）
	var new_size_level: int = size_level >> 1
	if new_size_level < Constants.EnemyConstants.SIZE_LEVEL_1:
		new_size_level = Constants.EnemyConstants.SIZE_LEVEL_1
	
	# 分裂生成子敌人
	for i in range(split_count):
		_spawn_split_enemy(new_size_level, i)

func _spawn_split_enemy(new_size_level: int, index: int) -> void:
	# 创建新的敌人实例
	var new_enemy : SplittingEnemy = duplicate()
	
	# 重置基础值标记，确保 set_size_level 使用正确的初始值
	# 这是关键修复：复制节点的 _is_base_values_set 状态是错的
	new_enemy._is_base_values_set = false
	
	# 跳过传送动画和无敌状态，分裂后立即可交互
	new_enemy._skip_teleport_on_ready = true
	
	# 计算偏移位置（避免重叠）
	var angle = (TAU / split_count) * index + randf() * 0.5
	var offset = Vector2(cos(angle), sin(angle)) * split_offset_distance
	new_enemy.global_position = global_position + offset
	
	# ⭐ 初始化弹出效果
	new_enemy._initialize_pop_effect(angle)
	
	# 设置新的体型等级
	new_enemy.size_level = new_size_level
	new_enemy.set_size_level(new_size_level)
	
	# 添加到场景
	get_parent().add_child(new_enemy)
	
	# 设置目标位置（如果敌人有导航）
	new_enemy.set_base_position(base_position)

func _initialize_pop_effect(base_angle: float) -> void:
	"""初始化弹出效果"""
	# 随机方向：在基础角度上添加随机偏移
	var random_angle_offset = randf_range(-0.5, 0.5)  # ±约28度随机偏移
	var pop_angle = base_angle + random_angle_offset
	
	# 随机速度
	var pop_speed = randf_range(pop_initial_speed_min, pop_initial_speed_max)
	
	# 设置弹出速度
	_pop_velocity = Vector2(cos(pop_angle), sin(pop_angle)) * pop_speed
	_pop_timer = 0.0
	_is_popping = true

func _process_pop_effect(delta: float) -> void:
	"""更新弹出效果"""
	if not _is_popping:
		return
	
	_pop_timer += delta
	
	# 检查是否结束
	if _pop_timer >= pop_duration:
		_is_popping = false
		_pop_velocity = Vector2.ZERO
		return
	
	# 计算衰减因子（使用缓动函数：ease-out）
	var t = _pop_timer / pop_duration
	var decay_factor = 1.0 - t
	decay_factor = decay_factor * decay_factor  # 二次缓动
	
	# 应用衰减后的速度
	var current_velocity = _pop_velocity * decay_factor
	global_position += current_velocity * delta
	
