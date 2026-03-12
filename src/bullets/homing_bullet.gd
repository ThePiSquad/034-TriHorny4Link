extends Bullet
class_name HomingBullet

# 追踪配置
var homing_enabled: bool = true
var detection_range: float = 150.0
var turn_speed: float = 5.0
var retarget_interval: float = 0.1

var _target: Node2D = null
var _retarget_timer: float = 0.0
var _speed: float = 0.0

func _ready() -> void:
	super._ready()
	_speed = _velocity.length()

func init(velocity_: Vector2, damage: int, lifetime_: float, bullet_type_: Enums.ColorType):
	super.init(velocity_, damage, lifetime_, bullet_type_)
	_speed = velocity_.length()

func _process(delta: float) -> void:
	if not _is_active:
		return
	
	if homing_enabled:
		_update_target(delta)
		_apply_homing(delta)
	
	position += _velocity * delta
	_lifetime -= delta
	
	if _lifetime <= 0:
		destroy()

func _update_target(delta: float) -> void:
	_retarget_timer -= delta
	
	if _retarget_timer <= 0:
		_retarget_timer = retarget_interval
		_find_nearest_target()

func _find_nearest_target() -> void:
	var enemies = get_tree().get_nodes_in_group("enemy")
	var nearest_enemy: Node2D = null
	var nearest_distance: float = detection_range
	
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		
		var distance = global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_enemy = enemy
	
	_target = nearest_enemy

func _apply_homing(delta: float) -> void:
	if not _target or not is_instance_valid(_target):
		return
	
	var target_position = _target.global_position
	var direction_to_target = (target_position - global_position).normalized()
	var current_direction = _velocity.normalized()
	
	var angle_to_target = current_direction.angle_to(direction_to_target)
	var max_turn = turn_speed * delta
	
	if abs(angle_to_target) > max_turn:
		angle_to_target = sign(angle_to_target) * max_turn
	
	var new_direction = current_direction.rotated(angle_to_target)
	_velocity = new_direction * _speed
	
	rotation = new_direction.angle()

func set_homing_config(enabled: bool, range: float, turn: float) -> void:
	homing_enabled = enabled
	detection_range = range
	turn_speed = turn
