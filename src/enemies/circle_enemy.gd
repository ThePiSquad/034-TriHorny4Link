extends Enemy

func _initialize_shape() -> void:
	super._initialize_shape()
	if hitbox_shape:
		hitbox_shape.shape.radius = enemy_size.x / 2
	if hurtbox_shape:
		hurtbox_shape.shape.radius = enemy_size.x / 2

func _setup_particle_texture(particle: GPUParticles2D) -> void:
	"""设置圆形敌人的死亡粒子纹理"""
	var texture = load("res://assets/particles/circle_particle.png")
	if texture:
		particle.texture = texture
	
