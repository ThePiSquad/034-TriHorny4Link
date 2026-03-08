extends Node2D

var structures: Dictionary[GridCoord,Structure]


func _ready() -> void:
	structures = {}


func add_structure(type: Enums.StructureType, pos: GridCoord) -> Structure:
	var north = structures.get(pos.north())
	var south = structures.get(pos.south())
	var west = structures.get(pos.west())
	var east = structures.get(pos.east())

	if type == Enums.StructureType.CRYSTAL:
		return Crystal.new().initialize(north, south, west, east)
	if type == Enums.StructureType.CONDUIT:
		return Conduit.new().initialize(north, south, west, east)
	if type == Enums.StructureType.TURRET:
		return Turret.new().initialize(north, south, west, east)

	return null
