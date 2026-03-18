extends Node2D

enum TutorialStep {
	STEP_0_ENEMY_ATTACK,      # 步骤0：敌人攻击
	STEP_1_PLACE_CRYSTAL,      # 步骤1：放置圆形（水晶）
	STEP_2_CONNECT_CONDUIT,     # 步骤2：连接矩形（导管）
	STEP_3_PLACE_TURRET,       # 步骤3：放置炮塔
	STEP_4_COLOR_MIXING,        # 步骤4：颜色混色演示
	STEP_5_ENEMY_INTRODUCTION,  # 步骤5：敌人介绍
	STEP_6_TEST_DEFENSE,        # 步骤6：测试防御
	COMPLETED
}

enum TutorialState {
	DEMONSTRATION,  # 演示状态
	INTERACTION,     # 交互状态
	WAITING,         # 等待状态
	COMPLETED        # 完成状态
}

@onready var input_manager: InputManager = $TutorialInputManager
@onready var structure_manager: StructureManager = $WorldPainter/StructureManager
@onready var hud: TutorialHUD = $TutorialHUD
@onready var camera: Camera2D = $Camera2D
@onready var enemy_manager: EnemyManager = $WorldPainter/EnemyManager
@onready var crystal: Crystal = $WorldPainter/StructureManager/Crystal

var current_step: TutorialStep = TutorialStep.STEP_0_ENEMY_ATTACK
var current_state: TutorialState = TutorialState.WAITING
var tutorial_timer: float = 0.0

func _center_camera_on_crystal() -> void:
	"""将摄像机居中到 Crystal 对象"""
	if crystal and camera:
		# 获取 Crystal 的全局位置
		var crystal_global_position = crystal.global_position
		# 设置摄像机的位置为 Crystal 的位置
		camera.global_position = crystal_global_position
		print("摄像机已居中到 Crystal，位置：", crystal_global_position)

func _ready() -> void:
	_center_camera_on_crystal()
	_initialize_tutorial()

func _initialize_tutorial() -> void:
	"""初始化教学"""
	print("教学关卡初始化")
	
	# 连接InputManager的引用
	if input_manager:
		input_manager.structure_manager = structure_manager
		input_manager.placement_preview = null
		input_manager.hud = hud
		input_manager.camera = camera
	
	# 禁用玩家交互
	_disable_player_interaction()
	
	# 收起HUD
	_hide_hud()
	
	# 开始教学流程
	_start_enemy_attack_demo()

func _disable_player_interaction() -> void:
	"""禁用玩家交互"""
	if input_manager:
		input_manager.set_input_enabled(false)

func _enable_player_interaction() -> void:
	"""启用玩家交互"""
	if input_manager:
		input_manager.set_input_enabled(true)

func _hide_hud() -> void:
	"""收起HUD"""
	if hud:
		hud.hide()
		hud.hide_hud()

func _show_hud() -> void:
	"""显示HUD"""
	if hud:
		hud.show_hud()

func _start_enemy_attack_demo() -> void:
	"""开始敌人攻击演示"""
	print("步骤0：敌人攻击演示")
	current_step = TutorialStep.STEP_0_ENEMY_ATTACK
	current_state = TutorialState.WAITING
	tutorial_timer = 0.0
	
	# 等待1秒
	await get_tree().create_timer(1.0).timeout
	
	# 生成矩形敌人
	_spawn_rect_enemy()

func _spawn_rect_enemy() -> void:
	"""生成矩形敌人"""
	print("生成矩形敌人")
	
	if not enemy_manager:
		print("错误：EnemyManager不存在")
		return
	if not crystal:
		print("错误：水晶不存在")
		return
	
	var spawn_position = crystal.global_position + Vector2(400.0, 0.0)
	
	# 生成矩形敌人
	var rect_enemy_scene = preload("res://src/enemies/rect_enemy.tscn")
	var enemy = rect_enemy_scene.instantiate()
	enemy.global_position = spawn_position
	
	# 添加到场景
	get_tree().current_scene.add_child(enemy)
	
	print("矩形敌人生成在：", spawn_position)
	
	# 进入下一步
	current_state = TutorialState.COMPLETED
	print("步骤0完成")
