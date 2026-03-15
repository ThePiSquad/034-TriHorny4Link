class_name WaveAnnouncement extends CanvasLayer

# UI 节点
var panel: Panel
var wave_label: Label
var preparation_label: Label
var animation_timer: Timer

# 动画相关
var is_animating: bool = false
var animation_time: float = 0.0
var visible_duration: float = 2.0
var fade_in_duration: float = 0.5
var fade_out_duration: float = 0.5

func _ready() -> void:
	# 创建 UI 元素
	_create_ui()
	
	# 初始隐藏
	hide_announcement()
	
	# 延迟连接信号，确保 EnemyManager 已初始化
	await get_tree().create_timer(0.5).timeout
	
	# 连接到 EnemyManager 的波次信号
	var enemy_manager = get_tree().get_root().get_node_or_null("World/WorldPainter/EnemyManager")
	if enemy_manager and enemy_manager.wave_system:
		enemy_manager.wave_system.wave_preparing.connect(_on_wave_preparing)
		enemy_manager.wave_system.wave_started.connect(_on_wave_started)
		print("WaveAnnouncement: 信号连接成功")
	else:
		print("WaveAnnouncement: 警告 - EnemyManager 或 wave_system 不存在")

func _create_ui() -> void:
	"""创建波次提示 UI"""
	# 主面板
	panel = Panel.new()
	panel.name = "WaveAnnouncementPanel"
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.3
	panel.anchor_bottom = 0.5
	panel.offset_left = -200
	panel.offset_right = 200
	panel.offset_top = -50
	panel.offset_bottom = 50
	add_child(panel)
	
	# 波次标签
	wave_label = Label.new()
	wave_label.name = "WaveLabel"
	wave_label.text = "WAVE 1"
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wave_label.add_theme_font_size_override("font_size", 48)
	wave_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	panel.add_child(wave_label)
	
	# 准备标签
	preparation_label = Label.new()
	preparation_label.name = "PreparationLabel"
	preparation_label.text = "准备战斗！"
	preparation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preparation_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	preparation_label.add_theme_font_size_override("font_size", 24)
	preparation_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	panel.add_child(preparation_label)

func _on_wave_preparing(wave_number: int) -> void:
	"""波次准备开始"""
	var is_boss = wave_number > 10
	show_announcement(wave_number, is_boss)

func _on_wave_started(_wave_number: int) -> void:
	"""波次开始"""
	hide_announcement()

func show_announcement(wave_number: int, is_boss: bool = false) -> void:
	"""显示波次提示"""
	if is_animating:
		return
	
	is_animating = true
	animation_time = 0.0
	
	# 设置文本
	if is_boss:
		wave_label.text = "BOSS WAVE!"
		wave_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
		preparation_label.text = "最终决战！"
	else:
		wave_label.text = "WAVE " + str(wave_number)
		wave_label.remove_theme_color_override("font_color")
		preparation_label.text = "准备战斗！"
	
	# 显示面板
	panel.visible = true
	panel.modulate.a = 0.0

func hide_announcement() -> void:
	"""隐藏波次提示"""
	panel.visible = false
	is_animating = false

func _process(delta: float) -> void:
	if not is_animating:
		return
	
	animation_time += delta
	
	# 淡入阶段
	if animation_time < fade_in_duration:
		var progress = animation_time / fade_in_duration
		panel.modulate.a = progress
	
	# 完全显示阶段
	elif animation_time < fade_in_duration + visible_duration:
		panel.modulate.a = 1.0
	
	# 淡出阶段
	elif animation_time < fade_in_duration + visible_duration + fade_out_duration:
		var progress = (animation_time - fade_in_duration - visible_duration) / fade_out_duration
		panel.modulate.a = 1.0 - progress
		
		if progress >= 1.0:
			panel.visible = false
			is_animating = false
	
	# 动画完成
	else:
		panel.visible = false
		is_animating = false
