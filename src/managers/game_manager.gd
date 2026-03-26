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

func _ready() -> void:
	instance = self

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
	# 游戏结束后的处理逻辑
	# 停止 BGM
	AudioManager.stop_bgm()

func get_score_data() -> Dictionary:
	return {
		"survival_time": survival_time,
		"enemy_score": enemy_score,
		"total_score": total_score
	}
