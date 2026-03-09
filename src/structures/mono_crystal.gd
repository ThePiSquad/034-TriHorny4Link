class_name MonoCrystal extends Structure

func _ready() -> void:
	structure_type = Enums.StructureType.MONO_CRYSTAL
	super._ready()

func _init() -> void:
	structure_type = Enums.StructureType.MONO_CRYSTAL

func on_neighbor_update() -> void:
	pass

func update_energy_level() -> void:
	# MonoCrystal作为能量源，设置基础能量值
	energy_level.red = 0
	energy_level.blue = 0
	energy_level.yellow = 0
	energy_level.source_distance = 0
	
	# 根据颜色设置对应的能量值
	match _color:
		Enums.ColorType.RED:
			energy_level.red = Constants.MONO_CRYSTAL_BASE_ENERGY
		Enums.ColorType.BLUE:
			energy_level.blue = Constants.MONO_CRYSTAL_BASE_ENERGY
		Enums.ColorType.YELLOW:
			energy_level.yellow = Constants.MONO_CRYSTAL_BASE_ENERGY
		_:
			# 其他颜色按之前的逻辑
			_sync_color_to_energy_level(_color)
	
	update.emit()
