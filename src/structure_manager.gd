extends Node2D

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
