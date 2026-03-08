class_name PlacementPreview
extends Node2D

@onready var shape_drawer: ShapeDrawer = $ShapeDrawer

var _structure_type: Enums.StructureType = Enums.StructureType.TURRET
var _is_visible: bool = true

func _ready() -> void:
	_update_appearance()

func set_structure_type(type: Enums.StructureType) -> void:
	_structure_type = type
	_update_appearance()

func update_position(world_position: Vector2) -> void:
	if not _is_visible:
		return
	
	var grid_coord = GridCoord.from_world_coord(Vector2i(world_position))
	var grid_world_pos = grid_coord.to_world_coord()
	
	position = Vector2(grid_world_pos) + Vector2(Constants.grid_size / 2, Constants.grid_size / 2)

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
			shape_drawer.fill_color = Color(0.5, 0.5, 0.5, 0.5)
			shape_drawer.stroke_color = Color(1, 1, 1, 0.8)
		Enums.StructureType.CONDUIT:
			shape_drawer.shape_type = Enums.ShapeType.RECTANGLE
			shape_drawer.fill_color = Color(0.5, 0.5, 0.5, 0.5)
			shape_drawer.stroke_color = Color(1, 1, 1, 0.8)
		Enums.StructureType.CRYSTAL:
			shape_drawer.shape_type = Enums.ShapeType.CIRCLE
			shape_drawer.fill_color = Color(0.5, 0.5, 0.5, 0.5)
			shape_drawer.stroke_color = Color(1, 1, 1, 0.8)
		Enums.StructureType.MONO_CRYSTAL:
			shape_drawer.shape_type = Enums.ShapeType.CIRCLE
			shape_drawer.fill_color = Color(0.5, 0.5, 0.5, 0.5)
			shape_drawer.stroke_color = Color(1, 1, 1, 0.8)
	
	shape_drawer.shape_size = Vector2(Constants.grid_size, Constants.grid_size)
	shape_drawer.queue_redraw()
