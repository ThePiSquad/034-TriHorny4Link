class_name StructureManager extends Node2D

var structures: Dictionary[GridCoord,Structure]


func _ready() -> void:
	structures = {}


func spawn(type: Enums.StructureType, pos: GridCoord) -> bool:
	if pos in Constants.generator_reserved_coords:
		return false
	if structures.get(pos)!=null:
		return false
	
	var north = structures.get(pos.north())
	var south = structures.get(pos.south())
	var west = structures.get(pos.west())
	var east = structures.get(pos.east())
	
	var structure:Structure

	if type == Enums.StructureType.CRYSTAL:
		structure = Crystal.new().initialize(north, south, west, east)
	if type == Enums.StructureType.CONDUIT:
		structure = Conduit.new().initialize(north, south, west, east)
	if type == Enums.StructureType.TURRET:
		structure = Turret.new().initialize(north, south, west, east)
	
	if structure!=null:
		structures.set(pos,structure)
		add_child(structure)
		return true
	else:
		return false


func remove(pos: GridCoord) -> bool:
	if pos in Constants.generator_reserved_coords:
		return false
	
	var structure = structures.get(pos)
	if structure == null:
		return false
	
	structures.erase(pos)
	structure.queue_free()
	
	_update_neighbors(pos)
	
	return true


func _update_neighbors(pos: GridCoord) -> void:
	var north = structures.get(pos.north())
	var south = structures.get(pos.south())
	var west = structures.get(pos.west())
	var east = structures.get(pos.east())
	
	if north != null:
		north.south = null
	if south != null:
		south.north = null
	if west != null:
		west.east = null
	if east != null:
		east.west = null


func has_structure(pos: GridCoord) -> bool:
	return structures.get(pos) != null


func get_structure(pos: GridCoord) -> Structure:
	return structures.get(pos)
