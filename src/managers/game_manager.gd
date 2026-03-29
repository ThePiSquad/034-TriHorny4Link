extends Node
class_name GameManager

# 游戏状态
enum GameState {
	PLAYING,
	GAME_OVER
}

# 信号
signal game_over_signal

# 单例实例
static var instance: GameManager

# 游戏数据
var current_state: GameManager.GameState = GameManager.GameState.PLAYING
var survival_time: float = 0.0  # 生存时间（秒）
var enemy_score: int = 0  # 击败敌人累计分数
var total_score: int = 0  # 总分数
var selected_level: String = "level_1"  # 选中的关卡
var is_victory: bool = false  # 是否是胜利结局

# 按炮塔颜色统计伤害
var damage_by_color: Dictionary = {}

# 游戏计时
var game_timer: float = 0.0

# 关卡进度
var unlocked_levels: Array[String] = ["tutorial", "level_0", "level_1"]
var completed_levels: Array[String] = []

const SAVE_FILE_PATH = "user://game_progress.cfg"

func _ready() -> void:
	instance = self
	_load_progress()

func start_game() -> void:
	current_state = GameManager.GameState.PLAYING
	survival_time = 0.0
	enemy_score = 0
	total_score = 0
	game_timer = 0.0
	_initialize_damage_stats()
	print("游戏开始")

func _initialize_damage_stats() -> void:
	damage_by_color = {}
	for color in Enums.ColorType.keys():
		damage_by_color[Enums.ColorType[color]] = 0

func add_damage_by_color(color: Enums.ColorType, damage: int) -> void:
	if not damage_by_color.has(color):
		damage_by_color[color] = 0
	damage_by_color[color] += damage

func end_game() -> void:
	if current_state == GameManager.GameState.GAME_OVER:
		return
	
	current_state = GameManager.GameState.GAME_OVER
	# 修改：总分仅统计敌人分数，不包含生存时间
	total_score = enemy_score
	print("游戏结束")
	print("生存时间：", survival_time, " 秒")
	print("敌人分数：", enemy_score)
	print("总分数：", total_score)
	
	# 触发游戏结束事件
	game_over_signal.emit()
	_on_game_over()

func _process(delta: float) -> void:
	if current_state == GameManager.GameState.PLAYING:
		game_timer += delta
		survival_time = game_timer

func add_enemy_score(score: int) -> void:
	enemy_score += score

func _on_game_over() -> void:
	pass

func get_score_data() -> Dictionary:
	return {
		"survival_time": survival_time,
		"enemy_score": enemy_score,
		"total_score": total_score
	}

func unlock_level(level_id: String) -> void:
	if not level_id in unlocked_levels:
		unlocked_levels.append(level_id)
		_save_progress()

func complete_level(level_id: String) -> void:
	if not level_id in completed_levels:
		completed_levels.append(level_id)
	
	if not level_id in unlocked_levels:
		unlocked_levels.append(level_id)
	
	var level_num = _get_next_level_number(level_id)
	if level_num > 0:
		var next_level = "level_" + str(level_num)
		if not next_level in unlocked_levels:
			unlocked_levels.append(next_level)
	
	_save_progress()

func _get_next_level_number(level_id: String) -> int:
	if level_id == "tutorial":
		return 0
	if level_id == "level_0":
		return 1
	var regex = RegEx.new()
	regex.compile("level_(\\d+)")
	var result = regex.search(level_id)
	if result:
		return result.get_string(1).to_int() + 1
	return -1

func is_level_unlocked(level_id: String) -> bool:
	return level_id in unlocked_levels

func is_level_completed(level_id: String) -> bool:
	return level_id in completed_levels

func _save_progress() -> void:
	var config = ConfigFile.new()
	config.set_value("progress", "unlocked_levels", unlocked_levels)
	config.set_value("progress", "completed_levels", completed_levels)
	var err = config.save(SAVE_FILE_PATH)
	if err != OK:
		print("保存进度失败: ", err)
	else:
		print("进度已保存")

func _load_progress() -> void:
	var config = ConfigFile.new()
	var err = config.load(SAVE_FILE_PATH)
	if err != OK:
		print("加载进度失败或文件不存在，使用默认进度")
		return
	
	unlocked_levels = config.get_value("progress", "unlocked_levels", ["tutorial", "level_0", "level_1"])
	completed_levels = config.get_value("progress", "completed_levels", [])
	print("进度已加载: 已解锁=", unlocked_levels, " 已完成=", completed_levels)
