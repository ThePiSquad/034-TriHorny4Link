class_name HUD extends CanvasLayer

signal icon_selected(icon)
signal selection_cleared

var icons = []
var selected_icon = null
var animation_enabled = true  # 动效开关

@onready var icons_container: HBoxContainer = $SelectionPanel/IconsContainer

var _max_turrets: int = 0
var _loop_anim_icons: Array[Control] = []

func _ready() -> void:
	if icons_container:
		for child in icons_container.get_children():
			icons.append(child)
	
	add_to_group("turret_count_observer")

func _on_turret_count_changed(current_count: int, max_count: int) -> void:
	_max_turrets = max_count
	_update_triangle_disabled_state(current_count >= max_count)
	if current_count >= max_count and selected_icon != null:
		var triangle_icon = _get_shape_icon(1)
		if triangle_icon:
			_play_shake_animation_for_icon(triangle_icon)

func _update_triangle_disabled_state(disabled: bool) -> void:
	for icon in icons:
		if icon is Control and icon.get("shape_type") != null:
			if icon.shape_type == 1:  # TRIANGLE
				icon.disabled = disabled
				break

func trigger_limit_reached_feedback() -> void:
	if selected_icon != null:
		_play_shake_animation_for_icon(selected_icon)

func play_shake_animation_for_structure(structure_type: Enums.StructureType, color_type: Enums.ColorType = Enums.ColorType.WHITE) -> void:
	var target_icon = _get_icon_for_structure(structure_type, color_type)
	if target_icon:
		_play_shake_animation_for_icon(target_icon)

func play_loop_shake_animation_for_structure(structure_type: Enums.StructureType, color_type: Enums.ColorType, should_continue: Callable) -> void:
	var target_icon = _get_icon_for_structure(structure_type, color_type)
	if target_icon:
		_play_loop_shake_animation(target_icon, should_continue)

func _get_icon_for_structure(structure_type: Enums.StructureType, color_type: Enums.ColorType):
	match structure_type:
		Enums.StructureType.MONO_CRYSTAL:
			return _get_color_circle_icon(color_type)
		Enums.StructureType.CONDUIT:
			return _get_shape_icon(0)  # RECTANGLE
		Enums.StructureType.TURRET:
			return _get_shape_icon(1)  # TRIANGLE
	return null

func _get_color_circle_icon(color_type: Enums.ColorType) -> Control:
	for icon in icons:
		if icon is Control and icon.get("circle_color") != null:
			match color_type:
				Enums.ColorType.RED:
					if icon.circle_color == Color.RED:
						return icon
				Enums.ColorType.YELLOW:
					if icon.circle_color == Color.YELLOW:
						return icon
				Enums.ColorType.BLUE:
					if icon.circle_color == Color.BLUE:
						return icon
	return null

func _get_shape_icon(shape_type_value: int) -> Control:
	for icon in icons:
		if icon is Control and icon.get("shape_type") != null:
			if icon.shape_type == shape_type_value:
				return icon
	return null

func _play_shake_animation_for_icon(icon: Control) -> void:
	if not icon:
		return
	
	icon.pivot_offset = icon.size / 2
	
	var tween = create_tween()
	var shake_angle = 0.3
	var duration = 0.08
	
	tween.tween_property(icon, "rotation", -shake_angle, duration)
	tween.tween_property(icon, "rotation", shake_angle, duration)
	tween.tween_property(icon, "rotation", -shake_angle * 0.5, duration)
	tween.tween_property(icon, "rotation", shake_angle * 0.5, duration)
	tween.tween_property(icon, "rotation", 0.0, duration)

