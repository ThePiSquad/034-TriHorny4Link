extends Node

var state:GameState


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	state = GameState.new()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
