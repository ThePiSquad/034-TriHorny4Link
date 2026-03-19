extends CanvasLayer

@onready var pause_button: Button = $PauseButton
@export var input_manager: InputManager

func _on_pause_button_pressed() -> void:
	"""暂停按钮按下时调用"""
	if input_manager:
		input_manager._toggle_pause() 
