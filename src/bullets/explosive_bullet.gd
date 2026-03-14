extends Bullet
class_name ExplosiveBullet

# 爆炸配置
var explosion_radius: float = 200.0
var explosion_damage: float = 40.0
var explosion_particle_duration: float = 1.0

var _exploded: bool = false

var particle_scene: PackedScene = preload("res://src/bullets/explosive_purple_particle.tscn")

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
	var particle_system = particle_scene.instantiate()
	particle_system.position = global_position
	particle_system.one_shot = true
	
	# 添加到场景
	get_parent().add_child(particle_system)
	particle_system.emitting = true
	
