class_name Connection
extends Node2D

## 建筑连接线类
## 实现横平竖直的连接线和能量流动效果

var start_structure: Structure
var end_structure: Structure

@export var style: ConnectionStyle

var line_width: float = 4.0
var line_color: Color = Color.WHITE
var energy_speed: float = 200.0
var energy_intensity: float = 1.0

var _energy_position: float = 0.0
var _line_length: float = 0.0
var _direction: Vector2
var _last_update_time: float = 0.0
var _energy_source: Structure  # 能量源（MonoCrystal）
var _energy_target: Structure  # 能量目标

func initialize(start: Structure, end: Structure) -> void:
	"""初始化连接"""
	start_structure = start
	end_structure = end
	
	# 连接颜色改变信号
	_connect_color_signals()
	
	# 确定能量源和目标
	_determine_energy_source_and_target()
	
	# 设置颜色
	_set_line_color()
	
	# 加载默认样式
	if not style:
		style = load("res://src/components/connection_style.tres")
		if style:
			_update_from_style()
	
	update()

func _connect_color_signals() -> void:
	"""连接颜色改变信号"""
	if start_structure and start_structure.has_signal("color_changed"):
		if not start_structure.color_changed.is_connected(_on_structure_color_changed):
			start_structure.color_changed.connect(_on_structure_color_changed)
	
	if end_structure and end_structure.has_signal("color_changed"):
		if not end_structure.color_changed.is_connected(_on_structure_color_changed):
			end_structure.color_changed.connect(_on_structure_color_changed)

func _on_structure_color_changed(color_type: Enums.ColorType) -> void:
	"""当建筑颜色改变时更新连接线颜色"""
	_set_line_color()
	queue_redraw()

func _disconnect_color_signals() -> void:
	"""断开颜色改变信号"""
	if start_structure and start_structure.has_signal("color_changed"):
		if start_structure.color_changed.is_connected(_on_structure_color_changed):
			start_structure.color_changed.disconnect(_on_structure_color_changed)
	
	if end_structure and end_structure.has_signal("color_changed"):
		if end_structure.color_changed.is_connected(_on_structure_color_changed):
			end_structure.color_changed.disconnect(_on_structure_color_changed)

func _update_from_style() -> void:
	"""从样式更新属性"""
	if style:
		line_width = style.line_width
		energy_speed = style.energy_speed
		energy_intensity = style.energy_intensity

func _determine_energy_source_and_target() -> void:
	"""确定能量源和目标"""
	# 检查是否有 Crystal 或 MonoCrystal
	var start_is_crystal = start_structure and is_instance_valid(start_structure) and start_structure.get_structure_type() == Enums.StructureType.CRYSTAL
	var end_is_crystal = end_structure and is_instance_valid(end_structure) and end_structure.get_structure_type() == Enums.StructureType.CRYSTAL
	
	var start_is_mono = start_structure and is_instance_valid(start_structure) and start_structure.get_structure_type() == Enums.StructureType.MONO_CRYSTAL
	var end_is_mono = end_structure and is_instance_valid(end_structure) and end_structure.get_structure_type() == Enums.StructureType.MONO_CRYSTAL
	
	if start_is_mono and end_is_crystal:
		# MonoCrystal 是能量源，Crystal 是能量目标
		_energy_source = start_structure
		_energy_target = end_structure
	elif end_is_mono and start_is_crystal:
		# MonoCrystal 是能量源，Crystal 是能量目标
		_energy_source = end_structure
		_energy_target = start_structure
	elif start_is_crystal and not end_is_crystal:
		# Crystal 是能量源，另一个建筑是能量目标
		_energy_source = start_structure
		_energy_target = end_structure
	elif end_is_crystal and not start_is_crystal:
		# Crystal 是能量源，另一个建筑是能量目标
		_energy_source = end_structure
		_energy_target = start_structure
	else:
		# 两个都是或都不是 Crystal，默认从 start 到 end
		_energy_source = start_structure
		_energy_target = end_structure

