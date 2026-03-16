class_name LevelSelectScreen extends Control

## 关卡选择界面

func _ready() -> void:
	# 连接按钮信号
	var level1_button = $CanvasLayer/VBoxContainer/LevelButtons/Level1Button
	var level2_button = $CanvasLayer/VBoxContainer/LevelButtons/Level2Button
	var level3_button = $CanvasLayer/VBoxContainer/LevelButtons/Level3Button
	var back_button = $CanvasLayer/VBoxContainer/BackButton
	
	if level1_button:
		level1_button.pressed.connect(_on_level1_pressed)
	
	if level2_button:
		level2_button.pressed.connect(_on_level2_pressed)
	
	if level3_button:
		level3_button.pressed.connect(_on_level3_pressed)
	
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	
	# 检查关卡是否可用
	_check_level_availability()

func _check_level_availability() -> void:
	# 检查关卡配置文件是否存在
	var level2_button = $CanvasLayer/VBoxContainer/LevelButtons/Level2Button
	var level3_button = $CanvasLayer/VBoxContainer/LevelButtons/Level3Button
	
	if level2_button:
		level2_button.disabled = not FileAccess.file_exists("res://config/levels/level_2.json")
	
	if level3_button:
		level3_button.disabled = not FileAccess.file_exists("res://config/levels/level_3.json")

func _on_level1_pressed() -> void:
	"""选择关卡 1"""
	_start_level("level_1")

func _on_level2_pressed() -> void:
	"""选择关卡 2"""
	_start_level("level_2")

func _on_level3_pressed() -> void:
	"""选择关卡 3"""
	_start_level("level_3")

func _on_back_pressed() -> void:
	"""返回主菜单"""
	var transition_manager = TransitionManager.instance
	if transition_manager:
		transition_manager.change_scene("res://src/main_menu.tscn")
	else:
		var scene_tree = get_tree()
		if scene_tree:
			scene_tree.change_scene_to_file("res://src/main_menu.tscn")

func _start_level(level_id: String) -> void:
	"""开始指定关卡"""
	# 存储选中的关卡
	if GameManager.instance:
		GameManager.instance.selected_level = level_id
	
	# 切换到游戏场景
	var transition_manager = TransitionManager.instance
	if transition_manager:
		transition_manager.change_scene("res://src/world.tscn")
	else:
		var scene_tree = get_tree()
		if scene_tree:
			scene_tree.change_scene_to_file("res://src/world.tscn")
