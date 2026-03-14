class_name HUD extends CanvasLayer

signal icon_selected(icon)
signal selection_cleared

var icons = []
var selected_icon = null
var animation_enabled = true  # 动效开关

@onready var icons_container: HBoxContainer = $SelectionPanel/IconsContainer

func _ready() -> void:
	if icons_container:
		for child in icons_container.get_children():
			icons.append(child)


func select_icon(_selected_icon) -> void:
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
	if not visible:
		return
	
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
