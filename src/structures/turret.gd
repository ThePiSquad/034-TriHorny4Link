extends EnergyTransmitter
class_name Turret

var bullet_scene: PackedScene = preload("res://src/bullets/bullet.tscn")
var homing_bullet_scene: PackedScene = preload("res://src/bullets/homing_bullet.tscn")
var magic_bullet_scene: PackedScene = preload("res://src/bullets/magic_bullet.tscn")
var lightning_bullet_scene: PackedScene = preload("res://src/bullets/lightning_bullet.tscn")
var explosive_bullet_scene: PackedScene = preload("res://src/bullets/explosive_bullet.tscn")

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

var target: Node2D = null
var enemies_in_range: Array[Node2D] = []
var can_fire: bool = true

# 失活状态
var is_active: bool = false

@onready var detection_area: Area2D = $DetectionArea
@onready var detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D

func _ready() -> void:
	super._ready()
	structure_type = Enums.StructureType.TURRET
	detection_shape.shape.radius = detection_range
	_update_turret_attributes()

func _init() -> void:
	structure_type = Enums.StructureType.TURRET

func _process(delta: float) -> void:
	_update_fire_timer(delta)
	_check_activation_status()
	
	if not is_active:
		return
	
	_update_target()
	_rotate_towards_target(delta)
	
	if target and can_fire:
		shot()

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
	
	# 失活时不修改颜色，保持当前颜色（白色或黑色）
	if is_active:
		var base_color = Constants.COLOR_MAP.get(color, Color.WHITE)
		shape_drawer.fill_color = base_color
		shape_drawer.stroke_color = base_color.lightened(0.3)
	
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
	
	# 过滤掉正在传送的敌人
	var valid_enemies = []
	for enemy in enemies_in_range:
		if enemy.has_method("can_be_targeted") and enemy.can_be_targeted():
			valid_enemies.append(enemy)
	
	if valid_enemies.is_empty():
		target = null
		return
	
	valid_enemies.sort_custom(_compare_distance)
	target = valid_enemies[0]

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
	elif shotgun_enabled and shotgun_count > 1:
		_fire_shotgun(base_angle)
	else:
		_fire_single_bullet(base_angle)
	
	can_fire = false
	fire_timer = 1.0 / fire_rate

func _fire_single_bullet(angle: float) -> void:
	var bullet: Node2D
	
	if homing_enabled and homing_bullet_scene:
		bullet = homing_bullet_scene.instantiate()
	else:
		bullet = bullet_scene.instantiate()
	
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
	var angle_spread_rad = deg_to_rad(shotgun_angle_spread)
	var start_angle = base_angle - angle_spread_rad * (shotgun_count - 1) / 2.0
	
	for i in range(shotgun_count):
		var angle = start_angle + angle_spread_rad * i
		_fire_single_bullet(angle)

func _fire_magic_bullet() -> void:
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
		if enemy.has_method("can_be_targeted") and enemy.can_be_targeted():
			if not enemy in enemies_in_range:
				enemies_in_range.append(enemy)

func _on_detection_area_area_exited(area: Area2D) -> void:
	var enemy = area.get_parent()
	if enemy and enemy.is_in_group("enemy"):
		enemies_in_range.erase(enemy)
