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
@onready var game_resource_manager: GameResourceManager = $GameResourceManager

var current_step: TutorialStep = TutorialStep.STEP_0_ENEMY_ATTACK
var current_state: TutorialState = TutorialState.WAITING
var tutorial_timer: float = 0.0

var placed_mono_crystal: MonoCrystal = null
var placed_conduit: Conduit = null
var highlight_tiles: Array[Node2D] = []
var highlight_tween: Tween = null

func _center_camera_on_crystal() -> void:
	"""将摄像机居中到 Crystal 对象"""
	if crystal and camera:
		# 获取 Crystal 的全局位置
		var crystal_global_position = crystal.global_position
		# 设置摄像机的位置为 Crystal 的位置
		camera.global_position = crystal_global_position
		print("摄像机已居中到 Crystal，位置：", crystal_global_position)

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
	
	# 监听游戏结束事件
	if game_manager and not game_manager.game_over_signal.is_connected(_on_game_over):
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
	if not game_resource_manager or not hud:
		return
	
	var red_ratio = game_resource_manager.get_resource_ratio("red")
	var blue_ratio = game_resource_manager.get_resource_ratio("blue")
	var yellow_ratio = game_resource_manager.get_resource_ratio("yellow")
	hud.set_resource_ratios(red_ratio, blue_ratio, yellow_ratio)

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
		input_manager.game_resource_manager = game_resource_manager
	
	# 连接资源管理器到HUD
	if game_resource_manager:
		game_resource_manager.resource_changed.connect(_on_resource_changed)
		_update_hud_resources()
	
	# 初始化GameManager
	_initialize_game_manager()
	
	# 禁用玩家交互
	_disable_player_interaction()
	
	# 收起HUD
	_hide_hud()
	
	# 开始教学流程
	_start_enemy_attack_demo()

func _enable_player_interaction() -> void:
	"""启用玩家交互"""
	if input_manager:
		input_manager.set_input_enabled(true)
	
	# 教学模式下禁止删除建筑
	if current_state != TutorialState.COMPLETED:
		_set_structures_deletable(false)
	else:
		# 教学完成后允许删除建筑
		_set_structures_deletable(true)

func _disable_player_interaction() -> void:
	"""禁用玩家交互"""
	if input_manager:
		input_manager.set_input_enabled(false)
	
	# 禁止删除建筑
	_set_structures_deletable(false)

func _set_structures_deletable(deletable: bool) -> void:
	"""设置所有建筑是否可以被删除"""
	if not structure_manager:
		return
	
	for child in structure_manager.get_children():
		if child is Structure:
			child.can_be_deleted = deletable

func _hide_hud() -> void:
	"""收起HUD"""
	if hud:
		hud.hide()
		hud.hide_hud()

func _show_hud() -> void:
	"""显示HUD"""
	if hud:
		hud.show_hud()

func _unlock_all_hud_features() -> void:
	"""解锁HUD的全部功能"""
	if not hud:
		return
	
	# 获取所有图标
	var red_circle = hud.get_node("SelectionPanel/IconsContainer/RedCircle")
	var blue_circle = hud.get_node("SelectionPanel/IconsContainer/BlueCircle")
	var yellow_circle = hud.get_node("SelectionPanel/IconsContainer/YellowCircle")
	var rectangle_icon = hud.get_node("SelectionPanel/IconsContainer/RectangleIcon")
	var triangle_icon = hud.get_node("SelectionPanel/IconsContainer/TriangleIcon")
	
	# 启用所有颜色圆圈
	if red_circle:
		red_circle.disabled = false
	if blue_circle:
		blue_circle.disabled = false
	if yellow_circle:
		yellow_circle.disabled = false
	
	# 启用矩形和三角形图标
	if rectangle_icon:
		rectangle_icon.disabled = false
	if triangle_icon:
		triangle_icon.disabled = false
	
	# 停止蓝色圆圈的高亮动画
	if blue_circle:
		blue_circle.highlight_animation = false
	
	# 移除输入限制
	if input_manager:
		input_manager.remove_restrictions()
	
	print("已解锁HUD的全部功能")

