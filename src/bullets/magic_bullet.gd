extends Bullet
class_name MagicBullet

# 魔法光束配置
var beam_width: float = 8.0
var beam_duration: float = 0.2
var beam_fade_in: float = 0.05
var beam_fade_out: float = 0.15

var _target: Node2D
var _beam_timer: float = 0.0
var _start_position: Vector2
var _target_position: Vector2

func init(velocity_: Vector2, damage: int, lifetime_: float, bullet_type_: Enums.ColorType):
	super.init(velocity_, damage, lifetime_, bullet_type_)

func set_target(target: Node2D, start_pos: Vector2, target_pos: Vector2) -> void:
	_target = target
	_start_position = start_pos
	_target_position = target_pos
	_lifetime = beam_duration
	_bullet_type = Enums.ColorType.YELLOW
	# 魔法子弹瞬间命中
	if _target and is_instance_valid(_target):
		if _target.has_method("take_damage"):
			_target.take_damage(_attack_damage, self)

func set_magic_config(beam_width_: float, beam_duration_: float) -> void:
	beam_width = beam_width_
	beam_duration = beam_duration_

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

func _ready() -> void:
	super._ready()
	
	# 魔法子弹瞬间命中
	if _target and is_instance_valid(_target):
		if _target.has_method("take_damage"):
			_target.take_damage(_attack_damage, self)

func reset() -> void:
	super.reset()
	_beam_timer = 0.0
	_target = null
	_start_position = Vector2.ZERO
	_target_position = Vector2.ZERO
	_bullet_type = Enums.ColorType.YELLOW

func activate() -> void:
	"""激活子弹"""
	super.activate()
	# 魔法子弹在激活时立即命中目标
	if _target and is_instance_valid(_target):
		if _target.has_method("take_damage"):
			_target.take_damage(_attack_damage, self)
