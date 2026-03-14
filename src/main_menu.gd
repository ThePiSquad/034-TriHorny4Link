extends Control

## 主菜单控制器
## 处理主菜单的 UI 交互和场景切换

@onready var start_button: Button = $CenterContainer/VBoxContainer/ButtonContainer/StartButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/ButtonContainer/QuitButton
var transition_manager = TransitionManager

# 游戏场景路径
const GAME_SCENE_PATH = "res://src/world.tscn"

func _ready() -> void:
	_setup_buttons()
	_setup_animations()
	
	# 确保鼠标可见
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _setup_buttons() -> void:
	"""设置按钮样式和信号"""
	# 连接信号（已经在场景文件中连接，这里作为备用）
	if not start_button.pressed.is_connected(_on_start_button_pressed):
		start_button.pressed.connect(_on_start_button_pressed)
	if not quit_button.pressed.is_connected(_on_quit_button_pressed):
		quit_button.pressed.connect(_on_quit_button_pressed)
	
	# 添加按钮悬停效果
	_add_hover_effect(start_button)
	_add_hover_effect(quit_button)

func _add_hover_effect(button: Button) -> void:
	"""为按钮添加悬停动画效果"""
	button.mouse_entered.connect(func():
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
	$CenterContainer.scale = Vector2(0.8, 0.8)
	$CenterContainer.modulate.a = 0.0
	
	# 播放入场动画
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property($CenterContainer, "scale", Vector2(1.0, 1.0), 0.8)
	tween.parallel().tween_property($CenterContainer, "modulate:a", 1.0, 0.5)

func _on_start_button_pressed() -> void:
	"""开始游戏按钮点击处理"""
	# 禁用按钮防止重复点击
	start_button.disabled = true
	quit_button.disabled = true
	
	# 播放按钮点击动画
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(start_button, "scale", Vector2(0.95, 0.95), 0.1)
	tween.tween_property(start_button, "scale", Vector2(1.0, 1.0), 0.1)
	
	# 切换到游戏场景
	if transition_manager:
		transition_manager.change_scene(GAME_SCENE_PATH)
	else:
		# 如果管理器不存在，直接切换
		get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_quit_button_pressed() -> void:
	"""退出游戏按钮点击处理"""
	# 播放按钮点击动画
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(quit_button, "scale", Vector2(0.95, 0.95), 0.1)
	tween.tween_property(quit_button, "scale", Vector2(1.0, 1.0), 0.1)
	
	# 延迟退出以播放动画
	await get_tree().create_timer(0.3).timeout
	get_tree().quit()

func _input(event: InputEvent) -> void:
	"""处理输入事件"""
	# 按 Enter 键开始游戏
	if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER:
		if not start_button.disabled:
			_on_start_button_pressed()
	
	# 按 ESC 键退出游戏
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if not quit_button.disabled:
			_on_quit_button_pressed()
