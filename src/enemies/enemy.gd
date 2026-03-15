class_name Enemy
extends Damageable

@onready var shape_drawer: ShapeDrawer = $ShapeDrawer
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

@export var move_speed: float = 100.0
@export var attack_damage: float = 10.0
@export var enemy_size: Vector2 = Vector2(Constants.grid_size, Constants.grid_size)
@export var size_level: int = Constants.EnemyConstants.SIZE_LEVEL_1

# 基础属性值（由场景设置，用于体型计算）
var _base_move_speed: float = 0.0
var _base_max_health: float = 0.0
var _base_attack_damage: float = 0.0
var _is_base_values_set: bool = false

# 随机旋转功能
@export var random_initial_rotation: bool = false
"""
是否在敌人初始生成时对绘制的图形应用随机旋转效果
- true: 启用随机旋转，范围为0-360度
- false: 保持原始旋转角度不变
"""

var direction: Vector2
var base_position: Vector2 = Vector2.ZERO
var shader = load("res://src/shaders/teleport_effect.gdshader")
# 传送效果相关
var _is_teleporting: bool = false  # 是否正在传送
var _teleport_duration: float = 1  # 传送动画持续时间（秒）
var _teleport_timer: float = 0.0  # 传送计时器
var _teleport_material: ShaderMaterial  # 传送效果材质

# 受击反馈相关
var _is_hit: bool = false  # 是否正在受击
var _hit_flash_duration: float = 0.2  # 闪烁持续时间（秒）
var _hit_flash_timer: float = 0.0  # 闪烁计时器
var _hit_flash_count: int = 0  # 闪烁次数
var _max_flash_count: int = 3  # 最大闪烁次数
var _original_color: Color = Color.WHITE  # 原始颜色
var _knockback_force: float = 200.0  # 击退力度
var _knockback_velocity: Vector2 = Vector2.ZERO  # 击退速度

# 死亡粒子特效相关
var death_particle_scene: PackedScene = preload("res://src/particles/broken_ptc.tscn")
var base_particle_amount: int = 24  # 基础粒子数量
var shape_influence_factor : int = 2

# 受击粒子特效相关
var hit_particle_scene: PackedScene = preload("res://src/particles/hit_ptc.tscn")

# 屏障相关
var _blocked_by_barrier: bool = false
var _barrier_hit_cooldown: float = 0.0
var _current_barrier: Node2D = null
var _attack_interval: float = 1.0  # 攻击间隔（秒）
var _attack_timer: float = 0.0

# 优先级管理
var _attack_priority: bool = false  # 是否处于攻击优先状态
var _priority_target: Node2D = null  # 优先级目标

func _initialize_shape() -> void:
	if shape_drawer:
		shape_drawer.shape_size = enemy_size

func set_base_position(dest_position: Vector2) -> void:
	base_position = dest_position
	# 更新导航代理的目标位置
	if navigation_agent:
		navigation_agent.target_position = base_position

func set_size_level(level: int) -> void:
	"""设置敌人体型等级并调整属性"""
	size_level = clamp(level, Constants.EnemyConstants.SIZE_LEVEL_1, Constants.EnemyConstants.MAX_SIZE_LEVEL)
	
	# 第一次调用时保存基础属性值（场景设置的值）
	if not _is_base_values_set:
		_base_move_speed = move_speed
		_base_max_health = max_health
		_base_attack_damage = attack_damage
		_is_base_values_set = true
	
	# 获取体型尺寸
	if Constants.EnemyConstants.SIZE_MAP.has(size_level):
		enemy_size = Constants.EnemyConstants.SIZE_MAP[size_level]
	
	# 获取属性调整系数
	if Constants.EnemyConstants.SIZE_ATTRIBUTE_MULTIPLIERS.has(size_level):
		var multipliers = Constants.EnemyConstants.SIZE_ATTRIBUTE_MULTIPLIERS[size_level]
		
		# 调整血量 - 基于场景设置的基础值
		var new_health = int(_base_max_health * multipliers.health)
		max_health = new_health
		current_health = new_health
		
		# 调整移动速度 - 基于场景设置的基础值
		move_speed = _base_move_speed * multipliers.speed
		
		# 调整攻击力 - 基于场景设置的基础值
		attack_damage = _base_attack_damage * multipliers.health  # 攻击力与血量同比例增长
	
	# 更新形状（只在shape_drawer可用时）
	if shape_drawer:
		_initialize_shape()
	
	# print("敌人体型设置为等级 ", size_level, "，尺寸: ", enemy_size, "，血量: ", max_health, "，速度: ", move_speed, "，攻击力: ", attack_damage)

