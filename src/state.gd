extends Resource

class_name GameState

var difficulty:int = 1.0
var upgrade:UpgradableState = UpgradableState.new()


class UpgradableState:
	var turret_range:int = 0
	var resource_generation:int = 0
	var crystal_energy:int = 0



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
