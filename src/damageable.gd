class_name Damageable
extends Node2D

@export var max_health:int
@export var health: int

signal health_depleted
signal health_update(value:int)

func damage(amount:int)->int:
	health-=amount
	if health<0:
		health_depleted.emit()
		health = 0
	health_update.emit(health)
	return health
