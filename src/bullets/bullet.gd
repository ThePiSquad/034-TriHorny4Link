extends Node2D

class_name Bullet

@onready var hit_area_2d: Area2D = $HitArea2D
@onready var shape_drawer: ShapeDrawer = $ShapeDrawer

@export var attributes:Array[Enums.BulletAttributes]

var _attack_damage:int = 10
var _lifetime:float
var max_lifetime:float
var _bullet_type: Enums.ColorType
var _is_active: bool = true
var _velocity: Vector2

func get_attack_damage() -> int:
	return _attack_damage

func set_attack_damage(value: int) -> void:
	_attack_damage = value

func get_velocity() -> Vector2:
	return _velocity

func set_velocity(value: Vector2) -> void:
	_velocity = value

func set_lifetime(value: float) -> void:
	_lifetime = value

func set_bullet_type(value: Enums.ColorType) -> void:
	_bullet_type = value

func set_is_active(value: bool) -> void:
	_is_active = value

func init(velocity_: Vector2, damage: int, lifetime_: float, bullet_type_: Enums.ColorType):
	_velocity = velocity_
	_attack_damage = damage
	_lifetime = lifetime_
	_bullet_type = bullet_type_
	_is_active = true

func _ready() -> void:
	shape_drawer.fill_color = Constants.COLOR_MAP[_bullet_type]

func _process(delta: float) -> void:
	if not _is_active:
		return
	
	position += _velocity * delta
	_lifetime -= delta
	
	if _lifetime <= 0:
		destroy()

func _on_hit_area_2d_area_entered(area: Area2D) -> void:
	var body = area.get_parent()
	if body and body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(_attack_damage, self)
		
		# 检查是否是动能子弹，触发受击效果
		if _is_kinetic_bullet():
			if body.has_method("_on_kinetic_hit"):
				body._on_kinetic_hit(self)
		
		destroy()

func _is_kinetic_bullet() -> bool:
	"""检查是否是动能子弹"""
	for attr in attributes:
		if attr == Enums.BulletAttributes.KINETIC:
			return true
	return false

func destroy() -> void:
	_is_active = false
	queue_free()
