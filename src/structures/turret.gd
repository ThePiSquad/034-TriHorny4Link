extends EnergyTransmitter
class_name Turret

var bullet_scene: PackedScene = preload("res://src/bullets/bullet.tscn")
var homing_bullet_scene: PackedScene = preload("res://src/bullets/homing_bullet.tscn")
var magic_bullet_scene: PackedScene = preload("res://src/bullets/magic_bullet.tscn")
var lightning_bullet_scene: PackedScene = preload("res://src/bullets/lightning_bullet.tscn")
var explosive_bullet_scene: PackedScene = preload("res://src/bullets/explosive_bullet.tscn")
var splitting_homing_bullet_scene: PackedScene = preload("res://src/bullets/splitting_homing_bullet.tscn")
var penetrating_bullet_scene: PackedScene = preload("res://src/bullets/penetrating_bullet.tscn")

var fire_rate: float = 1.0
var fire_timer: float = 0.0
var bullet_damage: float = 20.0
var bullet_speed: float = 300.0
var bullet_lifetime: float = 1.5
var detection_range: float = 200.0
var rotation_speed: float = 5.0

# 霰弹枪配置
var shotgun_enabled: bool = false
var shotgun_count: int = 1
var shotgun_angle_spread: float = 15.0

# 追踪子弹配置
var homing_enabled: bool = false
var homing_detection_range: float = 150.0
var homing_turn_speed: float = 5.0

# 魔法子弹配置
var magic_enabled: bool = false
var magic_beam_width: float = 8.0
var magic_beam_duration: float = 0.2

# 闪电子弹配置
var lightning_enabled: bool = false
var lightning_chain_range: float = 384.0
var lightning_max_chain: int = 3

# 爆炸子弹配置
var explosive_enabled: bool = false
var explosion_radius: float = 200.0
var explosion_particle_duration: float = 1.0

# 追踪分裂子弹配置
var splitting_homing_enabled: bool = false
var splitting_homing_detection_range: float = 150.0
var splitting_homing_turn_speed: float = 5.0
var splitting_count: int = 5
var splitting_angle_spread: float = 45.0
var splitting_bullet_damage: float = 15.0
var splitting_bullet_lifetime: float = 0.8

# 穿透子弹配置
var penetrating_enabled: bool = false
var penetrating_homing_enabled: bool = false
var penetrating_homing_detection_range: float = 150.0
var penetrating_homing_turn_speed: float = 5.0
var penetrating_max_targets: int = 4
var penetrating_damage_decay: float = 0.85

var target: Node2D = null
var enemies_in_range: Array[Node2D] = []
var can_fire: bool = true

# 失活状态
var is_active: bool = false

# 射击亮度提升效果
var _is_firing_flash: bool = false
var _firing_flash_duration: float = 0.15  # 亮度提升持续时间（秒）
var _firing_flash_tween: Tween = null
var _original_fill_color: Color = Color.WHITE
var _original_stroke_color: Color = Color.WHITE

@onready var detection_area: Area2D = $DetectionArea
@onready var detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D

var _enemy_cleanup_timer: float = 0.0
var _enemy_cleanup_interval: float = 1.0  # 每秒清理一次无效敌人

func _ready() -> void:
	super._ready()
	structure_type = Enums.StructureType.TURRET
	detection_shape.shape.radius = detection_range
	_update_turret_attributes()
	
	# 连接颜色变化信号
	color_changed.connect(_on_color_changed)
	
	# 初始颜色同步
	_sync_visual_to_current_color()

func _on_color_changed(new_color: Enums.ColorType) -> void:
	"""当颜色改变时同步视觉效果"""
	_sync_visual_to_current_color()

