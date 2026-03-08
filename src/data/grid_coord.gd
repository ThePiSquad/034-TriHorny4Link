class_name GridCoord
extends RefCounted

var x: int
var y: int


func _init(p_x: int, p_y: int) -> void:
	x = p_x
	y = p_y


func north() -> GridCoord:
	return GridCoord.new(x, y - 1)


func south() -> GridCoord:
	return GridCoord.new(x, y + 1)


func west() -> GridCoord:
	return GridCoord.new(x - 1, y)


func east() -> GridCoord:
	return GridCoord.new(x + 1, y)


func to_world_coord() -> Vector2i:
	return Vector2i(x * Constants.grid_size, y * Constants.grid_size)


static func from_world_coord(pos: Vector2i) -> GridCoord:
	return GridCoord.new(
		pos.x / Constants.grid_size, 
		pos.y / Constants.grid_size
	)
