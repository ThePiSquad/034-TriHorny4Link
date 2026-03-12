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

func _process_color_energy(neighbor_energy: EnergyLevel, color_name: String, current_max: int, current_min_distance: int) -> Dictionary:
	"""处理单个颜色的能量计算
	
	参数:
	- neighbor_energy: 邻居的能量等级
	- color_name: 颜色名称 ("red", "blue", "yellow")
	- current_max: 当前最大能量值
	- current_min_distance: 当前最小距离
	
	返回:
	- 包含更新后的最大值和最小距离的字典
	"""
	var energy_value = 0
	var source_distance = 0
	
	# 获取对应颜色的能量值和距离
	if color_name == "red":
		energy_value = neighbor_energy.red
		source_distance = neighbor_energy.red_source_distance
	elif color_name == "blue":
		energy_value = neighbor_energy.blue
		source_distance = neighbor_energy.blue_source_distance
	elif color_name == "yellow":
		energy_value = neighbor_energy.yellow
		source_distance = neighbor_energy.yellow_source_distance
	
	# 更新最大值和最小距离
	if energy_value > 0:
		if energy_value > current_max:
			current_max = energy_value
			current_min_distance = source_distance + 1
		elif energy_value == current_max and source_distance + 1 < current_min_distance:
			current_min_distance = source_distance + 1
	
	return {"max": current_max, "min_distance": current_min_distance}

func _create_color_energy(color_name: String, max_energy: int, min_distance: int) -> EnergyLevel:
	"""创建单个颜色的能量等级对象
	
	参数:
	- color_name: 颜色名称 ("red", "blue", "yellow")
	- max_energy: 最大能量值
	- min_distance: 最小距离
	
	返回:
	- 对应的EnergyLevel对象
	"""
	var energy = EnergyLevel.new()
	
	if max_energy > 0:
		# 计算衰减后的能量值
		var decayed_energy = max(max_energy - Constants.ENERGY_DECAY_PER_TILE, 0)
		
		# 设置对应颜色的能量值和距离
		if color_name == "red":
			energy.red = decayed_energy
			energy.red_source_distance = min_distance
		elif color_name == "blue":
			energy.blue = decayed_energy
			energy.blue_source_distance = min_distance
		elif color_name == "yellow":
			energy.yellow = decayed_energy
			energy.yellow_source_distance = min_distance
	
	return energy

func update_energy_level() -> void:
	# 从邻居获取最大能量值，并进行距离衰减
	var new_level: EnergyLevel = EnergyLevel.new()
	
	# 分别获取每个颜色的最大能量值和对应的最近距离
	var red_max: int = 0
	var blue_max: int = 0
	var yellow_max: int = 0
	var red_min_distance: int = Constants.MAX_ENERGY_RANGE
	var blue_min_distance: int = Constants.MAX_ENERGY_RANGE
	var yellow_min_distance: int = Constants.MAX_ENERGY_RANGE
	
	# 遍历所有邻居，分别记录每个颜色的最大值和最近距离
	var neighbors = [north, south, west, east]
	for neighbor in neighbors:
		if neighbor != null and is_instance_valid(neighbor) and neighbor.energy_level != null:
			var neighbor_energy = neighbor.energy_level
			
			# 处理红色能量
			var red_result = _process_color_energy(neighbor_energy, "red", red_max, red_min_distance)
			red_max = red_result["max"]
			red_min_distance = red_result["min_distance"]
			
			# 处理蓝色能量
			var blue_result = _process_color_energy(neighbor_energy, "blue", blue_max, blue_min_distance)
			blue_max = blue_result["max"]
			blue_min_distance = blue_result["min_distance"]
			
			# 处理黄色能量
			var yellow_result = _process_color_energy(neighbor_energy, "yellow", yellow_max, yellow_min_distance)
			yellow_max = yellow_result["max"]
			yellow_min_distance = yellow_result["min_distance"]
	
	# 如果有能量源，则进行距离衰减
	if red_max > 0 or blue_max > 0 or yellow_max > 0:
		# 分别创建每个颜色的能量源
		var red_energy = _create_color_energy("red", red_max, red_min_distance)
		var blue_energy = _create_color_energy("blue", blue_max, blue_min_distance)
		var yellow_energy = _create_color_energy("yellow", yellow_max, yellow_min_distance)
		
		# 合并三个颜色的能量
		new_level.add(red_energy)
		new_level.add(blue_energy)
		new_level.add(yellow_energy)
	
	# 更新能量等级
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
		if neighbor != null and is_instance_valid(neighbor):
			if neighbor is MonoCrystal:
				return true
			if neighbor is EnergyTransmitter and not neighbor.energy_level.is_empty():
				return true
	return false

func get_max_neighbor_resource_values() -> Dictionary:
	# 获取所有相邻建筑的red、blue、yellow属性的最大值
	var max_red: int = 0
	var max_blue: int = 0
	var max_yellow: int = 0
	
	# 遍历四个方向的邻居
	var neighbors = [north, south, west, east]
	for neighbor in neighbors:
		if neighbor != null and is_instance_valid(neighbor):
			# 安全获取邻居的能量等级
			if neighbor.has_method("get") and neighbor.has("energy_level"):
				var neighbor_energy = neighbor.energy_level
				if neighbor_energy != null:
					# 更新各颜色的最大值
					if neighbor_energy.red > max_red:
						max_red = neighbor_energy.red
					if neighbor_energy.blue > max_blue:
						max_blue = neighbor_energy.blue
					if neighbor_energy.yellow > max_yellow:
						max_yellow = neighbor_energy.yellow
	
	# 返回包含三个颜色最大值的字典
	return {
		"red": max_red,
		"blue": max_blue,
		"yellow": max_yellow
	}

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
		shape_drawer.stroke_color = base_color.lightened(0.3)
		shape_drawer.queue_redraw()
	
	# 发射颜色改变信号
	color_changed.emit(color_type)

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