func _sync_visual_to_current_color() -> void:
	"""同步视觉效果到当前颜色"""
	if not shape_drawer:
		return
	
	# 停止任何正在运行的 Tween 动画，避免覆盖新颜色
	if _firing_flash_tween and _firing_flash_tween.is_valid():
		_firing_flash_tween.kill()
	
	# 根据当前状态更新颜色
	if is_active:
		var base_color = Constants.COLOR_MAP.get(color, Color.WHITE)
		shape_drawer.fill_color = base_color
		shape_drawer.stroke_color = base_color.lightened(0.3)
		_original_fill_color = base_color  # 更新原始颜色用于射击闪光
	else:
		# 失活状态保持当前颜色
		_original_fill_color = shape_drawer.fill_color
	
	shape_drawer.queue_redraw()

func _init() -> void:
	structure_type = Enums.StructureType.TURRET

func _process(delta: float) -> void:
	_update_fire_timer(delta)
	_check_activation_status()
	
	# 定期清理无效敌人
	_enemy_cleanup_timer += delta
	if _enemy_cleanup_timer >= _enemy_cleanup_interval:
		_cleanup_invalid_enemies()
		_enemy_cleanup_timer = 0.0
	
	if not is_active:
		return
	
	_update_target()
	_rotate_towards_target(delta)
	
	if target and can_fire:
		shot()

func _cleanup_invalid_enemies() -> void:
	"""清理无效的敌人引用"""
	var cleaned_enemies = []
	for enemy in enemies_in_range:
		if is_instance_valid(enemy) and enemy.has_method("can_be_targeted") and enemy.can_be_targeted():
			cleaned_enemies.append(enemy)
	
	# 只在有变化时更新数组
	if cleaned_enemies.size() != enemies_in_range.size():
		enemies_in_range = cleaned_enemies
		# 如果目标失效，清除目标
		if not is_instance_valid(target) or (target and not target.can_be_targeted()):
			target = null

func _check_activation_status() -> void:
	"""检查炮台是否处于激活状态"""
	var was_active = is_active
	
	if energy_level == null or energy_level.is_empty():
		is_active = false
	elif color == Enums.ColorType.WHITE or color == Enums.ColorType.BLACK:
		is_active = false
	else:
		is_active = true
	
	if was_active != is_active:
		_update_activation_visual()

func _update_activation_visual() -> void:
	"""更新激活/失活状态的视觉效果"""
	if not shape_drawer:
		return
	
	# 停止任何正在运行的 Tween 动画，避免覆盖新颜色
	if _firing_flash_tween and _firing_flash_tween.is_valid():
		_firing_flash_tween.kill()
	
	# 根据激活状态更新颜色
	if is_active:
		# 激活状态：使用当前颜色的正常显示
		var base_color = Constants.COLOR_MAP.get(color, Color.WHITE)
		shape_drawer.fill_color = base_color
		shape_drawer.stroke_color = base_color.lightened(0.3)
		_original_fill_color = base_color  # 更新原始颜色用于射击闪光
	else:
		# 失活状态：保持当前颜色（不改变）
		_original_fill_color = shape_drawer.fill_color
	
	shape_drawer.queue_redraw()

func _update_fire_timer(delta: float) -> void:
	if fire_timer > 0:
		fire_timer -= delta
		if fire_timer <= 0:
			can_fire = true

func _update_target() -> void:
	if enemies_in_range.is_empty():
		target = null
		return
	
	# 如果当前目标仍然有效且可以锁定，继续锁定
	if is_instance_valid(target) and target.can_be_targeted():
		return
	
	# 选择最近的敌人
	enemies_in_range.sort_custom(_compare_distance)
	target = enemies_in_range[0]

func _compare_distance(a: Node2D, b: Node2D) -> bool:
	var dist_a = global_position.distance_to(a.global_position)
	var dist_b = global_position.distance_to(b.global_position)
	return dist_a < dist_b

