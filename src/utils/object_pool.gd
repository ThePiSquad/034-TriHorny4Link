extends Node
class_name ObjectPool

## 优化的对象池类 - 用于优化频繁创建/销毁的对象
## 适用于子弹、粒子等短生命周期对象

var _pool: Array = []
var _scene: PackedScene
var _parent: Node
var _pool_size: int = 0
var _active_count: int = 0  # 直接计数，不使用数组

# 调试日志配置
var _enable_debug_log: bool = false  # 默认关闭调试日志

func _init(scene: PackedScene, parent: Node, initial_size: int = 20) -> void:
	_scene = scene
	_parent = parent
	_pool_size = initial_size
	_initialize_pool()

func _initialize_pool() -> void:
	"""初始化对象池"""
	for i in range(_pool_size):
		var obj = _scene.instantiate()
		# 初始化为非激活状态
		_set_object_active(obj, false)
		_parent.add_child(obj)
		_pool.append(obj)

func _set_object_active(obj: Node, active: bool) -> void:
	"""设置对象激活状态"""
	# 优先使用子弹类的 activate/deactivate 方法
	if obj.has_method("activate") and active:
		obj.activate()
	elif obj.has_method("deactivate") and not active:
		obj.deactivate()
	else:
		# 通用方法
		obj.set_process(active)
		obj.set_process_input(active)
		obj.set_physics_process(active)
		obj.visible = active

func get_object() -> Node:
	"""从池中获取对象"""
	var obj: Node = null
	
	if _pool.size() > 0:
		obj = _pool.pop_back()
		if not is_instance_valid(obj):
			_active_count = max(0, _active_count - 1)
			return get_object()
	else:
		obj = _create_new_object()
	
	if obj and is_instance_valid(obj):
		_set_object_active_deferred(obj, true)
		_active_count += 1
		
		if _enable_debug_log:
			var timestamp = Time.get_datetime_string_from_system()
			print("[对象池][%s] 借出：%s 实例ID:%d 活跃数=%d" % [timestamp, _scene.resource_path.get_file(), obj.get_instance_id(), _active_count])
	
	return obj

func cleanup_invalid_objects() -> void:
	"""清理池中的无效对象（外部定期调用）"""
	var valid_objects = []
	for obj in _pool:
		if is_instance_valid(obj):
			valid_objects.append(obj)
		else:
			# 对象无效，减少计数
			_active_count = max(0, _active_count - 1)
	_pool = valid_objects

func _create_new_object() -> Node:
	"""创建新对象并添加到场景树"""
	var obj = _scene.instantiate()
	_parent.add_child(obj)
	_set_object_active_deferred(obj, true)
	_active_count += 1
	return obj

func _set_object_active_deferred(obj: Node, active: bool) -> void:
	"""延迟设置对象激活状态，避免在物理查询期间改变状态"""
	if obj.has_method("activate") and active:
		obj.call_deferred("activate")
	elif obj.has_method("deactivate") and not active:
		obj.call_deferred("deactivate")
	else:
		obj.call_deferred("set_visible", active)

func return_object(obj: Node) -> void:
	"""归还对象到池中"""
	if not is_instance_valid(obj):
		_active_count = max(0, _active_count - 1)
		if _enable_debug_log:
			var timestamp = Time.get_datetime_string_from_system()
			print("[对象池][%s] 归还：无效对象 活跃数=%d" % [timestamp, _active_count])
		return
	
	if obj.has_method("reset"):
		obj.call_deferred("reset")
	
	_set_object_active_deferred(obj, false)
	obj.call_deferred("set_position", Vector2(-10000, -10000))
	
	_pool.append(obj)
	_active_count = max(0, _active_count - 1)
	
	if _enable_debug_log:
		var timestamp = Time.get_datetime_string_from_system()
		print("[对象池][%s] 归还：%s 实例ID:%d 活跃数=%d" % [timestamp, _scene.resource_path.get_file(), obj.get_instance_id(), _active_count])

func get_active_count() -> int:
	"""获取当前活跃对象数量"""
	return _active_count

func get_pool_count() -> int:
	"""获取池中对象数量"""
	return _pool.size()

func get_stats() -> Dictionary:
	"""获取池的统计信息"""
	return {
		"active": _active_count,
		"pooled": _pool.size()
	}

func enable_debug_log(enable: bool) -> void:
	"""启用或禁用调试日志"""
	_enable_debug_log = enable

func is_debug_log_enabled() -> bool:
	"""检查调试日志是否启用"""
	return _enable_debug_log

func clear_pool() -> void:
	"""清理所有对象"""
	for obj in _pool:
		if is_instance_valid(obj):
			obj.queue_free()
	_pool.clear()
	_active_count = 0
