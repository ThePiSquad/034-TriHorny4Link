extends Control
class_name GameOverScreen

# 分数显示容器
@onready var score_container: VBoxContainer = $MarginContainer/VBoxContainer/ScoreContainer
@onready var restart_button: Button = $MarginContainer/VBoxContainer/ButtonContainer/RestartButton
@onready var main_menu_button: Button = $MarginContainer/VBoxContainer/ButtonContainer/MainMenuButton

# 游戏数据
var survival_time: float = 0.0
var enemy_score: int = 0
var total_score: int = 0

# 图案显示场景
var pattern_display_scene: PackedScene

func _ready() -> void:
	# 连接按钮信号
	if restart_button:
		restart_button.pressed.connect(_on_restart_button_pressed)
	if main_menu_button:
		main_menu_button.pressed.connect(_on_main_menu_button_pressed)
	
	# 尝试加载图案显示场景
	_load_pattern_display_scene()
	
	# 获取游戏数据
	var game_manager = GameManager.instance
	if game_manager:
		survival_time = game_manager.survival_time
		enemy_score = game_manager.enemy_score
		total_score = game_manager.total_score
	
	# 显示分数
	_display_scores()

func _load_pattern_display_scene() -> void:
	"""加载图案显示场景"""
	var path = "res://src/ui/score_pattern_display.tscn"
	if ResourceLoader.exists(path):
		pattern_display_scene = load(path)
		print("成功加载图案显示场景")
	else:
		pattern_display_scene = null
		print("警告：无法加载图案显示场景:", path)

func _display_scores() -> void:
	"""显示所有分数信息"""
	# 清空现有显示
	for child in score_container.get_children():
		child.queue_free()
	
	# 1. 显示生存时间（用蓝色图形表示，每秒 1 分）
	_add_section_title()
	_display_survival_time()
	
	# 2. 显示敌人分数
	_add_section_title()
	_display_enemy_score()
	
	# 3. 显示总分
	_add_section_title()
	_display_total_score()

func _add_section_title() -> void:
	"""添加分区标题（使用分隔线）"""
	# 使用分隔线
	var separator = HSeparator.new()
	separator.add_theme_constant_override("separation", 20)
	score_container.add_child(separator)

func _display_survival_time() -> void:
	"""显示生存时间分数"""
	var time_score = int(survival_time)
	var patterns = ScoreDisplayUtils.decompose_score(time_score)
	
	# 创建显示容器
	var container = HBoxContainer.new()
	container.add_theme_constant_override("alignment", 1)  # 1 = CENTER
	
	# 显示蓝色图形（生存时间用蓝色表示）
	for pattern in patterns:
		var display = _create_pattern_display(pattern)
		container.add_child(display)
	
	score_container.add_child(container)
	
	# 显示时间数值（用图形数量表示）
	_add_time_indicator(time_score)

func _add_time_indicator(seconds: int) -> void:
	"""添加时间指示器"""
	var label = Label.new()
	label.text = str(seconds) + "秒"
	label.add_theme_constant_override("horizontal_alignment", 1)  # 1 = CENTER
	label.add_theme_color_override("font_color", Color.BLUE)
	score_container.add_child(label)

func _display_enemy_score() -> void:
	"""显示敌人分数"""
	var patterns = ScoreDisplayUtils.decompose_score(enemy_score)
	
	var container = HBoxContainer.new()
	container.add_theme_constant_override("alignment", 1)  # 1 = CENTER
	
	for pattern in patterns:
		var display = _create_pattern_display(pattern)
		container.add_child(display)
	
	score_container.add_child(container)

func _display_total_score() -> void:
	"""显示总分"""
	var patterns = ScoreDisplayUtils.decompose_score(total_score)
	
	var container = HBoxContainer.new()
	container.add_theme_constant_override("alignment", 1)  # 1 = CENTER
	
	# 使用黄色图形突出显示总分
	for pattern in patterns:
		var display = _create_pattern_display(pattern)
		display.modulate = Color.YELLOW
		container.add_child(display)
	
	score_container.add_child(container)

func _create_pattern_display(pattern: ScoreDisplayUtils.ScorePattern) -> Control:
	"""创建图案显示控件"""
	if pattern_display_scene:
		var display = pattern_display_scene.instantiate()
		if display:
			display.set_pattern(pattern)
			return display
	
	# 如果场景加载失败，创建一个简单的占位符
	var placeholder = ColorRect.new()
	placeholder.custom_minimum_size = Vector2(40, 40)
	placeholder.color = Color.WHITE
	return placeholder

func _on_restart_button_pressed() -> void:
	"""重新开始游戏"""
	# 重新加载当前场景
	get_tree().reload_current_scene()

func _on_main_menu_button_pressed() -> void:
	"""返回主菜单"""
	# 切换到主菜单场景
	# 切换到游戏场景
	var transition_manager = TransitionManager
	if transition_manager:
		transition_manager.change_scene("res://src/main_menu.tscn")
	else:
		# 如果管理器不存在，直接切换
		get_tree().change_scene_to_file("res://src/main_menu.tscn")