func _rotate_towards_target(delta: float) -> void:
	if not target:
		return
	
	var target_angle = _get_angle_to_target(target.global_position)
	var current_angle = rotation
	var angle_diff = target_angle - current_angle
	
	while angle_diff > PI:
		angle_diff -= 2 * PI
	while angle_diff < -PI:
		angle_diff += 2 * PI
	
	var max_rotation = rotation_speed * delta
	angle_diff = clamp(angle_diff, -max_rotation, max_rotation)
	
	rotation += angle_diff

func _get_angle_to_target(target_position: Vector2) -> float:
	var angle = atan2(target_position.y - global_position.y, target_position.x - global_position.x)
	return angle + PI / 2

func shot() -> void:
	var base_angle = _get_angle_to_target(target.global_position) - PI / 2
	
	if magic_enabled and target:
		_fire_magic_bullet()
	elif lightning_enabled and target:
		_fire_lightning_bullet()
	elif explosive_enabled:
		_fire_explosive_bullet(base_angle)
	elif splitting_homing_enabled and target:
		_fire_splitting_homing_bullet()
	elif penetrating_enabled:
		_fire_penetrating_bullet(base_angle)
	elif shotgun_enabled and shotgun_count > 1:
		_fire_shotgun(base_angle)
	else:
		_fire_single_bullet(base_angle)
	
	# 触发亮度提升效果
	_start_firing_flash()
	
	can_fire = false
	fire_timer = 1.0 / fire_rate

func _start_firing_flash() -> void:
	"""启动射击亮度提升效果"""
	if not shape_drawer:
		return
	
	# 停止之前的补间动画
	if _firing_flash_tween and _firing_flash_tween.is_valid():
		_firing_flash_tween.kill()
	
	# 获取当前实际颜色（确保是最新的）
	var current_fill_color = shape_drawer.fill_color
	_original_fill_color = current_fill_color
	
	# 计算目标颜色（提亮 50%）
	var target_fill_color = _original_fill_color.lightened(0.5)
	
	# 创建补间动画
	_firing_flash_tween = create_tween()
	_firing_flash_tween.set_trans(Tween.TRANS_SINE)
	_firing_flash_tween.set_ease(Tween.EASE_IN_OUT)
	_firing_flash_tween.set_loops(1)
	
	# 补间动画：从原始颜色到提亮颜色，然后回到原始颜色
	_firing_flash_tween.tween_property(shape_drawer, "fill_color", target_fill_color, _firing_flash_duration / 2.0)
	_firing_flash_tween.tween_property(shape_drawer, "fill_color", _original_fill_color, _firing_flash_duration / 2.0)

func _fire_single_bullet(angle: float) -> void:
	var bullet: Node2D
	
	if homing_enabled and homing_bullet_scene:
		bullet = homing_bullet_scene.instantiate()
		AudioManager.play_turret_shoot("green")
	else:
		bullet = bullet_scene.instantiate()
		AudioManager.play_turret_shoot("blue")
	
	if not bullet:
		return
	
	var direction = Vector2(cos(angle), sin(angle))
	var bullet_velocity = direction * bullet_speed
	
	bullet.global_position = global_position + direction * 32
	
	if bullet is HomingBullet:
		bullet.init(bullet_velocity, int(bullet_damage), bullet_lifetime, color)
		bullet.set_homing_config(true, homing_detection_range, homing_turn_speed)
	elif bullet is Bullet:
		bullet.init(bullet_velocity, int(bullet_damage), bullet_lifetime, color)
	
	get_parent().add_child(bullet)

func _fire_shotgun(base_angle: float) -> void:
	AudioManager.play_turret_shoot("red")
	var angle_spread_rad = deg_to_rad(shotgun_angle_spread)
	var start_angle = base_angle - angle_spread_rad * (shotgun_count - 1) / 2.0
	
	for i in range(shotgun_count):
		var angle = start_angle + angle_spread_rad * i
		_fire_single_bullet(angle)

