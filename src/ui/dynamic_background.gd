extends Node2D
class_name DynamicBackground

@export var grid_size: float = 64.0
@export var background_scale: float = 0.8  # 背景缩放比例
@export var opacity: float = 0.3  # 背景透明度

# 具体结构场景
var _turret_scene: PackedScene
var _conduit_scene: PackedScene
var _mono_crystal_scene: PackedScene

var _background_elements: Array[Node2D] = []
var _animation_speed: float = 0.5  # 动画速度

func _ready() -> void:
	# 加载具体结构场景
	_turret_scene = load("res://src/structures/turret.tscn")
	_conduit_scene = load("res://src/structures/conduit.tscn")
	_mono_crystal_scene = load("res://src/structures/mono_crystal.tscn")
	
	# 生成背景元素
	_generate_background_elements()
	
	# 启动动画
	_start_animation()

func _generate_background_elements() -> void:
	"""生成背景元素"""
	var screen_size = get_viewport_rect().size
	var grid_cols = int(screen_size.x / grid_size) + 2
	var grid_rows = int(screen_size.y / grid_size) + 2
	
	# 随机生成结构
	for i in range(20):  # 生成20个随机结构
		_generate_random_structure(grid_cols, grid_rows)

func _generate_random_structure(grid_cols: int, grid_rows: int) -> void:
	"""生成随机结构"""
	# 随机选择结构类型
	var structure_type = _get_random_structure_type()
	
	# 根据类型选择对应的场景
	var scene: PackedScene = null
	match structure_type:
		Enums.StructureType.TURRET:
			scene = _turret_scene
		Enums.StructureType.CONDUIT:
			scene = _conduit_scene
		Enums.StructureType.MONO_CRYSTAL:
			scene = _mono_crystal_scene
	
	if not scene:
		return
	
	# 随机位置
	var grid_x = randi_range(-2, grid_cols)
	var grid_y = randi_range(-2, grid_rows)
	var position = Vector2(grid_x * grid_size, grid_y * grid_size)
	
	# 创建结构
	var structure = scene.instantiate()
	if not structure:
		return
	
	# 设置结构属性
	_setup_structure(structure, structure_type, position)
	
	# 添加到场景
	add_child(structure)
	_background_elements.append(structure)

func _get_random_structure_type() -> Enums.StructureType:
	"""获取随机结构类型"""
	var types = [
		Enums.StructureType.TURRET,
		Enums.StructureType.CONDUIT,
		Enums.StructureType.MONO_CRYSTAL
	]
	return types.pick_random()

func _setup_structure(structure: Node2D, type: Enums.StructureType, position: Vector2) -> void:
	"""设置结构属性"""
	structure.global_position = position
	
	# 禁用音效（背景元素不播放音效）
	if structure.has_method("set"):
		structure.set("play_sound", false)
	
	# 设置结构类型
	if structure.has_method("set_structure_type"):
		structure.set_structure_type(type)
	
	# 设置颜色（使用低饱和度颜色）
	if structure.has_method("set_color_type"):
		var color_type = _get_random_color_type()
		structure.set_color_type(color_type)
	
	# 应用背景效果
	_apply_background_effect(structure)
	
	# 随机旋转
	if structure.has_method("set_rotation_degrees"):
		structure.rotation_degrees = randf_range(0, 360)

func _get_random_color_type() -> Enums.ColorType:
	"""获取随机颜色类型"""
	var types = [
		Enums.ColorType.RED,
		Enums.ColorType.BLUE,
		Enums.ColorType.YELLOW
	]
	return types.pick_random()

func _apply_background_effect(structure: Node2D) -> void:
	"""应用背景效果（低强度视觉表现）"""
	# 查找 ShapeDrawer
	var shape_drawer = structure.find_child("ShapeDrawer", true, false)
	if shape_drawer and shape_drawer.has_method("set_modulate"):
		# 降低透明度和饱和度
		var color = Color(0.5, 0.5, 0.5, opacity)
		shape_drawer.set_modulate(color)
	
	# 查找其他视觉组件
	for child in structure.get_children():
		if child is CanvasItem:
			child.modulate.a = opacity

func _start_animation() -> void:
	"""启动背景动画"""
	# 为每个背景元素添加缓慢的漂浮动画
	for element in _background_elements:
		_add_float_animation(element)

func _add_float_animation(element: Node2D) -> void:
	"""添加漂浮动画"""
	var tween = create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	# 随机动画参数
	var float_distance = randf_range(5, 15)
	var float_duration = randf_range(3, 6)
	var initial_y = element.global_position.y
	
	tween.tween_property(element, "global_position:y", initial_y + float_distance, float_duration)
	tween.tween_property(element, "global_position:y", initial_y - float_distance, float_duration)

func cleanup() -> void:
	"""清理背景元素"""
	for element in _background_elements:
		if is_instance_valid(element):
			element.queue_free()
	_background_elements.clear()
