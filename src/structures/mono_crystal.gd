class_name MonoCrystal extends Structure

func _ready() -> void:
	super._ready()
	structure_type = Enums.StructureType.MONO_CRYSTAL

func _init() -> void:
	structure_type = Enums.StructureType.MONO_CRYSTAL

func on_neighbor_update() -> void:
	# MonoCrystal作为能量提供者，其颜色不受邻居影响
	# 保持自身颜色不变
	pass

func update_energy_level() -> void:
	# MonoCrystal作为能量源，其energy_level由自身color决定
	# 不需要从邻居获取能量，保持自身能量等级
	_sync_color_to_energy_level(_color)
