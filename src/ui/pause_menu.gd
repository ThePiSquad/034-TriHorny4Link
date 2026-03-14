extends Control
class_name PauseMenu

@onready var resume_button: Button = $CenterContainer/VBoxContainer/ButtonContainer/ResumeButton
@onready var main_menu_button: Button = $CenterContainer/VBoxContainer/ButtonContainer/MainMenuButton

func _ready() -> void:
	pass

func _input(event: InputEvent) -> void:
	# 按下 ESC 键关闭暂停菜单
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_close_pause_menu()

func _on_resume_button_pressed() -> void:
	"""继续游戏"""
	_close_pause_menu()

func _on_main_menu_button_pressed() -> void:
	"""返回主菜单"""
	# 切换到主菜单场景
	var transition_manager = TransitionManager.instance
	get_tree().paused = false
	if transition_manager:
		transition_manager.change_scene("res://src/main_menu.tscn")
	else:
		# 如果管理器不存在，直接切换
		get_tree().change_scene_to_file("res://src/main_menu.tscn")

func _close_pause_menu() -> void:
	"""关闭暂停菜单并恢复游戏"""
	# 恢复游戏
	get_tree().paused = false
	# 移除暂停菜单
	queue_free()
