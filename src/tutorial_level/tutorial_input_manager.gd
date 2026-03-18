extends InputManager

var input_enabled: bool = false

func set_input_enabled(enabled: bool) -> void:
	"""设置输入是否启用"""
	input_enabled = enabled

func _input(event: InputEvent) -> void:
	"""重载输入处理函数"""
	if not input_enabled:
		return
	
	super._input(event)

func _handle_placement_input(event: InputEvent) -> void:
	"""重载放置输入处理函数"""
	if not input_enabled:
		return
	
	super._handle_placement_input(event)

func _handle_camera_input(event: InputEvent) -> void:
	"""重载相机输入处理函数"""
	if not input_enabled:
		return
	
	super._handle_camera_input(event)
