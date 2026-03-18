extends InputManager

var input_enabled: bool = false
var allowed_structure_type: Enums.StructureType = Enums.StructureType.MONO_CRYSTAL
var allowed_color_type: Enums.ColorType = Enums.ColorType.BLUE

func set_input_enabled(enabled: bool) -> void:
	"""设置输入是否启用"""
	input_enabled = enabled

func set_allowed_structure_type(type: Enums.StructureType) -> void:
	"""设置允许放置的建筑类型"""
	allowed_structure_type = type

func set_allowed_color_type(color: Enums.ColorType) -> void:
	"""设置允许的颜色类型"""
	allowed_color_type = color

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

func _try_place() -> void:
	"""重载放置函数，添加教学限制"""
	if not input_enabled:
		return
	
	# 检查是否允许放置该类型
	if selected_structure_type != allowed_structure_type:
		return
	
	# 检查颜色是否允许
	if selected_color_type != allowed_color_type:
		return
	
	super._try_place()

func _on_icon_selected(icon) -> void:
	"""重载图标选择函数，添加教学限制"""
	if not input_enabled:
		return
	
	# 如果是颜色圆圈，检查颜色是否允许
	if icon is ColorCircle:
		var index = icon.get_index()
		var color_type: Enums.ColorType
		match index:
			0: color_type = Enums.ColorType.RED
			1: color_type = Enums.ColorType.BLUE
			2: color_type = Enums.ColorType.YELLOW
			_: color_type = Enums.ColorType.WHITE
		
		# 如果颜色不允许，不处理选择
		if color_type != allowed_color_type:
			return
	
	# 如果是形状图标，检查是否允许
	if icon is ShapeIcon:
		# 在教学步骤1中，不允许选择形状图标
		return
	
	super._on_icon_selected(icon)
