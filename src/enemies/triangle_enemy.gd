class_name TriangleEnemy extends Enemy

func _initialize_shape() -> void:
	super._initialize_shape()
	if hitbox_shape:
		hitbox_shape.shape.points[0] = Vector2(0, - enemy_size.y / 2)
		hitbox_shape.shape.points[1] = Vector2(- enemy_size.x / 2, enemy_size.y / 2)
		hitbox_shape.shape.points[2] = Vector2(enemy_size.x / 2, enemy_size.y / 2)
	if hurtbox_shape:
		hurtbox_shape.shape.points[0] = Vector2(0, - enemy_size.y / 2)
		hurtbox_shape.shape.points[1] = Vector2(- enemy_size.x / 2, enemy_size.y / 2)
		hurtbox_shape.shape.points[2] = Vector2(enemy_size.x / 2, enemy_size.y / 2)

func _setup_particle_texture(particle: GPUParticles2D) -> void:
	"""设置三角形敌人的死亡粒子纹理"""
	var texture = load("res://assets/particles/t_particle.png")
	if texture:
		particle.texture = texture
