class_name PlacementPreview
extends Node2D

@onready var shape_drawer: ShapeDrawer = $ShapeDrawer

var _structure_type: Enums.StructureType = Enums.StructureType.TURRET
var _is_visible: bool = true
var _structure_manager: StructureManager

var _valid_fill_color: Color = Color(0.5, 0.5, 0.5, 0.5)
var _valid_stroke_color: Color = Color(1, 1, 1, 0.8)
var _invalid_fill_color: Color = Color(1, 0, 0, 0.5)
var _invalid_stroke_color: Color = Color(1, 0.3, 0.3, 0.8)

func _ready() -> void:
	_update_appearance()

func set_structure_manager(manager: StructureManager) -> void:
	_structure_manager = manager

func set_structure_type(type: Enums.StructureType) -> void:
	_structure_type = type
	_update_appearance()

func update_position(world_position: Vector2) -> void:
	if not _is_visible:
		return
	
	var grid_coord = GridCoord.from_world_coord(Vector2i(world_position))
	var grid_world_pos = grid_coord.to_world_coord()
	
	position = Vector2(grid_world_pos) + Vector2(Constants.grid_size / 2, Constants.grid_size / 2)
	
	# 检查放置有效性并更新颜色
	_update_validity_color(grid_coord)

func _update_validity_color(grid_coord: GridCoord) -> void:
	"""根据放置有效性更新颜色"""
	if not shape_drawer:
		return
	
	var is_valid = true
	
	# 检查炮塔放置限制
	if _structure_type == Enums.StructureType.TURRET and _structure_manager:
		is_valid = _structure_manager.can_place_turret(grid_coord)
	
	# 更新颜色
	if is_valid:
		shape_drawer.fill_color = _valid_fill_color
		shape_drawer.stroke_color = _valid_stroke_color
	else:
		shape_drawer.fill_color = _invalid_fill_color
		shape_drawer.stroke_color = _invalid_stroke_color
	
	shape_drawer.queue_redraw()

func show_preview() -> void:
	_is_visible = true
	visible = true

func hide_preview() -> void:
	_is_visible = false
	visible = false

func _update_appearance() -> void:
	if not shape_drawer:
		return
	
	match _structure_type:
		Enums.StructureType.TURRET:
			shape_drawer.shape_type = Enums.ShapeType.TRIANGLE
		Enums.StructureType.CONDUIT:
			shape_drawer.shape_type = Enums.ShapeType.RECTANGLE
		Enums.StructureType.CRYSTAL:
			shape_drawer.shape_type = Enums.ShapeType.CIRCLE
		Enums.StructureType.MONO_CRYSTAL:
			shape_drawer.shape_type = Enums.ShapeType.CIRCLE
	
	shape_drawer.shape_size = Vector2(Constants.grid_size, Constants.grid_size)
	shape_drawer.queue_redraw()
