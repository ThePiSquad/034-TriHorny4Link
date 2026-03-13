extends Bullet
class_name LightningBullet

# 闪电光束配置
var beam_width: float = 3.0  # 比魔法子弹更纤细
var beam_duration: float = 0.5
var beam_fade_in: float = 0.05
var beam_fade_out: float = 0.15

# 连锁闪电配置
var chain_range: float = 384.0
var max_chain_targets: int = 3
var damage_multipliers: Array[float] = [1.0, 0.75, 0.5, 0.25, 0.1]

var _target: Node2D
var _beam_timer: float = 0.0
var _start_position: Vector2
var _target_position: Vector2
var _chain_targets: Array[Node2D] = []
var _chain_damages: Array[float] = []
var _chain_positions: Array[Vector2] = []

func init(velocity_: Vector2, damage: int, lifetime_: float, bullet_type_: Enums.ColorType):
	super.init(velocity_, damage, lifetime_, bullet_type_)

func set_target(target: Node2D, start_pos: Vector2, target_pos: Vector2) -> void:
	_target = target
	_start_position = start_pos
	_target_position = target_pos
	_lifetime = beam_duration

func _process(delta: float) -> void:
	if not _is_active:
		return
	
	_beam_timer += delta
	_lifetime -= delta
	
	if _target and is_instance_valid(_target):
		_target_position = _target.global_position
	
	queue_redraw()
	
	if _lifetime <= 0:
		destroy()

func _draw() -> void:
	if not _is_active:
		return
	
	var alpha = 1.0
	if _beam_timer < beam_fade_in:
		alpha = _beam_timer / beam_fade_in
	elif _beam_timer > beam_duration - beam_fade_out:
		alpha = (_beam_timer - (beam_duration - beam_fade_out)) / beam_fade_out
		alpha = 1.0 - alpha
	
	var color = shape_drawer.fill_color
	color.a = alpha
	
	# 绘制主光束
	draw_line(_start_position, _target_position, color, beam_width, true)
	
	# 绘制光束边缘（发光效果）
	var glow_color = color
	glow_color.a = alpha * 0.3
	draw_line(_start_position, _target_position, glow_color, beam_width * 2, true)
	
	# 绘制连锁闪电
	if _chain_positions.size() > 1:
		for i in range(_chain_positions.size() - 1):
			_draw_lightning_bolt(_chain_positions[i], _chain_positions[i + 1], color)

func _draw_lightning_bolt(start: Vector2, end: Vector2, color: Color) -> void:
	var distance = start.distance_to(end)
	var segments = max(3, int(distance / 32))
	var points = [start]
	
	for i in range(1, segments):
		var t = float(i) / float(segments)
		var point = start.lerp(end, t)
		var offset = Vector2(randf_range(-10, 10), randf_range(-10, 10)) * (1.0 - t)
		points.append(point + offset)
	
	points.append(end)
	
	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], color, beam_width, true)

func _ready() -> void:
	super._ready()
	
	# 闪电子弹瞬间命中并触发连锁
	if _target and is_instance_valid(_target):
		_trigger_chain_lightning(_target)

func _trigger_chain_lightning(first_target: Node2D) -> void:
	if not first_target or not is_instance_valid(first_target):
		return
	
	# 初始化连锁目标
	_chain_targets.clear()
	_chain_damages.clear()
	_chain_positions.clear()
	
	_chain_targets.append(first_target)
	_chain_damages.append(_attack_damage * damage_multipliers[0])
	_chain_positions.append(_start_position)
	_chain_positions.append(first_target.global_position)
	
	# 造成初始伤害
	if first_target.has_method("take_damage"):
		first_target.take_damage(int(_chain_damages[0]), self)
	
	# 继续连锁
	_find_chain_targets(first_target, 1)

func _find_chain_targets(current_target: Node2D, chain_index: int) -> void:
	if chain_index >= max_chain_targets or chain_index >= damage_multipliers.size():
		return
	
	var enemies = get_tree().get_nodes_in_group("enemy")
	var valid_targets: Array[Dictionary] = []
	
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy == current_target or enemy in _chain_targets:
			continue
		
		var distance = current_target.global_position.distance_to(enemy.global_position)
		if distance <= chain_range:
			valid_targets.append({"enemy": enemy, "distance": distance})
	
	# 按距离排序
	valid_targets.sort_custom(func(a, b): return a["distance"] < b["distance"])
	
	# 选择最近的目标
	if valid_targets.size() > 0:
		var next_target = valid_targets[0]["enemy"]
		var damage = _attack_damage * damage_multipliers[chain_index]
		
		_chain_targets.append(next_target)
		_chain_damages.append(damage)
		_chain_positions.append(next_target.global_position)
		
		# 造成伤害
		if next_target.has_method("take_damage"):
			next_target.take_damage(int(damage), self)
		
		# 继续连锁
		_find_chain_targets(next_target, chain_index + 1)
