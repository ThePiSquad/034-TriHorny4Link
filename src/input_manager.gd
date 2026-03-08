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

var _is_placing: bool = false
var _is_removing: bool = false
var _place_timer: float = 0.0
const PLACE_INTERVAL: float = 0.1

var _camera_dragging: bool = false
var _last_mouse_position: Vector2

func _ready() -> void:
	_update_mode()
	
	# 连接 HUD 信号
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
	if current_mode == InputMode.CAMERA:
		_update_camera_drag()
	else:
		_update_placement_preview()
		_handle_continuous_placement(delta)

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
			hud.visible = false
		if placement_preview:
			placement_preview.hide_preview()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		if hud:
			hud.visible = true
		if placement_preview:
			if _is_selection_active():
				placement_preview.show_preview()
			else:
				placement_preview.hide_preview()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _handle_camera_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_camera_dragging = true
				_last_mouse_position = event.position
			else:
				_camera_dragging = false

func _update_camera_drag() -> void:
	if _camera_dragging and camera:
		var current_mouse_position = get_viewport().get_mouse_position()
		var delta = _last_mouse_position - current_mouse_position
		camera.position += delta
		_last_mouse_position = current_mouse_position

func _handle_placement_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_is_placing = event.pressed
			if event.pressed and _is_selection_active():
				_try_place()
		else:
			_is_placing = false
		
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_is_removing = event.pressed
			if event.pressed:
				_try_remove()
		else:
			_is_removing = false

func _update_placement_preview() -> void:
	if not placement_preview or not _is_selection_active():
		return
	
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
	
	structure_manager.spawn(selected_structure_type, grid_coord)

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
	# 根据选中的图标类型设置结构类型
	if icon is ShapeIcon:
		if icon.shape_type == ShapeIcon.ShapeType.RECTANGLE:
			set_selected_structure_type(Enums.StructureType.CONDUIT)
		elif icon.shape_type == ShapeIcon.ShapeType.TRIANGLE:
			set_selected_structure_type(Enums.StructureType.TURRET)
	elif icon is ColorCircle:
		# 根据圆形颜色设置结构类型
		match icon.circle_color:
			Color.RED:
				set_selected_structure_type(Enums.StructureType.CRYSTAL)
			Color.BLUE:
				set_selected_structure_type(Enums.StructureType.MONO_CRYSTAL)
			_:
				set_selected_structure_type(Enums.StructureType.CRYSTAL)
	
	# 显示预览
	if placement_preview:
		placement_preview.show_preview()

func _on_selection_cleared() -> void:
	# 隐藏预览
	if placement_preview:
		placement_preview.hide_preview()
