class_name FlyTriangleEnemy extends TriangleEnemy

# 飞行敌人特殊属性
@export var rotation_speed: float = 180.0  # 旋转速度（度/秒）
@export var can_be_hit_by_kinetic: bool = false  # 是否可被子弹击中（默认免疫）
@export var is_flying: bool = true  # 是否为飞行单位（不受地面障碍阻挡）

@onready var shape_shadow_drawer: ShapeDrawer = $ShapeDrawer/ShapeShadowDrawer

func _ready() -> void:
	super._ready()
	# 设置无敌状态，只接受 MAGIC 类型攻击
	invincible = true
	shape_shadow_drawer.shape_size = shape_drawer.shape_size
	
	# 飞行敌人不受 NavigationObstacle2D 影响
	if navigation_agent:
		navigation_agent.avoidance_enabled = false

func _process(delta: float) -> void:
	# 持续旋转 shape_drawer
	if shape_drawer:
		shape_drawer.rotation_degrees += rotation_speed * delta
	super._process(delta)

func take_damage(amount: float, source: Node = null) -> void:
	# 检查是否是子弹攻击
	if source is Bullet:
		var bullet = source as Bullet
		# 只有 MAGIC 类型的子弹才能造成伤害
		if not _is_magic_bullet(bullet):
			# 完全免疫非 MAGIC 类型攻击，不扣血、不触发效果
			return
	
	# MAGIC 类型子弹或非子弹来源，正常处理伤害
	# 临时关闭无敌状态以接受伤害
	invincible = false
	super.take_damage(amount, source)
	invincible = true

func _on_hit(source: Node) -> void:
	# 检查攻击来源类型
	if source is Bullet:
		var bullet = source as Bullet
		# 只有 MAGIC 类型的攻击才能触发受击效果
		if _is_magic_bullet(bullet):
			# 触发父类的受击效果（闪烁、粒子等）
			super._on_hit(source)
		# KINETIC 类型攻击无效，不触发任何效果
	else:
		# 非子弹来源（如场地伤害）可以正常处理
		super._on_hit(source)

func _is_magic_bullet(bullet: Bullet) -> bool:
	"""检查是否是 MAGIC 类型的子弹（激光）"""
	for attr in bullet.attributes:
		if attr == Enums.BulletAttributes.MAGIC:
			return true
	return false
