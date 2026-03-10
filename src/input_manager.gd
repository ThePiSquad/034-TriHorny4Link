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

var current_mode: InputMode = InputMode.PLACEMENT
var selected_structure_type: Enums.StructureType = Enums.StructureType.TURRET
var selected_color_type: Enums.ColorType = Enums.ColorType.WHITE

var _is_placing: bool = false
var _is_removing: bool = false
var _place_timer: float = 0.0
const PLACE_INTERVAL: float = 0.1

var _camera_dragging: bool = false
var _last_mouse_position: Vector2
var _preview_should_be_visible: bool = false

# 相机缩放相关变量
var _zoom_speed: float = 0.1
var _min_zoom: float = 0.5
var _max_zoom: float = 2.0

# 相机移动相关变量
var _camera_move_speed: float = 200.0
var _camera_acceleration: float = 5.0
var _camera_velocity: Vector2 = Vector2.ZERO

# 相机边界限制
var _camera_min_x: float = -1000.0
var _camera_max_x: float = 1000.0
var _camera_min_y: float = -1000.0
var _camera_max_y: float = 1000.0

func _ready() -> void:
	_update_mode()
	if hud:
		hud.icon_selected.connect(_on_icon_selected)
		hud.selection_cleared.connect(_on_selection_cleared)

func _input(event: InputEvent) -> void:
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
	
	if current_mode == InputMode.CAMERA:
		_update_camera_drag()
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
			_camera_dragging = event.pressed
			if event.pressed:
				_last_mouse_position = event.position
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_camera(1.0 - _zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_camera(1.0 + _zoom_speed)

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
	var hovered_control = get_viewport().gui_get_hovered_control()
	if hovered_control != null:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_is_placing = event.pressed
			if event.pressed and _is_selection_active():
				_try_place()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_is_removing = event.pressed
			if event.pressed:
				_try_remove()

func _update_placement_preview() -> void:
	var hovered_control = get_viewport().gui_get_hovered_control()
	
	if hovered_control != null:
		_preview_should_be_visible = true
		placement_preview.hide_preview()
		return
	
	if not placement_preview or not _is_selection_active():
		return
	
	if _preview_should_be_visible:
		placement_preview.show_preview()
		_preview_should_be_visible = false
	
	var mouse_pos = get_global_mouse_position()
	placement_preview.update_position(mouse_pos)

func _handle_continuous_placement(delta: float) -> void:
	if _is_placing and _is_selection_active():
		_place_timer += delta
		if _place_timer >= PLACE_INTERVAL:
			_place_timer = 0.0
			_try_place()
	else:
		_place_timer = 0.0
	
	if _is_removing:
		_try_remove()

func _try_place() -> void:
	if not structure_manager or not _is_selection_active():
		return
	
	var mouse_pos = get_global_mouse_position()
	var grid_coord = GridCoord.from_world_coord(Vector2i(mouse_pos))
	structure_manager.spawn(selected_structure_type, grid_coord, selected_color_type)

func _try_remove() -> void:
	if not structure_manager:
		return
	
	var mouse_pos = get_global_mouse_position()
	var grid_coord = GridCoord.from_world_coord(Vector2i(mouse_pos))
	structure_manager.remove(grid_coord)

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
