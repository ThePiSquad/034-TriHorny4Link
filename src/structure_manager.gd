class_name StructureManager extends Node2D

var structures: Dictionary[Vector2i, Structure]

var crystal_scene: PackedScene = preload("res://src/structures/crystal.tscn")
var conduit_scene: PackedScene = preload("res://src/structures/conduit.tscn")
var turret_scene: PackedScene = preload("res://src/structures/turret.tscn")
var mono_crystal_scene: PackedScene = preload("res://src/structures/mono_crystal.tscn")

func _ready() -> void:
	structures = {}

func spawn(type: Enums.StructureType, pos: GridCoord, color_type: Enums.ColorType = Enums.ColorType.WHITE) -> bool:
	var pos_key = Vector2i(pos.x, pos.y)
	
	if pos in Constants.generator_reserved_coords:
		return false
	
	if structures.get(pos_key) != null:
		return false
	
	var north = structures.get(Vector2i(pos.north().x, pos.north().y))
	var south = structures.get(Vector2i(pos.south().x, pos.south().y))
	var west = structures.get(Vector2i(pos.west().x, pos.west().y))
	var east = structures.get(Vector2i(pos.east().x, pos.east().y))
	
	var structure: Structure

	match type:
		Enums.StructureType.CRYSTAL:
			if crystal_scene:
				structure = crystal_scene.instantiate()
		Enums.StructureType.CONDUIT:
			if conduit_scene:
				structure = conduit_scene.instantiate()
		Enums.StructureType.TURRET:
			if turret_scene:
				structure = turret_scene.instantiate()
		Enums.StructureType.MONO_CRYSTAL:
			if mono_crystal_scene:
				structure = mono_crystal_scene.instantiate()
				if structure is MonoCrystal:
					structure.color = color_type
	
	if structure != null:
		structure.initialize(north, south, west, east)
		
		var world_pos = pos.to_world_coord()
		structure.position = Vector2(world_pos) + Vector2(Constants.grid_size / 2, Constants.grid_size / 2)
		
		structures.set(pos_key, structure)
		add_child(structure)
		
		_update_neighbor_connections(pos, structure)
		structure.update_energy_level()
		
		return true
	else:
		return false

func remove(pos: GridCoord) -> bool:
	var pos_key = Vector2i(pos.x, pos.y)
	
	if pos in Constants.generator_reserved_coords:
		push_warning("Cannot remove structure at reserved position: " + str(pos))
		return false
	
	var structure: Structure = structures.get(pos_key)
	if structure == null:
		return false
	
	if structure.is_queued_for_deletion():
		return false
	
	structure.destroyed.emit()
	structures.erase(pos_key)
	_update_neighbors_and_notify(pos)
	structure.queue_free()
	
	return true

func _update_neighbors(pos: GridCoord) -> void:
	var north = structures.get(Vector2i(pos.north().x, pos.north().y))
	var south = structures.get(Vector2i(pos.south().x, pos.south().y))
	var west = structures.get(Vector2i(pos.west().x, pos.west().y))
	var east = structures.get(Vector2i(pos.east().x, pos.east().y))
	
	if north != null:
		north.south = null
	if south != null:
		south.north = null
	if west != null:
		west.east = null
	if east != null:
		east.west = null

func _update_neighbors_and_notify(pos: GridCoord) -> void:
	var north: Structure = structures.get(Vector2i(pos.north().x, pos.north().y))
	var south: Structure = structures.get(Vector2i(pos.south().x, pos.south().y))
	var west: Structure = structures.get(Vector2i(pos.west().x, pos.west().y))
	var east: Structure = structures.get(Vector2i(pos.east().x, pos.east().y))
	
	if north != null:
		north.south = null
		north.update_energy_level()
	if south != null:
		south.north = null
		south.update_energy_level()
	if west != null:
		west.east = null
		west.update_energy_level()
	if east != null:
		east.west = null
		east.update_energy_level()

func _update_neighbor_connections(pos: GridCoord, structure: Structure) -> void:
	var north: Structure = structures.get(Vector2i(pos.north().x, pos.north().y))
	var south: Structure = structures.get(Vector2i(pos.south().x, pos.south().y))
	var west: Structure = structures.get(Vector2i(pos.west().x, pos.west().y))
	var east: Structure = structures.get(Vector2i(pos.east().x, pos.east().y))
	
	if north != null:
		structure.north = north
		north.south = structure
		north.update_energy_level()
	if south != null:
		structure.south = south
		south.north = structure
		south.update_energy_level()
	if west != null:
		structure.west = west
		west.east = structure
		west.update_energy_level()
	if east != null:
		structure.east = east
		east.west = structure
		east.update_energy_level()

func has_structure(pos: GridCoord) -> bool:
	var pos_key = Vector2i(pos.x, pos.y)
	return structures.get(pos_key) != null

func get_structure(pos: GridCoord) -> Structure:
	var pos_key = Vector2i(pos.x, pos.y)
	return structures.get(pos_key)
