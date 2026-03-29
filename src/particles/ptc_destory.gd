extends GPUParticles2D

var _scene_path: String = ""
var _is_returned_to_pool: bool = false
var _destruction_timer: SceneTreeTimer = null
var _timer_connection: Callable = Callable()

func _ready() -> void:
	add_to_group("particle")
	emitting = true
	_start_destruction_timer()

func _start_destruction_timer() -> void:
	# 断开旧连接
	if _timer_connection.is_valid() and _destruction_timer and _destruction_timer.timeout.is_connected(_timer_connection):
		_destruction_timer.timeout.disconnect(_timer_connection)
	
	# 创建新计时器，延长等待时间确保粒子完全播放
	var wait_time = lifetime + 0.3
	_destruction_timer = get_tree().create_timer(wait_time)
	_timer_connection = _on_timer_timeout
	_destruction_timer.timeout.connect(_timer_connection)

func _on_timer_timeout() -> void:
	destroy()

func start_destruction_timer() -> void:
	_start_destruction_timer()

func destroy() -> void:
	if _is_returned_to_pool:
		return
	
	_is_returned_to_pool = true
	
	if _scene_path != "" and ObjectPoolManager.instance:
		call_deferred("_return_to_pool")
	else:
		queue_free()

func _return_to_pool() -> void:
	if ObjectPoolManager.instance and is_instance_valid(self):
		ObjectPoolManager.instance.return_object(_scene_path, self)

func reset() -> void:
	_is_returned_to_pool = false
	emitting = false
	visible = false
	_destruction_timer = null
	# 注意：不再重置颜色，因为不同的粒子类型有不同的颜色
	# 颜色应该在激活时由使用者设置，或者保持原始场景中定义的默认颜色

func set_scene_path(path: String) -> void:
	_scene_path = path

func activate() -> void:
	_is_returned_to_pool = false
	visible = true
	one_shot = true
	emitting = true
	restart()
	_start_destruction_timer()
