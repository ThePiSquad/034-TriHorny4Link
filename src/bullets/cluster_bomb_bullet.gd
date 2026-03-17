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
	var particle_system = particle_scene.instantiate()
	particle_system.position = global_position
	
	get_parent().add_child(particle_system)
	particle_system.emitting = true

func _spawn_cluster_bullets() -> void:
	var base_direction = _velocity.normalized()
	var base_angle = base_direction.angle()
	
	for i in range(cluster_count):
		var offset_angle = (i - (cluster_count - 1) / 2.0) * deg_to_rad(cluster_angle_spread)
		var direction = Vector2.from_angle(base_angle + offset_angle)
		var bullet_velocity = direction * cluster_bullet_speed
		
		var bullet :Bullet= _cluster_bullet_scene.instantiate()
		if not bullet:
			continue
		
		bullet.global_position = global_position
		bullet.init(bullet_velocity, int(cluster_bullet_damage), cluster_bullet_lifetime, _bullet_type)
		
		get_parent().add_child(bullet)

func set_cluster_config(count: int, angle_spread: float, bullet_damage: float, bullet_lifetime: float, bullet_speed: float) -> void:
	cluster_count = count
	cluster_angle_spread = angle_spread
	cluster_bullet_damage = bullet_damage
	cluster_bullet_lifetime = bullet_lifetime
	cluster_bullet_speed = bullet_speed
