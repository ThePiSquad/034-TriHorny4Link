extends Node
class_name ObjectPool

## 对象池类 - 用于优化频繁创建/销毁的对象
## 适用于子弹、粒子等短生命周期对象

var _pool: Array = []
var _scene: PackedScene
var _parent: Node
var _pool_size: int = 0
var _active_objects: Array = []

func _init(scene: PackedScene, parent: Node, initial_size: int = 20) -> void:
	_scene = scene
	_parent = parent
	_pool_size = initial_size
	_initialize_pool()

func _initialize_pool() -> void:
	"""初始化对象池"""
	var hidden_position = Vector2(-10000, -10000)  # 隐藏位置
	
	for i in range(_pool_size):
		var obj = _scene.instantiate()
		obj.set_process(false)
		obj.set_process_input(false)
		obj.set_physics_process(false)
		obj.visible = false
		obj.position = hidden_position  # 将对象移到隐藏位置
		
		# 确保对象处于非激活状态
		if obj.has_method("set_active"):
			obj.set_active(false)
		if obj.has_method("_set_active"):
			obj._set_active(false)
		
		_parent.add_child(obj)
		_pool.append(obj)

func get_object() -> Node:
	"""从池中获取对象"""
	var obj: Node = null
	
	# 清理池中的无效对象
	_cleanup_invalid_pooled_objects()
	
	# 清理活跃对象列表中的无效对象
	_cleanup_invalid_active_objects()
	
	if _pool.size() > 0:
		obj = _pool.pop_back()
		# 验证对象是否有效
		if not is_instance_valid(obj):
			# 对象无效，创建新对象
			obj = _scene.instantiate()
			_parent.add_child(obj)
	else:
		# 池为空，创建新对象
		obj = _scene.instantiate()
		_parent.add_child(obj)
	
	if obj and is_instance_valid(obj):
		obj.set_process(true)
		obj.visible = true
		_active_objects.append(obj)
	
	return obj

func _cleanup_invalid_active_objects() -> void:
	"""清理活跃对象列表中的无效对象"""
	var valid_objects = []
	for obj in _active_objects:
		if is_instance_valid(obj):
			valid_objects.append(obj)
	_active_objects = valid_objects

func return_object(obj: Node) -> void:
	"""归还对象到池中"""
	if not is_instance_valid(obj):
		# 对象已无效，直接返回
		return
	
	if obj in _active_objects:
		_active_objects.erase(obj)
		obj.set_process(false)
		obj.set_process_input(false)
		obj.set_physics_process(false)
		obj.visible = false
		
		# 重置对象状态（如果对象有 reset 方法）
		if obj.has_method("reset"):
			obj.reset()
		
		# 将对象移到隐藏位置
		obj.position = Vector2(-10000, -10000)
		
		_pool.append(obj)

func _cleanup_invalid_pooled_objects() -> void:
	"""清理池中的无效对象"""
	var valid_objects = []
	for obj in _pool:
		if is_instance_valid(obj):
			valid_objects.append(obj)
	_pool = valid_objects

func get_active_count() -> int:
	"""获取当前活跃对象数量"""
	return _active_objects.size()

func get_pool_count() -> int:
	"""获取池中对象数量"""
	return _pool.size()

func clear_pool() -> void:
	"""清理所有对象"""
	for obj in _pool:
		if is_instance_valid(obj):
			obj.queue_free()
	_pool.clear()
	_active_objects.clear()
