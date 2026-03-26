extends HBoxContainer
class_name DamageBar

@onready var color_label: Label = $ColorLabel
@onready var progress_bar: ProgressBar = $ProgressBar

var _display_color: Color = Color.WHITE

func setup(color: Color, damage: int, percentage: float) -> void:
	_display_color = color
	
	color_label.text = "● " + str(damage)
	color_label.add_theme_color_override("font_color", color)
	
	progress_bar.value = percentage
	progress_bar.min_value = 0
	progress_bar.max_value = 100
	
	_update_bar_style()

func _update_bar_style() -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = _display_color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	progress_bar.add_theme_stylebox_override("fill", style)
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.15, 0.15, 0.15, 0.9)
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	progress_bar.add_theme_stylebox_override("background", bg_style)

func _on_ready() -> void:
	pass
