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
@onready var placement_preview: PlacementPreview = $PlacementPreview

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
		input_manager.placement_preview = placement_preview
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
	
	# 监听敌人攻击水晶的事件
	crystal.hit.connect(_on_crystal_hit)
	
	# 添加到场景
	get_tree().current_scene.add_child(enemy)
	
	print("矩形敌人生成在：", spawn_position)
	
	# 等待敌人攻击水晶
	await crystal.hit
	
	print("步骤0完成，敌人已攻击水晶")
	
	# 进入步骤1
	_start_place_crystal_tutorial()

func _on_crystal_hit(source: Node) -> void:
	"""水晶被攻击时的回调"""
	print("水晶被攻击，源：", source)

func _start_place_crystal_tutorial() -> void:
	"""开始放置水晶教学"""
	print("步骤1：放置蓝色MonoCrystal教学")
	current_step = TutorialStep.STEP_1_PLACE_CRYSTAL
	current_state = TutorialState.DEMONSTRATION
	
	# 显示HUD
	_show_hud()
	
	# 限制只能选择蓝色
	_limit_color_selection_to_blue()
	
	# 限制输入管理器
	if input_manager:
		input_manager.set_allowed_structure_type(Enums.StructureType.MONO_CRYSTAL)
		input_manager.set_allowed_color_type(Enums.ColorType.BLUE)
	
	# 等待1秒让玩家看清HUD
	await get_tree().create_timer(1.0).timeout
	
	# 启用玩家交互
	_enable_player_interaction()
	
	# 进入交互状态
	current_state = TutorialState.INTERACTION
	
	# 监听MonoCrystal放置事件
	if structure_manager:
		structure_manager.child_entered_tree.connect(_on_structure_placed)
	
	print("请玩家放置蓝色MonoCrystal")

func _limit_color_selection_to_blue() -> void:
	"""限制只能选择蓝色"""
	if not hud:
		return
	
	# 获取所有图标
	var red_circle = hud.get_node("SelectionPanel/IconsContainer/RedCircle")
	var blue_circle = hud.get_node("SelectionPanel/IconsContainer/BlueCircle")
	var yellow_circle = hud.get_node("SelectionPanel/IconsContainer/YellowCircle")
	var rectangle_icon = hud.get_node("SelectionPanel/IconsContainer/RectangleIcon")
	var triangle_icon = hud.get_node("SelectionPanel/IconsContainer/TriangleIcon")
	
	# 禁用红色和黄色圆圈
	if red_circle:
		red_circle.disabled = true
	if yellow_circle:
		yellow_circle.disabled = true
	
	# 禁用矩形和三角形图标
	if rectangle_icon:
		rectangle_icon.disabled = true
	if triangle_icon:
		triangle_icon.disabled = true
	
	# 确保蓝色可用并启动高亮动画
	if blue_circle:
		blue_circle.disabled = false
		blue_circle.highlight_animation = true
	
	print("已限制只能选择蓝色")

func _on_structure_placed(node: Node) -> void:
	"""建筑放置时的回调"""
	if not node or not node is MonoCrystal:
		return
	
	print("检测到MonoCrystal放置")
	
	# 验证是否是蓝色
	var mono_crystal = node as MonoCrystal
	if mono_crystal.color != Enums.ColorType.BLUE:
		print("错误：放置的不是蓝色MonoCrystal")
		return
	
	print("成功放置蓝色MonoCrystal")
	
	# 停止蓝色圆圈的高亮动画
	if hud:
		var blue_circle = hud.get_node("SelectionPanel/IconsContainer/BlueCircle")
		if blue_circle:
			blue_circle.highlight_animation = false
	
	# 断开连接
	if structure_manager:
		structure_manager.child_entered_tree.disconnect(_on_structure_placed)
	
	# 进入下一步
	_start_conduit_tutorial()

func _start_conduit_tutorial() -> void:
	"""开始连接导管教学"""
	print("步骤2：连接导管教学")
	current_step = TutorialStep.STEP_2_CONNECT_CONDUIT
	current_state = TutorialState.COMPLETED
	# TODO: 实现步骤2
