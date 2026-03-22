class_name FlyTriangleEnemy extends TriangleEnemy

# 飞行敌人特殊属性
@export var rotation_speed: float = 180.0  # 旋转速度（度/秒）
@export var can_be_hit_by_kinetic: bool = false  # 是否可被子弹击中（默认免疫）

func _ready() -> void:
	super._ready()
	# 设置无敌状态，只接受 MAGIC 类型攻击
	invincible = true

func _process(delta: float) -> void:
	# 持续旋转 shape_drawer
	if shape_drawer:
		shape_drawer.rotation_degrees += rotation_speed * delta

func _on_hit(source: Node) -> void:
	# 检查攻击来源类型
	if source is Bullet:
		var bullet = source as Bullet
		# 只有 MAGIC 类型的攻击才能命中
		if _is_magic_bullet(bullet):
			# 暂时关闭无敌，让父类处理正常伤害
			invincible = false
			super._on_hit(source)
			invincible = true
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
