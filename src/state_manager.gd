extends Node

class_name StateManager

var state:GameState


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	state = GameState.new()
