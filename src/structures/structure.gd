class_name Structure

extends Node2D

signal update
signal destroyed


var energy_level: EnergyLevel

@export var structure_type:Enums.StructureType

var color: Enums.ColorType:
	get():
		return energy_level.get_color()

# Neighbors, can be null indicating there is no structure connecting to it
var north: Structure = null:
	set(s):
		connect_neighbor(s)
		north = s

var south: Structure = null:
	set(s):
		connect_neighbor(s)
		south = s
var west: Structure = null:
	set(s):
		connect_neighbor(s)	
		west = s
var east: Structure = null:
	set(s):
		connect_neighbor(s)	
		east = s


func initialize(
	p_north: Structure = null,
	p_south: Structure = null,
	p_west: Structure = null,
	p_east: Structure = null,
) -> Structure:
	north = p_north
	south = p_south
	west = p_west
	east = p_east
	return self

func connect_neighbor(s:Structure)->void:
	if s==null:
		return
	else:
		s.update.connect(self.on_neighbor_update)
		s.destroyed.connect(self.on_neighbor_destroyed)

func on_health_depleted() -> void:
	pass

func get_structure_type() -> Enums.StructureType:
	return structure_type


func on_neighbor_update() -> void:
	print("on_neighbor_update")

func on_neighbor_destroyed()->void:
	print("on_neighbor_destroyed")

func update_energy_level() -> void:
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


func _exit_tree() -> void:
	update.emit()


func _ready() -> void:
	update.emit()


func _on_damageable_health_depleted() -> void:
	destroyed.emit()
