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

var pool_stats_container: VBoxContainer
var pool_stats_content: VBoxContainer

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

# 对象池统计缓存
var _pool_stats_cache: Dictionary = {}
var _pool_peak_stats: Dictionary = {}  # 峰值统计
var _pool_creation_count: Dictionary = {}  # 创建计数
var _pool_reuse_count: Dictionary = {}  # 重用计数

func _ready() -> void:
	visible = false
	_cached_bullet_stats = _get_bullet_stats()
	_create_pool_stats_ui()
	_initialize_pool_stats()

func _create_pool_stats_ui() -> void:
	pool_stats_container = VBoxContainer.new()
	pool_stats_container.name = "PoolStatsContainer"
	pool_stats_container.offset_left = 10.0
	pool_stats_container.offset_top = 145.0
	pool_stats_container.offset_right = 240.0
	pool_stats_container.offset_bottom = 390.0
	add_child(pool_stats_container)
	
	var title = Label.new()
	title.name = "PoolStatsTitle"
	title.text = "对象池统计"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.offset_right = 230.0
	title.offset_bottom = 20.0
	pool_stats_container.add_child(title)
	
	var scroll = ScrollContainer.new()
	scroll.name = "PoolStatsScroll"
	scroll.offset_top = 20.0
	scroll.offset_right = 230.0
	scroll.offset_bottom = 245.0
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pool_stats_container.add_child(scroll)
	
	pool_stats_content = VBoxContainer.new()
	pool_stats_content.name = "PoolStatsContent"
	pool_stats_content.offset_right = 230.0
	pool_stats_content.offset_bottom = 225.0
	scroll.add_child(pool_stats_content)
	
	print("PerformanceMonitor: UI 节点创建完成")

func _initialize_pool_stats() -> void:
	if ObjectPoolManager.instance:
		var stats = ObjectPoolManager.instance.get_pool_stats()
		print("PerformanceMonitor: 找到 %d 个对象池" % stats.size())
		for scene_path in stats:
			_pool_stats_cache[scene_path] = {"active": 0, "pooled": 0}
			_pool_peak_stats[scene_path] = {"active_peak": 0, "total_created": 0}
			_pool_creation_count[scene_path] = 0
			_pool_reuse_count[scene_path] = 0

func _process(delta: float) -> void:
	if not show_monitor:
		return
	
	update_timer += delta
	if update_timer >= update_interval:
		update_timer = 0.0
		_update_display()
		_update_pool_stats()
	
	if _touch_click_timer > 0:
		_touch_click_timer -= delta
		if _touch_click_timer <= 0:
			_touch_click_count = 0
	
	_stats_cache_timer -= delta
	if _stats_cache_timer <= 0:
		_cached_bullet_stats = _get_bullet_stats()
		_stats_cache_timer = 0.2

func _update_display() -> void:
	if not visible:
		return
	
	var fps = Performance.get_monitor(Performance.TIME_FPS)
	fps_label.text = "FPS: %d" % fps
	
	var static_mem = Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
	memory_label.text = "内存：%.1f MB" % static_mem
	
	var enemy_count = get_tree().get_node_count_in_group("enemy")
	enemy_count_label.text = "敌人：%d" % enemy_count
	
	var turret_count = get_tree().get_node_count_in_group("turret")
	turret_count_label.text = "炮塔：%d" % turret_count
	
	bullet_count_label.text = "子弹：%d (活跃:%d)" % [_cached_bullet_stats.total, _cached_bullet_stats.active]
	
	if fps >= 55:
		fps_label.modulate = Color.GREEN
	elif fps >= 30:
		fps_label.modulate = Color.YELLOW
	else:
		fps_label.modulate = Color.RED

func _update_pool_stats() -> void:
	if not ObjectPoolManager.instance:
		if pool_stats_container:
			pool_stats_container.visible = false
		return
	
	if not pool_stats_container or not pool_stats_content:
		return
	
	pool_stats_container.visible = true
	var stats = ObjectPoolManager.instance.get_pool_stats()
	
	for child in pool_stats_content.get_children():
		child.queue_free()
	
	var total_active = 0
	var total_pooled = 0
	
	for scene_path in stats:
		var pool_stats = stats[scene_path]
		var active = pool_stats.get("active", 0)
		var pooled = pool_stats.get("pooled", 0)
		var total = active + pooled
		
		total_active += active
		total_pooled += pooled
		
		if not _pool_peak_stats.has(scene_path):
			_pool_peak_stats[scene_path] = {"active_peak": 0, "total_created": total}
		
		if active > _pool_peak_stats[scene_path].active_peak:
			_pool_peak_stats[scene_path].active_peak = active
		
		if total > _pool_peak_stats[scene_path].total_created:
			var new_created = total - _pool_peak_stats[scene_path].total_created
			_pool_peak_stats[scene_path].total_created += new_created
			_pool_creation_count[scene_path] = _pool_creation_count.get(scene_path, 0) + new_created
		
		var reuse_count = max(0, active + _pool_peak_stats[scene_path].total_created - total)
		_pool_reuse_count[scene_path] = reuse_count
		
		var pool_name = scene_path.get_file().replace(".tscn", "")
		var stats_text = "%s\n  活跃：%d | 池中：%d | 峰值：%d\n  创建：%d | 重用：%d" % [
			pool_name,
			active,
			pooled,
			_pool_peak_stats[scene_path].active_peak,
			_pool_creation_count.get(scene_path, 0),
			_pool_reuse_count.get(scene_path, 0)
		]
		
		var label = Label.new()
		label.text = stats_text
		label.add_theme_font_size_override("font_size", 10)
		pool_stats_content.add_child(label)
	
	var total_label = Label.new()
	total_label.text = "\n总计：活跃 %d | 池中 %d | 对象池数：%d" % [total_active, total_pooled, stats.size()]
	total_label.add_theme_font_size_override("font_size", 11)
	total_label.add_theme_color_override("font_color", Color.YELLOW)
	pool_stats_content.add_child(total_label)

func _get_bullet_stats() -> Dictionary:
	var total_count = 0
	var active_count = 0
	
	if ObjectPoolManager.instance:
		var stats = ObjectPoolManager.instance.get_pool_stats()
		for scene_path in stats:
			if scene_path.begins_with("res://src/bullets/"):
				var pool_stats = stats[scene_path]
				var pooled = pool_stats.get("pooled", 0)
				var active = pool_stats.get("active", 0)
				total_count += pooled
				active_count += active
	else:
		var all_bullets = get_tree().get_nodes_in_group("bullet")
		for bullet in all_bullets:
			if is_instance_valid(bullet):
				total_count += 1
				if bullet.has_method("is_active") and bullet.is_active():
					active_count += 1
	
	return {"total": total_count, "active": active_count}

func toggle_monitor() -> void:
	show_monitor = !show_monitor
	visible = show_monitor

func _handle_touch_input(touch_pos: Vector2) -> void:
	if not _touch_area.has_point(touch_pos):
		return
	
	_touch_click_timer = _touch_click_timeout
	_touch_click_count += 1
	
	if _touch_click_count >= 3:
		toggle_monitor()
		_touch_click_count = 0
		_touch_click_timer = 0.0

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11:
			toggle_monitor()
	
	if event is InputEventScreenTouch and event.pressed:
		_handle_touch_input(event.position)
