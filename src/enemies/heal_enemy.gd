class_name HealEnemy extends Enemy

@onready var heal_timer: Timer = $HealTimer

'''
治疗型敌人
会倾向于躲在其他的敌人后面
能力：
间歇的对范围内的敌人进行治疗
范围内治疗单位上限默认5
'''

# 治疗能力配置
@export_group("Healing")
@export var heal_interval: float = 5.0  # 治疗间隔（秒）
@export var heal_radius: float = 6 * Constants.grid_size  # 治疗范围半径
@export var heal_amount: float = 30.0  # 每次治疗量
@export var max_heal_targets: int = 3  # 最大治疗目标数
# 粒子效果
@export var heal_particle_scene: PackedScene

var is_healing : bool = false
var _heal_targets: Array[Node2D] = []

# 连接系统参数
@export_group("Connection")
@export var connection_color: Color = Color(0.2, 0.9, 0.4, 0.7)  # 绿色治疗线颜色
@export var connection_line_width: float = 3.0  # 线条宽度

# 连接系统内部变量
var _connection_lines: Line2D = null
var _connected_targets: Array[Node2D] = []
var _connection_check_timer: float = 0.0
var _connection_check_interval: float = 0.3  # 连接检测间隔
var _connection_animations: Dictionary = {}  # 连接动画状态

# 性能优化：位置缓存
var _last_checked_position: Vector2 = Vector2.INF
var _position_change_threshold: float = 5.0

# 性能优化：连线渲染缓存
var _last_line_update_time: float = 0.0
var _line_update_interval: float = 1.0 / 30.0  # 约30fps更新频率

func _setup_particle_texture(particle: GPUParticles2D) -> void:
	"""设置死亡粒子纹理"""
	var texture = load("res://assets/particles/circle_particle.png")
	if texture:
		particle.texture = texture

func _ready() -> void:
	super._ready()
	heal_timer.wait_time = heal_interval
	_initialize_connection_system()
	if has_signal("died"):
		died.connect(_on_heal_enemy_died)

func _initialize_connection_system() -> void:
	_connection_lines = Line2D.new()
	_connection_lines.default_color = connection_color
	_connection_lines.width = connection_line_width
	_connection_lines.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_connection_lines.end_cap_mode = Line2D.LINE_CAP_ROUND
	_connection_lines.z_index = -1
	add_child(_connection_lines)

func _on_heal_enemy_died(source: Node) -> void:
	_cleanup_connections()

func _cleanup_connections() -> void:
	_connected_targets.clear()
	_connection_animations.clear()
	if _connection_lines:
		_connection_lines.clear_points()

func _on_heal_timer_timeout() -> void:
	_perform_healing()

func _find_heal_targets() -> Array[Node2D]:
	"""寻找治疗范围内的友方单位"""
	var targets: Array[Node2D] = []
	var enemies = get_tree().get_nodes_in_group("enemy")
	
	for enemy in enemies:
		if enemy != self and is_instance_valid(enemy) and enemy is Enemy:
			var distance = global_position.distance_to(enemy.global_position)
			if distance <= heal_radius:
				# 只治疗血量不满的友军
				if enemy.has_method("get_health_percentage"):
					var health_pct = enemy.get_health_percentage()
					if health_pct < 1.0:
						targets.append(enemy)
	
	# 按血量排序，优先治疗血量低的
	targets.sort_custom(func(a, b): 
		if a.has_method("get_health_percentage") and b.has_method("get_health_percentage"):
			return a.get_health_percentage() < b.get_health_percentage()
		return false
	)
	
	# 限制最大治疗目标数
	if targets.size() > max_heal_targets:
		targets.resize(max_heal_targets)
	
	return targets

func _perform_healing() -> void:
	"""执行治疗"""
	_heal_targets = _find_heal_targets()
	
	if _heal_targets.size() == 0:
		return
	
	is_healing = true
	
	# 播放治疗粒子效果
	_spawn_heal_particle()
	
	# 治疗所有目标
	for target in _heal_targets:
		if is_instance_valid(target):
			target.heal(heal_amount * size_level, self)
	
	# 治疗完成后重置状态
	await get_tree().create_timer(0.5).timeout
	is_healing = false

func _spawn_heal_particle() -> void:
	"""生成治疗粒子效果"""
	if not heal_particle_scene:
		return
	
	var particle: GPUParticles2D = heal_particle_scene.instantiate()
	if not particle:
		return
	
	# 设置粒子位置为治疗敌人位置
	particle.global_position = global_position
	particle.one_shot = true
	particle.emitting = true
	
	# 设置治疗范围
	if particle.process_material:
		particle.process_material.emission_sphere_radius = heal_radius
	
	# 添加到场景中
	get_tree().current_scene.add_child(particle)

func _process(delta: float) -> void:
	super._process(delta)
	_update_connection_system(delta)

func _update_connection_system(delta: float) -> void:
	if not _connection_lines:
		return
	
	_connection_check_timer += delta
	if _connection_check_timer >= _connection_check_interval:
		_connection_check_timer = 0.0
		_update_connections()
	
	_update_connection_animations(delta)
	_update_connection_lines()

func _update_connections() -> void:
	if global_position.distance_to(_last_checked_position) < _position_change_threshold:
		return
	_last_checked_position = global_position
	
	var current_targets = _find_heal_targets()
	var new_connections: Array[Node2D] = []
	
	for target in current_targets:
		if not is_instance_valid(target):
			continue
		if not target in _connected_targets:
			_connection_animations[target] = {
				"alpha": 0.0,
				"target_alpha": 1.0,
				"timer": 0.0
			}
		new_connections.append(target)
	
	for target in _connected_targets:
		if not is_instance_valid(target):
			continue
		if not target in new_connections:
			if target in _connection_animations:
				_connection_animations[target]["target_alpha"] = 0.0
				_connection_animations[target]["timer"] = 0.0
	
	_connected_targets = new_connections

func _update_connection_animations(delta: float) -> void:
	var targets_to_remove: Array[Node] = []
	
	for target in _connection_animations:
		var anim = _connection_animations[target]
		anim["timer"] += delta
		
		var progress = min(anim["timer"] / 0.2, 1.0)
		anim["alpha"] = lerp(anim["alpha"], anim["target_alpha"], progress)
		
		if progress >= 1.0 and anim["target_alpha"] == 0.0:
			targets_to_remove.append(target)
	
	for target in targets_to_remove:
		_connection_animations.erase(target)

func _update_connection_lines() -> void:
	if not _connection_lines:
		return
	
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - _last_line_update_time < _line_update_interval:
		return
	_last_line_update_time = current_time
	
	_connection_lines.clear_points()
	
	for target in _connected_targets:
		if not is_instance_valid(target):
			continue
		
		var alpha = 1.0
		if target in _connection_animations:
			alpha = _connection_animations[target]["alpha"]
		
		var color = connection_color
		color.a = alpha
		_connection_lines.default_color = color
		_connection_lines.add_point(Vector2.ZERO)
		_connection_lines.add_point(to_local(target.global_position))
