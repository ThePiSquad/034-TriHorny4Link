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

# 游戏计时
var game_timer: float = 0.0

func _ready() -> void:
	# 确保单例
	if instance == null:
		instance = self
	else:
		queue_free()
		return
	
	# 不自动移除，保持跨场景存在
	# add_to_group("game_manager")

func start_game() -> void:
	current_state = GameManager.GameState.PLAYING
	survival_time = 0.0
	enemy_score = 0
	total_score = 0
	game_timer = 0.0
	print("游戏开始")

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
	print("击败敌人，获得分数：", score, "，累计敌人分数：", enemy_score)

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
