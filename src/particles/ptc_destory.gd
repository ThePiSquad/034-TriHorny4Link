extends GPUParticles2D

var _scene_path: String = ""  # 用于归还到对象池
var _is_returned_to_pool: bool = false  # 标记是否已归还到对象池
var _destruction_timer: SceneTreeTimer = null  # 销毁计时器

func _ready() -> void:
	# 添加到 particle 组，便于管理
	add_to_group("particle")
	
	# 发射粒子
	emitting = true
	
	# 在粒子生命周期结束后自动销毁
	_start_destruction_timer()

func _start_destruction_timer() -> void:
	"""启动销毁计时器"""
	if _destruction_timer:
		# 重用时创建新的计时器
		_destruction_timer = get_tree().create_timer(lifetime + 0.1)
		_destruction_timer.timeout.connect(_on_timer_timeout)
	else:
		# 首次创建
		_destruction_timer = get_tree().create_timer(lifetime + 0.1)
		_destruction_timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout() -> void:
	"""计时器超时回调"""
	destroy()

func start_destruction_timer() -> void:
	"""公开方法，用于对象池复用后手动启动计时器"""
	_start_destruction_timer()

func destroy() -> void:
	"""销毁粒子"""
	if _is_returned_to_pool:
		return
	
	_is_returned_to_pool = true
	
	# 使用对象池归还
	if _scene_path != "" and ObjectPoolManager.instance:
		ObjectPoolManager.instance.return_object(_scene_path, self)
	else:
		queue_free()

func reset() -> void:
	"""重置粒子状态用于对象池复用"""
	_is_returned_to_pool = false
	emitting = false
	visible = false
	# 清理旧计时器（如果有的话）
	_destruction_timer = null

func set_scene_path(path: String) -> void:
	"""设置场景路径用于归还到对象池"""
	_scene_path = path
