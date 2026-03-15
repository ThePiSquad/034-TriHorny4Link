class_name WaveSystem
extends RefCounted

# 波次状态枚举
enum WaveState {
	IDLE,           # 空闲状态
	PREPARING,      # 波次准备中（提示阶段）
	SPAWNING,       # 正在生成敌人
	COMPLETED       # 波次完成
}

# 当前波次系统状态
var current_wave: int = 0
var current_state: WaveState = WaveState.IDLE
var current_wave_progress: int = 0  # 当前波次已生成的敌人数量
var total_wave_count: int = 10      # 常规波次数
var boss_wave_count: int = 1        # Boss 波次数

# 波次配置
var wave_intervals: Dictionary = {
	"preparation_time": 3.0,    # 波次准备时间（秒）
	"spawn_interval": 0.8,      # 敌人生存间隔（秒）
	"waves": {                  # 每波敌人配置
		1: {"size": 1, "count": 5},      # 第1波：体型1，5个敌人
		2: {"size": 2, "count": 6},      # 第2波：体型2，6个敌人
		3: {"size": 3, "count": 7},      # 第3波：体型3，7个敌人
		4: {"size": 4, "count": 8},      # 第4波：体型4，8个敌人
		5: {"size": 5, "count": 9},      # 第5波：体型5，9个敌人
		6: {"size": 6, "count": 10},     # 第6波：体型6，10个敌人
		7: {"size": 7, "count": 10},     # 第7波：体型7，10个敌人
		8: {"size": 8, "count": 12},     # 第8波：体型8，12个敌人
		9: {"size": 9, "count": 12},     # 第9波：体型9，12个敌人
		10: {"size": 10, "count": 15},   # 第10波：体型10，15个敌人
		11: {"size": 20, "count": 1},    # Boss波：体型20（256x256），1个敌人
	}
}

# 时间跟踪
var preparation_timer: float = 0.0
var spawn_timer: float = 0.0

# 信号
signal wave_started(wave_number: int)
signal wave_preparing(wave_number: int)
signal wave_completed(wave_number: int)
signal all_waves_completed()
signal boss_wave_started()
signal boss_defeated()

func _init() -> void:
	reset()

func reset() -> void:
	"""重置波次系统"""
	current_wave = 0
	current_state = WaveState.IDLE
	current_wave_progress = 0
	preparation_timer = 0.0
	spawn_timer = 0.0

func advance_to_next_wave() -> bool:
	"""推进到下一波，返回是否还有波次"""
	if current_wave >= total_wave_count + boss_wave_count:
		return false
	
	current_wave += 1
	current_state = WaveState.PREPARING
	preparation_timer = 0.0
	current_wave_progress = 0
	
	# 发射准备信号
	wave_preparing.emit(current_wave)
	
	if current_wave > total_wave_count:
		boss_wave_started.emit()
	
	return true

func is_wave_active() -> bool:
	"""检查是否有波次正在进行"""
	return current_state != WaveState.IDLE and current_state != WaveState.COMPLETED

func is_boss_wave() -> bool:
	"""检查是否是 Boss 波"""
	return current_wave > total_wave_count

func get_current_wave_info() -> Dictionary:
	"""获取当前波次信息"""
	if current_wave <= 0 or current_wave > total_wave_count + boss_wave_count:
		return {}
	
	var wave_config = wave_intervals.waves[current_wave]
	return {
		"wave_number": current_wave,
		"size": wave_config.size,
		"total_count": wave_config.count,
		"spawned_count": current_wave_progress,
		"is_boss": is_boss_wave(),
		"remaining_count": wave_config.count - current_wave_progress
	}

func update(delta: float) -> void:
	"""更新波次系统"""
	match current_state:
		WaveState.PREPARING:
			preparation_timer += delta
			if preparation_timer >= wave_intervals.preparation_time:
				# 准备时间结束，进入生成阶段
				current_state = WaveState.SPAWNING
				spawn_timer = 0.0
				print("波次 ", current_wave, " 准备完成，开始生成敌人！")
				wave_started.emit(current_wave)
		
		WaveState.SPAWNING:
			# 检查是否应该生成下一个敌人
			spawn_timer += delta
			if spawn_timer >= wave_intervals.spawn_interval:
				spawn_timer = 0.0
				
				# 获取当前波次配置
				var wave_config = wave_intervals.waves[current_wave]
				
				# 检查是否已完成当前波次的所有敌人生成
				if current_wave_progress < wave_config.count:
					current_wave_progress += 1
					print("生成第 ", current_wave_progress, "/", wave_config.count, " 个敌人")
				else:
					# 当前波次完成
					current_state = WaveState.COMPLETED
					print("波次 ", current_wave, " 完成！")
					wave_completed.emit(current_wave)
					
					# 如果是 Boss 波且被击败
					if is_boss_wave():
						boss_defeated.emit()
		
		WaveState.COMPLETED:
			# 等待进入下一波
			pass

func is_current_wave_completed() -> bool:
	"""检查当前波次是否完成"""
	if current_wave <= 0:
		return false
	
	var wave_config = wave_intervals.waves[current_wave]
	return current_wave_progress >= wave_config.count and current_state == WaveState.COMPLETED

func is_all_waves_completed() -> bool:
	"""检查是否所有波次都已完成"""
	return current_wave >= total_wave_count + boss_wave_count and current_state == WaveState.COMPLETED
