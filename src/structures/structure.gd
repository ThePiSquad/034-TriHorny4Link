class_name Structure

extends Node2D

signal update

var energy_level: EnergyLevel

var color: Enums.ColorType:
	get():
		return energy_level.get_color()

# Neighbors, can be null indicating there is no structure connecting to it
var north: Structure = null:
	set(s):
		if s != null:
			s.update.connect(self.on_neighbor_update)
		on_neighbor_update()
		north = s

var south: Structure = null:
	set(s):
		if s != null:
			s.update.connect(self.on_neighbor_update)
		on_neighbor_update()
		south = s
var west: Structure = null:
	set(s):
		if s != null:
			s.update.connect(self.on_neighbor_update)
		on_neighbor_update()
		west = s
var east: Structure = null:
	set(s):
		if s != null:
			s.update.connect(self.on_neighbor_update)
		on_neighbor_update()
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


func on_health_depleted() -> void:
	pass


func on_neighbor_update() -> void:
	print("on_neighbor_update")


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
