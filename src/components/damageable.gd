class_name Damageable
extends Node2D

signal health_changed(current: float, max: float)
signal died(source: Node)

@onready var hitbox_area: Area2D = $HitboxArea
@onready var hurtbox_area: Area2D = $HurtboxArea
@onready var hitbox_shape: CollisionShape2D = $HitboxArea/CollisionShape2D
@onready var hurtbox_shape: CollisionShape2D = $HurtboxArea/CollisionShape2D

@export var max_health: float = 100.0:
	set(value):
		max_health = max(1.0, value)
		if current_health > max_health:
			current_health = max_health

var current_health: float:
	get:
		return current_health
	set(value):
		var old_health = current_health
		current_health = clamp(value, 0.0, max_health)
		if old_health != current_health:
			health_changed.emit(current_health, max_health)
			if current_health <= 0.0:
				died.emit(_last_damage_source)

var _last_damage_source: Node = null

func _ready() -> void:
	current_health = max_health
	

func take_damage(amount: float, source: Node = null) -> void:
	if current_health <= 0.0:
		_on_death()
		return
	
	_last_damage_source = source
	current_health -= amount
	if current_health <= 0.0:	_on_death()


func get_health() -> float:
	return current_health

func get_max_health() -> float:
	return max_health

func get_health_percentage() -> float:
	return current_health / max_health

func is_dead() -> bool:
	return current_health <= 0.0

func is_alive() -> bool:
	return current_health > 0.0

func _on_death() -> void:
	if has_method("on_health_depleted"):
		call("on_health_depleted")
	queue_free()
	pass
