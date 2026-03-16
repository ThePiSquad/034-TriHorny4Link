extends Enemy

# Boss 特有属性
var is_boss: bool = false
var boss_health_multiplier: float = 10.0  # Boss 生命值倍数
var boss_damage_multiplier: float = 2.0   # Boss 伤害倍数
var boss_score_value: int = 1000          # Boss 击败分数

func _ready() -> void:
	super._ready()
	# 检查是否是 Boss（体型为 20 即 256x256）
	if size_level >= 20:
		_setup_as_boss()
	else:
		print("圆形敌人生成，体型等级=", size_level, " 不是 Boss")

func _exit_tree() -> void:
	if is_boss:
		print("=== Boss 从场景树移除 ===")
		print("移除原因：可能是被击败或其他原因")

func _setup_as_boss() -> void:
	"""设置为 Boss 属性"""
	is_boss = true
	max_health *= boss_health_multiplier
	current_health = max_health
	attack_damage *= boss_damage_multiplier
	score_value = boss_score_value
	print("=== Boss 初始化完成 ===")
	print("生命值=", current_health, " 伤害=", attack_damage, " 分数=", score_value)
	print("体型等级=", size_level, " 尺寸=", enemy_size)

func _on_hit(source: Node) -> void:
	super._on_hit(source)
	if is_boss:
		print("Boss 受击！剩余生命=", current_health, "/", max_health, " 伤害来源=", source.name if source else "未知")

func _initialize_shape() -> void:
	super._initialize_shape()
	if hitbox_shape:
		hitbox_shape.shape.radius = enemy_size.x / 2
	if hurtbox_shape:
		hurtbox_shape.shape.radius = enemy_size.x / 2

func _setup_particle_texture(particle: GPUParticles2D) -> void:
	"""设置圆形敌人的死亡粒子纹理"""
	var texture = load("res://assets/particles/circle_particle.png")
	if texture:
		particle.texture = texture
	
	# Boss 使用特殊粒子效果
	if is_boss:
		particle.amount = 200  # 更多粒子
		particle.lifetime = 2.0
	
