class_name RectEnemy extends Enemy

func _initialize_shape() -> void:
	super._initialize_shape()
	if hitbox_shape:
		hitbox_shape.shape.size = enemy_size
	if hurtbox_shape:
		hurtbox_shape.shape.size = enemy_size

func _on_hitbox_area_body_entered(body: Node2D) -> void:
	super._on_hitbox_area_body_entered(body)
	print("hit!!rect")
