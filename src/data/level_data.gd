class_name LevelData extends Resource

## 关卡数据类
## 定义单个关卡的所有配置信息

@export var level_id: String = ""  ## 关卡唯一标识符
@export var level_name: String = ""  ## 关卡名称
@export var level_description: String = ""  ## 关卡描述
@export var waves: Array[WaveData] = []  ## 关卡包含的所有波次
@export var difficulty: int = 1  ## 关卡难度等级（1-10）
@export var recommended_level: int = 1  ## 推荐玩家等级
@export var boss_wave_index: int = -1  ## Boss 波次索引（-1 表示无 Boss）

## 获取指定波次的数据
func get_wave(wave_index: int) -> WaveData:
	if wave_index >= 0 and wave_index < waves.size():
		return waves[wave_index]
	return null

## 获取波次总数
func get_wave_count() -> int:
	return waves.size()

## 检查是否包含 Boss 波次
func has_boss_wave() -> bool:
	return boss_wave_index >= 0 and boss_wave_index < waves.size()

## 获取 Boss 波次数据
func get_boss_wave() -> WaveData:
	if has_boss_wave():
		return waves[boss_wave_index]
	return null