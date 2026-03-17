extends Bullet
class_name ContinuousExplosiveBullet

var explosion_radius: float = 200.0
var explosion_damage: float = 40.0
var explosion_particle_duration: float = 1.0
var slow_debuff_duration: float = 2.0
var slow_debuff_multiplier: float = 0.5

var _exploded: bool = false
var particle_scene: PackedScene = preload("res://src/bullets/explosive_purple_blue_particle.tscn")

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
		_apply_slow_debuff(body)
		explode()
		destroy()

func explode() -> void:
	if _exploded:
		return
	
	_exploded = true
	
	_trigger_area_damage()
	AudioManager.play_bullet_hit("purple")
	_create_explosion_effect()

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
	var particle_system = particle_scene.instantiate()
	particle_system.position = global_position
	
	get_parent().add_child(particle_system)
	particle_system.emitting = true

func _apply_slow_debuff(enemy: Node2D) -> void:
	if not is_instance_valid(enemy):
		return
	
	if enemy.has_method("apply_slow_debuff"):
		enemy.apply_slow_debuff(slow_debuff_duration, slow_debuff_multiplier)
