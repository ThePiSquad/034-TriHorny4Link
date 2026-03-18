class_name LevelSelectScreen extends Control

@onready var level0_button: Button = $CanvasLayer/VBoxContainer/LevelButtons/Level0Button
@onready var level1_button: Button = $CanvasLayer/VBoxContainer/LevelButtons/Level1Button
@onready var level2_button: Button = $CanvasLayer/VBoxContainer/LevelButtons/Level2Button
@onready var level3_button: Button = $CanvasLayer/VBoxContainer/LevelButtons/Level3Button
@onready var back_button: Button = $CanvasLayer/VBoxContainer/BackButton

## 关卡选择界面

func _ready() -> void:
	# 连接按钮信号
	if level0_button:
		level0_button.pressed.connect(_on_level0_pressed)
		_add_hover_effect(level0_button)
	
	if level1_button:
		level1_button.pressed.connect(_on_level1_pressed)
		_add_hover_effect(level1_button)
	
	if level2_button:
		level2_button.pressed.connect(_on_level2_pressed)
		_add_hover_effect(level2_button)
	
	if level3_button:
		level3_button.pressed.connect(_on_level3_pressed)
		_add_hover_effect(level3_button)
	
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
		_add_hover_effect(back_button)
	
	# 检查关卡是否可用
	_check_level_availability()
	
	# 设置入场动画
	_setup_animations()

func _add_hover_effect(button: Button) -> void:
	"""为按钮添加悬停动画效果"""
	button.mouse_entered.connect(func():
		AudioManager.play_ui_hover()
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.3)
	)
	
	button.mouse_exited.connect(func():
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.3)
	)

func _setup_animations() -> void:
	"""设置入场动画"""
	# 初始缩放
	$CanvasLayer.scale = Vector2(0.8, 0.8)
	$CanvasLayer.modulate.a = 0.0
	
	# 播放入场动画
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property($CanvasLayer, "scale", Vector2(1.0, 1.0), 0.8)
	tween.parallel().tween_property($CanvasLayer, "modulate:a", 1.0, 0.5)

func _check_level_availability() -> void:
	# 检查关卡配置文件是否存在
	if level2_button:
		level2_button.disabled = not FileAccess.file_exists("res://config/levels/level_2.json")
	
	if level3_button:
		level3_button.disabled = not FileAccess.file_exists("res://config/levels/level_3.json")

func _on_level0_pressed() -> void:
	"""选择关卡 1"""
	_play_button_click_animation(level0_button)
	await get_tree().create_timer(0.2).timeout
	# 进入教学关卡
	

func _on_level1_pressed() -> void:
	"""选择关卡 1"""
	_play_button_click_animation(level1_button)
	await get_tree().create_timer(0.2).timeout
	_start_level("level_1")

func _on_level2_pressed() -> void:
	"""选择关卡 2"""
	_play_button_click_animation(level2_button)
	await get_tree().create_timer(0.2).timeout
	_start_level("level_2")

func _on_level3_pressed() -> void:
	"""选择关卡 3"""
	_play_button_click_animation(level3_button)
	await get_tree().create_timer(0.2).timeout
	_start_level("level_3")

func _on_back_pressed() -> void:
	"""返回主菜单"""
	_play_button_click_animation(back_button)
	await get_tree().create_timer(0.2).timeout
	
	var transition_manager = TransitionManager.instance
	if transition_manager:
		transition_manager.change_scene("res://src/main_menu.tscn")
	else:
		var scene_tree = get_tree()
		if scene_tree:
			scene_tree.change_scene_to_file("res://src/main_menu.tscn")

func _play_button_click_animation(button: Button) -> void:
	"""播放按钮点击动画"""
	AudioManager.play_ui_click()
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.1)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)

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
