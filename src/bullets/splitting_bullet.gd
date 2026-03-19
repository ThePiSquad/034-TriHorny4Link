extends HomingBullet
class_name SplittingBullet

var attack_delay: float = 0.15
var _attack_delay_timer: float = 0.0
var _can_attack: bool = false

func _ready() -> void:
	super._ready()

func init(velocity_: Vector2, damage: int, lifetime_: float, bullet_type_: Enums.ColorType):
	super.init(velocity_, damage, lifetime_, bullet_type_)
	_attack_delay_timer = attack_delay
	_can_attack = false

func reset() -> void:
	super.reset()
	_attack_delay_timer = attack_delay
	_can_attack = false

func _process(delta: float) -> void:
	super._process(delta)
	
	if not _can_attack:
		_attack_delay_timer -= delta
		if _attack_delay_timer <= 0:
			_can_attack = true

func _on_hit_area_2d_area_entered(area: Area2D) -> void:
	if not _can_attack:
		return
	
	super._on_hit_area_2d_area_entered(area)
	AudioManager.play_bullet_hit("green")

func set_attack_delay(delay: float) -> void:
	attack_delay = delay
	_attack_delay_timer = delay
