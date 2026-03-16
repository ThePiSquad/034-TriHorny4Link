extends HomingBullet
class_name PenetratingBullet

var penetrating_max_targets: int = 4
var penetrating_damage_decay: float = 0.85
var current_damage: float = 0.0
var hit_targets: Array[Node2D] = []

func init(velocity_: Vector2, damage: int, lifetime_: float, bullet_type_: Enums.ColorType):
	super.init(velocity_, damage, lifetime_, bullet_type_)
	current_damage = float(damage)

func _on_hit_area_2d_area_entered(area: Area2D) -> void:
	var body = area.get_parent()
	
	if not body or not body.is_in_group("enemy"):
		return
	
	if body in hit_targets:
		return
	
	hit_targets.append(body)
	
	if body.has_method("take_damage"):
		body.take_damage(int(current_damage), self)
	
	AudioManager.play_bullet_hit("green")
	
	if hit_targets.size() >= penetrating_max_targets:
		destroy()
		return
	
	current_damage *= penetrating_damage_decay
	
	if current_damage < 1.0:
		destroy()

func set_penetrating_config(max_targets: int, damage_decay: float) -> void:
	penetrating_max_targets = max_targets
	penetrating_damage_decay = damage_decay
