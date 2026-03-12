class_name ConnectionManager
extends Node2D

## 建筑连接系统管理器
## 负责管理建筑之间的连接线和能量流动效果

var connections: Dictionary = {}
var connection_scene: PackedScene
var default_style: ConnectionStyle

func _ready() -> void:
	connection_scene = preload("res://src/components/connection.tscn")
	default_style = load("res://src/components/connection_style.tres")

func add_connection(start_structure: Structure, end_structure: Structure) -> void:
	"""添加建筑之间的连接"""
	var key = _get_connection_key(start_structure, end_structure)
	if connections.has(key):
		return
	
	var connection = connection_scene.instantiate()
	if connection and connection is Connection:
		connection.initialize(start_structure, end_structure)
		if default_style:
			connection.style = default_style
		add_child(connection)
		connections[key] = connection

func remove_connection(start_structure: Structure, end_structure: Structure) -> void:
	"""移除建筑之间的连接"""
	var key = _get_connection_key(start_structure, end_structure)
	if connections.has(key):
		var connection = connections[key]
		if is_instance_valid(connection):
			connection.queue_free()
		connections.erase(key)

func update_connections() -> void:
	"""更新所有连接"""
	# 性能优化：只更新需要更新的连接
	for connection in connections.values():
		if is_instance_valid(connection):
			connection.update()

func _get_connection_key(start: Structure, end: Structure) -> String:
	"""获取连接的唯一键"""
	var start_pos = GridCoord.from_world_coord(Vector2i(start.global_position))
	var end_pos = GridCoord.from_world_coord(Vector2i(end.global_position))
	var key1 = str(start_pos.x) + "," + str(start_pos.y) + "-" + str(end_pos.x) + "," + str(end_pos.y)
	var key2 = str(end_pos.x) + "," + str(end_pos.y) + "-" + str(start_pos.x) + "," + str(start_pos.y)
	return key1 if key1 < key2 else key2

func clear_connections() -> void:
	"""清除所有连接"""
	for connection in connections.values():
		if is_instance_valid(connection):
			connection.queue_free()
	connections.clear()

func set_default_style(style: ConnectionStyle) -> void:
	"""设置默认样式"""
	default_style = style
	# 更新现有连接的样式
	for connection in connections.values():
		if is_instance_valid(connection):
			connection.style = style
			connection._update_from_style()

func update_connection_colors(structure: Structure) -> void:
	"""更新与指定建筑相关的所有连接的颜色"""
	if not structure or not is_instance_valid(structure):
		return
	
	# 遍历所有连接，找到与该建筑相关的连接
	for connection in connections.values():
		if is_instance_valid(connection):
			if connection.start_structure == structure or connection.end_structure == structure:
				connection.refresh_color()
