extends GPUParticles2D

func _ready() -> void:
	# 发射粒子
	emitting = true
	
	# 在粒子生命周期结束后自动销毁
	await get_tree().create_timer(lifetime * 2 + 0.1).timeout
	queue_free()
