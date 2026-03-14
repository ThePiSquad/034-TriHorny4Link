extends Structure
class_name Crystal

# 游戏开始时间
var _game_start_time: float = 0.0
var _is_game_started: bool = false

# 死亡粒子特效
var broken_particle_scene: PackedScene = preload("res://src/particles/broken_ptc.tscn")

func _ready() -> void:
	super._ready()
	# 添加到 crystal 组，让敌人能够找到
	add_to_group("crystal")
	print("Crystal 添加到组：crystal，位置：", global_position)
	
	# 启动游戏
	_start_game()

func _start_game() -> void:
	"""游戏开始"""
	_is_game_started = true
	_game_start_time = Time.get_ticks_msec() / 1000.0
	print("游戏开始，Crystal 初始化完成")

func on_health_depleted() -> void:
	"""Crystal 被摧毁时的处理（重写 Structure 的方法）"""
	super.on_health_depleted()
	print("Crystal 被摧毁！")
	
	# 播放死亡粒子特效
	_spawn_broken_particle()
	
	# 结束游戏
	_end_game()

func _spawn_broken_particle() -> void:
	"""播放 Crystal 被摧毁的粒子特效"""
	if broken_particle_scene:
		var particle = broken_particle_scene.instantiate()
		if particle:
			get_parent().add_child(particle)
			particle.global_position = global_position
			print("播放 Crystal 死亡粒子特效")

func _end_game() -> void:
	"""结束游戏"""
	# 获取 GameManager 实例
	var game_manager = GameManager.instance
	if game_manager:
		# 计算最终生存时间
		var current_time = Time.get_ticks_msec() / 1000.0
		game_manager.survival_time = current_time - _game_start_time
		print("游戏结束，生存时间：", game_manager.survival_time, " 秒")
		
		# 触发游戏结束
		game_manager.end_game()
	else:
		push_warning("GameManager 实例不存在，无法结束游戏")
