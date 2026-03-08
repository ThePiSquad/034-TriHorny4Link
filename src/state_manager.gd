@tool
class_name StateManager
extends Node

var state: GameState


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	state = GameState.new()
