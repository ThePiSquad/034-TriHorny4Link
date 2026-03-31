extends Bullet
class_name ContinuousExplosiveBullet

var explosion_radius: float = 200.0
var explosion_damage: float = 40.0
var explosion_particle_duration: float = 1.0
var slow_debuff_duration: float = 2.0
var slow_debuff_multiplier: float = 0.5

var _exploded: bool = false
var particle_scene: PackedScene = preload("res://src/bullets/explosive_purple_blue_particle.tscn")

func _ready() -> void:
	super._ready()

func init(velocity_: Vector2, damage: int, lifetime_: float, bullet_type_: Enums.ColorType):
	super.init(velocity_, damage, lifetime_, bullet_type_)
	explosion_damage = damage

func set_continuous_explosive_config(explosion_radius_: float, explosion_particle_duration_: float, slow_debuff_duration_: float, slow_debuff_multiplier_: float) -> void:
	explosion_radius = explosion_radius_
	explosion_particle_duration = explosion_particle_duration_
	slow_debuff_duration = slow_debuff_duration_
	slow_debuff_multiplier = slow_debuff_multiplier_

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
		_apply_slow_debuff(body)
		explode()
		_apply_slow_debuff_to_nearby_enemies()
		destroy()

func explode_and_destroy() -> void:
	if not _exploded:
		return
	explode()
	_apply_slow_debuff_to_nearby_enemies()
	destroy()

func _apply_slow_debuff_to_nearby_enemies() -> void:
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if is_instance_valid(enemy):
			var distance = global_position.distance_to(enemy.global_position)
			if distance <= explosion_radius:
				_apply_slow_debuff(enemy)

func explode() -> void:
	if _exploded:
		return
	
	_exploded = true
	
	_trigger_area_damage()
	AudioManager.play_bullet_hit("purple")
	_create_explosion_effect()

func _trigger_area_damage() -> void:
	# 检查游戏是否已结束
	var game_manager = GameManager.instance
	if game_manager and game_manager.current_state == GameManager.GameState.GAME_OVER:
		return
	
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
		particle_system = ObjectPoolManager.instance.get_object("res://src/bullets/explosive_purple_blue_particle.tscn")
	
	# 如果对象池失败，使用传统方式
	if not particle_system:
		particle_system = particle_scene.instantiate()
		get_parent().call_deferred("add_child", particle_system)
	else:
		# 设置场景路径用于归还
		if particle_system.has_method("set_scene_path"):
			particle_system.set_scene_path("res://src/bullets/explosive_purple_blue_particle.tscn")
		# 调用 activate 方法确保正确初始化（包括颜色重置和计时器）
		if particle_system.has_method("activate"):
			particle_system.activate()
	
	particle_system.position = global_position
	# activate() 已经调用了 restart() 和 emitting = true，不需要重复调用

func _apply_slow_debuff(enemy: Node2D) -> void:
	if not is_instance_valid(enemy):
		return
	
	if enemy.has_method("apply_slow_debuff"):
		enemy.apply_slow_debuff(slow_debuff_duration, slow_debuff_multiplier)
