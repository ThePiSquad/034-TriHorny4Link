class_name Structure
extends Damageable

signal update
signal destroyed
# 信号：颜色改变时发射
signal color_changed(color_type: Enums.ColorType)

var energy_level: EnergyLevel = EnergyLevel.new()

@onready var shape_drawer: ShapeDrawer = $ShapeDrawer

@export var structure_type: Enums.StructureType

var _color: Enums.ColorType = Enums.ColorType.WHITE

# 粒子特效相关
var particle_scene: PackedScene = preload("res://src/particles/energy_diss_ptc.tscn")

@export var color: Enums.ColorType:
	get():
		return _color
	set(s):
		var old_color = _color
		_color = s
		_sync_color_to_energy_level(s)
		if is_node_ready() and shape_drawer:
			shape_drawer.fill_color = Constants.COLOR_MAP[s]
		
		# 如果颜色改变了，发射信号
		if old_color != s:
			color_changed.emit(s)

var north: Structure = null:
	set(s):
		if s == null or is_instance_valid(s):
			north = s

var south: Structure = null:
	set(s):
		if s == null or is_instance_valid(s):
			south = s

var west: Structure = null:
	set(s):
		if s == null or is_instance_valid(s):
			west = s

var east: Structure = null:
	set(s):
		if s == null or is_instance_valid(s):
			east = s

func initialize(
	p_north: Structure = null,
	p_south: Structure = null,
	p_west: Structure = null,
	p_east: Structure = null
) -> Structure:
	if is_instance_valid(p_north):
		north = p_north
		connect_neighbor(p_north)
	if is_instance_valid(p_south):
		south = p_south
		connect_neighbor(p_south)
	if is_instance_valid(p_west):
		west = p_west
		connect_neighbor(p_west)
	if is_instance_valid(p_east):
		east = p_east
		connect_neighbor(p_east)
	return self

func connect_neighbor(s: Structure) -> void:
	if s == null or not is_instance_valid(s):
		return
	# 双向连接：互相监听对方的update信号
	if not s.update.is_connected(self.on_neighbor_update):
		s.update.connect(self.on_neighbor_update)
	if not self.update.is_connected(s.on_neighbor_update):
		self.update.connect(s.on_neighbor_update)
	# 检查destroyed信号是否已连接，避免重复连接
	if not s.destroyed.is_connected(self.on_neighbor_destroyed):
		s.destroyed.connect(self.on_neighbor_destroyed)

func _on_hit(source: Node) -> void:
	"""受到任何伤害时的统一处理"""
	# 触发屏幕抖动
	_trigger_screen_shake()

func _trigger_screen_shake() -> void:
	"""触发屏幕抖动效果"""
	var world = get_tree().get_first_node_in_group("world")
	if world and world.has_node("ScreenShakeManager"):
		var shake_manager = world.get_node("ScreenShakeManager")
		if shake_manager and shake_manager.has_method("shake"):
			# 根据建筑类型调整抖动强度
			var intensity = 8.0
			var duration = 0.3
			
			# CRYSTAL 受到攻击时抖动更强
			if structure_type == Enums.StructureType.CRYSTAL:
				intensity = 12.0
				duration = 0.4
			
			shake_manager.shake(duration, intensity)

func on_health_depleted() -> void:
	var manager = get_parent()
	if manager is StructureManager:
		var pos = GridCoord.from_world_coord(Vector2i(global_position))
		# 生成摧毁粒子效果
		_spawn_particle()
		manager.remove(pos)

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
	super._ready()
	_sync_color_to_energy_level(_color)
	update.emit()
	if shape_drawer:
		shape_drawer.fill_color = Constants.COLOR_MAP.get(_color, Color.WHITE)
		shape_drawer.stroke_color = shape_drawer.fill_color.lightened(0.3)
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
		# 生成删除粒子效果
		_spawn_particle()
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

func spawn_particle() -> void:
	"""生成粒子特效（外部调用接口）"""
	_spawn_particle()

func _spawn_particle() -> void:
	"""生成粒子特效"""
	if not particle_scene:
		return
	
	var particle = particle_scene.instantiate()
	if not particle:
		return
	
	# 设置粒子位置为建筑位置
	particle.global_position = global_position
	
	# 设置粒子纹理和颜色
	_setup_particle(particle)
	
	# 添加到场景中
	get_parent().add_child(particle)

func setup_particle(particle: GPUParticles2D) -> void:
	"""设置粒子纹理和颜色（外部调用接口）"""
	_setup_particle(particle)

func _setup_particle(particle: GPUParticles2D) -> void:
	"""设置粒子纹理和颜色"""
	# 根据建筑类型设置纹理
	var texture_path = ""
	match structure_type:
		Enums.StructureType.MONO_CRYSTAL:
			texture_path = "res://assets/particles/circle_solid_particle.png"
		Enums.StructureType.CONDUIT:
			texture_path = "res://assets/particles/rect_solid_particle.png"
		Enums.StructureType.TURRET:
			texture_path = "res://assets/particles/t_solid_particle.png"
	
	# 加载并设置纹理
	if texture_path != "":
		var texture = load(texture_path)
		if texture:
			particle.texture = texture
	
	# 根据建筑颜色设置粒子颜色
	if particle.process_material is ParticleProcessMaterial:
		var mat = particle.process_material as ParticleProcessMaterial
		var color = Constants.COLOR_MAP.get(_color, Color.WHITE)
		mat.color = color
	
	# 设置 one shot 模式
	particle.one_shot = true
	
	# 启动粒子发射
	particle.emitting = true
