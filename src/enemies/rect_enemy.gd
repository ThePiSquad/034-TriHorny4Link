class_name RectEnemy extends Enemy

func _initialize_shape() -> void:
	super._initialize_shape()
	if hitbox_shape:
		hitbox_shape.shape.size = enemy_size
	if hurtbox_shape:
		hurtbox_shape.shape.size = enemy_size

func _on_hitbox_area_entered(area: Area2D) -> void:
	super._on_hitbox_area_entered(area)
	
