class_name ObjectPoolManager

var bullet_pools: Dictionary = {}
var particle_pools: Dictionary = {}
var max_pool_size: int = 20

func _ready() -> void:
	# 预创建对象池
	_prepare_bullet_pools()
	_prepare_particle_pools()

func _prepare_bullet_pools() -> void:
	# 预加载子弹场景
	var bullet_scenes = [
		preload("res://src/bullets/bullet.tscn"),
		preload("res://src/bullets/homing_bullet.tscn"),
		preload("res://src/bullets/magic_bullet.tscn"),
		preload("res://src/bullets/lightning_bullet.tscn"),
		preload("res://src/bullets/explosive_bullet.tscn")
	]
	
	for scene in bullet_scenes:
		var pool = []
		for i in range(max_pool_size):
			var bullet = scene.instantiate()
			bullet.set_is_active(false)
			bullet.queue_free()  # 初始时不添加到场景
			pool.append(bullet)
		bullet_pools[scene.resource_path] = pool

func _prepare_particle_pools() -> void:
	# 预创建粒子效果
	var pool = []
	for i in range(max_pool_size):
		var particle_system = GPUParticles2D.new()
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
		particle_system.lifetime = 1.0
		particle_system.one_shot = true
		pool.append(particle_system)
	particle_pools["explosion"] = pool

func get_bullet(scene_path: String) -> Node2D:
	if not bullet_pools.has(scene_path):
		return load(scene_path).instantiate()
	
	var pool = bullet_pools[scene_path]
	if pool.is_empty():
		return load(scene_path).instantiate()
	
	var bullet = pool.pop_back()
	if not is_instance_valid(bullet):
		return load(scene_path).instantiate()
	
	bullet.set_is_active(true)
	return bullet

func return_bullet(scene_path: String, bullet: Node2D) -> void:
	if not bullet_pools.has(scene_path):
		bullet.queue_free()
		return
	
	var pool = bullet_pools[scene_path]
	if pool.size() < max_pool_size:
		bullet.set_is_active(false)
		bullet.queue_free()  # 从场景中移除
		pool.append(bullet)
	else:
		bullet.queue_free()

func get_particle_effect(effect_type: String) -> GPUParticles2D:
	if not particle_pools.has(effect_type):
		return _create_particle_effect(effect_type)
	
	var pool = particle_pools[effect_type]
	if pool.is_empty():
		return _create_particle_effect(effect_type)
	
	var particles = pool.pop_back()
	if not is_instance_valid(particles):
		return _create_particle_effect(effect_type)
	
	return particles

func return_particle_effect(effect_type: String, particles: GPUParticles2D) -> void:
	if not particle_pools.has(effect_type):
		particles.queue_free()
		return
	
	var pool = particle_pools[effect_type]
	if pool.size() < max_pool_size:
		particles.queue_free()  # 从场景中移除
		pool.append(particles)
	else:
		particles.queue_free()

func _create_particle_effect(effect_type: String) -> GPUParticles2D:
	var particle_system = GPUParticles2D.new()
	var particle_process_material = ParticleProcessMaterial.new()
	
	if effect_type == "explosion":
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
		particle_system.amount = 50
		particle_system.lifetime = 1.0
		particle_system.one_shot = true
	
	particle_system.process_material = particle_process_material
	return particle_system
