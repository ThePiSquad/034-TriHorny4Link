class_name Structure
extends Damageable

signal update
signal destroyed

var energy_level: EnergyLevel = EnergyLevel.new()

@onready var shape_drawer: ShapeDrawer = $ShapeDrawer

@export var structure_type: Enums.StructureType

var _color: Enums.ColorType = Enums.ColorType.WHITE

@export var color: Enums.ColorType:
	get():
		return _color
	set(s):
		_color = s
		_sync_color_to_energy_level(s)
		if is_node_ready() and shape_drawer:
			shape_drawer.fill_color = Constants.COLOR_MAP[s]

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
	p_east: Structure = null
) -> Structure:
	north = p_north
	south = p_south
	west = p_west
	east = p_east
	return self

func connect_neighbor(s: Structure) -> void:
	if s == null:
		return
	# 双向连接：互相监听对方的update信号
	if not s.update.is_connected(self.on_neighbor_update):
		s.update.connect(self.on_neighbor_update)
	if not self.update.is_connected(s.on_neighbor_update):
		self.update.connect(s.on_neighbor_update)
	# 检查destroyed信号是否已连接，避免重复连接
	if not s.destroyed.is_connected(self.on_neighbor_destroyed):
		s.destroyed.connect(self.on_neighbor_destroyed)

func on_health_depleted() -> void:
	pass

func get_structure_type() -> Enums.StructureType:
	return structure_type

func on_neighbor_update() -> void:
	pass

func on_neighbor_destroyed() -> void:
	pass

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
	_sync_color_to_energy_level(_color)
	update.emit()
	if shape_drawer:
		shape_drawer.fill_color = Constants.COLOR_MAP.get(_color, Color.WHITE)
	call_deferred("_setup_input_handling")

func _setup_input_handling() -> void:
	if not shape_drawer:
		return
	
	await get_tree().process_frame
	
	var input_area = shape_drawer.get_node_or_null("InputArea")
	if input_area and input_area is Area2D:
		input_area.input_event.connect(_on_input_event)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_request_deletion()

func _request_deletion() -> void:
	if not is_inside_tree() or is_queued_for_deletion():
		return
	
	var manager = get_parent()
	if manager is StructureManager:
		var pos = GridCoord.from_world_coord(Vector2i(global_position))
		if not manager.remove(pos):
			push_warning("Failed to remove structure at position: " + str(pos))
	else:
		destroyed.emit()
		queue_free()

func _sync_color_to_energy_level(color_type: Enums.ColorType) -> void:
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
