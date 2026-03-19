extends CanvasLayer
class_name PerformanceMonitor

## 性能监控器 - 用于实时显示游戏性能数据
## 切换方式：
## - PC：按 F11 键
## - 安卓：点击屏幕左上角区域 3 次（隐藏区域）

@onready var fps_label: Label = $FPSLabel
@onready var memory_label: Label = $MemoryLabel
@onready var enemy_count_label: Label = $EnemyCountLabel
@onready var turret_count_label: Label = $TurretCountLabel
@onready var bullet_count_label: Label = $BulletCountLabel

var update_interval: float = 1.0  # 更新间隔（秒）- 降低更新频率
var update_timer: float = 0.0

var show_monitor: bool = true  # 是否显示监控面板

# 安卓触摸切换配置
var _touch_click_count: int = 0
var _touch_click_timer: float = 0.0
var _touch_click_timeout: float = 0.5  # 点击间隔超时时间（秒）
var _touch_area: Rect2 = Rect2(0, 0, 100, 100)  # 左上角触摸区域

# 缓存统计结果，减少重复计算
var _cached_bullet_stats: Dictionary = {"total": 0, "active": 0}
var _stats_cache_timer: float = 0.0

func _ready() -> void:
	# 默认隐藏，按 F11 显示
	visible = false
	# 立即更新一次缓存
	_cached_bullet_stats = _get_bullet_stats()

func _process(delta: float) -> void:
	if not show_monitor:
		return
	
	update_timer += delta
	if update_timer >= update_interval:
		update_timer = 0.0
		_update_display()
	
	# 更新触摸点击计时器
	if _touch_click_timer > 0:
		_touch_click_timer -= delta
		if _touch_click_timer <= 0:
			_touch_click_count = 0
	
	# 更新缓存计时器（更频繁地更新）
	_stats_cache_timer -= delta
	if _stats_cache_timer <= 0:
		_cached_bullet_stats = _get_bullet_stats()
		_stats_cache_timer = 0.2  # 0.2 秒缓存一次，更及时

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
	
	# 子弹数量统计（使用缓存）
	bullet_count_label.text = "子弹：%d (活跃:%d)" % [_cached_bullet_stats.total, _cached_bullet_stats.active]
	
	# 根据 FPS 改变颜色
	if fps >= 55:
		fps_label.modulate = Color.GREEN
	elif fps >= 30:
		fps_label.modulate = Color.YELLOW
	else:
		fps_label.modulate = Color.RED

func _get_bullet_stats() -> Dictionary:
	"""获取子弹统计信息（优化版）"""
	var total_count = 0
	var active_count = 0
	
	if ObjectPoolManager.instance:
		var stats = ObjectPoolManager.instance.get_pool_stats()
		
		# 只统计子弹类型，减少字符串操作
		for scene_path in stats:
			if scene_path.begins_with("res://src/bullets/"):
				var pool_stats = stats[scene_path]
				var pooled = pool_stats.get("pooled", 0)
				var active = pool_stats.get("active", 0)
				total_count += pooled
				active_count += active
	else:
		# 如果对象池管理器不存在，尝试直接统计场景中的子弹
		var all_bullets = get_tree().get_nodes_in_group("bullet")
		for bullet in all_bullets:
			if is_instance_valid(bullet):
				total_count += 1
				if bullet.has_method("is_active") and bullet.is_active():
					active_count += 1
	
	return {"total": total_count, "active": active_count}

func toggle_monitor() -> void:
	"""切换监控面板显示"""
	show_monitor = !show_monitor
	visible = show_monitor

func _handle_touch_input(touch_pos: Vector2) -> void:
	"""处理触摸输入（安卓）"""
	# 检查触摸是否在左上角区域
	if not _touch_area.has_point(touch_pos):
		return
	
	# 重置点击计时器
	_touch_click_timer = _touch_click_timeout
	
	# 增加点击计数
	_touch_click_count += 1
	
	# 如果点击达到 3 次，切换监控面板
	if _touch_click_count >= 3:
		toggle_monitor()
		_touch_click_count = 0
		_touch_click_timer = 0.0

func _input(event: InputEvent) -> void:
	# PC 键盘切换
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11:
			toggle_monitor()
	
	# 安卓触摸切换
	if event is InputEventScreenTouch and event.pressed:
		_handle_touch_input(event.position)