func _set_line_color() -> void:
	"""设置连接线颜色"""
	# 特殊情况：如果是 MonoCrystal 到 Crystal 的连接，使用 MonoCrystal 的颜色
	if _energy_source and is_instance_valid(_energy_source):
		if _energy_source.get_structure_type() == Enums.StructureType.MONO_CRYSTAL:
			# 获取 MonoCrystal 的颜色
			var mono_color_type = _energy_source.color
			line_color = Constants.COLOR_MAP.get(mono_color_type, Color.WHITE)
			return
	
	# 普通情况：智能选择颜色：根据邻居的能量等级选择颜色
	var color_type = _determine_color_from_neighbors()
	line_color = Constants.COLOR_MAP.get(color_type, Color.WHITE)

func _determine_color_from_neighbors() -> Enums.ColorType:
	"""根据邻居的能量等级智能选择颜色"""
	# 获取两个建筑的能量等级
	var start_energy = _get_structure_energy(start_structure)
	var end_energy = _get_structure_energy(end_structure)
	
	# 合并能量等级
	var combined_energy = EnergyLevel.new()
	if start_energy:
		combined_energy.add(start_energy)
	if end_energy:
		combined_energy.add(end_energy)
	
	# 根据合并后的能量等级选择颜色
	return combined_energy.get_color()

func _get_structure_energy(structure: Structure) -> EnergyLevel:
	"""获取建筑的能量等级"""
	if not structure or not is_instance_valid(structure):
		return null
	
	if "energy_level" in structure:
		return structure.energy_level
	
	return null

func refresh_color() -> void:
	"""刷新连接线颜色"""
	_set_line_color()
	queue_redraw()

func update() -> void:
	"""更新连接"""
	if not start_structure or not end_structure or not is_instance_valid(start_structure) or not is_instance_valid(end_structure):
		_disconnect_color_signals()
		queue_free()
		return
	
	# 计算连接线路径
	var start_pos = start_structure.global_position
	var end_pos = end_structure.global_position
	
	# 确保横平竖直的路径
	if abs(start_pos.x - end_pos.x) > abs(start_pos.y - end_pos.y):
		# 水平优先
		_line_length = abs(start_pos.x - end_pos.x)
		_direction = Vector2(1 if end_pos.x > start_pos.x else -1, 0)
	else:
		# 垂直优先
		_line_length = abs(start_pos.y - end_pos.y)
		_direction = Vector2(0, 1 if end_pos.y > start_pos.y else -1)

func _process(delta: float) -> void:
	"""处理能量流动"""
	# 性能优化：限制更新频率
	_last_update_time += delta
	if _last_update_time < 0.016:  # 约60fps
		return
	_last_update_time = 0.0
	
	_energy_position += energy_speed * delta
	if _energy_position > _line_length:
		_energy_position = 0
	queue_redraw()

func _draw() -> void:
	"""绘制连接线和能量流动"""
	if not start_structure or not end_structure or not is_instance_valid(start_structure) or not is_instance_valid(end_structure):
		return
	
	var start_pos = start_structure.global_position
	var end_pos = end_structure.global_position
	
	# 绘制主线
	draw_line(start_pos, end_pos, line_color, line_width)
	
	# 绘制能量流动
	if _line_length > 0 and _energy_source and _energy_target and is_instance_valid(_energy_source) and is_instance_valid(_energy_target):
		var source_pos = _energy_source.global_position
		var target_pos = _energy_target.global_position
		var energy_pos = _energy_position
		
		# 计算能量流动方向向量
		var flow_direction = (target_pos - source_pos).normalized()
		
		# 计算能量位置
		var energy_current_pos = source_pos + flow_direction * energy_pos
		var energy_next_pos = source_pos + flow_direction * min(energy_pos + 20, _line_length)
		
		# 绘制能量流动效果
		var energy_color = line_color * energy_intensity
		draw_line(energy_current_pos, energy_next_pos, energy_color, line_width * 1.5)

func _exit_tree() -> void:
	"""清理信号连接"""
	_disconnect_color_signals()
