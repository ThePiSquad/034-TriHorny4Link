class_name Enemy
extends Node2D

@onready var shape_drawer: ShapeDrawer = $ShapeDrawer
@onready var damageable: Damageable = $Damageable

@export var move_speed: float = 100.0
@export var attack_damage: float = 10.0
@export var enemy_size: Vector2 = Vector2(Constants.grid_size, Constants.grid_size)

var direction: Vector2
var base_position: Vector2 = Vector2.ZERO

func _initialize_shape() -> void:
	shape_drawer.shape_size = enemy_size

func set_base_position(dest_position: Vector2) -> void:
	base_position = dest_position

func take_damage(amount: float, source: Node = null) -> void:
	damageable.take_damage(amount, source)

func _ready() -> void:
	_initialize_shape()
	damageable.died.connect(_on_damageable_died)

func _on_damageable_died(source: Node) -> void:
	queue_free()

func _process(delta: float) -> void:
	_update_movement(delta)

func _update_movement(delta: float) -> void:
	if global_position != base_position:
		direction = (base_position - global_position).normalized()
		_avoid_conduits(direction)
		global_position += direction * move_speed * delta

func _avoid_conduits(direction: Vector2) -> void:
	pass

func _on_hitbox_area_body_entered(body: Node2D) -> void:
	if body and body.has_method("get_structure_type"):
		if body.get_structure_type() == Enums.StructureType.CRYSTAL:
			if body.has_method("take_damage"):
				body.take_damage(attack_damage, self)
			take_damage(damageable.max_health, self) # 自毁
