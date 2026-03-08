extends Enemy

@onready var hit_collision_shape_2d: CollisionShape2D = $HitArea2D/HitCollisionShape2D
@onready var hurt_collision_shape_2d: CollisionShape2D = $HurtArea2D/HurtCollisionShape2D

# @override
func _initialize_shape() -> void:
	super._initialize_shape()
	hit_collision_shape_2d.shape.size = enemy_size
	hurt_collision_shape_2d.shape.size = enemy_size
