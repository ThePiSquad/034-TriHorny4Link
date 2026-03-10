extends Resource

class_name GameState

var difficulty:int = 1
var upgrade:UpgradableState = UpgradableState.new()
var enermies:EnermyCollection = EnermyCollection.new()

var is_energy_value_display : bool = false

class UpgradableState:
	var turret_range:int = 0
	var resource_generation:int = 0
	var crystal_energy:int = 0
	var storage:int = 0
	
class EnermyCollection:
	pass
