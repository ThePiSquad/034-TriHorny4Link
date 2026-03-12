extends Bullet
class_name ExplosiveBullet

# 爆炸配置
var explosion_radius: float = 200.0
var explosion_damage: float = 40.0
var explosion_particle_duration: float = 1.0

var _exploded: bool = false

func init(velocity_: Vector2, damage: int, lifetime_: float, bullet_type_: Enums.ColorType):
	super.init(velocity_, damage, lifetime_, bullet_type_)
	explosion_damage = damage

func _process(delta: float) -> void:
	if not _is_active:
		return
	
	position += _velocity * delta
	_lifetime -= delta
	
	if _lifetime <= 0:
		explode()
		destroy()

func _on_hit_area_2d_area_entered(area: Area2D) -> void:
	var body = area.get_parent()
	if body and body.is_in_group("enemy"):
		explode()
		destroy()

func explode() -> void:
	if _exploded:
		return
	
	_exploded = true
	
	# 触发范围伤害
	_trigger_area_damage()
	
	# 生成爆炸粒子效果
	_create_explosion_effect()

func _trigger_area_damage() -> void:
	var enemies = get_tree().get_nodes_in_group("enemy")
	
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		
		var distance = global_position.distance_to(enemy.global_position)
		if distance <= explosion_radius:
			# 伤害衰减
			var damage_multiplier = 1.0 - (distance / explosion_radius)
			var final_damage = int(explosion_damage * damage_multiplier)
			
			if enemy.has_method("take_damage"):
				enemy.take_damage(final_damage, self)

func _create_explosion_effect() -> void:
	# 生成爆炸粒子效果
	var particle_system = GPUParticles2D.new()
	particle_system.name = "ExplosionParticles"
	particle_system.position = global_position
	
	# 配置粒子系统
	var particle_process_material = ParticleProcessMaterial.new()
	particle_process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	particle_process_material.emission_sphere_radius = 10.0
	particle_process_material.initial_velocity_min = 100.0
	particle_process_material.initial_velocity_max = 300.0
	particle_process_material.damping_min = 2.0
	particle_process_material.damping_max = 2.0
	particle_process_material.gravity = Vector3(0, 0, 0)
	particle_process_material.color = Color(1, 0.5, 1, 1)
	particle_process_material.scale_min = 8.0
	particle_process_material.scale_max = 15.0
	
	particle_system.process_material = particle_process_material
	particle_system.amount = 50
	particle_system.lifetime = explosion_particle_duration
	particle_system.one_shot = true
	
	# 添加到场景
	get_parent().add_child(particle_system)
	particle_system.emitting = true
	
	# 自动清理
	var tween = create_tween()
	tween.tween_interval(explosion_particle_duration + 0.1)
	tween.tween_callback(particle_system.queue_free)
