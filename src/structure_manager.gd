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
	
	# 检查是否在保留坐标中
	for reserved in Constants.generator_reserved_coords:
		if reserved.x == pos.x and reserved.y == pos.y:
			return false
	
	if structures.get(pos_key) != null:
		return false
	
	# 检查是否有敌人在目标位置附近
	if _has_enemy_nearby(pos):
		return false
	
	# 检查炮塔放置限制（必须靠近conduit）
	if type == Enums.StructureType.TURRET:
		if not _has_nearby_conduit(pos):
			return false
	
	var north = structures.get(Vector2i(pos.north().x, pos.north().y))
	var south = structures.get(Vector2i(pos.south().x, pos.south().y))
	var west = structures.get(Vector2i(pos.west().x, pos.west().y))
	var east = structures.get(Vector2i(pos.east().x, pos.east().y))
	
	# 验证邻居的有效性
	if north != null and not is_instance_valid(north):
		north = null
	if south != null and not is_instance_valid(south):
		south = null
	if west != null and not is_instance_valid(west):
		west = null
	if east != null and not is_instance_valid(east):
		east = null
	
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
	
	# 检查是否在保留坐标中
	for reserved in Constants.generator_reserved_coords:
		if reserved.x == pos.x and reserved.y == pos.y:
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
	
	if north != null and is_instance_valid(north):
		north.south = null
	if south != null and is_instance_valid(south):
		south.north = null
	if west != null and is_instance_valid(west):
		west.east = null
	if east != null and is_instance_valid(east):
		east.west = null

func _update_neighbors_and_notify(pos: GridCoord) -> void:
	var north: Structure = structures.get(Vector2i(pos.north().x, pos.north().y))
	var south: Structure = structures.get(Vector2i(pos.south().x, pos.south().y))
	var west: Structure = structures.get(Vector2i(pos.west().x, pos.west().y))
	var east: Structure = structures.get(Vector2i(pos.east().x, pos.east().y))
	
	if north != null and is_instance_valid(north):
		north.south = null
		north.update_energy_level()
	if south != null and is_instance_valid(south):
		south.north = null
		south.update_energy_level()
	if west != null and is_instance_valid(west):
		west.east = null
		west.update_energy_level()
	if east != null and is_instance_valid(east):
		east.west = null
		east.update_energy_level()

func _update_neighbor_connections(pos: GridCoord, structure: Structure) -> void:
	var north: Structure = structures.get(Vector2i(pos.north().x, pos.north().y))
	var south: Structure = structures.get(Vector2i(pos.south().x, pos.south().y))
	var west: Structure = structures.get(Vector2i(pos.west().x, pos.west().y))
	var east: Structure = structures.get(Vector2i(pos.east().x, pos.east().y))
	
	if north != null and is_instance_valid(north):
		structure.north = north
		north.south = structure
		north.update_energy_level()
	if south != null and is_instance_valid(south):
		structure.south = south
		south.north = structure
		south.update_energy_level()
	if west != null and is_instance_valid(west):
		structure.west = west
		west.east = structure
		west.update_energy_level()
	if east != null and is_instance_valid(east):
		structure.east = east
		east.west = structure
		east.update_energy_level()

func has_structure(pos: GridCoord) -> bool:
	var pos_key = Vector2i(pos.x, pos.y)
	return structures.get(pos_key) != null

func get_structure(pos: GridCoord) -> Structure:
	var pos_key = Vector2i(pos.x, pos.y)
	return structures.get(pos_key)

func _has_enemy_nearby(pos: GridCoord) -> bool:
	"""检查是否有敌人在目标位置附近"""
	var world_pos = pos.to_world_coord()
	var check_radius = Constants.grid_size * 1.5  # 检查半径为1.5个格子
	
	# 获取场景中的所有敌人
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy and is_instance_valid(enemy):
			var distance = enemy.global_position.distance_to(world_pos)
			if distance < check_radius:
				return true
	
	return false

func _has_nearby_conduit(pos: GridCoord) -> bool:
	"""检查指定位置周围上下左右是否存在conduit"""
	var north = structures.get(Vector2i(pos.north().x, pos.north().y))
	var south = structures.get(Vector2i(pos.south().x, pos.south().y))
	var west = structures.get(Vector2i(pos.west().x, pos.west().y))
	var east = structures.get(Vector2i(pos.east().x, pos.east().y))
	
	# 验证邻居的有效性
	if north != null and not is_instance_valid(north):
		north = null
	if south != null and not is_instance_valid(south):
		south = null
	if west != null and not is_instance_valid(west):
		west = null
	if east != null and not is_instance_valid(east):
		east = null
	
	# 检查是否有conduit
	if north != null and north.get_structure_type() == Enums.StructureType.CONDUIT:
		return true
	if south != null and south.get_structure_type() == Enums.StructureType.CONDUIT:
		return true
	if west != null and west.get_structure_type() == Enums.StructureType.CONDUIT:
		return true
	if east != null and east.get_structure_type() == Enums.StructureType.CONDUIT:
		return true
	
	return false

func can_place_turret(pos: GridCoord) -> bool:
	"""检查是否可以在指定位置放置炮塔"""
	# 检查是否有敌人在目标位置附近
	if _has_enemy_nearby(pos):
		return false
	
	# 检查是否靠近conduit
	if not _has_nearby_conduit(pos):
		return false
	
	# 检查位置是否已被占用
	var pos_key = Vector2i(pos.x, pos.y)
	if structures.get(pos_key) != null:
		return false
	
	# 检查是否在保留坐标中
	for reserved in Constants.generator_reserved_coords:
		if reserved.x == pos.x and reserved.y == pos.y:
			return false
	
	return true
