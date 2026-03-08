class_name MonoCrystal extends Structure

func _ready() -> void:
	structure_type = Enums.StructureType.MONO_CRYSTAL
	super._ready()

func _init() -> void:
	structure_type = Enums.StructureType.MONO_CRYSTAL

func on_neighbor_update() -> void:
	pass

func update_energy_level() -> void:
	_sync_color_to_energy_level(_color)