func _ready() -> void:
	super._ready()
	
	# 应用体型设置
	if size_level != Constants.EnemyConstants.SIZE_LEVEL_1:
		set_size_level(size_level)
	else:
		_initialize_shape()
	
	# 添加到 enemy 组，让结构管理器能够找到
	add_to_group("enemy")
	
	# 应用随机旋转效果（如果启用）
	if random_initial_rotation and shape_drawer:
		var random_angle = randf_range(0.0, 360.0)
		shape_drawer.rotation_degrees = random_angle
	
	# 保存原始颜色
	if shape_drawer:
		_original_color = shape_drawer.fill_color
	
	died.connect(_on_damageable_died)
	
	# 初始化传送效果
	_initialize_teleport_effect()
	
	# 配置导航代理
	if navigation_agent:
		navigation_agent.target_position = base_position
		navigation_agent.path_desired_distance = 4.0
		navigation_agent.target_desired_distance = 4.0
		navigation_agent.max_speed = move_speed
		navigation_agent.path_max_distance = 100.0  # 最大路径距离
		navigation_agent.time_horizon = 0.5  # 时间视野
		navigation_agent.radius = 10.0  # 避障半径
		navigation_agent.neighbor_distance = 50.0  # 邻居距离

func _initialize_teleport_effect() -> void:
	"""初始化传送效果"""
	# 加载传送效果着色器
	if shader:
		_teleport_material = ShaderMaterial.new()
		_teleport_material.shader = shader
		
		# 设置初始参数
		_teleport_material.set_shader_parameter("progress", 1.0)
		_teleport_material.set_shader_parameter("shape_size", Vector2(enemy_size.x * 3, enemy_size.y * 3))
		_teleport_material.set_shader_parameter("beam_size", 0.15)
		_teleport_material.set_shader_parameter("color", Color.RED)
		# 应用材质到 shape_drawer
		if shape_drawer:
			shape_drawer.material = _teleport_material
		
		# 启动传送动画
		_start_teleport()

func _on_damageable_died(source: Node) -> void:
	# 生成死亡粒子特效
	_spawn_death_particle()
	
	# 添加敌人分数
	_add_enemy_score()
	
	# 断开屏障的死亡信号连接
	if _current_barrier and _current_barrier.has_signal("died"):
		if _current_barrier.died.is_connected(_on_barrier_destroyed):
			_current_barrier.died.disconnect(_on_barrier_destroyed)
	
	queue_free()

func _add_enemy_score() -> void:
	"""添加敌人分数到 GameManager"""
	# 根据体型获取分数
	var score = Constants.EnemyConstants.ENEMY_SCORE_MAP.get(size_level, 10)
	
	# 添加到 GameManager
	var game_manager = GameManager.instance
	if game_manager:
		game_manager.add_enemy_score(score)
	else:
		push_warning("GameManager 实例不存在，无法添加分数")

func _spawn_death_particle() -> void:
	"""生成死亡粒子特效"""
	if not death_particle_scene:
		return
	
	var particle : GPUParticles2D = death_particle_scene.instantiate()
	if not particle:
		return
	
	# 设置粒子位置为敌人位置
	particle.global_position = global_position
	
	# 根据敌人体型计算粒子数量
	var size_multiplier = (enemy_size.x / Constants.grid_size) * shape_influence_factor
	particle.amount = int(base_particle_amount * size_multiplier)
	particle.process_material.emission_sphere_radius = 16 * size_multiplier
	particle.process_material.scale_min = 0.05 * size_multiplier
	particle.process_material.scale_max = 0.35 * size_multiplier
	particle.process_material.initial_velocity_min = 70 * size_multiplier
	particle.process_material.initial_velocity_max = 170 * size_multiplier
	
	particle.one_shot = true
	particle.emitting = true
	
	# 设置粒子纹理（由子类实现）
	_setup_particle_texture(particle)
	
	# 添加到场景中
	get_parent().add_child(particle)

func _setup_particle_texture(particle: GPUParticles2D) -> void:
	"""设置粒子纹理（由子类重写）"""
	# 基类不设置纹理，由子类实现
	pass

func _process(delta: float) -> void:
	# 更新传送效果（始终更新，即使在传送期间）
	_update_teleport(delta)
	
	# 更新受击效果
	_update_hit_effect(delta)
	
	# 更新屏障冷却计时器
	if _barrier_hit_cooldown > 0:
		_barrier_hit_cooldown -= delta
	
	# 检查当前屏障是否仍然有效
	_check_barrier_validity()

