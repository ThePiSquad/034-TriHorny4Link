class_name WaveSystem extends RefCounted

## 波次系统
## 管理游戏波次进度和敌人生成逻辑

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
var current_preparing_wave: int = 0  # 当前正在准备的波次（用于信号传递）
var total_wave_count: int = 10      # 常规波次数
var boss_wave_count: int = 1        # Boss 波次数

# 关卡数据（从 ResourceManager 加载）
var current_level_data: LevelData = null

# 默认波次配置（向后兼容）
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

## 加载关卡数据
## 参数:
## level_id: 关卡唯一标识符
## 返回: 是否加载成功
func load_level(level_id: String) -> bool:
	print("WaveSystem: 开始加载关卡 ", level_id)
	print("ResourceManager.instance 是否存在：", ResourceManager.instance != null)
	
	if not ResourceManager.instance:
		push_error("ResourceManager 实例不存在")
		return false
	
	var level_data = ResourceManager.instance.load_level(level_id)
	print("level_data 是否为空：", level_data == null)
	
	if not level_data:
		push_error("关卡加载失败：" + level_id)
		return false
	
	current_level_data = level_data
	total_wave_count = level_data.get_wave_count()
	boss_wave_count = 1 if level_data.has_boss_wave() else 0
	
	print("关卡加载成功：", level_data.level_name, " (", total_wave_count, " 波)")
	return true

## 重置波次系统
func reset() -> void:
	current_wave = 0
	current_state = WaveState.IDLE
	current_wave_progress = 0
	preparation_timer = 0.0
	spawn_timer = 0.0

## 推进到下一波
## 返回: 是否还有波次
func advance_to_next_wave() -> bool:
	if current_level_data:
		# 使用关卡数据
		if current_wave >= current_level_data.get_wave_count():
			return false
		
		# 保存当前正在准备的波次
		current_preparing_wave = current_wave
		
		# 进入准备状态
		current_state = WaveState.PREPARING
		preparation_timer = 0.0
		current_wave_progress = 0
		
		# 发射准备信号
		wave_preparing.emit(current_preparing_wave)
		
		# 增加波次号
		current_wave += 1
		
		if current_level_data.has_boss_wave() and current_wave > current_level_data.boss_wave_index:
			boss_wave_started.emit()
		
		return true
	else:
		# 使用默认配置
		if current_wave >= total_wave_count + boss_wave_count:
			return false
		
		# 保存当前正在准备的波次
		current_preparing_wave = current_wave
		
		# 进入准备状态
		current_state = WaveState.PREPARING
		preparation_timer = 0.0
		current_wave_progress = 0
		
		# 发射准备信号
		wave_preparing.emit(current_preparing_wave)
		
		# 增加波次号
		current_wave += 1
		
		if current_wave > total_wave_count:
			boss_wave_started.emit()
		
		return true

## 检查是否有波次正在进行
func is_wave_active() -> bool:
	return current_state != WaveState.IDLE and current_state != WaveState.COMPLETED

## 检查是否是 Boss 波
func is_boss_wave() -> bool:
	if current_level_data:
		var wave_data = current_level_data.get_wave(current_preparing_wave)
		return wave_data != null and wave_data.is_boss_wave
	else:
		return current_preparing_wave > total_wave_count

## 获取当前波次信息
func get_current_wave_info() -> Dictionary:
	if current_level_data:
		var wave_data = current_level_data.get_wave(current_preparing_wave)
		if wave_data:
			return {
				"wave_number": current_preparing_wave,
				"wave_name": wave_data.wave_name,
				"size": _get_wave_size_level(wave_data),
				"total_count": wave_data.get_total_enemy_count(),
				"spawned_count": current_wave_progress,
				"is_boss": wave_data.is_boss_wave,
				"remaining_count": wave_data.get_total_enemy_count() - current_wave_progress,
				"preparation_time": wave_data.preparation_time,
				"spawn_interval": wave_data.spawn_interval,
				"wave_interval": wave_data.wave_interval,
				"require_clear_previous": wave_data.require_clear_previous,
				"min_enemies_alive": wave_data.min_enemies_alive,
				"enemy_configs": wave_data.enemy_configs
			}
	
	# 使用默认配置
	if current_preparing_wave <= 0 or current_preparing_wave > total_wave_count + boss_wave_count:
		return {}
	
	var wave_config = wave_intervals.waves.get(current_preparing_wave, {})
	return {
		"wave_number": current_preparing_wave,
		"wave_name": "第 " + str(current_preparing_wave) + " 波",
		"size": wave_config.get("size", 1),
		"total_count": wave_config.get("count", 0),
		"spawned_count": current_wave_progress,
		"is_boss": is_boss_wave(),
		"remaining_count": wave_config.get("count", 0) - current_wave_progress,
		"preparation_time": wave_intervals.preparation_time,
		"spawn_interval": wave_intervals.spawn_interval,
		"wave_interval": 2.0,
		"require_clear_previous": false,
		"min_enemies_alive": 0
	}

