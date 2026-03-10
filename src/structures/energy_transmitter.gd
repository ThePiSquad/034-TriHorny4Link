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
		if neighbor != null and neighbor.energy_level != null:
			var neighbor_energy = neighbor.energy_level
			
			# 处理红色能量
			if neighbor_energy.red > 0:
				if neighbor_energy.red > red_max:
					red_max = neighbor_energy.red
					red_min_distance = neighbor_energy.red_source_distance + 1
				elif neighbor_energy.red == red_max and neighbor_energy.red_source_distance + 1 < red_min_distance:
					red_min_distance = neighbor_energy.red_source_distance + 1
			
			# 处理蓝色能量
			if neighbor_energy.blue > 0:
				if neighbor_energy.blue > blue_max:
					blue_max = neighbor_energy.blue
					blue_min_distance = neighbor_energy.blue_source_distance + 1
				elif neighbor_energy.blue == blue_max and neighbor_energy.blue_source_distance + 1 < blue_min_distance:
					blue_min_distance = neighbor_energy.blue_source_distance + 1
			
			# 处理黄色能量
			if neighbor_energy.yellow > 0:
				if neighbor_energy.yellow > yellow_max:
					yellow_max = neighbor_energy.yellow
					yellow_min_distance = neighbor_energy.yellow_source_distance + 1
				elif neighbor_energy.yellow == yellow_max and neighbor_energy.yellow_source_distance + 1 < yellow_min_distance:
					yellow_min_distance = neighbor_energy.yellow_source_distance + 1
	
	# 如果有能量源，则进行距离衰减
	if red_max > 0 or blue_max > 0 or yellow_max > 0:
		# 分别创建每个颜色的能量源
		var red_energy = EnergyLevel.new()
		var blue_energy = EnergyLevel.new()
		var yellow_energy = EnergyLevel.new()
		
		# 设置红色能量
		if red_max > 0:
			red_energy.red = red_max
			red_energy.red_source_distance = red_min_distance
			red_energy = red_energy.decay(0)  # 已经计算过距离，不再衰减
		
		# 设置蓝色能量
		if blue_max > 0:
			blue_energy.blue = blue_max
			blue_energy.blue_source_distance = blue_min_distance
			blue_energy = blue_energy.decay(0)
		
		# 设置黄色能量
		if yellow_max > 0:
			yellow_energy.yellow = yellow_max
			yellow_energy.yellow_source_distance = yellow_min_distance
			yellow_energy = yellow_energy.decay(0)
		
		# 合并三个颜色的能量
		new_level.add(red_energy)
		new_level.add(blue_energy)
		new_level.add(yellow_energy)
		
		print("【EnergyTransmitter】获取邻居最大能量: Red=" + str(red_max) + "(dist=" + str(red_min_distance) + "), Blue=" + str(blue_max) + "(dist=" + str(blue_min_distance) + "), Yellow=" + str(yellow_max) + "(dist=" + str(yellow_min_distance) + ")")
		print("【EnergyTransmitter】合并后能量: Red=" + str(new_level.red) + ", Blue=" + str(new_level.blue) + ", Yellow=" + str(new_level.yellow))
	
	# 更新能量等级
	if !new_level.equal(energy_level):
		print("【EnergyTransmitter】能量变化，更新显示")
		energy_level = new_level
		_energy_intensity = energy_level.get_intensity()
		update.emit()
		# 更新颜色显示
		_update_appearance_from_energy_level()
	else:
		print("【EnergyTransmitter】能量未变化，跳过")

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

func get_max_neighbor_resource_values() -> Dictionary:
	# 获取所有相邻建筑的red、blue、yellow属性的最大值
	var max_red: int = 0
	var max_blue: int = 0
	var max_yellow: int = 0
	
	# 遍历四个方向的邻居
	var neighbors = [north, south, west, east]
	for neighbor in neighbors:
		if neighbor != null:
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