func _physics_process(delta: float) -> void:
	# 如果正在传送，跳过其他逻辑
	if _is_teleporting:
		return
	
	# 攻击优先处理
	_handle_attack_priority()
	
	# 如果有当前屏障，持续攻击
	if _current_barrier:
		_attack_timer += delta
		if _attack_timer >= _attack_interval:
			_attack_timer = 0.0
			_attack_barrier(_current_barrier)
		return
	
	# 导航移动逻辑
	if navigation_agent:
		# 检查是否到达目标
		if navigation_agent.is_navigation_finished():
			# 重新设置目标
			navigation_agent.target_position = base_position
		
		# 获取下一个路径点并移动
		var next_path_position = navigation_agent.get_next_path_position()
		if next_path_position != Vector2.INF:
			var move_direction = (next_path_position - global_position).normalized()
			global_position += move_direction * move_speed * delta
		else:
			# 如果无法获取路径点，直接向目标移动
			var move_direction = (base_position - global_position).normalized()
			global_position += move_direction * move_speed * delta
	else:
		# 没有导航代理时直接移动
		var move_direction = (base_position - global_position).normalized()
		global_position += move_direction * move_speed * delta

func _update_hit_effect(delta: float) -> void:
	"""更新受击效果"""
	if not _is_hit:
		return
	
	# 更新闪烁计时器
	_hit_flash_timer += delta
	
	# 计算闪烁次数
	var flash_interval = _hit_flash_duration / _max_flash_count
	var current_flash = int(_hit_flash_timer / flash_interval)
	
	if current_flash >= _max_flash_count:
		# 闪烁完成，恢复原始颜色
		_finish_hit_effect()
		return
	
	# 切换颜色（奇数次显示白色，偶数次显示原始颜色）
	if shape_drawer:
		if current_flash % 2 == 0:
			shape_drawer.fill_color = Color.WHITE
		else:
			shape_drawer.fill_color = _original_color
	
	# 应用击退效果
	if _knockback_velocity != Vector2.ZERO:
		position += _knockback_velocity * delta
		# 衰减击退速度
		_knockback_velocity = _knockback_velocity.lerp(Vector2.ZERO, delta * 5.0)

func _on_hit(source: Node) -> void:
	"""受到任何伤害时的统一处理"""
	if _is_teleporting:
		return
	
	_is_hit = true
	_hit_flash_timer = 0.0
	_hit_flash_count = 0
	
	# 立即开始闪烁
	shape_drawer.fill_color = Color.WHITE
	AudioManager.play_enemy_hit()
	# 如果是动能子弹，添加击退效果
	if source is Bullet:
		var bullet = source as Bullet
		if _is_kinetic_bullet(bullet):
			_apply_knockback(bullet)
		
		# 生成受击粒子特效
		_spawn_hit_particle(bullet)

func _spawn_hit_particle(bullet: Bullet) -> void:
	"""生成受击粒子特效"""
	if not hit_particle_scene:
		return
	
	# 实例化粒子特效
	var hit_particle = hit_particle_scene.instantiate()
	if hit_particle:
		# 设置粒子位置为敌人位置
		hit_particle.global_position = global_position
		
		# 获取子弹颜色并设置粒子颜色
		if bullet.has_method("get_bullet_type"):
			var bullet_color_type = bullet.get_bullet_type()
			var bullet_color = Constants.COLOR_MAP.get(bullet_color_type, Color.WHITE)
			
			# 设置粒子系统的颜色
			_set_particle_color(hit_particle, bullet_color)
		
		# 添加到场景中
		get_tree().current_scene.add_child(hit_particle)

func _set_particle_color(particle: Node, color: Color) -> void:
	"""设置粒子系统的颜色"""
	if particle is GPUParticles2D:
		var material = particle.process_material
		if material is ParticleProcessMaterial:
			# 创建材质的副本以避免影响其他实例
			var new_material = material.duplicate()
			new_material.color = color
			# 应用新材质
			particle.process_material = new_material

func _is_kinetic_bullet(bullet: Bullet) -> bool:
	"""检查是否是动能子弹"""
	for attr in bullet.attributes:
		if attr == Enums.BulletAttributes.KINETIC:
			return true
	return false

