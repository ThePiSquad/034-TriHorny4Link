extends CanvasLayer

const ColorCircle = preload("res://src/ui/color_circle.gd")
const ShapeIcon = preload("res://src/ui/shape_icon.gd")

var icons = []


func _ready() -> void:
	var icons_container = $SelectionPanel/IconsContainer
	if icons_container:
		for child in icons_container.get_children():
			icons.append(child)


func select_icon(selected_icon) -> void:
	for icon in icons:
		if icon is ColorCircle or icon is ShapeIcon:
			icon.is_selected = false
	
	if selected_icon:
		if selected_icon is ColorCircle or selected_icon is ShapeIcon:
			selected_icon.is_selected = true


func set_resource_ratio(color_name: String, ratio: float) -> void:
	var icons_container = $SelectionPanel/IconsContainer
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
