extends CanvasLayer

## 场景切换管理器
## 负责管理场景加载、卸载和转场动画

signal transition_started
signal transition_completed
signal scene_loaded

# 转场配置
@export var default_transition_duration: float = 1.0
@export var transition_shader: ShaderMaterial
@export var default_scene_path: String = "res://src/main_menu.tscn"

# 内部状态
var _is_transitioning: bool = false
var _current_scene: Node
var _transition_overlay: ColorRect
var _tween: Tween
var _shader_material: ShaderMaterial

# 单例实例
static var instance: TransitionManager

func _ready() -> void:
	instance = self
	_setup_transition_overlay()
	
	# 保持在场景切换时不被删除
	set_process_internal(true)

func _setup_transition_overlay() -> void:
	"""设置转场覆盖层"""
	# 尝试从子节点获取 ColorRect
	if has_node("ColorRect"):
		_transition_overlay = $ColorRect
		if _transition_overlay.material is ShaderMaterial:
			_shader_material = _transition_overlay.material as ShaderMaterial
	else:
		# 如果没有子节点，动态创建
		_transition_overlay = ColorRect.new()
		_transition_overlay.name = "TransitionOverlay"
		_transition_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		_transition_overlay.color = Color.BLACK
		_transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# 应用 Shader（如果有）
		if transition_shader:
			_shader_material = transition_shader
		else:
			# 创建默认 Shader
			_shader_material = ShaderMaterial.new()
			_shader_material.shader = load("res://src/shaders/transition_shader.gdshader")
		
		_transition_overlay.material = _shader_material
		add_child(_transition_overlay)
	
	_transition_overlay.visible = false

func change_scene(scene_path: String, transition_duration: float = -1.0) -> void:
	"""
	切换到新场景
	
	参数:
		scene_path: 目标场景路径
		transition_duration: 转场持续时间（-1 使用默认值）
	"""
	if _is_transitioning:
		push_warning("SceneTransitionManager: 转场正在进行中，忽略新的请求")
		return
	
	if not ResourceLoader.exists(scene_path):
		push_error("SceneTransitionManager: 场景文件不存在 - " + scene_path)
		return
	
	if transition_duration < 0:
		transition_duration = default_transition_duration
	
	_is_transitioning = true
	transition_started.emit()
	
	# 异步加载场景
	var loader = ResourceLoader.load_threaded_request(scene_path)
	
	# 等待加载完成
	while ResourceLoader.load_threaded_get_status(scene_path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
	
	# 检查加载状态
	var load_status = ResourceLoader.load_threaded_get_status(scene_path)
	if load_status != ResourceLoader.THREAD_LOAD_LOADED:
		push_error("SceneTransitionManager: 场景加载失败 - " + scene_path)
		_is_transitioning = false
		return
	
	# 获取加载的资源
	var new_scene: PackedScene = ResourceLoader.load_threaded_get(scene_path)
	
	if not new_scene:
		push_error("SceneTransitionManager: 无法实例化场景 - " + scene_path)
		_is_transitioning = false
		return
	
	# 执行转场动画
	await _play_transition(transition_duration / 2.0)
	
	# 切换场景
	_swap_scene(new_scene)
	scene_loaded.emit()
	
	# 完成转场
	await _play_transition(transition_duration / 2.0, false)
	
	_is_transitioning = false
	transition_completed.emit()

func _swap_scene(new_scene: PackedScene) -> void:
	"""切换场景"""
	var tree = get_tree()
	
	# 保存当前场景
	var current_scene = tree.current_scene
	
	# 实例化新场景
	var instance = new_scene.instantiate()
	
	# 添加新场景
	tree.root.add_child(instance)
	
	# 设置为当前场景
	tree.current_scene = instance
	
	# 释放旧场景
	if current_scene:
		current_scene.queue_free()
	
	_current_scene = instance

func _play_transition(duration: float, fade_in: bool = true) -> void:
	"""播放转场动画"""
	if _tween and _tween.is_valid():
		_tween.kill()
	
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_IN_OUT)
	
	_transition_overlay.visible = true
	
	if _shader_material:
		# 使用 Shader 进行转场
		if fade_in:
			# 切入
			_shader_material.set_shader_parameter("position", 1.0)
			_tween.tween_method(
				func(value): _shader_material.set_shader_parameter("position", value),
				1.0,
				-1.5,
				duration
			)
		else:
			# 切出
			_shader_material.set_shader_parameter("position", -1.5)
			_tween.tween_method(
				func(value): _shader_material.set_shader_parameter("position", value),
				-1.5,
				1.0,
				duration
			)
			_tween.tween_callback(func(): _transition_overlay.visible = false)
	else:
		# 回退到简单的 alpha 渐变
		if fade_in:
			# 淡入（变黑）
			_tween.tween_property(_transition_overlay, "color:a", 1.0, duration)
		else:
			# 淡出（恢复）
			_tween.tween_property(_transition_overlay, "color:a", 0.0, duration)
			_tween.tween_callback(func(): _transition_overlay.visible = false)
	
	await _tween.finished

func fade_to_black(duration: float = 1.0, callback: Callable = Callable()) -> void:
	"""淡入黑色（不切换场景）"""
	if _tween and _tween.is_valid():
		_tween.kill()
	
	_transition_overlay.visible = true
	
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(_transition_overlay, "color:a", 1.0, duration)
	_tween.tween_callback(func():
		if callback.is_valid():
			callback.call()
	)

func fade_from_black(duration: float = 1.0, callback: Callable = Callable()) -> void:
	"""从黑色淡出"""
	if _tween and _tween.is_valid():
		_tween.kill()
	
	_transition_overlay.visible = true
	
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(_transition_overlay, "color:a", 0.0, duration)
	_tween.tween_callback(func():
		_transition_overlay.visible = false
		if callback.is_valid():
			callback.call()
	)

func is_transitioning() -> bool:
	"""检查是否正在转场"""
	return _is_transitioning

func get_current_scene() -> Node:
	"""获取当前场景"""
	return _current_scene
