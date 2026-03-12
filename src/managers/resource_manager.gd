class_name ResourceManager
extends Node

signal resource_changed

var resources: Dictionary = {
	"red": 20,
	"blue": 20,
	"yellow": 20
}

var max_storage: int = Constants.ResourceConstants.MAX_STORAGE
var production_rate: float = Constants.ResourceConstants.PRODUCTION_RATE
var production_timer: float = 0.0

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	production_timer += delta
	
	if production_timer >= 1.0:
		production_timer = 0.0
		produce_resources()

func produce_resources() -> void:
	for resource_type in resources:
		var current_amount = resources[resource_type]
		var new_amount = min(current_amount + production_rate, max_storage)
		if new_amount != current_amount:
			resources[resource_type] = new_amount
			resource_changed.emit()

func get_resource(resource_type: String) -> int:
	if resources.has(resource_type):
		return resources[resource_type]
	return 0

func get_resource_ratio(resource_type: String) -> float:
	if resources.has(resource_type):
		return float(resources[resource_type]) / float(max_storage)
	return 0.0

func has_enough_resources(resource_type: String, amount: int) -> bool:
	if resources.has(resource_type):
		return resources[resource_type] >= amount
	return false

func has_enough_resources_all(red_amount: int, blue_amount: int, yellow_amount: int) -> bool:
	return resources["red"] >= red_amount and resources["blue"] >= blue_amount and resources["yellow"] >= yellow_amount

func consume_resources(resource_type: String, amount: int) -> bool:
	if not has_enough_resources(resource_type, amount):
		return false
	
	resources[resource_type] -= amount
	resource_changed.emit()
	return true

func consume_resources_all(red_amount: int, blue_amount: int, yellow_amount: int) -> bool:
	if not has_enough_resources_all(red_amount, blue_amount, yellow_amount):
		return false
	
	resources["red"] -= red_amount
	resources["blue"] -= blue_amount
	resources["yellow"] -= yellow_amount
	resource_changed.emit()
	return true

func get_all_resources() -> Dictionary:
	return resources.duplicate()

func set_resources(red: int, blue: int, yellow: int) -> void:
	resources["red"] = clamp(red, 0, max_storage)
	resources["blue"] = clamp(blue, 0, max_storage)
	resources["yellow"] = clamp(yellow, 0, max_storage)
	resource_changed.emit()

func add_resources(resource_type: String, amount: int) -> void:
	if resources.has(resource_type):
		resources[resource_type] = clamp(resources[resource_type] + amount, 0, max_storage)
		resource_changed.emit()

func add_resources_all(red_amount: int, blue_amount: int, yellow_amount: int) -> void:
	resources["red"] = clamp(resources["red"] + red_amount, 0, max_storage)
	resources["blue"] = clamp(resources["blue"] + blue_amount, 0, max_storage)
	resources["yellow"] = clamp(resources["yellow"] + yellow_amount, 0, max_storage)
	resource_changed.emit()

func get_max_storage() -> int:
	return max_storage

func get_production_rate() -> float:
	return production_rate
