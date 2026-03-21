extends Node2D

@export var state: GameState = GameState.new()

@onready var input_manager: InputManager = $InputManager
@onready var placement_preview: PlacementPreview = $PlacementPreview
@onready var structure_manager: StructureManager = $WorldPainter/StructureManager
@onready var hud: HUD = $HUD
@onready var camera: Camera2D = $Camera2D
@onready var game_resource_manager: GameResourceManager = $GameResourceManager
@onready var screen_shake_manager: ScreenShakeManager = $ScreenShakeManager
@onready var crystal: Node2D = $WorldPainter/StructureManager/Crystal
@onready var navigation_region: NavigationRegion2D = $NavigationRegion2D

# 游戏结束场景
var game_over_scene: PackedScene = preload("res://src/ui/game_over_screen.tscn")

# 导航网格更新相关
var _navigation_update_queued: bool = false
var _conduits_positions: Array = []  # 存储所有 Conduit 的位置

func _ready() -> void:
	# 连接 InputManager 的引用
	input_manager.structure_manager = structure_manager
	input_manager.placement_preview = placement_preview
	input_manager.hud = hud
	input_manager.camera = camera
	input_manager.game_resource_manager = game_resource_manager
	
	# 初始化 PlacementPreview
	placement_preview.set_structure_type(Enums.StructureType.TURRET)
	
	# 连接资源管理器到 HUD
	game_resource_manager.resource_changed.connect(_on_resource_changed)
	_update_hud_resources()
	
	# 设置屏幕抖动管理器的相机引用
	screen_shake_manager.camera = camera
	
	# 将 World 节点添加到 world 组
	add_to_group("world")
	
	# 初始化 GameManager
	_initialize_game_manager()
	
	# 摄像机初始位置设置：将 Crystal 居中
	_center_camera_on_crystal()

func _initialize_game_manager() -> void:
	"""初始化游戏管理器"""
	# 开发阶段：清除关卡缓存以确保加载最新配置
	if ResourceManager.instance:
		ResourceManager.instance.clear_level_cache()
		print("已清除关卡缓存，将重新加载最新配置")
	
	var game_manager = GameManager.instance
	if game_manager:
		# 重置游戏状态
		game_manager.start_game()
		print("GameManager 初始化完成")
	
	# 启动 EnemyManager 的波次系统
	var enemy_manager = $WorldPainter/EnemyManager
	if enemy_manager and enemy_manager.has_method("start_game"):
		enemy_manager.start_game()
	
	# 监听游戏结束事件
	if game_manager and not game_manager.game_over_signal.is_connected(_on_game_over):
		game_manager.game_over_signal.connect(_on_game_over)

func _on_game_over() -> void:
	"""游戏结束时的处理"""
	print("收到游戏结束事件，切换到结束页面")
	# 禁用所有敌人和子弹的行为，但不删除它们
	_disable_game_objects()
	# 延迟切换，确保粒子效果播放完成
	await get_tree().create_timer(2.0).timeout
	_switch_to_game_over_scene()

func _switch_to_game_over_scene() -> void:
	"""切换到游戏结束场景"""
	var transition_manager = TransitionManager.instance
	if transition_manager:
		print("使用 TransitionManager 切换到游戏结束场景")
		transition_manager.change_scene("res://src/ui/game_over_screen.tscn")
	else:
		print("警告：TransitionManager 实例不存在，使用默认场景切换")
		var scene_tree = get_tree()
		if scene_tree:
			scene_tree.change_scene_to_file("res://src/ui/game_over_screen.tscn")

func _on_resource_changed() -> void:
	_update_hud_resources()

func _update_hud_resources() -> void:
	var red_ratio = game_resource_manager.get_resource_ratio("red")
	var blue_ratio = game_resource_manager.get_resource_ratio("blue")
	var yellow_ratio = game_resource_manager.get_resource_ratio("yellow")
	hud.set_resource_ratios(red_ratio, blue_ratio, yellow_ratio)

