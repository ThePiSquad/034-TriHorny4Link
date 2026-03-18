class_name StructureManager extends Node2D

var structures: Dictionary[Vector2i, Structure]
var connection_manager: ConnectionManager

var crystal_scene: PackedScene = preload("res://src/structures/crystal.tscn")
var conduit_scene: PackedScene = preload("res://src/structures/conduit.tscn")
var turret_scene: PackedScene = preload("res://src/structures/turret.tscn")
var mono_crystal_scene: PackedScene = preload("res://src/structures/mono_crystal.tscn")

func _ready() -> void:
	structures = {}
	# 创建连接管理器
	connection_manager = ConnectionManager.new()
	add_child(connection_manager)

func spawn(type: Enums.StructureType, pos: GridCoord, color_type: Enums.ColorType = Enums.ColorType.WHITE) -> bool:
	var pos_key = Vector2i(pos.x, pos.y)
	
	print("尝试放置建筑，类型：", type, "位置：", pos, "颜色：", color_type)
	
	# 检查是否在保留坐标中
	for reserved in Constants.generator_reserved_coords:
		if reserved.x == pos.x and reserved.y == pos.y:
			print("  失败：在保留坐标中")
			return false
	
	if structures.get(pos_key) != null:
		print("  失败：位置已被占用")
		return false
	
	# 检查是否有敌人在目标位置附近
	if _has_enemy_nearby(pos):
		print("  失败：有敌人在附近")
		return false
	
	# 检查炮塔放置限制（必须靠近conduit）
	if type == Enums.StructureType.TURRET:
		if not _has_nearby_conduit(pos):
			print("  失败：炮塔必须靠近导管")
			return false
	
	# 检查导管放置限制
	if type == Enums.StructureType.CONDUIT:
		if not can_place_conduit(pos):
			print("  失败：导管放置限制")
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
		
		# 更新相邻连线的颜色
		_update_neighbor_connections_color(pos, structure)
		
		# 如果是 MonoCrystal，创建到 Crystal 的连接
		if type == Enums.StructureType.MONO_CRYSTAL:
			_create_connection_to_crystal(structure)
			# 强制更新连接
			if connection_manager:
				connection_manager.update_connections()
		
		# 生成放置粒子效果
		_spawn_place_particle(structure)
		
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
	
	# 移除相关连接
	_remove_structure_connections(structure)
	
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
	var check_radius = Constants.grid_size * 1.5  # 检查半径为 1.5 个格子
	
	# 获取场景中的所有敌人
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy and is_instance_valid(enemy):
			var distance = enemy.global_position.distance_to(world_pos)
			if distance < check_radius:
				return true
	
	return false

func _create_connection_to_crystal(mono_crystal: Structure) -> void:
	"""创建 MonoCrystal 到 Crystal 的连接"""
	# 获取所有 Crystal 建筑
	var crystals = get_tree().get_nodes_in_group("crystal")
	if crystals.is_empty():
		push_warning("没有找到 Crystal 节点")
		return
	
	# 获取第一个有效的 Crystal
	var crystal: Structure = null
	for c in crystals:
		if c and is_instance_valid(c) and c is Structure:
			crystal = c
			break
	
	if not crystal:
		push_warning("没有找到有效的 Crystal")
		return
	
	# 检查 connection_manager
	if not connection_manager:
		push_warning("ConnectionManager 不可用")
		return
	
	# 检查连接是否已存在
	if connection_manager.has_connection(mono_crystal, crystal):
		print("MonoCrystal 到 Crystal 的连接已存在")
		return
	
	# 创建连接
	connection_manager.add_connection(mono_crystal, crystal)
	print("创建 MonoCrystal 到 Crystal 的连接，MonoCrystal 位置：", mono_crystal.global_position, " Crystal 位置：", crystal.global_position)

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

func can_place_conduit(pos: GridCoord) -> bool:
	"""检查是否可以在指定位置放置导管"""
	# 检查是否有敌人在目标位置附近
	if _has_enemy_nearby(pos):
		print("检查导管放置：有敌人在附近")
		return false
	
	# 检查位置是否已被占用
	var pos_key = Vector2i(pos.x, pos.y)
	if structures.get(pos_key) != null:
		print("检查导管放置：位置已被占用")
		return false
	
	# 检查是否在保留坐标中
	for reserved in Constants.generator_reserved_coords:
		if reserved.x == pos.x and reserved.y == pos.y:
			print("检查导管放置：在保留坐标中")
			return false
	
	print("检查导管放置：可以放置")
	return true

