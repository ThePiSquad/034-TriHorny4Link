class_name HUD extends CanvasLayer

signal icon_selected(icon)
signal selection_cleared

var icons = []
var selected_icon = null

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
	
	# 选择新图标
	if _selected_icon:
		if _selected_icon is ColorCircle or _selected_icon is ShapeIcon:
			_selected_icon.is_selected = true
			self.selected_icon = _selected_icon
			icon_selected.emit(_selected_icon)
	else:
		_clear_selection()


func _clear_selection() -> void:
	for icon in icons:
		if icon is ColorCircle or icon is ShapeIcon:
			icon.is_selected = false
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
		circle.fill_ratio = ratio
		circle.queue_redraw()


func set_resource_ratios(red: float, blue: float, yellow: float) -> void:
	set_resource_ratio("red", red)
	set_resource_ratio("blue", blue)
	set_resource_ratio("yellow", yellow)
