extends Structure
class_name Turret

func _ready() -> void:
	super._ready()
	structure_type = Enums.StructureType.TURRET

func _init() -> void:
	structure_type = Enums.StructureType.TURRET

func on_neighbor_update() -> void:
	# 当邻居更新时，重新计算自身颜色
	_update_color_from_neighbors()

func update_energy_level() -> void:
	# Turret从邻居获取能量
	var new_level: EnergyLevel = EnergyLevel.new()

	if north != null:
		new_level.add(north.energy_level.decay())
	if south != null:
		new_level.add(south.energy_level.decay())
	if west != null:
		new_level.add(west.energy_level.decay())
	if east != null:
		new_level.add(east.energy_level.decay())

	if !new_level.equal(energy_level):
		energy_level = new_level
		update.emit()
		# 更新颜色显示
		_update_appearance_from_energy_level()

func _update_color_from_neighbors() -> void:
	# 检查周围是否存在MonoCrystal
	var has_mono_crystal = _has_mono_crystal_neighbor()
	
	if has_mono_crystal:
		# 存在MonoCrystal，根据能量等级更新颜色
		_update_appearance_from_energy_level()
	else:
		# 不存在MonoCrystal，显示为白色
		_set_color(Enums.ColorType.WHITE)

func _has_mono_crystal_neighbor() -> bool:
	# 检查四个方向是否存在MonoCrystal
	if north != null and north is MonoCrystal:
		return true
	if south != null and south is MonoCrystal:
		return true
	if west != null and west is MonoCrystal:
		return true
	if east != null and east is MonoCrystal:
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
		shape_drawer.fill_color = Constants.COLOR_MAP.get(color_type, Color.WHITE)