func _update_neighbor_connections_color(pos: GridCoord, structure: Structure) -> void:
	"""更新相邻连线的颜色"""
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
	
	# 更新与邻居的连接
	if north and is_instance_valid(north):
		connection_manager.add_connection(structure, north)
		connection_manager.update_connection_colors(structure)
		connection_manager.update_connection_colors(north)
	if south and is_instance_valid(south):
		connection_manager.add_connection(structure, south)
		connection_manager.update_connection_colors(structure)
		connection_manager.update_connection_colors(south)
	if west and is_instance_valid(west):
		connection_manager.add_connection(structure, west)
		connection_manager.update_connection_colors(structure)
		connection_manager.update_connection_colors(west)
	if east and is_instance_valid(east):
		connection_manager.add_connection(structure, east)
		connection_manager.update_connection_colors(structure)
		connection_manager.update_connection_colors(east)

func _spawn_place_particle(structure: Structure) -> void:
	"""生成放置粒子效果"""
	if not structure or not structure.particle_scene:
		return
	
	var particle = structure.particle_scene.instantiate()
	if not particle:
		return
	
	# 设置粒子位置为建筑位置
	particle.global_position = structure.global_position
	
	# 设置粒子纹理和颜色
	structure.setup_particle(particle)
	
	# 添加到场景中
	add_child(particle)

func _update_connections(pos: GridCoord, structure: Structure) -> void:
	"""更新建筑的连接"""
	var north = structures.get(Vector2i(pos.north().x, pos.north().y))
	var south = structures.get(Vector2i(pos.south().x, pos.south().y))
	var west = structures.get(Vector2i(pos.west().x, pos.west().y))
	var east = structures.get(Vector2i(pos.east().x, pos.east().y))
	
	if north and is_instance_valid(north):
		connection_manager.add_connection(structure, north)
	if south and is_instance_valid(south):
		connection_manager.add_connection(structure, south)
	if west and is_instance_valid(west):
		connection_manager.add_connection(structure, west)
	if east and is_instance_valid(east):
		connection_manager.add_connection(structure, east)

func _remove_structure_connections(structure: Structure) -> void:
	"""移除建筑的所有连接"""
	if not connection_manager:
		return
	
	# 移除与邻居的连接
	if structure.north and is_instance_valid(structure.north):
		connection_manager.remove_connection(structure, structure.north)
	if structure.south and is_instance_valid(structure.south):
		connection_manager.remove_connection(structure, structure.south)
	if structure.west and is_instance_valid(structure.west):
		connection_manager.remove_connection(structure, structure.west)
	if structure.east and is_instance_valid(structure.east):
		connection_manager.remove_connection(structure, structure.east)
	
	# 还需要移除到 Crystal 的连接（如果是 MonoCrystal）
	if structure.get_structure_type() == Enums.StructureType.MONO_CRYSTAL:
		var crystals = get_tree().get_nodes_in_group("crystal")
		for c in crystals:
			if c and is_instance_valid(c) and c is Structure:
				connection_manager.remove_connection(structure, c)
				break

func update_all_connections() -> void:
	"""更新所有连接"""
	connection_manager.update_connections()

func update_chain_connections(structure: Structure) -> void:
	"""手动触发链路上的所有连线更新"""
	_update_chain_connections(structure)

func _update_chain_connections(start_structure: Structure) -> void:
	"""更新链路上的所有连线"""
	if not start_structure or not is_instance_valid(start_structure):
		return
	
	# 使用BFS遍历整个链路
	var visited: Array[Structure] = []
	var queue: Array[Structure] = [start_structure]
	
	while queue.size() > 0:
		var current = queue.pop_front()
		
		# 检查是否已访问
		if current in visited:
			continue
		
		visited.append(current)
		
		# 获取所有邻居
		var neighbors = [current.north, current.south, current.west, current.east]
		
		for neighbor in neighbors:
			if neighbor and is_instance_valid(neighbor) and not (neighbor in visited):
				# 更新连接
				connection_manager.add_connection(current, neighbor)
				queue.append(neighbor)
