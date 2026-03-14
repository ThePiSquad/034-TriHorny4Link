extends Control
class_name GameOverScreen

# Debug 模式开关
const DEBUG_MODE: bool = false  # 设置为 true 启用 debug 模式

# 分数显示容器
@onready var score_container: VBoxContainer = $MarginContainer/VBoxContainer/ScoreContainer
@onready var restart_button: Button = $MarginContainer/VBoxContainer/ButtonContainer/RestartButton
@onready var main_menu_button: Button = $MarginContainer/VBoxContainer/ButtonContainer/MainMenuButton
@onready var debug_score_display: VBoxContainer = $MarginContainer/VBoxContainer/DebugScoreDisplay

# 游戏数据
var survival_time: float = 0.0
var enemy_score: int = 0
var total_score: int = 0

# 图案显示场景
const PATTERN_DISPLAY_SCENE_PATH = "res://src/ui/score_pattern_display.tscn"
var pattern_display_scene: PackedScene

func _ready() -> void:
	# 连接按钮信号
	if restart_button:
		restart_button.pressed.connect(_on_restart_button_pressed)
	if main_menu_button:
		main_menu_button.pressed.connect(_on_main_menu_button_pressed)
	
	# 预加载图案显示场景
	pattern_display_scene = load(PATTERN_DISPLAY_SCENE_PATH)
	if pattern_display_scene == null:
		print("严重错误：无法加载图案显示场景：", PATTERN_DISPLAY_SCENE_PATH)
		print("场景文件是否存在：", ResourceLoader.exists(PATTERN_DISPLAY_SCENE_PATH))
	else:
		print("成功加载图案显示场景：", PATTERN_DISPLAY_SCENE_PATH)
		print("场景资源类型：", pattern_display_scene.get_class())
	
	# 获取游戏数据
	var game_manager = GameManager.instance
	if game_manager:
		survival_time = game_manager.survival_time
		enemy_score = game_manager.enemy_score
		total_score = game_manager.total_score
	
	# 显示分数
	_display_scores()
	
	# 显示 debug 信息（如果启用）
	_update_debug_display()

func _display_scores() -> void:
	"""显示所有分数信息"""
	# 清空现有显示
	for child in score_container.get_children():
		child.queue_free()
	
	# 显示总分（包含生存时间和敌人分数的汇总）
	# 这样更简洁，避免信息冗余
	_display_total_score()
	
	# 添加详细信息区域（可选，显示分项明细）
	_display_score_details()

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
	
	# 创建垂直容器（标签 + 图案）
	var section_container = VBoxContainer.new()
	section_container.add_theme_constant_override("separation", 10)
	section_container.add_theme_constant_override("alignment", 1)  # 1 = CENTER
	
	# 添加标签
	var label = Label.new()
	label.text = "生存时间: " + str(time_score) + " 秒"
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))  # 淡蓝色
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section_container.add_child(label)
	
	# 创建图案容器（使用 FlowContainer 实现自动换行）
	var container = FlowContainer.new()
	container.alignment = FlowContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("h_separation", 8)
	container.add_theme_constant_override("v_separation", 8)
	
	# 显示蓝色图形（生存时间用蓝色表示）
	for pattern in patterns:
		var display = _create_pattern_display(pattern)
		container.add_child(display)
	
	section_container.add_child(container)
	score_container.add_child(section_container)

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
	
	# 创建垂直容器（标签 + 图案）
	var section_container = VBoxContainer.new()
	section_container.add_theme_constant_override("separation", 10)
	section_container.add_theme_constant_override("alignment", 1)  # 1 = CENTER
	
	# 添加标签
	var label = Label.new()
	label.text = "击败敌人: " + str(enemy_score) + " 分"
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))  # 淡红色
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section_container.add_child(label)
	
	# 创建图案容器（使用 FlowContainer 实现自动换行）
	var container = FlowContainer.new()
	container.alignment = FlowContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("h_separation", 8)
	container.add_theme_constant_override("v_separation", 8)
	
	for pattern in patterns:
		var display = _create_pattern_display(pattern)
		container.add_child(display)
	
	section_container.add_child(container)
	score_container.add_child(section_container)

func _display_total_score() -> void:
	"""显示总分"""
	var patterns = ScoreDisplayUtils.decompose_score(total_score)
	
	# 创建垂直容器（标签 + 图案）
	var section_container = VBoxContainer.new()
	section_container.add_theme_constant_override("separation", 10)
	section_container.add_theme_constant_override("alignment", 1)  # 1 = CENTER
	section_container.name = "TotalScoreSection"
	
	# 添加标签（突出显示）
	var label = Label.new()
	label.text = "总分数: " + str(total_score) + " 分"
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))  # 金黄色
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.visible = false
	label.name = "TotalScoreLabel"
	section_container.add_child(label)
	
	# 创建图案容器（使用 FlowContainer 实现自动换行）
	var container = FlowContainer.new()
	container.alignment = FlowContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("h_separation", 8)
	container.add_theme_constant_override("v_separation", 8)
	
	# 显示总分图案，保持图案原本的颜色
	for pattern in patterns:
		var display = _create_pattern_display(pattern)
		# 不再覆盖颜色，让图案显示其原本的颜色
		container.add_child(display)
	
	section_container.add_child(container)
	score_container.add_child(section_container)