func _start_normal_game() -> void:
	"""启动正常的刷怪逻辑"""
	if not enemy_manager:
		print("错误：EnemyManager不存在")
		return
	
	print("启动正常的刷怪逻辑")
	
	# 设置GameManager的选关为tutorial
	if GameManager.instance:
		GameManager.instance.selected_level = "tutorial"
	
	# 启动EnemyManager的游戏逻辑
	enemy_manager.start_game()

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
		# 显式设置当前选中的建筑类型和颜色，确保预览正确
		input_manager.set_selected_structure_type(Enums.StructureType.MONO_CRYSTAL)
		# 强制设置当前颜色为蓝色
		input_manager.selected_color_type = Enums.ColorType.BLUE
	
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
	
	# 保存放置的MonoCrystal引用
	placed_mono_crystal = mono_crystal
	
	# 教学模式下禁止删除建筑
	mono_crystal.can_be_deleted = false
	
	# 停止蓝色圆圈的高亮动画
	if hud:
		var blue_circle = hud.get_node("SelectionPanel/IconsContainer/BlueCircle")
		if blue_circle:
			blue_circle.highlight_animation = false
	
	# 立即禁用玩家交互，防止删除建筑
	_disable_player_interaction()
	
	# 断开连接
	if structure_manager:
		structure_manager.child_entered_tree.disconnect(_on_structure_placed)
	
	# 进入下一步
	_start_conduit_tutorial()

func _start_conduit_tutorial() -> void:
	"""开始连接导管教学"""
	print("步骤2：连接导管教学")
	current_step = TutorialStep.STEP_2_CONNECT_CONDUIT
	current_state = TutorialState.DEMONSTRATION
	
	# 禁止玩家放置任何东西
	_disable_player_interaction()
	
	# 取消HUD选择
	if hud:
		hud._clear_selection()
	
	# 等待1秒
	await get_tree().create_timer(1.0).timeout
	
	# 让HUD只允许选择矩形
	_limit_selection_to_rectangle()
	
	# 启用玩家交互
	_enable_player_interaction()
	
	# 进入交互状态
	current_state = TutorialState.INTERACTION
	
	# 显示MonoCrystal周围可放置的地块
	_show_highlight_tiles()
	
	# 监听导管放置事件
	if structure_manager:
		structure_manager.child_entered_tree.connect(_on_conduit_placed)
	
	print("请玩家在MonoCrystal旁边放置导管")

func _limit_selection_to_rectangle() -> void:
	"""限制只能选择矩形"""
	if not hud:
		return
	
	# 获取所有图标
	var red_circle = hud.get_node("SelectionPanel/IconsContainer/RedCircle")
	var blue_circle = hud.get_node("SelectionPanel/IconsContainer/BlueCircle")
	var yellow_circle = hud.get_node("SelectionPanel/IconsContainer/YellowCircle")
	var rectangle_icon = hud.get_node("SelectionPanel/IconsContainer/RectangleIcon")
	var triangle_icon = hud.get_node("SelectionPanel/IconsContainer/TriangleIcon")
	
	# 禁用所有颜色圆圈
	if red_circle:
		red_circle.disabled = true
	if blue_circle:
		blue_circle.disabled = true
	if yellow_circle:
		yellow_circle.disabled = true
	
	# 禁用三角形图标
	if triangle_icon:
		triangle_icon.disabled = true
	
	# 确保矩形可用
	if rectangle_icon:
		rectangle_icon.disabled = false
	
	# 设置输入管理器允许放置导管
	if input_manager:
		input_manager.set_allowed_structure_type(Enums.StructureType.CONDUIT)
		input_manager.set_allowed_color_type(Enums.ColorType.WHITE)
	
	print("已限制只能选择矩形")