## 获取波次体型等级
func _get_wave_size_level(wave_data: WaveData) -> int:
	if wave_data.enemy_configs.is_empty():
		return 1
	
	# 返回第一个敌人配置的体型等级
	var first_config = wave_data.enemy_configs[0]
	if first_config.use_random_size:
		return first_config.size_level_max
	return first_config.size_level

## 更新波次系统
func update(delta: float) -> void:
	match current_state:
		WaveState.PREPARING:
			var prep_time = _get_preparation_time()
			preparation_timer += delta
			if preparation_timer >= prep_time:
				# 准备时间结束，进入生成阶段
				current_state = WaveState.SPAWNING
				spawn_timer = 0.0
				wave_started.emit(current_preparing_wave)
		
		WaveState.SPAWNING:
			# 敌人生成由 EnemyManager 负责，这里只负责状态管理
			# 检查波次是否应该完成
			if current_level_data:
				var wave_data = current_level_data.get_wave(current_preparing_wave)
				if wave_data and current_wave_progress >= wave_data.get_total_enemy_count():
					# 当前波次完成
					current_state = WaveState.COMPLETED
					wave_completed.emit(current_preparing_wave)
			else:
				var wave_config = wave_intervals.waves.get(current_preparing_wave, {})
				var total_count = wave_config.get("count", 0)
				if current_wave_progress >= total_count:
					# 当前波次完成
					current_state = WaveState.COMPLETED
					wave_completed.emit(current_preparing_wave)
		
		WaveState.COMPLETED:
			# 等待进入下一波
			pass

## 获取准备时间
func _get_preparation_time() -> float:
	if current_level_data:
		var wave_data = current_level_data.get_wave(current_preparing_wave)
		if wave_data:
			return wave_data.preparation_time
	return wave_intervals.preparation_time

## 获取生成间隔
func get_spawn_interval() -> float:
	if current_level_data:
		var wave_data = current_level_data.get_wave(current_preparing_wave)
		if wave_data:
			return wave_data.spawn_interval
	return wave_intervals.spawn_interval

## 获取生成间隔（内部使用）
func _get_spawn_interval() -> float:
	return get_spawn_interval()

## 检查当前波次是否完成
func is_current_wave_completed() -> bool:
	if current_preparing_wave <= 0:
		return false
	
	if current_level_data:
		var wave_data = current_level_data.get_wave(current_preparing_wave)
		if wave_data:
			return current_wave_progress >= wave_data.get_total_enemy_count() and current_state == WaveState.COMPLETED
		else:
			return false
	else:
		var wave_config = wave_intervals.waves.get(current_preparing_wave, {})
		return current_wave_progress >= wave_config.get("count", 0) and current_state == WaveState.COMPLETED

## 检查是否所有波次都已完成
func is_all_waves_completed() -> bool:
	if current_level_data:
		return current_wave >= current_level_data.get_wave_count() and current_state == WaveState.COMPLETED
	else:
		return current_wave >= total_wave_count + boss_wave_count and current_state == WaveState.COMPLETED

## 增加波次进度
func increment_wave_progress() -> void:
	current_wave_progress += 1

## 获取关卡数据
func get_level_data() -> LevelData:
	return current_level_data

## 获取波次数据
func get_wave_data(wave_index: int) -> WaveData:
	if current_level_data:
		return current_level_data.get_wave(wave_index)
	return null
