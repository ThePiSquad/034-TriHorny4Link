extends Node2D

@export var state: GameState = GameState.new()

@onready var input_manager: InputManager = $InputManager
@onready var placement_preview: PlacementPreview = $PlacementPreview
@onready var structure_manager: StructureManager = $WorldPainter/StructureManager
@onready var hud: HUD = $HUD
@onready var camera: Camera2D = $Camera2D
@onready var resource_manager: ResourceManager = $ResourceManager
@onready var screen_shake_manager: ScreenShakeManager = $ScreenShakeManager
@onready var crystal: Node2D = $WorldPainter/StructureManager/Crystal

# 游戏结束场景
var game_over_scene: PackedScene = preload("res://src/ui/game_over_screen.tscn")

func _ready() -> void:
	# 连接 InputManager 的引用
	input_manager.structure_manager = structure_manager
	input_manager.placement_preview = placement_preview
	input_manager.hud = hud
	input_manager.camera = camera
	input_manager.resource_manager = resource_manager
	
	# 初始化 PlacementPreview
	placement_preview.set_structure_type(Enums.StructureType.TURRET)
	
	# 连接资源管理器到 HUD
	resource_manager.resource_changed.connect(_on_resource_changed)
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
	var game_manager = GameManager.instance
	if not game_manager:
		# 创建 GameManager 节点
		game_manager = GameManager.new()
		add_child(game_manager)
		game_manager.start_game()
		print("GameManager 初始化完成")
	
	# 监听游戏结束事件
	if not game_manager.game_over_signal.is_connected(_on_game_over):
		game_manager.game_over_signal.connect(_on_game_over)

func _on_game_over() -> void:
	"""游戏结束时的处理"""
	print("收到游戏结束事件，切换到结束页面")
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
	var red_ratio = resource_manager.get_resource_ratio("red")
	var blue_ratio = resource_manager.get_resource_ratio("blue")
	var yellow_ratio = resource_manager.get_resource_ratio("yellow")
	hud.set_resource_ratios(red_ratio, blue_ratio, yellow_ratio)

func _center_camera_on_crystal() -> void:
	"""将摄像机居中到 Crystal 对象"""
	if crystal and camera:
		# 获取 Crystal 的全局位置
		var crystal_global_position = crystal.global_position
		# 设置摄像机的位置为 Crystal 的位置
		camera.global_position = crystal_global_position
		print("摄像机已居中到 Crystal，位置：", crystal_global_position)
