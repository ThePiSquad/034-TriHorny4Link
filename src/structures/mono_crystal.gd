class_name MonoCrystal extends Structure

var _distance_to_crystal: int = 0

func _ready() -> void:
	structure_type = Enums.StructureType.MONO_CRYSTAL
	super._ready()

func _init() -> void:
	structure_type = Enums.StructureType.MONO_CRYSTAL

func on_neighbor_update() -> void:
	pass

func _get_crystal() -> Node:
	var crystals = get_tree().get_nodes_in_group("crystal")
	for c in crystals:
		if c and is_instance_valid(c):
			return c
	return null

func _calculate_distance_to_crystal() -> int:
	var crystal = _get_crystal()
	if not crystal:
		return 0
	
	var distance_pixels = global_position.distance_to(crystal.global_position)
	var distance_tiles = int(distance_pixels / Constants.grid_size)
	return distance_tiles

func _calculate_energy_with_decay(base_energy: int, distance: int) -> int:
	if distance <= 0:
		return base_energy
	
	@warning_ignore("integer_division")
	var decay_units = distance / Constants.ENERGY_DECAY_DISTANCE_BASE
	var decayed_energy = base_energy - (decay_units * Constants.ENERGY_DECAY_RATE)
	return max(decayed_energy, Constants.ENERGY_MIN_THRESHOLD)

func update_energy_level() -> void:
	energy_level.red = 0
	energy_level.blue = 0
	energy_level.yellow = 0
	energy_level.red_source_distance = 0
	energy_level.blue_source_distance = 0
	energy_level.yellow_source_distance = 0
	
	_distance_to_crystal = _calculate_distance_to_crystal()
	var effective_energy = _calculate_energy_with_decay(Constants.MONO_CRYSTAL_BASE_ENERGY, _distance_to_crystal)
	
	match _color:
		Enums.ColorType.RED:
			energy_level.red = effective_energy
			energy_level.red_source_distance = _distance_to_crystal
		Enums.ColorType.BLUE:
			energy_level.blue = effective_energy
			energy_level.blue_source_distance = _distance_to_crystal
		Enums.ColorType.YELLOW:
			energy_level.yellow = effective_energy
			energy_level.yellow_source_distance = _distance_to_crystal
		_:
			_sync_color_to_energy_level(_color)
	
	update.emit()
