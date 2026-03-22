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
var _is_being_destroyed: bool = false  # 防止重复销毁

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

func activate() -> void:
	"""激活子弹"""
	_is_active = true
	set_process(true)
	set_physics_process(true)
	set_process_input(true)
	visible = true

func deactivate() -> void:
	"""停用子弹"""
	_is_active = false
	set_process(false)
	set_physics_process(false)
	set_process_input(false)
	visible = false

func get_bullet_type() -> Enums.ColorType:
	return _bullet_type

func init(velocity_: Vector2, damage: int, lifetime_: float, bullet_type_: Enums.ColorType):
	_velocity = velocity_
	_attack_damage = damage
	_lifetime = lifetime_
	max_lifetime = lifetime_
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
		# 检查游戏是否已结束
		var game_manager = GameManager.instance
		if game_manager and game_manager.current_state == GameManager.GameState.GAME_OVER:
			return
		
		# 检查是否是飞行敌人（免疫普通子弹）
		if body is FlyTriangleEnemy:
			var fly_enemy = body as FlyTriangleEnemy
			# 如果子弹不是 MAGIC 类型，完全穿过飞行敌人
			if not _is_magic_bullet() and not fly_enemy.can_be_hit_by_kinetic:
				return
		
		if body.has_method("take_damage"):
			body.take_damage(_attack_damage, self)
		destroy()

func _is_magic_bullet() -> bool:
	"""检查子弹是否是 MAGIC 类型"""
	for attr in attributes:
		if attr == Enums.BulletAttributes.MAGIC:
			return true
	return false

func destroy() -> void:
	# 防止重复销毁
	if _is_being_destroyed:
		return
	
	_is_being_destroyed = true
	_is_active = false
	
	# 使用对象池归还
	if _scene_path != "" and ObjectPoolManager.instance:
		ObjectPoolManager.instance.return_object(_scene_path, self)
	elif is_inside_tree():
		queue_free()

func reset() -> void:
	"""重置子弹状态用于对象池复用"""
	_is_active = false
	_is_being_destroyed = false
	_lifetime = max_lifetime
	_velocity = Vector2.ZERO
	position = Vector2.ZERO
	rotation = 0.0
	_attack_damage = 10
	_bullet_type = Enums.ColorType.WHITE
