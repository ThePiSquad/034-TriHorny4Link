class_name Structure

extends Node2D

signal update
signal destroyed

var energy_level: EnergyLevel = EnergyLevel.new()

@onready var shape_drawer: ShapeDrawer = $ShapeDrawer

@export var structure_type:Enums.StructureType

var _color: Enums.ColorType = Enums.ColorType.WHITE

@export var color: Enums.ColorType:
	get():
		return _color
	set(s):
		# 存储颜色值
		_color = s
		# 同步到 energy_level
		_sync_color_to_energy_level(s)
		# 只有当 shape_drawer 存在且节点已经进入场景树时才更新外观
		if is_node_ready() and shape_drawer:
			shape_drawer.fill_color = Constants.COLOR_MAP[s]

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
	# 初始化时应用编辑器中设置的颜色
	_sync_color_to_energy_level(_color)
	update.emit()
	_update_appearance()

func _update_appearance() -> void:
	if shape_drawer:
		# 直接使用_color变量，而不是从energy_level获取
		shape_drawer.fill_color = Constants.COLOR_MAP.get(_color, Color.WHITE)

func _sync_color_to_energy_level(color_type: Enums.ColorType) -> void:
	# 根据颜色类型设置 energy_level 的值
	match color_type:
		Enums.ColorType.RED:
			energy_level.red = 3
			energy_level.blue = 0
			energy_level.yellow = 0
		Enums.ColorType.BLUE:
			energy_level.red = 0
			energy_level.blue = 3
			energy_level.yellow = 0
		Enums.ColorType.YELLOW:
			energy_level.red = 0
			energy_level.blue = 0
			energy_level.yellow = 3
		Enums.ColorType.GREEN:
			energy_level.red = 0
			energy_level.blue = 2
			energy_level.yellow = 2
		Enums.ColorType.ORANGE:
			energy_level.red = 2
			energy_level.blue = 0
			energy_level.yellow = 1
		Enums.ColorType.PURPLE:
			energy_level.red = 1
			energy_level.blue = 2
			energy_level.yellow = 0
		Enums.ColorType.BLACK:
			energy_level.red = 1
			energy_level.blue = 1
			energy_level.yellow = 1
		Enums.ColorType.WHITE:
			energy_level.red = 0
			energy_level.blue = 0
			energy_level.yellow = 0