func _show_highlight_tiles() -> void:
	"""显示MonoCrystal周围可放置的地块"""
	if not placed_mono_crystal:
		print("错误：placed_mono_crystal为空")
		return
	
	# 清除之前的高亮
	_clear_highlight_tiles()
	
	# 获取MonoCrystal的网格坐标
	var crystal_pos = GridCoord.from_world_coord(Vector2i(placed_mono_crystal.global_position.x, placed_mono_crystal.global_position.y))
	print("MonoCrystal网格坐标：", crystal_pos)
	
	# 获取周围4个方向的坐标（上下左右）
	var directions = [
		Vector2i(0, -1),   # 上
		Vector2i(0, 1),    # 下
		Vector2i(-1, 0),   # 左
		Vector2i(1, 0)     # 右
	]
	
	# 创建高亮地块
	for dir in directions:
		var neighbor_pos = GridCoord.new(crystal_pos.x + dir.x, crystal_pos.y + dir.y)
		var world_pos = neighbor_pos.to_world_coord()
		
		print("检查位置：", neighbor_pos, "世界坐标：", world_pos)
		
		# 检查该位置是否可以放置导管
		var can_place = structure_manager.can_place_conduit(neighbor_pos)
		print("  可以放置导管：", can_place)
		
		if can_place:
			_create_highlight_tile(Vector2(world_pos.x, world_pos.y))
	
	print("已显示", highlight_tiles.size(), "个高亮地块")
	
	# 开始闪烁动画
	if highlight_tiles.size() > 0:
		_start_highlight_animation()

func _create_highlight_tile(position: Vector2) -> void:
	"""创建高亮地块"""
	var highlight = Sprite2D.new()
	highlight.texture = load("res://assets/particles/rect_solid_particle.png")
	highlight.position = position + Vector2(Constants.grid_size / 2, Constants.grid_size / 2)
	highlight.z_index = -2
	highlight.modulate = Color(1.0, 1.0, 1.0, 0.5)
	
	add_child(highlight)
	highlight_tiles.append(highlight)
	
	print("创建高亮地块在位置：", position)

func _start_highlight_animation() -> void:
	"""开始高亮闪烁动画"""
	if highlight_tween:
		highlight_tween.kill()
	
	highlight_tween = create_tween()
	highlight_tween.set_loops()
	highlight_tween.set_parallel(true)
	highlight_tween.set_trans(Tween.TRANS_SINE)
	highlight_tween.set_ease(Tween.EASE_IN_OUT)
	
	# 循环闪烁动画：0.2 -> 0.5 -> 0.2
	for tile in highlight_tiles:
		if is_instance_valid(tile):
			highlight_tween.tween_property(tile, "modulate:a", 0.5, 0.8)
			highlight_tween.tween_property(tile, "modulate:a", 0.2, 0.8)
	
	print("开始高亮闪烁动画")

func _stop_highlight_animation() -> void:
	"""停止高亮闪烁动画"""
	if highlight_tween:
		highlight_tween.kill()
		highlight_tween = null
	
	# 重置透明度
	for tile in highlight_tiles:
		if is_instance_valid(tile):
			tile.modulate.a = 1.0

func _clear_highlight_tiles() -> void:
	"""清除所有高亮地块"""
	for tile in highlight_tiles:
		if is_instance_valid(tile):
			tile.queue_free()
	highlight_tiles.clear()

