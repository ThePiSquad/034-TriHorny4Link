class_name Enemy
extends Node2D

signal died(enemy: Enemy)

@onready var shape_drawer: ShapeDrawer = $ShapeDrawer

var current_health: float
var direction: Vector2

@export var move_speed: float = 100.0
@export var attack_damage: float = 10.0
@export var enemy_size: Vector2 
# 目标位置
@export var base_position: Vector2 = Vector2.ZERO

# "Enemy subclass need implement _initialize_shape()"
func _initialize_shape() -> void:
	shape_drawer.shape_size = enemy_size

func set_base_position(dest_position: Vector2) -> void:
	base_position = dest_position

func take_damage(amount: float) -> void:
	current_health -= amount
	if current_health <= 0:
		_die()

func _die() -> void:
	died.emit(self)
	queue_free()

func _ready() -> void:
	_initialize_shape()

func _process(delta: float) -> void:
	_update_movement(delta)

func _update_movement(delta: float) -> void:
	if global_position != base_position:
		direction = (base_position - global_position).normalized()
		_avoid_conduits(direction)
		global_position += direction * move_speed * delta

# 避障逻辑
func _avoid_conduits(direction: Vector2) -> void:
	#var conduit_nodes = get_tree().get_nodes_in_group("conduits")
	#for conduit in conduit_nodes:
		#if conduit and conduit.has_method("get_structure_type") and conduit.get_structure_type() == Enums.StructureType.CONDUIT:
			#var distance = global_position.distance_to(conduit.global_position)
			#if distance < 100.0:
				#var avoid_direction = (global_position - conduit.global_position).normalized()
				#direction += avoid_direction * 0.5
				#direction = direction.normalized()
	# TODO
	pass

# 碰到原色水晶，造成伤害并且销毁自己
func _on_hit_area_2d_body_entered(body: Node2D) -> void:
	if body and body.has_method("get_structure_type"):
		if body.get_structure_type() == Enums.StructureType.CRYSTAL:
			if body.has_method("take_damage"):
				body.take_damage(attack_damage)
			_die()