func _fire_magic_bullet() -> void:
	AudioManager.play_turret_shoot("yellow")
	if not target or not magic_bullet_scene:
		return
	
	var bullet = magic_bullet_scene.instantiate()
	if not bullet or not bullet is MagicBullet:
		return
	
	var angle = _get_angle_to_target(target.global_position) - PI / 2
	var direction = Vector2(cos(angle), sin(angle))
	var start_pos = global_position + direction * 32
	var target_pos = target.global_position
	
	bullet.set_target(target, start_pos, target_pos)
	bullet.init(Vector2.ZERO, int(bullet_damage), magic_beam_duration, color)
	
	bullet.global_position = Vector2.ZERO
	get_parent().add_child(bullet)

func _fire_lightning_bullet() -> void:
	AudioManager.play_turret_shoot("orange")
	if not target or not lightning_bullet_scene:
		return
	
	var bullet = lightning_bullet_scene.instantiate()
	if not bullet or not bullet is LightningBullet:
		return
	
	var angle = _get_angle_to_target(target.global_position) - PI / 2
	var direction = Vector2(cos(angle), sin(angle))
	var start_pos = global_position + direction * 32
	var target_pos = target.global_position
	
	bullet.set_target(target, start_pos, target_pos)
	bullet.init(Vector2.ZERO, int(bullet_damage), 0.5, color)
	
	bullet.global_position = Vector2.ZERO
	get_parent().add_child(bullet)

func _fire_explosive_bullet(angle: float) -> void:
	AudioManager.play_turret_shoot("purple")
	if not explosive_bullet_scene:
		return
	
	var bullet = explosive_bullet_scene.instantiate()
	if not bullet or not bullet is ExplosiveBullet:
		return
	
	var direction = Vector2(cos(angle), sin(angle))
	var bullet_velocity = direction * bullet_speed
	
	bullet.global_position = global_position + direction * 32
	bullet.init(bullet_velocity, int(bullet_damage), bullet_lifetime, color)
	get_parent().add_child(bullet)

func _fire_splitting_homing_bullet() -> void:
	AudioManager.play_turret_shoot("green")
	if not target or not splitting_homing_bullet_scene:
		return
	
	var bullet = splitting_homing_bullet_scene.instantiate()
	if not bullet or not bullet is SplittingHomingBullet:
		return
	
	var angle = _get_angle_to_target(target.global_position) - PI / 2
	var direction = Vector2(cos(angle), sin(angle))
	var start_pos = global_position + direction * 32
	
	bullet.global_position = start_pos
	bullet.init(direction * bullet_speed, int(bullet_damage), bullet_lifetime, color)
	bullet.set_homing_config(true, splitting_homing_detection_range, splitting_homing_turn_speed)
	bullet.set_splitting_config(splitting_count, splitting_angle_spread, splitting_bullet_damage, splitting_bullet_lifetime)
	
	var splitting_bullet_homing_detection_range = Constants.TURRET_CONFIG.get(color, {}).get("splitting_bullet_homing_detection_range", 5 * Constants.grid_size)
	var splitting_bullet_homing_turn_speed = Constants.TURRET_CONFIG.get(color, {}).get("splitting_bullet_homing_turn_speed", 10.0)
	var splitting_bullet_attack_delay = Constants.TURRET_CONFIG.get(color, {}).get("splitting_bullet_attack_delay", 0.15)
	bullet.set_splitting_bullet_homing_config(splitting_bullet_homing_detection_range, splitting_bullet_homing_turn_speed, splitting_bullet_attack_delay)
	
	get_parent().add_child(bullet)

func _fire_penetrating_bullet(angle: float) -> void:
	AudioManager.play_turret_shoot("green")
	if not penetrating_bullet_scene:
		return
	
	var bullet = penetrating_bullet_scene.instantiate()
	if not bullet or not bullet is PenetratingBullet:
		return
	
	var direction = Vector2(cos(angle), sin(angle))
	var bullet_velocity = direction * bullet_speed
	
	bullet.global_position = global_position + direction * 32
	bullet.init(bullet_velocity, int(bullet_damage), bullet_lifetime, color)
	
	if penetrating_homing_enabled:
		bullet.set_homing_config(true, penetrating_homing_detection_range, penetrating_homing_turn_speed)
	
	bullet.set_penetrating_config(penetrating_max_targets, penetrating_damage_decay)
	
	get_parent().add_child(bullet)

