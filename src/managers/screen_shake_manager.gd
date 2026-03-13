class_name ScreenShakeManager
extends Node

## 屏幕抖动管理器
## 负责管理和播放屏幕抖动效果

@export var camera: Camera2D

# 抖动配置参数
@export var default_duration: float = 0.3  # 默认抖动持续时间（秒）
@export var default_intensity: float = 10.0  # 默认抖动强度

# 抖动状态
var _is_shaking: bool = false
var _shake_duration: float = 0.0
var _shake_timer: float = 0.0
var _shake_intensity: float = 0.0
var _original_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	if not camera:
		camera = get_viewport().get_camera_2d()
	
	if camera:
		_original_offset = camera.offset

func _process(delta: float) -> void:
	if not _is_shaking:
		return
	
	# 更新抖动计时器
	_shake_timer += delta
	
	# 计算衰减系数（从 1.0 逐渐衰减到 0.0）
	var decay = 1.0 - (_shake_timer / _shake_duration)
	decay = max(0.0, decay)
	
	# 应用抖动效果
	if decay > 0.0:
		_apply_shake(decay)
	else:
		_stop_shake()

func _apply_shake(decay: float) -> void:
	"""应用抖动效果"""
	if not camera:
		return
	
	# 计算当前强度
	var current_intensity = _shake_intensity * decay
	
	# 生成随机抖动偏移
	var shake_offset = Vector2(
		randf_range(-current_intensity, current_intensity),
		randf_range(-current_intensity, current_intensity)
	)
	
	# 应用抖动
	camera.offset = _original_offset + shake_offset

func _stop_shake() -> void:
	"""停止抖动效果"""
	_is_shaking = false
	_shake_timer = 0.0
	_shake_duration = 0.0
	_shake_intensity = 0.0
	
	if camera:
		camera.offset = _original_offset

func shake(duration: float = -1.0, intensity: float = -1.0) -> void:
	"""
	触发屏幕抖动效果
	
	参数:
		duration: 抖动持续时间（秒），-1 表示使用默认值
		intensity: 抖动强度，-1 表示使用默认值
	"""
	var actual_duration = duration if duration > 0 else default_duration
	var actual_intensity = intensity if intensity > 0 else default_intensity
	
	# 如果已经在抖动，取更大的强度
	if _is_shaking:
		actual_intensity = max(_shake_intensity, actual_intensity)
		actual_duration = max(_shake_duration, actual_duration)
	
	_is_shaking = true
	_shake_duration = actual_duration
	_shake_timer = 0.0
	_shake_intensity = actual_intensity
	
	# 保存原始偏移
	if camera:
		_original_offset = camera.offset

func is_shaking() -> bool:
	"""检查是否正在抖动"""
	return _is_shaking
