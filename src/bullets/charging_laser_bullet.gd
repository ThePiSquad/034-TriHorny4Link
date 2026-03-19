extends MagicBullet
class_name ChargingLaserBullet

var damage_increment: float = 3.0
var max_damage_multiplier: float = 3.0
var damage_interval: float = 0.3

var _current_damage: float = 0.0
var _damage_timer: float = 0.0
var _is_continuous: bool = true
var _energy_pulse_timer: float = 0.0
var _energy_pulse_speed: float = 8.0
var _fade_out_timer: float = 0.0
var _fade_out_duration: float = 0.2
var _is_fading_out: bool = false

func _ready() -> void:
	super._ready()

func init(velocity_: Vector2, damage: int, lifetime_: float, bullet_type_: Enums.ColorType):
	super.init(velocity_, damage, lifetime_, bullet_type_)
	_current_damage = float(damage)
	_lifetime = 10.0
	_is_continuous = true
	_damage_timer = damage_interval

func reset() -> void:
	super.reset()
	_current_damage = 0.0
	_damage_timer = 0.0
	_is_continuous = true
	_energy_pulse_timer = 0.0
	_fade_out_timer = 0.0
	_is_fading_out = false

func set_target(target: Node2D, start_pos: Vector2, target_pos: Vector2, current_damage_: float = 0.0) -> void:
	_target = target
	_start_position = start_pos
	_target_position = target_pos
	_current_damage = current_damage_ if current_damage_ > 0 else float(_attack_damage)

func _process(delta: float) -> void:
	if not _is_active or not _is_continuous:
		return
	
	if _target and is_instance_valid(_target):
		_target_position = _target.global_position
	else:
		start_fade_out()
		return
	
	_energy_pulse_timer += delta * _energy_pulse_speed
	queue_redraw()
	
	if _is_fading_out:
		_fade_out_timer += delta
		if _fade_out_timer >= _fade_out_duration:
			stop_continuous()
			return
	
	_damage_timer -= delta
	
	if _damage_timer <= 0:
		_deal_damage()
		_damage_timer = damage_interval

func _deal_damage() -> void:
	if not _target or not is_instance_valid(_target):
		return
	
	if _target.has_method("take_damage"):
		_target.take_damage(int(_current_damage), self)
		AudioManager.play_bullet_hit("orange")

func _draw() -> void:
	if not _is_active or not _is_continuous:
		return
	
	var base_color = shape_drawer.fill_color
	
	var fade_alpha = 1.0
	if _is_fading_out:
		fade_alpha = 1.0 - (_fade_out_timer / _fade_out_duration)
		fade_alpha = max(0.0, fade_alpha)
	
	var pulse = (sin(_energy_pulse_timer) + 1.0) / 2.0
	var pulse_width = beam_width + pulse * 4.0
	
	var main_color = base_color
	main_color.a = fade_alpha
	draw_line(_start_position, _target_position, main_color, pulse_width, true)
	
	var glow_color = base_color
	glow_color.a = 0.4 + pulse * 0.3
	glow_color.a *= fade_alpha
	draw_line(_start_position, _target_position, glow_color, pulse_width * 2.5, true)
	
	var outer_glow_color = base_color
	outer_glow_color.a = 0.2 + pulse * 0.15
	outer_glow_color.a *= fade_alpha
	draw_line(_start_position, _target_position, outer_glow_color, pulse_width * 4.0, true)
	
	_draw_energy_particles(base_color, fade_alpha)
	_draw_energy_waves(base_color, fade_alpha)

func _draw_energy_particles(base_color: Color, fade_alpha: float) -> void:
	var distance = _start_position.distance_to(_target_position)
	var particle_count = max(5, int(distance / 50))
	
	for i in range(particle_count):
		var t = float(i) / float(particle_count)
		var pulse_offset = sin(_energy_pulse_timer + i * 0.6) * 0.4
		var point = _start_position.lerp(_target_position, t + pulse_offset)
		
		var particle_color = base_color
		particle_color.a = 0.7 + sin(_energy_pulse_timer + i * 1.0) * 0.4
		particle_color.a *= fade_alpha
		
		var size = 4.0 + sin(_energy_pulse_timer + i * 1.5) * 2.5
		draw_circle(point, size, particle_color)
		
		var core_color = Color.WHITE
		core_color.a = 0.5 + sin(_energy_pulse_timer + i * 1.2) * 0.3
		core_color.a *= fade_alpha
		draw_circle(point, size * 0.4, core_color)

func _draw_energy_waves(base_color: Color, fade_alpha: float) -> void:
	var distance = _start_position.distance_to(_target_position)
	var wave_count = 3
	
	for i in range(wave_count):
		var wave_offset = int(_energy_pulse_timer + i * PI * 2.0 / wave_count) % int(PI * 2.0)
		var wave_t = (sin(wave_offset) + 1.0) / 2.0
		
		var wave_color = base_color
		wave_color.h += 0.1
		wave_color.a = 0.3 + wave_t * 0.2
		wave_color.a *= fade_alpha
		
		var wave_width = beam_width * 1.5 + wave_t * 3.0
		draw_line(_start_position, _target_position, wave_color, wave_width, true)

func start_fade_out() -> void:
	if not _is_fading_out:
		_is_fading_out = true
		_fade_out_timer = 0.0

func stop_continuous() -> void:
	_is_continuous = false
	destroy()

func get_current_damage() -> float:
	return _current_damage

func set_charging_config(damage_increment_: float, max_damage_multiplier_: float) -> void:
	damage_increment = damage_increment_
	max_damage_multiplier = max_damage_multiplier_

func set_beam_width(width: float) -> void:
	beam_width = width
