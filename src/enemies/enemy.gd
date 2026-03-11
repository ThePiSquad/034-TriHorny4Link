class_name Enemy
extends Damageable

@onready var shape_drawer: ShapeDrawer = $ShapeDrawer

@export var move_speed: float = 100.0
@export var attack_damage: float = 10.0
@export var enemy_size: Vector2 = Vector2(Constants.grid_size, Constants.grid_size)

# 随机旋转功能
@export var random_initial_rotation: bool = false
"""
是否在敌人初始生成时对绘制的图形应用随机旋转效果
- true: 启用随机旋转，范围为0-360度
- false: 保持原始旋转角度不变
"""

var direction: Vector2
var base_position: Vector2 = Vector2.ZERO

# 屏障相关
var _blocked_by_barrier: bool = false
var _barrier_hit_cooldown: float = 0.0
var _current_barrier: Node2D = null
var _attack_interval: float = 1.0  # 攻击间隔（秒）
var _attack_timer: float = 0.0

func _initialize_shape() -> void:
	shape_drawer.shape_size = enemy_size

func set_base_position(dest_position: Vector2) -> void:
	base_position = dest_position

func _ready() -> void:
	super._ready()
	_initialize_shape()
	
	# 应用随机旋转效果（如果启用）
	if random_initial_rotation and shape_drawer:
		var random_angle = randf_range(0.0, 360.0)
		shape_drawer.rotation_degrees = random_angle
		print("敌人随机旋转角度: ", random_angle, " 度")
	
	died.connect(_on_damageable_died)

func _on_damageable_died(source: Node) -> void:
	# 断开屏障的死亡信号连接
	if _current_barrier and _current_barrier.has_signal("died"):
		if _current_barrier.died.is_connected(_on_barrier_destroyed):
			_current_barrier.died.disconnect(_on_barrier_destroyed)
	
	queue_free()

func _process(delta: float) -> void:
	# 更新屏障冷却计时器
	if _barrier_hit_cooldown > 0:
		_barrier_hit_cooldown -= delta
	
	# 如果有当前屏障，持续攻击
	if _current_barrier:
		# 检查屏障是否仍然有效（在场景中且未被摧毁）
		var is_barrier_valid = false
		if _current_barrier.is_inside_tree():
			# 检查是否有生命值方法
			if _current_barrier.has_method("get_health"):
				is_barrier_valid = _current_barrier.get_health() > 0
			else:
				# 如果没有生命值方法，检查是否在场景中
				is_barrier_valid = true
		
		if is_barrier_valid:
			_attack_timer += delta
			if _attack_timer >= _attack_interval:
				_attack_timer = 0.0
				_attack_barrier(_current_barrier)
		else:
			# 屏障已被摧毁，恢复移动
			print("屏障已被摧毁，恢复移动")
			_current_barrier = null
			_blocked_by_barrier = false
	
	_update_movement(delta)

func _update_movement(delta: float) -> void:
	if global_position != base_position:
		direction = (base_position - global_position).normalized()
		_avoid_conduits(direction)
		
		# 如果没有被屏障阻挡，则移动
		if not _blocked_by_barrier:
			global_position += direction * move_speed * delta

func _avoid_conduits(direction: Vector2) -> void:
	pass

func _on_hitbox_area_entered(area: Area2D) -> void:
	# 获取Area2D的父节点（实际的Structure对象）
	var body = area.get_parent()
	if body and body.has_method("get_structure_type"):
		if body.get_structure_type() == Enums.StructureType.CRYSTAL:
			body.take_damage(attack_damage, self)
			take_damage(max_health, self) # 自毁

func on_barrier_hit(barrier: Node2D) -> void:
	"""被屏障阻挡时的回调"""
	if _barrier_hit_cooldown > 0:
		return
	
	print("敌人被屏障阻挡")
	_blocked_by_barrier = true
	_current_barrier = barrier
	_barrier_hit_cooldown = 0.5  # 冷却时间0.5秒
	_attack_timer = 0.0  # 重置攻击计时器
	
	# 连接屏障的死亡信号
	if barrier.has_signal("died") and not barrier.died.is_connected(_on_barrier_destroyed):
		barrier.died.connect(_on_barrier_destroyed)
	
	# 立即进行第一次攻击
	_attack_barrier(barrier)

func _on_barrier_destroyed(source: Node) -> void:
	"""屏障被摧毁时的回调"""
	print("屏障被摧毁信号触发")
	_current_barrier = null
	_blocked_by_barrier = false

func _attack_barrier(barrier: Node2D) -> void:
	"""攻击屏障"""
	if barrier and barrier.has_method("take_damage"):
		barrier.take_damage(attack_damage, self)
		print("敌人攻击屏障，造成伤害: ", attack_damage)