func _create_pattern_display(pattern: ScoreDisplayUtils.ScorePattern) -> Control:
	"""创建图案显示控件"""
	if pattern_display_scene == null:
		print("严重错误：pattern_display_scene 未加载，路径：", PATTERN_DISPLAY_SCENE_PATH)
		var placeholder = ColorRect.new()
		placeholder.custom_minimum_size = Vector2(40, 40)
		placeholder.color = Color.WHITE
		return placeholder
	
	var display = pattern_display_scene.instantiate()
	if display:
		# 设置图案数据
		display.set_pattern(pattern)
		return display
	else:
		print("错误：无法实例化 pattern_display_scene")
	
	# 如果实例化失败，创建一个简单的白色占位符矩形作为后备显示
	print("警告：使用 ColorRect 占位符")
	var placeholder = ColorRect.new()
	placeholder.custom_minimum_size = Vector2(40, 40)
	placeholder.color = Color.WHITE
	return placeholder

func _display_score_details() -> void:
	"""显示分数详细信息（生存时间和敌人分数）"""
	# 创建详细信息容器
	var details_container = VBoxContainer.new()
	details_container.add_theme_constant_override("separation", 15)
	details_container.add_theme_constant_override("alignment", 1)  # 1 = CENTER
	# 默认不可见
	details_container.visible = false
	# 设置名称以便在 _input 中引用
	details_container.name = "ScoreDetailsContainer"

	# 创建水平容器显示两项明细
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 40)
	hbox.add_theme_constant_override("alignment", 1)  # 1 = CENTER
	
	# 生存时间明细
	var time_vbox = VBoxContainer.new()
	time_vbox.add_theme_constant_override("separation", 5)
	var time_label = Label.new()
	time_label.text = "生存时间"
	time_label.add_theme_font_size_override("font_size", 14)
	time_label.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_vbox.add_child(time_label)
	var time_value = Label.new()
	time_value.text = str(int(survival_time)) + " 秒"
	time_value.add_theme_font_size_override("font_size", 14)
	time_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_vbox.add_child(time_value)
	hbox.add_child(time_vbox)
	
	# 敌人分数明细
	var enemy_vbox = VBoxContainer.new()
	enemy_vbox.add_theme_constant_override("separation", 5)
	var enemy_label = Label.new()
	enemy_label.text = "击败敌人"
	enemy_label.add_theme_font_size_override("font_size", 14)
	enemy_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	enemy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_vbox.add_child(enemy_label)
	var enemy_value = Label.new()
	enemy_value.text = str(enemy_score) + " 分"
	enemy_value.add_theme_font_size_override("font_size", 14)
	enemy_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_vbox.add_child(enemy_value)
	hbox.add_child(enemy_vbox)
	
	details_container.add_child(hbox)
	score_container.add_child(details_container)

func _input(event: InputEvent) -> void:
	"""处理输入事件"""
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		# 按下空格键显示总分标签和详细信息
		var total_score_section = score_container.get_node_or_null("TotalScoreSection")
		if total_score_section:
			var total_score_label = total_score_section.get_node_or_null("TotalScoreLabel")
			if total_score_label and not total_score_label.visible:
				total_score_label.visible = true
				print("显示总分数")
		
		var details_container = score_container.get_node_or_null("ScoreDetailsContainer")
		if details_container and not details_container.visible:
			details_container.visible = true
			print("显示分数详细信息")

func _update_debug_display() -> void:
	"""更新 debug 信息显示"""
	if not DEBUG_MODE:
		# 隐藏 debug 显示
		if debug_score_display:
			debug_score_display.visible = false
		return
	
	# 显示 debug 信息
	if debug_score_display:
		debug_score_display.visible = true
		
		# 清空现有内容
		for child in debug_score_display.get_children():
			child.queue_free()
		
		# 添加 debug 标题
		var debug_title = Label.new()
		debug_title.text = "Debug Info"
		debug_title.add_theme_font_size_override("font_size", 20)
		debug_title.add_theme_color_override("font_color", Color.YELLOW)
		debug_title.add_theme_constant_override("horizontal_alignment", 1)  # 1 = CENTER
		debug_score_display.add_child(debug_title)
		
		# 添加生存时间
		var time_label = Label.new()
		time_label.text = "生存时间: " + str(int(survival_time)) + " 秒"
		time_label.add_theme_constant_override("horizontal_alignment", 1)  # 1 = CENTER
		time_label.add_theme_color_override("font_color", Color.BLUE)
		debug_score_display.add_child(time_label)
		
		# 添加敌人分数
		var enemy_label = Label.new()
		enemy_label.text = "敌人分数: " + str(enemy_score)
		enemy_label.add_theme_constant_override("horizontal_alignment", 1)  # 1 = CENTER
		enemy_label.add_theme_color_override("font_color", Color.RED)
		debug_score_display.add_child(enemy_label)
		
		# 添加总分
		var total_label = Label.new()
		total_label.text = "总分数: " + str(total_score)
		total_label.add_theme_font_size_override("font_size", 18)
		total_label.add_theme_constant_override("horizontal_alignment", 1)  # 1 = CENTER
		total_label.add_theme_color_override("font_color", Color.YELLOW)
		debug_score_display.add_child(total_label)

func _on_restart_button_pressed() -> void:
	AudioManager.play_ui_click()
	"""重新开始游戏"""
	# 重新加载当前场景
	var transition_manager = TransitionManager.instance
	if transition_manager:
		transition_manager.change_scene("res://src/world.tscn")
	else:
		get_tree().reload_current_scene()

func _on_main_menu_button_pressed() -> void:
	AudioManager.play_ui_click()
	"""返回主菜单"""
	# 切换到主菜单场景
	var transition_manager = TransitionManager.instance
	if transition_manager:
		transition_manager.change_scene("res://src/main_menu.tscn")
	else:
		# 如果管理器不存在，直接切换
		get_tree().change_scene_to_file("res://src/main_menu.tscn")


func _on_restart_button_mouse_entered() -> void:
	AudioManager.play_ui_hover()


func _on_main_menu_button_mouse_entered() -> void:
	AudioManager.play_ui_hover()
