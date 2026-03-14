class_name InputManager
extends Node2D

enum InputMode {
	PLACEMENT,
	CAMERA
}

signal mode_changed(mode: InputMode)

@export var structure_manager: StructureManager
@export var placement_preview: PlacementPreview
@export var hud: HUD
@export var camera: Camera2D
@export var resource_manager: ResourceManager

var current_mode: InputMode = InputMode.PLACEMENT
var selected_structure_type: Enums.StructureType = Enums.StructureType.TURRET
var selected_color_type: Enums.ColorType = Enums.ColorType.WHITE

var _is_placing: bool = false
var _is_removing: bool = false
var _place_timer: float = 0.0

var _camera_dragging: bool = false
var _last_mouse_position: Vector2
var _preview_should_be_visible: bool = false

# 相机缩放相关变量
var _zoom_speed: float = Constants.CameraConstants.ZOOM_SPEED
var _min_zoom: float = Constants.CameraConstants.MIN_ZOOM
var _max_zoom: float = Constants.CameraConstants.MAX_ZOOM

# 相机移动相关变量
var _camera_move_speed: float = Constants.CameraConstants.MOVE_SPEED
var _camera_acceleration: float = Constants.CameraConstants.ACCELERATION
var _camera_velocity: Vector2 = Vector2.ZERO

# 相机边界限制
var _camera_min_x: float = Constants.CameraConstants.MIN_X
var _camera_max_x: float = Constants.CameraConstants.MAX_X
var _camera_min_y: float = Constants.CameraConstants.MIN_Y
var _camera_max_y: float = Constants.CameraConstants.MAX_Y

func _ready() -> void:
	_update_mode()
	if hud:
		hud.icon_selected.connect(_on_icon_selected)
		hud.selection_cleared.connect(_on_selection_cleared)
	
	# 设置placement_preview的structure_manager引用
	if placement_preview and structure_manager:
		placement_preview.set_structure_manager(structure_manager)

func _input(event: InputEvent) -> void:
	# 处理鼠标滚轮事件（任何模式下都可用）
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_camera(1.0 + _zoom_speed)
			return
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_camera(1.0 - _zoom_speed)
			return
	
	if event.is_action_pressed("toggle_camera_mode"):
		_toggle_mode()
		return
	
	if current_mode == InputMode.CAMERA:
		if event.is_action_pressed("ui_cancel"):
			_set_mode(InputMode.PLACEMENT)
			return
		_handle_camera_input(event)
	else:
		_handle_placement_input(event)

func _process(delta: float) -> void:
	# 处理相机移动
	_handle_camera_movement(delta)
	
	# 始终更新相机拖动（任何模式都可以拖动）
	_update_camera_drag()
	
	if current_mode == InputMode.CAMERA:
		pass
	else:
		_update_placement_preview()
		_handle_continuous_placement(delta)

func _handle_camera_movement(delta: float) -> void:
	if not camera:
		return
	
	# 计算移动方向
	var move_dir = Vector2.ZERO
	
	if Input.is_action_pressed("ui_up"):
		move_dir.y -= 1
	if Input.is_action_pressed("ui_down"):
		move_dir.y += 1
	if Input.is_action_pressed("ui_left"):
		move_dir.x -= 1
	if Input.is_action_pressed("ui_right"):
		move_dir.x += 1
	
	# 归一化方向向量
	if move_dir.length() > 0:
		move_dir = move_dir.normalized()
	
	# 应用加速度
	var target_velocity = move_dir * _camera_move_speed
	_camera_velocity = _camera_velocity.lerp(target_velocity, _camera_acceleration * delta)
	
	# 应用相机移动
	camera.position += _camera_velocity * delta
	
	# 限制相机边界
	camera.position.x = clamp(camera.position.x, _camera_min_x, _camera_max_x)
	camera.position.y = clamp(camera.position.y, _camera_min_y, _camera_max_y)

func _toggle_mode() -> void:
	if current_mode == InputMode.PLACEMENT:
		_set_mode(InputMode.CAMERA)
	else:
		_set_mode(InputMode.PLACEMENT)

func _set_mode(mode: InputMode) -> void:
	current_mode = mode
	_update_mode()
	mode_changed.emit(mode)

func _update_mode() -> void:
	if current_mode == InputMode.CAMERA:
		if hud:
			hud.hide_hud()
		if placement_preview:
			placement_preview.hide_preview()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		if hud:
			hud.show_hud()
		if placement_preview:
			if _is_selection_active():
				placement_preview.show_preview()
			else:
				placement_preview.hide_preview()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _handle_camera_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# 左键拖动 - 在相机模式下始终允许
			_camera_dragging = event.pressed
			if event.pressed:
				_last_mouse_position = event.position
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			# 中键拖动 - 在任何模式下都允许
			_camera_dragging = event.pressed
			if event.pressed:
				_last_mouse_position = event.position

func _update_camera_drag() -> void:
	if _camera_dragging and camera:
		var current_mouse_position = get_viewport().get_mouse_position()
		var delta = _last_mouse_position - current_mouse_position
		camera.position += delta
		_last_mouse_position = current_mouse_position

func _zoom_camera(zoom_factor: float) -> void:
	if not camera:
		return
	
	# 计算新的缩放值
	var new_zoom = camera.zoom * zoom_factor
	
	# 限制缩放范围
	new_zoom = Vector2(
		clamp(new_zoom.x, _min_zoom, _max_zoom),
		clamp(new_zoom.y, _min_zoom, _max_zoom)
	)
	
	# 平滑过渡到新的缩放值
	camera.zoom = new_zoom

