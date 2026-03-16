extends HomingBullet
class_name SplittingHomingBullet

var splitting_count: int = 5
var splitting_angle_spread: float = 45.0
var splitting_bullet_damage: float = 15.0
var splitting_bullet_lifetime: float = 0.8
var splitting_bullet_scene: PackedScene = preload("res://src/bullets/splitting_bullet.tscn")
var splitting_bullet_homing_detection_range: float = 150.0
var splitting_bullet_homing_turn_speed: float = 10.0
var splitting_bullet_attack_delay: float = 0.15

var _has_split: bool = false

func init(velocity_: Vector2, damage: int, lifetime_: float, bullet_type_: Enums.ColorType):
	super.init(velocity_, damage, lifetime_, bullet_type_)

func _on_hit_area_2d_area_entered(area: Area2D) -> void:
	if _has_split:
		return
	
	_has_split = true
	_split_into_bullets()
	super._on_hit_area_2d_area_entered(area)

func _split_into_bullets() -> void:
	var enemies = get_tree().get_nodes_in_group("enemy")
	var valid_targets: Array[Node2D] = []
	
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy == _target:
			continue
		
		var distance = global_position.distance_to(enemy.global_position)
		if distance <= detection_range:
			valid_targets.append(enemy)
	
	var angle_spread_rad = deg_to_rad(splitting_angle_spread)
	var base_angle = rotation
	
	if not valid_targets.is_empty():
		for i in range(min(splitting_count, valid_targets.size())):
			var target_enemy = valid_targets[i]
			var direction = (target_enemy.global_position - global_position).normalized()
			var angle = direction.angle()
			
			_fire_splitting_bullet(angle, splitting_bullet_damage)
	else:
		var start_angle = base_angle - angle_spread_rad * (splitting_count - 1) / 2.0
		
		for i in range(splitting_count):
			var angle = start_angle + angle_spread_rad * i
			_fire_splitting_bullet(angle, splitting_bullet_damage)

func _fire_splitting_bullet(angle: float, damage: float) -> void:
	var bullet = splitting_bullet_scene.instantiate()
	if not bullet:
		return
	
	var direction = Vector2(cos(angle), sin(angle))
	var bullet_velocity = direction * _speed
	
	bullet.global_position = global_position
	bullet.init(bullet_velocity, int(damage), splitting_bullet_lifetime, _bullet_type)
	bullet.set_homing_config(true, splitting_bullet_homing_detection_range, splitting_bullet_homing_turn_speed)
	bullet.set_attack_delay(splitting_bullet_attack_delay)
	
	get_tree().current_scene.add_child(bullet)

func set_splitting_config(count: int, angle_spread: float, damage: float, lifetime: float) -> void:
	splitting_count = count
	splitting_angle_spread = angle_spread
	splitting_bullet_damage = damage
	splitting_bullet_lifetime = lifetime

func set_splitting_bullet_homing_config(detection_range: float, turn_speed: float, attack_delay: float) -> void:
	splitting_bullet_homing_detection_range = detection_range
	splitting_bullet_homing_turn_speed = turn_speed
	splitting_bullet_attack_delay = attack_delay
