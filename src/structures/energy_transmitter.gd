class_name EnergyTransmitter
extends Structure

# 能量强度
var _energy_intensity: float = 0.0

func _ready() -> void:
	super._ready()
	# 初始颜色更新
	_update_color_from_neighbors()

func on_neighbor_update() -> void:
	# 当邻居更新时，重新计算自身能量
	update_energy_level()

func update_energy_level() -> void:
	# 从邻居获取能量（只选择最强能量源，不叠加）
	var new_level: EnergyLevel = EnergyLevel.new()
	var min_distance: int = Constants.MAX_ENERGY_RANGE
	
	# 从所有邻居收集能量，考虑距离衰减
	var neighbors = [north, south, west, east]
	for neighbor in neighbors:
		if neighbor != null and not neighbor.energy_level.is_empty():
			# 获取邻居的能量（经过1格衰减）
			var decayed_energy = neighbor.energy_level.decay(1)
			
			# 只接受距离更近的能量，不进行叠加
			if decayed_energy.source_distance < min_distance:
				min_distance = decayed_energy.source_distance
				new_level = decayed_energy.copy()
	
	# 限制最大距离
	if min_distance >= Constants.MAX_ENERGY_RANGE:
		new_level = EnergyLevel.new()
	
	if !new_level.equal(energy_level):
		energy_level = new_level
		_energy_intensity = energy_level.get_intensity()
		update.emit()
		# 更新颜色显示
		_update_appearance_from_energy_level()

func _update_color_from_neighbors() -> void:
	# 检查周围是否存在能量源
	var has_energy_source = _has_energy_source_neighbor()
	
	if has_energy_source:
		# 存在能量源，根据能量等级更新颜色
		update_energy_level()
	else:
		# 不存在能量源，显示为白色
		_set_color(Enums.ColorType.WHITE)
		_energy_intensity = 0.0

func _has_energy_source_neighbor() -> bool:
	# 检查四个方向是否存在能量源
	var neighbors = [north, south, west, east]
	for neighbor in neighbors:
		if neighbor != null:
			if neighbor is MonoCrystal:
				return true
			if neighbor is EnergyTransmitter and not neighbor.energy_level.is_empty():
				return true
	return false

func _update_appearance_from_energy_level() -> void:
	# 根据energy_level计算颜色并更新显示
	var color_type = energy_level.get_color()
	_set_color(color_type)

func _set_color(color_type: Enums.ColorType) -> void:
	# 设置颜色并更新显示
	_color = color_type
	if shape_drawer:
		var base_color :Color= Constants.COLOR_MAP.get(color_type, Color.WHITE)
		shape_drawer.fill_color = base_color
		shape_drawer.queue_redraw()

#func _process(_delta: float) -> void:
	## 可视化能量效果
	#if _energy_intensity > 0 and shape_drawer:
		#_update_energy_visualization()
#
#func _update_energy_visualization() -> void:
	#"""更新能量可视化效果"""
	#if shape_drawer:
		#var base_color = Constants.COLOR_MAP.get(_color, Color.WHITE)
		## 根据能量强度和距离计算亮度
		#var distance_factor = 1.0 - float(energy_level.source_distance) / float(Constants.MAX_ENERGY_RANGE)
		#var brightness = 0.3 + (_energy_intensity * 0.7 * distance_factor)
		#shape_drawer.fill_color = base_color * brightness