func _handle_placement_input(event: InputEvent) -> void:
	# 鼠标滚轮事件已经在 _input 函数中处理，这里不需要再处理
	if event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		return
	
	var hovered_control = get_viewport().gui_get_hovered_control()
	
	if event is InputEventMouseButton:
		# 中键拖动 - 在任何情况下都允许（包括鼠标在 UI 上）
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			_camera_dragging = event.pressed
			if event.pressed:
				_last_mouse_position = event.position
			return
		
		# 如果鼠标在 UI 上，忽略其他输入
		if hovered_control != null:
			return
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			# 左键 - 选中时放置，未选中时拖动场景
			if _is_selection_active():
				_is_placing = event.pressed
				if event.pressed:
					_try_place()
			else:
				# 未选中任何建造时，左键拖动场景
				_camera_dragging = event.pressed
				if event.pressed:
					_last_mouse_position = event.position
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_is_removing = event.pressed
			if event.pressed:
				_try_remove()

func _update_placement_preview() -> void:
	var hovered_control = get_viewport().gui_get_hovered_control()
	
	if hovered_control != null:
		_preview_should_be_visible = true
		if placement_preview:
			placement_preview.hide_preview()
		return
	
	if not placement_preview:
		return
	
	# 更新预览位置，无论是否选中建造
	var mouse_pos = get_global_mouse_position()
	placement_preview.update_position(mouse_pos)
	
	if _is_selection_active():
		if _preview_should_be_visible:
			placement_preview.show_preview()
			_preview_should_be_visible = false
	else:
		placement_preview.hide_preview()

func _handle_continuous_placement(delta: float) -> void:
	if _is_placing and _is_selection_active():
		_place_timer += delta
		if _place_timer >= Constants.InputConstants.PLACE_INTERVAL:
			_place_timer = 0.0
			_try_place()
	else:
		_place_timer = 0.0
	
	if _is_removing:
		_try_remove()

func _try_place() -> void:
	if not structure_manager or not _is_selection_active():
		return
	
	if not _can_afford_structure():
		return
	
	var mouse_pos = get_global_mouse_position()
	var grid_coord = GridCoord.from_world_coord(Vector2i(mouse_pos))
	
	if structure_manager.spawn(selected_structure_type, grid_coord, selected_color_type):
		_consume_resources()

func _try_remove() -> void:
	if not structure_manager:
		return
	
	var mouse_pos = get_global_mouse_position()
	var grid_coord = GridCoord.from_world_coord(Vector2i(mouse_pos))
	structure_manager.remove(grid_coord)

func _can_afford_structure() -> bool:
	if not resource_manager:
		return true
	
	match selected_structure_type:
		Enums.StructureType.MONO_CRYSTAL:
			match selected_color_type:
				Enums.ColorType.RED:
					return resource_manager.has_enough_resources("red", Constants.ResourceConstants.MONO_CRYSTAL_COST)
				Enums.ColorType.BLUE:
					return resource_manager.has_enough_resources("blue", Constants.ResourceConstants.MONO_CRYSTAL_COST)
				Enums.ColorType.YELLOW:
					return resource_manager.has_enough_resources("yellow", Constants.ResourceConstants.MONO_CRYSTAL_COST)
				_:
					return true
		Enums.StructureType.CONDUIT, Enums.StructureType.TURRET:
			return resource_manager.has_enough_resources_all(
				Constants.ResourceConstants.CONDUIT_COST,
				Constants.ResourceConstants.CONDUIT_COST,
				Constants.ResourceConstants.CONDUIT_COST
			)
		_:
			return true

func _consume_resources() -> void:
	if not resource_manager:
		return
	
	match selected_structure_type:
		Enums.StructureType.MONO_CRYSTAL:
			match selected_color_type:
				Enums.ColorType.RED:
					resource_manager.consume_resources("red", Constants.ResourceConstants.MONO_CRYSTAL_COST)
				Enums.ColorType.BLUE:
					resource_manager.consume_resources("blue", Constants.ResourceConstants.MONO_CRYSTAL_COST)
				Enums.ColorType.YELLOW:
					resource_manager.consume_resources("yellow", Constants.ResourceConstants.MONO_CRYSTAL_COST)
		Enums.StructureType.CONDUIT, Enums.StructureType.TURRET:
			resource_manager.consume_resources_all(
				Constants.ResourceConstants.CONDUIT_COST,
				Constants.ResourceConstants.CONDUIT_COST,
				Constants.ResourceConstants.CONDUIT_COST
			)

func set_selected_structure_type(type: Enums.StructureType) -> void:
	selected_structure_type = type
	if placement_preview:
		placement_preview.set_structure_type(type)

func _is_selection_active() -> bool:
	if not hud:
		return false
	return hud.is_icon_selected()

func _on_icon_selected(icon) -> void:
	if icon is ShapeIcon:
		if icon.shape_type == ShapeIcon.ShapeType.RECTANGLE:
			set_selected_structure_type(Enums.StructureType.CONDUIT)
		elif icon.shape_type == ShapeIcon.ShapeType.TRIANGLE:
			set_selected_structure_type(Enums.StructureType.TURRET)
	elif icon is ColorCircle:
		set_selected_structure_type(Enums.StructureType.MONO_CRYSTAL)
		var index = icon.get_index()
		match index:
			0: selected_color_type = Enums.ColorType.RED
			1: selected_color_type = Enums.ColorType.BLUE
			2: selected_color_type = Enums.ColorType.YELLOW
			_: selected_color_type = Enums.ColorType.WHITE
	
	if placement_preview:
		placement_preview.show_preview()

func _on_selection_cleared() -> void:
	if placement_preview:
		placement_preview.hide_preview()
