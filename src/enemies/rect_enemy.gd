class_name RectEnemy extends Enemy

func _initialize_shape() -> void:
	super._initialize_shape()
	if hitbox_shape:
		hitbox_shape.shape.size = enemy_size
	if hurtbox_shape:
		hurtbox_shape.shape.size = enemy_size

func _on_hitbox_area_entered(area: Area2D) -> void:
	super._on_hitbox_area_entered(area)

func _setup_particle_texture(particle: GPUParticles2D) -> void:
	"""设置矩形敌人的死亡粒子纹理"""
	var texture = load("res://assets/particles/rect_particle.png")
	if texture:
		particle.texture = texture
	