func _update_turret_attributes() -> void:
	var config = Constants.TURRET_CONFIG.get(color, {})
	fire_rate = config.get("fire_rate", 1.0)
	bullet_speed = config.get("bullet_speed", 300.0)
	bullet_damage = config.get("bullet_damage", 20.0)
	detection_range = config.get("detection_range", 200.0)
	bullet_lifetime = config.get("bullet_lifetime", 1.5)
	
	shotgun_enabled = config.get("shotgun_enabled", false)
	shotgun_count = config.get("shotgun_count", 1)
	shotgun_angle_spread = config.get("shotgun_angle_spread", 15.0)
	
	homing_enabled = config.get("homing_enabled", false)
	homing_detection_range = config.get("homing_detection_range", 150.0)
	homing_turn_speed = config.get("homing_turn_speed", 5.0)
	
	magic_enabled = config.get("magic_enabled", false)
	magic_beam_width = config.get("magic_beam_width", 8.0)
	magic_beam_duration = config.get("magic_beam_duration", 0.2)
	
	lightning_enabled = config.get("lightning_enabled", false)
	lightning_chain_range = config.get("lightning_chain_range", 384.0)
	lightning_max_chain = config.get("lightning_max_chain", 3)
	
	explosive_enabled = config.get("explosive_enabled", false)
	explosion_radius = config.get("explosion_radius", 200.0)
	explosion_particle_duration = config.get("explosion_particle_duration", 1.0)
	
	splitting_homing_enabled = config.get("splitting_homing_enabled", false)
	splitting_homing_detection_range = config.get("splitting_homing_detection_range", 150.0)
	splitting_homing_turn_speed = config.get("splitting_homing_turn_speed", 5.0)
	splitting_count = config.get("splitting_count", 5)
	splitting_angle_spread = config.get("splitting_angle_spread", 45.0)
	splitting_bullet_damage = config.get("splitting_bullet_damage", 15.0)
	splitting_bullet_lifetime = config.get("splitting_bullet_lifetime", 0.8)
	
	penetrating_enabled = config.get("penetrating_enabled", false)
	penetrating_homing_enabled = config.get("penetrating_homing_enabled", false)
	penetrating_homing_detection_range = config.get("penetrating_homing_detection_range", 150.0)
	penetrating_homing_turn_speed = config.get("penetrating_homing_turn_speed", 5.0)
	penetrating_max_targets = config.get("penetrating_max_targets", 4)
	penetrating_damage_decay = config.get("penetrating_damage_decay", 0.85)
	
	_update_detection_range()

func _update_detection_range() -> void:
	if detection_shape and detection_shape.shape is CircleShape2D:
		detection_shape.shape.radius = detection_range

func update_energy_level() -> void:
	super.update_energy_level()
	_update_turret_attributes()
	_check_activation_status()

func _on_detection_area_area_entered(area: Area2D) -> void:
	var enemy = area.get_parent()
	if enemy and enemy.is_in_group("enemy"):
		# 检查敌人是否可以被索敌
		if is_instance_valid(enemy) and enemy.has_method("can_be_targeted") and enemy.can_be_targeted():
			if not enemy in enemies_in_range:
				enemies_in_range.append(enemy)

func _on_detection_area_area_exited(area: Area2D) -> void:
	var enemy = area.get_parent()
	if enemy and enemy.is_in_group("enemy"):
		if enemy in enemies_in_range:
			enemies_in_range.erase(enemy)
		# 如果当前目标是离开的敌人，立即清除
		if target == enemy:
			target = null
