extends GPUParticles2D

func _ready() -> void:
	# 添加到 particle 组，便于管理
	add_to_group("particle")
	
	# 发射粒子
	emitting = true
	
	# 在粒子生命周期结束后自动销毁
	await get_tree().create_timer(lifetime + 0.1).timeout
	queue_free()
