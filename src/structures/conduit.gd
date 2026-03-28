extends EnergyTransmitter
class_name Conduit

@onready var barrier_body: StaticBody2D = $BarrierBody
@onready var barrier_area: Area2D = $BarrierArea

# 屏障功能
@export var is_barrier: bool = false
"""
是否启用屏障功能
- true: Conduit作为物理屏障，阻挡敌人移动
- false: Conduit仅作为导线，不阻挡敌人
"""

var barrier_collision : CollisionShape2D
var _blocking_enemies: Array[Node] = []

func _ready() -> void:
	super._ready()
	structure_type = Enums.StructureType.CONDUIT
	
	for child in barrier_body.get_children():
			if child is CollisionShape2D:
				barrier_collision = child
	
	if barrier_collision == null:
		print("未找到Conduit的阻挡碰撞Shape")
	
	_update_barrier_state()

func _init() -> void:
	structure_type = Enums.StructureType.CONDUIT

func set_barrier_enabled(enabled: bool) -> void:
	is_barrier = enabled
	_update_barrier_state()

func _update_barrier_state() -> void:
	if barrier_body:
		barrier_collision.disabled = not is_barrier
	if barrier_area:
		barrier_area.monitoring = is_barrier
	_update_barrier_visual()

func _update_barrier_visual() -> void:
	if not shape_drawer:
		return
	
	shape_drawer.stroke_enabled = true
	shape_drawer.stroke_width = 1.0
	#shape_drawer.stroke_color = Color.GRAY
	#if is_barrier:
		## 屏障模式：显示更粗的边框
		#shape_drawer.stroke_enabled = true
		#shape_drawer.stroke_width = 1.0
		#shape_drawer.stroke_color = Color.GRAY
	#else:
		## 导线模式：正常显示
		#shape_drawer.stroke_enabled = false

func _on_barrier_area_entered(area: Area2D) -> void:
	if not is_barrier:
		return
	
	# 获取 Area2D 的父节点（实际的敌人对象）
	var body = area.get_parent()
	if body and body.has_method("on_barrier_hit"):
		# 检查是否是飞行敌人，飞行敌人不受阻挡
		if body is FlyEnemy:
			var fly_enemy = body as FlyEnemy
			if fly_enemy.is_flying:
				return  # 飞行敌人直接穿过，不触发屏障
		
		if not body in _blocking_enemies:
			_blocking_enemies.append(body)
		
		body.on_barrier_hit(self)

func _on_barrier_area_area_exited(area: Area2D) -> void:
	if not is_barrier:
		return
	
	var body = area.get_parent()
	if body and body in _blocking_enemies:
		_blocking_enemies.erase(body)
		if body.has_method("on_barrier_exit"):
			body.on_barrier_exit(self)

func is_blocking_enemy(enemy: Node) -> bool:
	"""检查敌人是否仍在阻挡范围内"""
	return enemy in _blocking_enemies
