extends Structure
class_name Crystal

func _ready() -> void:
	super._ready()
	# 添加到crystal组，让敌人能够找到
	add_to_group("crystal")
	print("Crystal添加到组: crystal，位置: ", global_position)
