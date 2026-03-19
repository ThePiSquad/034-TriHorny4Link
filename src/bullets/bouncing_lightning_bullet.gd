extends Bullet
class_name BouncingLightningBullet

var max_bounces: int = 5
var damage_decay: float = 0.9
var bounce_range: float = 384.0
var attack_delay: float = 0.15

var _bounce_count: int = 0
var _attack_delay_timer: float = 0.0
var _can_attack: bool = true
var _hit_enemies: Array[Node2D] = []

func _ready() -> void:
	super._ready()
	_hit_enemies.clear()
	_bounce_count = 0
	_attack_delay_timer = 0.0
	_can_attack = true

func reset() -> void:
	super.reset()
	_hit_enemies.clear()
	_bounce_count = 0
	_attack_delay_timer = 0.0
	_can_attack = true

func _process(delta: float) -> void:
	super._process(delta)
	
	if not _can_attack:
		_attack_delay_timer -= delta
		if _attack_delay_timer <= 0:
			_can_attack = true

func _on_hit_area_2d_area_entered(area: Area2D) -> void:
	if not _can_attack:
		return
	
	var body = area.get_parent()
	
	if not body or not body.is_in_group("enemy"):
		return
	
	if body in _hit_enemies:
		return
	
	_hit_enemies.append(body)
	
	if body.has_method("take_damage"):
		body.take_damage(_attack_damage, self)
		AudioManager.play_bullet_hit("orange")
	
	_schedule_next_bounce()

func _schedule_next_bounce() -> void:
	_bounce_count += 1
	
	if _bounce_count >= max_bounces:
		destroy()
		return
	
	_attack_delay_timer = attack_delay
	_can_attack = false
	
	_perform_next_bounce()

func _perform_next_bounce() -> void:
	var enemies = get_tree().get_nodes_in_group("enemy")
	var valid_targets: Array[Node2D] = []
	var fallback_targets: Array[Node2D] = []
	
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		
		var distance = global_position.distance_to(enemy.global_position)
		if distance <= bounce_range:
			if enemy not in _hit_enemies:
				valid_targets.append(enemy)
			else:
				fallback_targets.append(enemy)
	
	var next_target: Node2D = null
	
	if valid_targets.size() > 0:
		next_target = valid_targets[randi() % valid_targets.size()]
	elif fallback_targets.size() > 0:
		next_target = fallback_targets[randi() % fallback_targets.size()]
	
	if next_target:
		var direction = (next_target.global_position - global_position).normalized()
		_velocity = direction * 1600.0
		rotation = direction.angle() + PI / 2
		
		var damage = _attack_damage * damage_decay
		_attack_damage = int(damage)
	else:
		destroy()

func set_bouncing_config(chain_range_: float, max_bounces_: int, damage_decay_: float) -> void:
	bounce_range = chain_range_
	max_bounces = max_bounces_
	damage_decay = damage_decay_
