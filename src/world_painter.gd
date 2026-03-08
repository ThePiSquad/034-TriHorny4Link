extends Node2D

var stateManager:StateManager


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	stateManager = %StateManager

func spawn_structure()->Structure:
	return Crystal.new()
