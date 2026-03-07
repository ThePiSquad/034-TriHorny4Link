extends CanvasLayer

const ColorCircle = preload("res://src/ui/color_circle.gd")
const ShapeIcon = preload("res://src/ui/shape_icon.gd")

var icons = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 获取所有图标节点
	var icons_container = $SelectionPanel/IconsContainer
	if icons_container:
		for child in icons_container.get_children():
			icons.append(child)
			# 连接点击信号
			if child.has_method("_gui_input"):
				# 这里我们通过重写 _gui_input 来实现单选逻辑
				pass


# 处理图标点击，实现单选逻辑
func select_icon(selected_icon) -> void:
	# 取消所有图标的选中状态
	for icon in icons:
		# 直接访问 is_selected 属性（GDScript 会安全处理不存在的属性）
		if icon is ColorCircle or icon is ShapeIcon:
			icon.is_selected = false
	
	# 选中当前图标
	if selected_icon:
		if selected_icon is ColorCircle or selected_icon is ShapeIcon:
			selected_icon.is_selected = true
