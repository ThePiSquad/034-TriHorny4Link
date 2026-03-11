class_name Enemy
extends Damageable

@onready var shape_drawer: ShapeDrawer = $ShapeDrawer

@export var move_speed: float = 100.0
@export var attack_damage: float = 10.0
@export var enemy_size: Vector2 = Vector2(Constants.grid_size, Constants.grid_size)

var direction: Vector2
var base_position: Vector2 = Vector2.ZERO

func _initialize_shape() -> void:
	shape_drawer.shape_size = enemy_size

func set_base_position(dest_position: Vector2) -> void:
	base_position = dest_position

func _ready() -> void:
	super._ready()
	_initialize_shape()
	died.connect(_on_damageable_died)

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

func _on_hitbox_area_entered(area: Area2D) -> void:
	# 获取Area2D的父节点（实际的Structure对象）
	var body = area.get_parent()
	if body and body.has_method("get_structure_type"):
		if body.get_structure_type() == Enums.StructureType.CRYSTAL:
			body.take_damage(attack_damage, self)
			take_damage(max_health, self) # 自毁
