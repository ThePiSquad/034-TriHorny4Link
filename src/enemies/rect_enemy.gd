extends Enemy

func _initialize_shape() -> void:
	super._initialize_shape()
	if damageable.hitbox_shape:
		damageable.hitbox_shape.shape.size = enemy_size
	if damageable.hurtbox_shape:
		damageable.hurtbox_shape.shape.size = enemy_size