func _center_camera_on_crystal() -> void:
	"""将摄像机居中到 Crystal 对象"""
	if crystal and camera:
		# 获取 Crystal 的全局位置
		var crystal_global_position = crystal.global_position
		# 设置摄像机的位置为 Crystal 的位置
		camera.global_position = crystal_global_position
		print("摄像机已居中到 Crystal，位置：", crystal_global_position)

func _disable_game_objects() -> void:
	"""禁用所有游戏对象的行为（但不删除）"""
	print("禁用游戏对象...")
	
	# 停止敌人生成
	var enemy_manager = $WorldPainter/EnemyManager
	if enemy_manager:
		enemy_manager.game_started = false
		if enemy_manager.wave_system:
			enemy_manager.wave_system.reset()
	
	# 禁用所有敌人的行为
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if is_instance_valid(enemy):
			# 设置为非激活状态，停止移动和攻击
			enemy.set_process(false)
			enemy.set_physics_process(false)
			enemy.set_process_input(false)
			if enemy.has_method("set_navigation_enabled"):
				enemy.set_navigation_enabled(false)
	
	# 禁用所有子弹的行为
	var bullets = get_tree().get_nodes_in_group("bullet")
	for bullet in bullets:
		if is_instance_valid(bullet):
			# 设置为非激活状态，停止移动
			bullet.set_process(false)
			bullet.set_physics_process(false)
			bullet.set_process_input(false)
			bullet.visible = false
	
	print("游戏对象已禁用")

var _navigation_update_timer: float = 0.0
var _navigation_update_interval: float = 0.5  # 每 0.5 秒检查一次导航网格更新

func _process(delta: float) -> void:
	# 更新导航障碍物（当 Conduit 变化时）- 限制更新频率
	_navigation_update_timer += delta
	if _navigation_update_timer >= _navigation_update_interval:
		_navigation_update_timer = 0.0
		_check_navigation_update_needed()

func _check_navigation_update_needed() -> void:
	"""检查是否需要更新导航网格"""
	# 获取所有 Conduit
	var conduits = get_tree().get_nodes_in_group("structure")
	var current_positions: Array = []
	
	for conduit in conduits:
		if conduit and is_instance_valid(conduit) and conduit.has_method("get_structure_type"):
			var structure_type = conduit.get_structure_type()
			if structure_type == Enums.StructureType.CONDUIT:
				current_positions.append(conduit.position)
	
	# 检查 Conduit 位置是否发生变化
	if current_positions != _conduits_positions:
		_conduits_positions = current_positions
		if not _navigation_update_queued:
			_navigation_update_queued = true
			# 延迟一帧更新，避免频繁调用
			await get_tree().process_frame
			_update_navigation_mesh()
			_navigation_update_queued = false

func _update_navigation_mesh() -> void:
	"""动态更新导航网格以反映障碍物的位置"""
	if not navigation_region:
		return
	
	# 获取当前的导航多边形
	var nav_poly = navigation_region.navigation_polygon
	if not nav_poly:
		return
	
	# 使用 NavigationServer2D 重新烘焙导航网格
	var source_geometry = NavigationMeshSourceGeometryData2D.new()
	
	# 解析源几何数据
	NavigationServer2D.parse_source_geometry_data(nav_poly, source_geometry, self)
	
	# 添加 Conduit 作为障碍物
	for pos in _conduits_positions:
		var half_size = Constants.grid_size / 2.0
		var obstacle_vertices = PackedVector2Array([
			pos + Vector2(-half_size, -half_size),
			pos + Vector2(-half_size, half_size),
			pos + Vector2(half_size, half_size),
			pos + Vector2(half_size, -half_size)
		])
		source_geometry.add_projected_obstruction(obstacle_vertices, true)
	
	# 从源几何数据烘焙导航网格
	NavigationServer2D.bake_from_source_geometry_data(nav_poly, source_geometry)
	
	# 通知导航区域更新
	navigation_region.navigation_polygon = nav_poly