func _on_conduit_placed(node: Node) -> void:
	"""导管放置时的回调"""
	if not node or not node is Conduit:
		return
	
	print("检测到导管放置")
	
	# 保存放置的导管引用
	var conduit = node as Conduit
	placed_conduit = conduit
	var conduit_pos = GridCoord.from_world_coord(Vector2i(conduit.global_position.x, conduit.global_position.y))
	var crystal_pos = GridCoord.from_world_coord(Vector2i(placed_mono_crystal.global_position.x, placed_mono_crystal.global_position.y))
	
	# 计算两个GridCoord之间的偏移
	var dx = conduit_pos.x - crystal_pos.x
	var dy = conduit_pos.y - crystal_pos.y
	
	# 只允许上下左右4个方向（曼哈顿距离为1）
	var is_adjacent = (abs(dx) == 1 and dy == 0) or (dx == 0 and abs(dy) == 1)
	
	if not is_adjacent:
		print("导管不在MonoCrystal旁边（只允许上下左右）")
		return
	
	print("导管放置在MonoCrystal旁边")
	
	# 教学模式下禁止删除建筑
	conduit.can_be_deleted = false
	
	# 清除高亮地块
	_clear_highlight_tiles()
	
	# 禁用玩家操作
	_disable_player_interaction()
	
	# 取消HUD选择
	if hud:
		hud._clear_selection()
	
	# 断开连接
	if structure_manager:
		structure_manager.child_entered_tree.disconnect(_on_conduit_placed)
	
	# 进入下一步
	_start_turret_tutorial()

func _start_turret_tutorial() -> void:
	"""开始放置炮塔教学"""
	print("步骤3：放置炮塔教学")
	current_step = TutorialStep.STEP_3_PLACE_TURRET
	current_state = TutorialState.DEMONSTRATION
	
	# 禁止玩家放置任何东西
	_disable_player_interaction()
	
	# 取消HUD选择
	if hud:
		hud._clear_selection()
	
	# 等待1秒
	await get_tree().create_timer(1.0).timeout
	
	# 让HUD只允许选择三角形
	_limit_selection_to_triangle()
	
	# 启用玩家交互
	_enable_player_interaction()
	
	# 进入交互状态
	current_state = TutorialState.INTERACTION
	
	# 显示Conduit周围可放置的地块
	_show_conduit_highlight_tiles()
	
	# 监听炮塔放置事件
	if structure_manager:
		structure_manager.child_entered_tree.connect(_on_turret_placed)
	
	print("请玩家在Conduit旁边放置炮塔")

func _limit_selection_to_triangle() -> void:
	"""限制只能选择三角形"""
	if not hud:
		return
	
	# 获取所有图标
	var red_circle = hud.get_node("SelectionPanel/IconsContainer/RedCircle")
	var blue_circle = hud.get_node("SelectionPanel/IconsContainer/BlueCircle")
	var yellow_circle = hud.get_node("SelectionPanel/IconsContainer/YellowCircle")
	var rectangle_icon = hud.get_node("SelectionPanel/IconsContainer/RectangleIcon")
	var triangle_icon = hud.get_node("SelectionPanel/IconsContainer/TriangleIcon")
	
	# 禁用所有颜色圆圈
	if red_circle:
		red_circle.disabled = true
	if blue_circle:
		blue_circle.disabled = true
	if yellow_circle:
		yellow_circle.disabled = true
	
	# 禁用矩形图标
	if rectangle_icon:
		rectangle_icon.disabled = true
	
	# 确保三角形可用
	if triangle_icon:
		triangle_icon.disabled = false
	
	# 设置输入管理器允许放置炮塔
	if input_manager:
		input_manager.set_allowed_structure_type(Enums.StructureType.TURRET)
		input_manager.set_allowed_color_type(Enums.ColorType.WHITE)
		# 显式设置当前选中的建筑类型，确保预览正确
		input_manager.set_selected_structure_type(Enums.StructureType.TURRET)
		# 强制设置当前颜色为白色
		input_manager.selected_color_type = Enums.ColorType.WHITE
	
	print("已限制只能选择三角形")

