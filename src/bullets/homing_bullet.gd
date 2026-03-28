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

# 尾巴视觉效果
var _trail_points: Array[Vector2] = []
var _trail_max_length: int = 8
var _trail_update_interval: float = 0.03
var _trail_timer: float = 0.0

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
	
	_update_trail(delta)
	
	position += _velocity * delta
	_lifetime -= delta
	
	if _lifetime <= 0:
		destroy()

func _update_trail(delta: float) -> void:
	_trail_timer -= delta
	
	if _trail_timer <= 0:
		_trail_timer = _trail_update_interval
		_trail_points.push_front(global_position)
		
		if _trail_points.size() > _trail_max_length:
			_trail_points.pop_back()
	
	queue_redraw()

func _draw() -> void:
	if _trail_points.size() < 2:
		return
	
	var local_points: Array[Vector2] = []
	for point in _trail_points:
		local_points.append(to_local(point))
	
	for i in range(local_points.size() - 1):
		var alpha = float(local_points.size() - i) / float(local_points.size())
		var width = 4.0 * alpha
		var color = shape_drawer.fill_color
		color.a = alpha * 0.6
		
		draw_line(local_points[i], local_points[i + 1], color, width, true)

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
		
		# 排除飞行敌人（kinetic子弹无法有效击中）
		if enemy.get("can_be_hit_by_kinetic") != null and not enemy.can_be_hit_by_kinetic:
			continue
		
		var distance = global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_enemy = enemy
	
	_target = nearest_enemy

func reset() -> void:
	"""重置子弹状态用于对象池复用"""
	super.reset()
	_target = null
	_retarget_timer = 0.0
	_trail_points.clear()
	_trail_timer = 0.0
	_speed = 0.0

func activate() -> void:
	"""激活子弹"""
	super.activate()
	# 重新计算速度
	if _velocity.length() > 0:
		_speed = _velocity.length()

func destroy() -> void:
	# 清理拖尾效果
	_clear_trail()
	super.destroy()

func _clear_trail() -> void:
	"""清理拖尾效果"""
	_trail_points.clear()
	_trail_timer = 0.0
	queue_redraw()

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

func _on_hit_area_2d_area_entered(area: Area2D) -> void:
	super._on_hit_area_2d_area_entered(area)
	AudioManager.play_bullet_hit("green")