func _apply_knockback(bullet: Bullet) -> void:
	"""应用击退效果"""
	# 计算击退方向（子弹飞行方向）
	var knockback_direction = bullet.get_velocity().normalized()
	
	# 根据体型计算击退力度（体型越大越难击退）
	var size_multiplier = 1.0
	if Constants.EnemyConstants.SIZE_ATTRIBUTE_MULTIPLIERS.has(size_level):
		var multipliers = Constants.EnemyConstants.SIZE_ATTRIBUTE_MULTIPLIERS[size_level]
		size_multiplier = 1.0 / multipliers.health  # 血量越高越难击退
	
	var final_knockback = _knockback_force * size_multiplier
	_knockback_velocity = knockback_direction * final_knockback

func _finish_hit_effect() -> void:
	"""完成受击效果"""
	_is_hit = false
	_knockback_velocity = Vector2.ZERO
	
	# 恢复原始颜色
	if shape_drawer:
		shape_drawer.fill_color = _original_color

func _update_teleport(delta: float) -> void:
	"""更新传送效果"""
	if not _is_teleporting:
		return
	
	# 更新传送计时器
	_teleport_timer += delta
	
	# 计算 progress 值（从 1.0 平滑过渡到 0.0）
	var progress = 1.0 - (_teleport_timer / _teleport_duration)
	progress = clamp(progress, 0.0, 1.0)
	
	# 更新着色器参数
	if _teleport_material:
		_teleport_material.set_shader_parameter("progress", progress)
	
	# 检查传送是否完成
	if progress <= 0.0:
		_finish_teleport()

func _start_teleport() -> void:
	"""启动传送效果"""
	_is_teleporting = true
	_teleport_timer = 0.0
	
	# 设置无敌状态
	invincible = true

func _finish_teleport() -> void:
	"""完成传送效果"""
	_is_teleporting = false
	
	# 恢复可受击状态
	invincible = false
	
	# 触发后续逻辑
	_on_teleport_complete()

func _on_teleport_complete() -> void:
	"""传送完成后的处理"""
	# 可以在子类中重写此方法
	pass

func can_be_targeted() -> bool:
	"""检查是否可以被索敌"""
	# 传送期间不能被索敌
	if _is_teleporting:
		return false
	return true

func _check_barrier_validity() -> void:
	"""检查屏障是否仍然有效"""
	if _current_barrier:
		# 检查屏障是否在场景树中
		if not _current_barrier.is_inside_tree():
			# 屏障已被删除，恢复移动
			_current_barrier = null
			_blocked_by_barrier = false
			# 攻击完成后恢复正常状态
			_attack_priority = false
			_priority_target = null
			return
		
		# 检查屏障是否有生命值且生命值大于0
		if _current_barrier.has_method("get_health"):
			if _current_barrier.get_health() <= 0:
				# 屏障已被摧毁，恢复移动
				_current_barrier = null
				_blocked_by_barrier = false
				# 攻击完成后恢复正常状态
				_attack_priority = false
				_priority_target = null

func on_barrier_hit(barrier: Node2D) -> void:
	"""被屏障阻挡时的回调"""
	if _barrier_hit_cooldown > 0:
		return
	
	#print("敌人被屏障阻挡")
	_blocked_by_barrier = true
	_current_barrier = barrier
	_barrier_hit_cooldown = 0.5  # 冷却时间0.5秒
	_attack_timer = 0.0  # 重置攻击计时器
	
	# 连接屏障的死亡信号
	if barrier.has_signal("died") and not barrier.died.is_connected(_on_barrier_destroyed):
		barrier.died.connect(_on_barrier_destroyed)
	
	# 立即进行第一次攻击
	_attack_barrier(barrier)

func _on_barrier_destroyed(source: Node) -> void:
	"""屏障被摧毁时的回调"""
	_current_barrier = null
	_blocked_by_barrier = false
	_attack_priority = false
	_priority_target = null

func _attack_barrier(barrier: Node2D) -> void:
	"""攻击屏障"""
	if barrier and barrier.has_method("take_damage"):
		barrier.take_damage(attack_damage, self)
		#print("敌人攻击屏障，造成伤害: ", attack_damage)

func _handle_attack_priority() -> void:
	"""处理攻击优先级"""
	# 如果正在攻击屏障，设置攻击优先级
	if _current_barrier and not _attack_priority:
		_attack_priority = true
		_priority_target = _current_barrier
	# 如果屏障已经消失，解除攻击优先级
	if _attack_priority and not _current_barrier:
		_attack_priority = false
		_priority_target = null

func _on_hitbox_area_area_entered(area: Area2D) -> void:
	# 获取Area2D的父节点（实际的Structure对象）
	var body = area.get_parent()
	if body and body.has_method("get_structure_type"):
		if body.get_structure_type() == Enums.StructureType.CRYSTAL:
			body.take_damage(attack_damage, self)
			take_damage(max_health, self) # 自毁
