class_name HealEnemy extends Enemy

@onready var heal_timer: Timer = $HealTimer

'''
治疗型敌人
会倾向于躲在其他的敌人后面
能力：
间歇的对范围内的敌人进行治疗
范围内治疗单位上限默认5
'''

# 治疗能力配置
@export_group("Healing")
@export var heal_interval: float = 5.0  # 治疗间隔（秒）
@export var heal_radius: float = 6 * Constants.grid_size  # 治疗范围半径
@export var heal_amount: float = 30.0  # 每次治疗量
@export var max_heal_targets: int = 3  # 最大治疗目标数
# 粒子效果
@export var heal_particle_scene: PackedScene

var is_healing : bool = false
var _heal_targets: Array[Node2D] = []

func _setup_particle_texture(particle: GPUParticles2D) -> void:
	"""设置死亡粒子纹理"""
	var texture = load("res://assets/particles/circle_particle.png")
	if texture:
		particle.texture = texture

func _ready() -> void:
	super._ready()
	heal_timer.wait_time = heal_interval

func _on_heal_timer_timeout() -> void:
	_perform_healing()

func _find_heal_targets() -> Array[Node2D]:
	"""寻找治疗范围内的友方单位"""
	var targets: Array[Node2D] = []
	var enemies = get_tree().get_nodes_in_group("enemy")
	
	for enemy in enemies:
		if enemy != self and is_instance_valid(enemy) and enemy is Enemy:
			var distance = global_position.distance_to(enemy.global_position)
			if distance <= heal_radius:
				# 只治疗血量不满的友军
				if enemy.has_method("get_health_percentage"):
					var health_pct = enemy.get_health_percentage()
					if health_pct < 1.0:
						targets.append(enemy)
	
	# 按血量排序，优先治疗血量低的
	targets.sort_custom(func(a, b): 
		if a.has_method("get_health_percentage") and b.has_method("get_health_percentage"):
			return a.get_health_percentage() < b.get_health_percentage()
		return false
	)
	
	# 限制最大治疗目标数
	if targets.size() > max_heal_targets:
		targets.resize(max_heal_targets)
	
	return targets

func _perform_healing() -> void:
	"""执行治疗"""
	_heal_targets = _find_heal_targets()
	
	if _heal_targets.size() == 0:
		return
	
	is_healing = true
	
	# 播放治疗粒子效果
	_spawn_heal_particle()
	
	# 治疗所有目标
	for target in _heal_targets:
		if is_instance_valid(target):
			target.heal(heal_amount * size_level, self)
	
	# 治疗完成后重置状态
	await get_tree().create_timer(0.5).timeout
	is_healing = false

func _spawn_heal_particle() -> void:
	"""生成治疗粒子效果"""
	if not heal_particle_scene:
		return
	
	var particle: GPUParticles2D = heal_particle_scene.instantiate()
	if not particle:
		return
	
	# 设置粒子位置为治疗敌人位置
	particle.global_position = global_position
	particle.one_shot = true
	particle.emitting = true
	
	# 设置治疗范围
	if particle.process_material:
		particle.process_material.emission_sphere_radius = heal_radius
	
	# 添加到场景中
	get_tree().current_scene.add_child(particle)
