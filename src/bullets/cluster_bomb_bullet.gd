extends Bullet
class_name ClusterBombBullet

var explosion_radius: float = 200.0
var explosion_damage: float = 40.0
var explosion_particle_duration: float = 1.0
var cluster_count: int = 4
var cluster_angle_spread: float = 15.0
var cluster_bullet_damage: float = 15.0
var cluster_bullet_lifetime: float = 0.8
var cluster_bullet_speed: float = 600.0

var _exploded: bool = false
var _cluster_bullet_scene: PackedScene = preload("res://src/bullets/bullet.tscn")
var particle_scene: PackedScene = preload("res://src/bullets/explosive_purple_red_particle.tscn")

func _ready() -> void:
	super._ready()

func init(velocity_: Vector2, damage: int, lifetime_: float, bullet_type_: Enums.ColorType):
	super.init(velocity_, damage, lifetime_, bullet_type_)
	explosion_damage = damage

func reset() -> void:
	super.reset()
	_exploded = false

func _process(delta: float) -> void:
	if not _is_active:
		return
	
	position += _velocity * delta
	_lifetime -= delta
	
	if _lifetime <= 0 and not _exploded:
		explode()
		destroy()

func _on_hit_area_2d_area_entered(area: Area2D) -> void:
	if _exploded:
		return
	
	var body = area.get_parent()
	if body and body.is_in_group("enemy"):
		explode()
		destroy()

func explode_and_destroy() -> void:
	if not _exploded:
		return
	explode()
	destroy()

func explode() -> void:
	if _exploded:
		return
	
	_exploded = true
	
	_trigger_area_damage()
	AudioManager.play_bullet_hit("purple")
	_create_explosion_effect()
	_spawn_cluster_bullets()

func _trigger_area_damage() -> void:
	var enemies = get_tree().get_nodes_in_group("enemy")
	
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		
		var distance = global_position.distance_to(enemy.global_position)
		if distance <= explosion_radius:
			var damage_multiplier = 1.0 - (distance / explosion_radius)
			var final_damage = int(explosion_damage * damage_multiplier)
			
			if enemy.has_method("take_damage"):
				enemy.take_damage(final_damage, self)

func _create_explosion_effect() -> void:
	"""生成爆炸粒子效果"""
	var particle_system: GPUParticles2D = null
	
	# 尝试使用对象池
	if ObjectPoolManager.instance:
		particle_system = ObjectPoolManager.instance.get_object("res://src/bullets/explosive_purple_red_particle.tscn")
	
	# 如果对象池失败，使用传统方式
	if not particle_system:
		particle_system = particle_scene.instantiate()
		get_parent().add_child(particle_system)
	else:
		# 设置场景路径用于归还
		if particle_system.has_method("set_scene_path"):
			particle_system.set_scene_path("res://src/bullets/explosive_purple_red_particle.tscn")
		# 手动启动销毁计时器（对象池复用时不会自动调用_ready）
		if particle_system.has_method("start_destruction_timer"):
			particle_system.start_destruction_timer()
	
	particle_system.position = global_position
	particle_system.restart()  # 先重启
	particle_system.emitting = true  # 再发射

func _spawn_cluster_bullets() -> void:
	var base_direction = _velocity.normalized()
	var base_angle = base_direction.angle()
	
	for i in range(cluster_count):
		var offset_angle = (i - (cluster_count - 1) / 2.0) * deg_to_rad(cluster_angle_spread)
		var direction = Vector2.from_angle(base_angle + offset_angle)
		var bullet_velocity = direction * cluster_bullet_speed
		
		var bullet: Bullet = null
		
		# 尝试使用对象池
		if ObjectPoolManager.instance:
			bullet = ObjectPoolManager.instance.get_object("res://src/bullets/bullet.tscn") as Bullet
		
		# 如果对象池失败，使用传统方式
		if not bullet:
			bullet = _cluster_bullet_scene.instantiate() as Bullet
			if bullet:
				get_parent().add_child(bullet)
		
		if not bullet:
			continue
		
		# 设置场景路径用于归还（对象池复用时也需要）
		if bullet.has_method("set_scene_path"):
			bullet.set_scene_path("res://src/bullets/bullet.tscn")
		
		bullet.global_position = global_position
		bullet.init(bullet_velocity, int(cluster_bullet_damage), cluster_bullet_lifetime, _bullet_type)

func _add_bullet_to_scene(bullet: Bullet) -> void:
	"""延迟添加子弹到场景"""
	get_parent().add_child(bullet)

func set_cluster_config(count: int, angle_spread: float, bullet_damage: float, bullet_lifetime: float, bullet_speed: float) -> void:
	cluster_count = count
	cluster_angle_spread = angle_spread
	cluster_bullet_damage = bullet_damage
	cluster_bullet_lifetime = bullet_lifetime
	cluster_bullet_speed = bullet_speed

func set_explosion_config(explosion_radius_: float, explosion_particle_duration_: float) -> void:
	explosion_radius = explosion_radius_
	explosion_particle_duration = explosion_particle_duration_