func _show_conduit_highlight_tiles() -> void:
	"""显示Conduit周围可放置的地块"""
	if not placed_conduit:
		print("错误：placed_conduit为空")
		return
	
	# 清除之前的高亮
	_clear_highlight_tiles()
	
	# 获取Conduit的网格坐标
	var conduit_pos = GridCoord.from_world_coord(Vector2i(placed_conduit.global_position.x, placed_conduit.global_position.y))
	print("Conduit网格坐标：", conduit_pos)
	
	# 获取周围4个方向的坐标（上下左右）
	var directions = [
		Vector2i(0, -1),   # 上
		Vector2i(0, 1),    # 下
		Vector2i(-1, 0),   # 左
		Vector2i(1, 0)     # 右
	]
	
	# 创建高亮地块
	for dir in directions:
		var neighbor_pos = GridCoord.new(conduit_pos.x + dir.x, conduit_pos.y + dir.y)
		var world_pos = neighbor_pos.to_world_coord()
		
		print("检查位置：", neighbor_pos, "世界坐标：", world_pos)
		
		# 检查该位置是否可以放置炮塔
		var can_place = structure_manager.can_place_turret(neighbor_pos)
		print("  可以放置炮塔：", can_place)
		
		if can_place:
			_create_highlight_tile(Vector2(world_pos.x, world_pos.y))
	
	print("已显示", highlight_tiles.size(), "个高亮地块")
	
	# 开始闪烁动画
	if highlight_tiles.size() > 0:
		_start_highlight_animation()

func _on_turret_placed(node: Node) -> void:
	"""炮塔放置时的回调"""
	if not node or not node is Turret:
		return
	
	print("检测到炮塔放置")
	
	# 保存放置的炮塔引用
	var turret = node as Turret
	
	# 教学模式下禁止删除建筑
	turret.can_be_deleted = false
	
	# 检查是否在Conduit旁边
	var turret_pos = GridCoord.from_world_coord(Vector2i(turret.global_position.x, turret.global_position.y))
	var conduit_pos = GridCoord.from_world_coord(Vector2i(placed_conduit.global_position.x, placed_conduit.global_position.y))
	
	# 计算两个GridCoord之间的偏移
	var dx = turret_pos.x - conduit_pos.x
	var dy = turret_pos.y - conduit_pos.y
	
	# 只允许上下左右4个方向（曼哈顿距离为1）
	var is_adjacent = (abs(dx) == 1 and dy == 0) or (dx == 0 and abs(dy) == 1)
	
	if not is_adjacent:
		print("炮塔不在Conduit旁边（只允许上下左右）")
		return
	
	print("炮塔放置在Conduit旁边")
	
	# 清除高亮地块
	_clear_highlight_tiles()
	
	# 禁用玩家操作
	_disable_player_interaction()
	
	# 取消HUD选择
	if hud:
		hud._clear_selection()
	
	# 断开连接
	if structure_manager:
		structure_manager.child_entered_tree.disconnect(_on_turret_placed)
	
	# 监听炮塔激活状态
	turret.is_active = false  # 确保初始状态为未激活
	turret.color_changed.connect(_on_turret_color_changed)
	
	# 进入等待炮塔激活状态
	_wait_for_turret_activation(turret)

func _on_turret_color_changed(new_color: Enums.ColorType) -> void:
	"""炮塔颜色改变时的回调"""
	print("炮塔颜色改变：", new_color)
	
	# 检查炮塔是否激活
	var turret = _get_placed_turret()
	if turret and turret.is_active:
		print("炮塔已激活！")
		_on_turret_activated()

func _get_placed_turret() -> Turret:
	"""获取最近放置的炮塔"""
	if not structure_manager:
		return null
	
	# 遍历所有建筑，找到最近放置的炮塔
	for structure in structure_manager.get_children():
		if structure is Turret:
			return structure as Turret
	
	return null

func _wait_for_turret_activation(turret: Turret) -> void:
	"""等待炮塔激活"""
	print("等待炮塔激活...")
	current_state = TutorialState.WAITING
	
	# 定期检查炮塔激活状态
	var check_timer = 0.0
	while not turret.is_active:
		await get_tree().process_frame
		check_timer += get_process_delta_time()
		
		# 超时保护（最多等待10秒）
		if check_timer > 10.0:
			print("等待炮塔激活超时")
			break
	
	if turret.is_active:
		_on_turret_activated()

