class_name SplittingEnemy extends RectEnemy

@export var split_count: int = 2  # 分裂数量
@export var split_offset_distance: float = 50.0  # 分裂时子敌人的偏移距离

func _ready() -> void:
	super._ready()
	# 连接死亡信号以在死亡时触发分裂
	died.connect(_on_splitting_enemy_died)

func _on_splitting_enemy_died(source: Node) -> void:
	# 检查是否需要分裂（size_level > 1）
	if size_level > Constants.EnemyConstants.SIZE_LEVEL_1 and source != self:
		_perform_split()
	
	# 调用父类死亡处理
	super._on_damageable_died(source)

func _perform_split() -> void:
	# 计算分裂后的体型等级（向下取整）
	var new_size_level: int = int(size_level / 2.0)
	if new_size_level < Constants.EnemyConstants.SIZE_LEVEL_1:
		new_size_level = Constants.EnemyConstants.SIZE_LEVEL_1
	
	# 分裂生成子敌人
	for i in range(split_count):
		_spawn_split_enemy(new_size_level, i)

func _spawn_split_enemy(new_size_level: int, index: int) -> void:
	# 创建新的敌人实例
	var new_enemy : SplittingEnemy = duplicate()
	
	# 计算偏移位置（避免重叠）
	var angle = (TAU / split_count) * index + randf() * 0.5
	var offset = Vector2(cos(angle), sin(angle)) * split_offset_distance
	new_enemy.global_position = global_position + offset
	
	# 设置新的体型等级
	new_enemy.size_level = new_size_level
	new_enemy.set_size_level(new_size_level)
	
	# 添加到场景树
	get_tree().current_scene.add_child(new_enemy)
	
	# 设置目标位置（如果敌人有导航）
	new_enemy.set_base_position(base_position)
	
