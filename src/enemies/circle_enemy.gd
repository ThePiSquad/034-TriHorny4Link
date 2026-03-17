class_name CircleEnemy extends Enemy

# Boss 特有属性
var is_boss: bool = false
var boss_health_multiplier: float = 10.0  # Boss 生命值倍数
var boss_damage_multiplier: float = 2.0   # Boss 伤害倍数
var boss_score_value: int = 1000          # Boss 击败分数

# 连接系统参数
@export var connection_radius: float = 200.0  # 连接检测半径
@export var connection_color: Color = Color(0.2, 0.8, 0.2, 0.7)  # 连接线颜色

# 连接系统内部变量
var _connection_lines: Line2D = null
var _connected_enemies: Array = []  # 已连接的敌人列表
var _connection_check_timer: float = 0.0
var _connection_check_interval: float = 0.5  # 连接检测间隔（秒）
var _connection_animations: Dictionary = {}  # 连接动画状态 {enemy: {alpha: float, target_alpha: float, timer: float}}

func _ready() -> void:
	super._ready()
	# 检查是否是 Boss（体型为 20 即 256x256）
	if size_level >= 20:
		_setup_as_boss()
	
	# 初始化连接系统
	_initialize_connection_system()

func _initialize_connection_system() -> void:
	"""初始化连接检测系统"""
	# 获取连接线节点
	_connection_lines = get_node_or_null("ConnectionLines")
	if _connection_lines:
		_connection_lines.default_color = connection_color

func _setup_as_boss() -> void:
	"""设置为 Boss 属性"""
	is_boss = true
	max_health *= boss_health_multiplier
	current_health = max_health
	attack_damage *= boss_damage_multiplier
	score_value = boss_score_value

func _initialize_shape() -> void:
	super._initialize_shape()
	if hitbox_shape:
		hitbox_shape.shape.radius = enemy_size.x / 2
	if hurtbox_shape:
		hurtbox_shape.shape.radius = enemy_size.x / 2
	
	# 更新 ShapeDrawer 的 shape_size
	if shape_drawer:
		shape_drawer.shape_size = enemy_size

func _setup_particle_texture(particle: GPUParticles2D) -> void:
	"""设置圆形敌人的死亡粒子纹理"""
	var texture = load("res://assets/particles/circle_particle.png")
	if texture:
		particle.texture = texture
	
	# Boss 使用特殊粒子效果
	if is_boss:
		particle.amount = 200  # 更多粒子
		particle.lifetime = 2.0

func _process(delta: float) -> void:
	"""每帧更新连接检测和动画"""
	super._process(delta)
	
	# 更新连接检测计时器
	_connection_check_timer += delta
	if _connection_check_timer >= _connection_check_interval:
		_connection_check_timer = 0.0
		_update_connections()
	
	# 更新连接动画
	_update_connection_animations(delta)
	
	# 更新连接线位置
	_update_connection_lines()

func _update_connections() -> void:
	"""更新连接状态"""
	var all_enemies = get_tree().get_nodes_in_group("enemy")
	var new_connections = []
	
	for enemy in all_enemies:
		# 检查敌人是否仍然有效（没有被释放）
		if not is_instance_valid(enemy) or not enemy.is_inside_tree():
			continue
		
		# 跳过自己和圆形敌人
		if enemy == self or enemy is CircleEnemy:
			continue
		
		# 检查距离
		var distance = global_position.distance_to(enemy.global_position)
		if distance <= connection_radius:
			# 添加到新连接列表
			if not enemy in _connected_enemies:
				# 新连接，启动淡入动画
				_connection_animations[enemy] = {
					"alpha": 0.0,
					"target_alpha": 1.0,
					"timer": 0.0
				}
			new_connections.append(enemy)
	
	# 检查断开的连接
	for enemy in _connected_enemies:
		# 检查敌人是否仍然有效
		if not is_instance_valid(enemy) or not enemy.is_inside_tree():
			continue
		
		if not enemy in new_connections:
			# 连接断开，启动淡出动画
			if enemy in _connection_animations:
				_connection_animations[enemy]["target_alpha"] = 0.0
				_connection_animations[enemy]["timer"] = 0.0
	
	# 更新连接列表
	_connected_enemies = new_connections

func _update_connection_animations(delta: float) -> void:
	"""更新连接动画"""
	var enemies_to_remove = []
	
	for enemy in _connection_animations:
		var anim = _connection_animations[enemy]
		anim["timer"] += delta
		
		# 0.2秒淡入淡出动画
		var progress = min(anim["timer"] / 0.2, 1.0)
		anim["alpha"] = lerp(anim["alpha"], anim["target_alpha"], progress)
		
		# 如果动画完成且目标alpha为0，移除
		if progress >= 1.0 and anim["target_alpha"] == 0.0:
			enemies_to_remove.append(enemy)
	
	# 移除完成的动画
	for enemy in enemies_to_remove:
		_connection_animations.erase(enemy)

func _update_connection_lines() -> void:
	"""更新连接线位置"""
	if not _connection_lines:
		return
	
	_connection_lines.clear_points()
	
	for enemy in _connected_enemies:
		# 检查敌人是否仍然有效（没有被释放）
		if not is_instance_valid(enemy) or not enemy.is_inside_tree():
			continue
		
		# 添加起点（圆形敌人中心）
		_connection_lines.add_point(Vector2.ZERO)
		# 添加终点（连接敌人位置，相对于圆形敌人）
		_connection_lines.add_point(to_local(enemy.global_position))

func _calculate_damage_reduction() -> float:
	"""计算伤害减免率"""
	var n = _connected_enemies.size()
	var reduction_rate: float = 0.0
	
	if n <= 5:
		# n ≤ 5 时，减免率 = 10% × n
		reduction_rate = 0.1 * n
	else:
		# n > 5 时，减免率 = 50% + 30% × (1 - e^(1-n/5))
		var exponent = 1.0 - (n / 5.0)
		reduction_rate = 0.5 + 0.3 * (1.0 - exp(exponent))
	
	# 确保减免率不超过80%
	reduction_rate = min(reduction_rate, 0.8)
	
	return reduction_rate

func take_damage(amount: float, source: Node = null) -> void:
	"""重写伤害接收函数，应用伤害减免"""
	var reduction_rate = _calculate_damage_reduction()
	var reduced_damage = amount * (1.0 - reduction_rate)
	
	# 输出调试信息
	print("DEBUG: 圆形敌人受到伤害 - 原始：", amount, "，减免率：", reduction_rate * 100, "%，最终：", reduced_damage)
	
	# 调用父类的伤害接收函数
	super.take_damage(reduced_damage, source)
	