func _play_loop_shake_animation(icon: Control, should_continue: Callable) -> void:
	if not icon:
		return
	
	if icon in _loop_anim_icons:
		return
	
	_loop_anim_icons.append(icon)
	icon.pivot_offset = icon.size / 2
	
	var tween = create_tween()
	var shake_angle = 0.3
	var duration = 0.08
	
	tween.tween_property(icon, "rotation", -shake_angle, duration)
	tween.tween_property(icon, "rotation", shake_angle, duration)
	tween.tween_property(icon, "rotation", -shake_angle * 0.5, duration)
	tween.tween_property(icon, "rotation", shake_angle * 0.5, duration)
	tween.tween_property(icon, "rotation", 0.0, duration)
	
	tween.finished.connect(func(): 
		_loop_anim_icons.erase(icon)
		if should_continue.call():
			_play_loop_shake_animation(icon, should_continue)
	)

func select_icon(_selected_icon) -> void:
	AudioManager.play_ui_click()
	# 检查是否点击了已选中的图标
	if self.selected_icon == _selected_icon:
		# 取消选择
		_clear_selection()
		return
	
	# 清除之前的选择
	for icon in icons:
		if icon is ColorCircle or icon is ShapeIcon:
			icon.is_selected = false
			# 添加取消选择动画
			if animation_enabled:
				var tween = create_tween()
				tween.set_trans(Tween.TRANS_BACK)
				tween.set_ease(Tween.EASE_OUT)
				tween.tween_property(icon, "scale", Vector2(1.0, 1.0), 0.2)
	
	# 选择新图标
	if _selected_icon:
		if _selected_icon is ColorCircle or _selected_icon is ShapeIcon:
			_selected_icon.is_selected = true
			self.selected_icon = _selected_icon
			# 添加选择动画
			if animation_enabled:
				var tween = create_tween()
				tween.set_trans(Tween.TRANS_BACK)
				tween.set_ease(Tween.EASE_OUT)
				tween.tween_property(_selected_icon, "scale", Vector2(1.2, 1.2), 0.2)
			icon_selected.emit(_selected_icon)
	else:
		_clear_selection()


func _clear_selection() -> void:
	for icon in icons:
		if icon is ColorCircle or icon is ShapeIcon:
			icon.is_selected = false
			# 添加取消选择动画
			if animation_enabled:
				var tween = create_tween()
				tween.set_trans(Tween.TRANS_BACK)
				tween.set_ease(Tween.EASE_OUT)
				tween.tween_property(icon, "scale", Vector2(1.0, 1.0), 0.2)
	selected_icon = null
	selection_cleared.emit()


func get_selected_icon():
	return selected_icon


func is_icon_selected() -> bool:
	return selected_icon != null


## 用法示例  设置单个资源
#   set_resource_ratio("red", 0.75)
func set_resource_ratio(color_name: String, ratio: float) -> void:
	if not icons_container:
		return
	
	var circle = icons_container.get_node_or_null(color_name.capitalize() + "Circle")
	if circle:
		if animation_enabled:
			# 添加资源变化动画
			var tween = create_tween()
			tween.set_trans(Tween.TRANS_QUAD)
			tween.set_ease(Tween.EASE_OUT)
			tween.tween_property(circle, "fill_ratio", ratio, 0.3)
		else:
			circle.fill_ratio = ratio
		circle.queue_redraw()


func set_resource_ratios(red: float, blue: float, yellow: float) -> void:
	set_resource_ratio("red", red)
	set_resource_ratio("blue", blue)
	set_resource_ratio("yellow", yellow)

# 动画相关函数
func show_hud() -> void:
	if not visible:
		visible = true
	
	# 动画显示HUD
	if $SelectionPanel:
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property($SelectionPanel, "offset_top", -100.0, 0.3)

func hide_hud() -> void:
	#if not visible:
		#return
	
	# 动画隐藏HUD
	if $SelectionPanel:
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_IN)
		tween.tween_property($SelectionPanel, "offset_top", 0.0, 0.3)
		tween.tween_callback(func():
			visible = false
		)

func is_hud_visible() -> bool:
	return visible

func set_animation_enabled(enabled: bool) -> void:
	"""设置动效开关"""
	animation_enabled = enabled

func is_animation_enabled() -> bool:
	"""检查动效是否启用"""
	return animation_enabled
