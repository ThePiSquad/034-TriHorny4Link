extends HUD 
class_name TutorialHUD

var current_step: int = 0
var step_name: String = ""

func set_step_info(step: int, name: String) -> void:
	"""设置步骤信息"""
	current_step = step
	step_name = name
	_update_display()

func _update_display() -> void:
	"""更新显示"""
	if has_node("StepLabel"):
		var step_label = $StepLabel
		step_label.text = "步骤 %d: %s" % [current_step + 1, step_name]