func _on_turret_activated() -> void:
	"""炮塔激活时的回调"""
	print("炮塔已激活，教学完成！")
	current_state = TutorialState.COMPLETED
	
	# 清除高亮地块
	_clear_highlight_tiles()
	
	# 禁用玩家操作
	_disable_player_interaction()
	
	# 取消HUD选择
	if hud:
		hud._clear_selection()
	
	# 在炮塔方向远离Crystal的地方生成敌人
	_spawn_enemy_for_turret()
	
	# 等待一段时间，让玩家看到炮塔攻击敌人
	await get_tree().create_timer(3.0).timeout
	
	# 解锁HUD的全部功能
	_unlock_all_hud_features()
	
	# 启用玩家交互
	_enable_player_interaction()
	
	# 启动正常的刷怪逻辑
	_start_normal_game()

func _spawn_enemy_for_turret() -> void:
	"""在炮塔方向远离Crystal的地方生成敌人"""
	if not crystal or not structure_manager:
		print("错误：crystal或structure_manager不存在")
		return
	
	# 获取炮塔
	var turret = _get_placed_turret()
	if not turret:
		print("错误：找不到炮塔")
		return
	
	# 计算从Crystal到炮塔的方向
	var crystal_pos = crystal.global_position
	var turret_pos = turret.global_position
	var direction = (turret_pos - crystal_pos).normalized()
	
	# 计算生成位置：从炮塔位置继续沿着方向延伸
	var spawn_distance = 450.0  # 从炮塔到敌人的距离（在炮塔检测范围内）
	var spawn_position = turret_pos + direction * spawn_distance
	
	# 检查是否超过最大距离（760px）
	var distance_from_crystal = (spawn_position - crystal_pos).length()
	if distance_from_crystal > 760.0:
		# 如果超过最大距离，调整到最大距离
		spawn_position = crystal_pos + direction * 760.0
	
	print("生成敌人，位置：", spawn_position)
	print("  炮塔位置：", turret_pos)
	print("  Crystal位置：", crystal_pos)
	print("  方向：", direction)
	print("  距离Crystal：", (spawn_position - crystal_pos).length())
	
	# 生成矩形敌人
	var rect_enemy_scene = preload("res://src/enemies/rect_enemy.tscn")
	var enemy = rect_enemy_scene.instantiate()
	enemy.global_position = spawn_position
	
	# 禁用传送效果，让敌人立即可以被锁定
	enemy._is_teleporting = false
	enemy.invincible = false
	
	print("敌人生成配置：")
	print("  位置：", spawn_position)
	print("  _is_teleporting：", enemy._is_teleporting)
	print("  invincible：", enemy.invincible)
	print("  can_be_targeted：", enemy.can_be_targeted())
	print("  HurtboxArea collision_layer：", enemy.get_node("HurtboxArea").collision_layer)
	print("  HurtboxArea collision_mask：", enemy.get_node("HurtboxArea").collision_mask)
	
	# 添加到场景
	get_tree().current_scene.add_child(enemy)
	
	# 等待一帧，确保_ready()函数已经执行完毕
	await get_tree().process_frame
	
	# 再次禁用传送效果，因为_ready()会重新启动传送
	enemy._is_teleporting = false
	enemy.invincible = false
	if enemy.shape_drawer and enemy.shape_drawer.material:
		enemy.shape_drawer.material = null
	print("敌人生成后配置（在_ready()之后）：")
	print("  _is_teleporting：", enemy._is_teleporting)
	print("  invincible：", enemy.invincible)
	print("  can_be_targeted：", enemy.can_be_targeted())
	print("  shape_drawer.material：", enemy.shape_drawer.material)
	
	print("敌人生成成功")
