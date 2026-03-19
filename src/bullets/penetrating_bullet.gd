extends HomingBullet
class_name PenetratingBullet

var max_targets: int = 4
var damage_decay: float = 0.85
var current_damage: float = 0.0
var _hit_targets: Array[Node2D] = []

func _ready() -> void:
	super._ready()

func init(velocity_: Vector2, damage: int, lifetime_: float, bullet_type_: Enums.ColorType):
	super.init(velocity_, damage, lifetime_, bullet_type_)
	current_damage = float(damage)
	_hit_targets.clear()

func reset() -> void:
	super.reset()
	_hit_targets.clear()
	current_damage = 0.0

func _on_hit_area_2d_area_entered(area: Area2D) -> void:
	var body = area.get_parent()
	
	if not body or not body.is_in_group("enemy"):
		return
	
	if body in _hit_targets:
		return
	
	_hit_targets.append(body)
	
	if body.has_method("take_damage"):
		body.take_damage(int(current_damage), self)
	
	AudioManager.play_bullet_hit("green")
	
	if _hit_targets.size() >= max_targets:
		destroy()
		return
	
	current_damage *= damage_decay
	
	if current_damage < 1.0:
		destroy()

func set_penetrating_config(max_targets: int, damage_decay: float) -> void:
	self.max_targets = max_targets
	self.damage_decay = damage_decay
