extends Node2D

class_name Bullet

#@onready var hit_area_2d: Area2D = $HitArea2D
@onready var shape_drawer: ShapeDrawer = $ShapeDrawer

@export var attributes:Array[Enums.BulletAttributes]

var _attack_damage:int = 10
var _lifetime:float
var max_lifetime:float = 1.0  # 默认值防止为 0
var _bullet_type: Enums.ColorType
var _is_active: bool = false  # 初始为非激活状态
var _velocity: Vector2
var _scene_path: String = ""  # 用于归还到对象池
var _is_returned_to_pool: bool = false  # 标记是否已归还到对象池

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

func get_bullet_type() -> Enums.ColorType:
	return _bullet_type

func init(velocity_: Vector2, damage: int, lifetime_: float, bullet_type_: Enums.ColorType):
	_velocity = velocity_
	_attack_damage = damage
	_lifetime = lifetime_
	_bullet_type = bullet_type_
	_is_active = true
	
	# 立即更新颜色
	if shape_drawer:
		shape_drawer.fill_color = Constants.COLOR_MAP.get(_bullet_type, Color.WHITE)

func set_scene_path(path: String) -> void:
	"""设置场景路径用于归还到对象池"""
	_scene_path = path

func _ready() -> void:
	# 添加到 bullet 组，方便性能监控
	add_to_group("bullet")
	
	if shape_drawer:
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
		destroy()

func destroy() -> void:
	# 防止重复销毁
	if _is_returned_to_pool:
		return
	
	_is_active = false
	_is_returned_to_pool = true
	
	# 使用对象池归还
	if _scene_path != "" and ObjectPoolManager.instance:
		ObjectPoolManager.instance.return_object(_scene_path, self)
	else:
		queue_free()

func reset() -> void:
	"""重置子弹状态用于对象池复用"""
	_is_active = false  # 重置为非激活状态
	_is_returned_to_pool = false
	_lifetime = max_lifetime
	_velocity = Vector2.ZERO
	position = Vector2.ZERO
	rotation = 0.0
