extends EnergyTransmitter
class_name Turret

var bullet_scene: PackedScene = preload("res://src/bullets/bullet.tscn")

var fire_rate: float = 1.0
var fire_timer: float = 0.0
var bullet_damage: float = 20.0
var bullet_speed: float = 300.0
var bullet_lifetime: float = 1.5
var detection_range: float = 200.0
var rotation_speed: float = 5.0

# 霰弹枪配置
var shotgun_enabled: bool = false
var shotgun_count: int = 1
var shotgun_angle_spread: float = 15.0

var target: Node2D = null
var enemies_in_range: Array[Node2D] = []
var can_fire: bool = true

@onready var detection_area: Area2D = $DetectionArea
@onready var detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D

func _ready() -> void:
	super._ready()
	structure_type = Enums.StructureType.TURRET
	detection_shape.shape.radius = detection_range
	_update_turret_attributes()

func _init() -> void:
	structure_type = Enums.StructureType.TURRET

func _process(delta: float) -> void:
	_update_fire_timer(delta)
	_update_target()
	_rotate_towards_target(delta)
	
	if target and can_fire:
		shot()

func _update_fire_timer(delta: float) -> void:
	if fire_timer > 0:
		fire_timer -= delta
		if fire_timer <= 0:
			can_fire = true

func _update_target() -> void:
	if enemies_in_range.is_empty():
		target = null
		return
	
	enemies_in_range.sort_custom(_compare_distance)
	target = enemies_in_range[0]

func _compare_distance(a: Node2D, b: Node2D) -> bool:
	var dist_a = global_position.distance_to(a.global_position)
	var dist_b = global_position.distance_to(b.global_position)
	return dist_a < dist_b

func _rotate_towards_target(delta: float) -> void:
	if not target:
		return
	
	var target_angle = _get_angle_to_target(target.global_position)
	var current_angle = rotation
	var angle_diff = target_angle - current_angle
	
	while angle_diff > PI:
		angle_diff -= 2 * PI
	while angle_diff < -PI:
		angle_diff += 2 * PI
	
	var max_rotation = rotation_speed * delta
	angle_diff = clamp(angle_diff, -max_rotation, max_rotation)
	
	rotation += angle_diff

func _get_angle_to_target(target_position: Vector2) -> float:
	var angle = atan2(target_position.y - global_position.y, target_position.x - global_position.x)
	return angle + PI / 2

func shot() -> void:
	if not bullet_scene:
		return
	
	var base_angle = _get_angle_to_target(target.global_position) - PI / 2
	
	if shotgun_enabled and shotgun_count > 1:
		_fire_shotgun(base_angle)
	else:
		_fire_single_bullet(base_angle)
	
	can_fire = false
	fire_timer = 1.0 / fire_rate

func _fire_single_bullet(angle: float) -> void:
	var bullet: Bullet = bullet_scene.instantiate()
	if not bullet:
		return
	
	var direction = Vector2(cos(angle), sin(angle))
	var bullet_velocity = direction * bullet_speed
	
	bullet.global_position = global_position + direction * 32
	bullet.init(bullet_velocity, int(bullet_damage), bullet_lifetime, color)
	get_parent().add_child(bullet)

func _fire_shotgun(base_angle: float) -> void:
	var angle_spread_rad = deg_to_rad(shotgun_angle_spread)
	var start_angle = base_angle - angle_spread_rad * (shotgun_count - 1) / 2.0
	
	for i in range(shotgun_count):
		var angle = start_angle + angle_spread_rad * i
		_fire_single_bullet(angle)

func _update_turret_attributes() -> void:
	var config = Constants.TURRET_CONFIG.get(color, {})
	fire_rate = config.get("fire_rate", 1.0)
	bullet_speed = config.get("bullet_speed", 300.0)
	bullet_damage = config.get("bullet_damage", 20.0)
	detection_range = config.get("detection_range", 200.0)
	bullet_lifetime = config.get("bullet_lifetime", 1.5)
	
	# 霰弹枪配置
	shotgun_enabled = config.get("shotgun_enabled", false)
	shotgun_count = config.get("shotgun_count", 1)
	shotgun_angle_spread = config.get("shotgun_angle_spread", 15.0)
	
	_update_detection_range()

func _update_detection_range() -> void:
	if detection_shape and detection_shape.shape is CircleShape2D:
		detection_shape.shape.radius = detection_range

func update_energy_level() -> void:
	super.update_energy_level()
	_update_turret_attributes()

func _on_detection_area_area_entered(area: Area2D) -> void:
	var enemy = area.get_parent()
	if enemy and enemy.is_in_group("enemy"):
		if not enemy in enemies_in_range:
			enemies_in_range.append(enemy)

func _on_detection_area_area_exited(area: Area2D) -> void:
	var enemy = area.get_parent()
	if enemy and enemy.is_in_group("enemy"):
		enemies_in_range.erase(enemy)
