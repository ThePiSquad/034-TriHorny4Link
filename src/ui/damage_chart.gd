extends VBoxContainer
class_name DamageChart

const DAMAGE_BAR_SCENE = preload("res://src/ui/damage_bar.tscn")

@onready var title: Label = $Title
@onready var bars_container: VBoxContainer = $BarsContainer
@onready var total_label: Label = $TotalLabel

func setup(data: Array, total_damage: int) -> void:
	for child in bars_container.get_children():
		child.queue_free()
	
	if total_damage == 0:
		visible = false
		return
	
	visible = true
	
	for item in data:
		var color = item.color
		var damage = item.damage
		var percentage = float(damage) / float(total_damage) * 100.0
		
		var bar = DAMAGE_BAR_SCENE.instantiate()
		bars_container.add_child(bar)
		
		var display_color = Constants.COLOR_MAP.get(color, Color.WHITE)
		(bar as DamageBar).setup(display_color, damage, percentage)
	
	total_label.text = "All: " + str(total_damage)
