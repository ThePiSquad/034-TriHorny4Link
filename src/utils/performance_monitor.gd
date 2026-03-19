extends CanvasLayer
class_name PerformanceMonitor

## 性能监控器 - 用于实时显示游戏性能数据

@onready var fps_label: Label = $FPSLabel
@onready var memory_label: Label = $MemoryLabel
@onready var enemy_count_label: Label = $EnemyCountLabel
@onready var turret_count_label: Label = $TurretCountLabel
@onready var bullet_count_label: Label = $BulletCountLabel

var update_interval: float = 0.5  # 更新间隔（秒）
var update_timer: float = 0.0

var show_monitor: bool = true  # 是否显示监控面板

func _ready() -> void:
	# 默认隐藏，按 F11 显示
	visible = false

func _process(delta: float) -> void:
	if not show_monitor:
		return
	
	update_timer += delta
	if update_timer >= update_interval:
		update_timer = 0.0
		_update_display()

func _update_display() -> void:
	"""更新显示数据"""
	if not visible:
		return
	
	# FPS
	var fps = Performance.get_monitor(Performance.TIME_FPS)
	fps_label.text = "FPS: %d" % fps
	
	# 内存使用（MB）
	var static_mem = Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
	var msg_mem = Performance.get_monitor(Performance.MEMORY_MESSAGE_BUFFER_MAX) / 1048576.0
	memory_label.text = "内存：%.1f MB" % static_mem
	
	# 敌人数量
	var enemy_count = get_tree().get_node_count_in_group("enemy")
	enemy_count_label.text = "敌人：%d" % enemy_count
	
	# 炮塔数量
	var turret_count = get_tree().get_node_count_in_group("turret")
	turret_count_label.text = "炮塔：%d" % turret_count
	
	# 子弹数量（估算）
	var bullet_count = _count_bullets()
	bullet_count_label.text = "子弹：%d" % bullet_count
	
	# 根据 FPS 改变颜色
	if fps >= 55:
		fps_label.modulate = Color.GREEN
	elif fps >= 30:
		fps_label.modulate = Color.YELLOW
	else:
		fps_label.modulate = Color.RED

func _count_bullets() -> int:
	"""统计子弹数量"""
	var count = 0
	var all_nodes = get_tree().get_nodes_in_group("bullet")
	for node in all_nodes:
		if node is Bullet:
			count += 1
	return count

func toggle_monitor() -> void:
	"""切换监控面板显示"""
	show_monitor = !show_monitor
	visible = show_monitor

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11:
			toggle_monitor()
