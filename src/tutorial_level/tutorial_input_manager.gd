extends InputManager

var input_enabled: bool = false
var allowed_structure_type: Enums.StructureType = Enums.StructureType.MONO_CRYSTAL
var allowed_color_type: Enums.ColorType = Enums.ColorType.BLUE
var restrictions_enabled: bool = true  # 是否启用教学限制

func set_input_enabled(enabled: bool) -> void:
	"""设置输入是否启用"""
	input_enabled = enabled

func set_allowed_structure_type(type: Enums.StructureType) -> void:
	"""设置允许放置的建筑类型"""
	allowed_structure_type = type

func set_allowed_color_type(color: Enums.ColorType) -> void:
	"""设置允许的颜色类型"""
	allowed_color_type = color

func remove_restrictions() -> void:
	"""移除教学限制"""
	restrictions_enabled = false
	print("已移除教学输入限制")

func _input(event: InputEvent) -> void:
	"""重载输入处理函数"""
	if not input_enabled:
		return
	
	# 处理鼠标滚轮事件（任何模式下都可用）
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_camera(1.0 + _zoom_speed)
			return
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_camera(1.0 - _zoom_speed)
			return
	
	# 处理暂停菜单
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_toggle_pause()
		return
	
	# 如果游戏暂停，忽略其他输入
	if is_paused:
		return
	
	if event.is_action_pressed("toggle_camera_mode"):
		_toggle_mode()
		return
	
	if current_mode == InputMode.CAMERA:
		if event.is_action_pressed("ui_cancel"):
			_set_mode(InputMode.PLACEMENT)
			return
		_handle_camera_input(event)
	else:
		_handle_placement_input(event)

func _handle_placement_input(event: InputEvent) -> void:
	"""重载放置输入处理函数"""
	if not input_enabled:
		return
	
	# 在教学模式下，禁止右键删除操作
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		print("教学：拦截右键删除操作")
		return
	
	super._handle_placement_input(event)

func _handle_camera_input(event: InputEvent) -> void:
	"""重载相机输入处理函数"""
	if not input_enabled:
		return
	
	super._handle_camera_input(event)

func _handle_continuous_placement(delta: float) -> void:
	"""重载连续放置处理函数，教学模式下禁止删除"""
	if not input_enabled:
		return
	
	super._handle_continuous_placement(delta)

func _try_place() -> void:
	"""重载放置函数，添加教学限制"""
	if not input_enabled:
		print("教学：输入未启用，无法放置")
		return
	
	# 如果限制已移除，使用默认逻辑
	if not restrictions_enabled:
		super._try_place()
		return
	
	# 检查是否允许放置该类型
	if selected_structure_type != allowed_structure_type:
		# print("教学：建筑类型不允许。当前：", selected_structure_type, "允许：", allowed_structure_type)
		return
	
	# 检查颜色是否允许
	if selected_color_type != allowed_color_type:
		print("教学：颜色不允许。当前：", selected_color_type, "允许：", allowed_color_type)
		return
	
	# print("教学：尝试放置建筑，类型：", selected_structure_type, "颜色：", selected_color_type)
	super._try_place()

func _on_icon_selected(icon) -> void:
	"""重载图标选择函数，添加教学限制"""
	if not input_enabled:
		return
	
	# 如果限制已移除，使用默认逻辑
	if not restrictions_enabled:
		super._on_icon_selected(icon)
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
		# 检查形状类型是否匹配允许的建筑类型
		var shape_type = icon.shape_type
		var structure_type: Enums.StructureType
		
		if shape_type == ShapeIcon.ShapeType.RECTANGLE:
			structure_type = Enums.StructureType.CONDUIT
		elif shape_type == ShapeIcon.ShapeType.TRIANGLE:
			structure_type = Enums.StructureType.TURRET
		else:
			return
		
		# 如果建筑类型不允许，不处理选择
		if structure_type != allowed_structure_type:
			return
	
	super._on_icon_selected(icon)

func _try_remove() -> void:
	"""重载删除函数，教学模式下禁止删除"""
	if not input_enabled:
		return
	
	print("教学：禁止删除操作")
	return
