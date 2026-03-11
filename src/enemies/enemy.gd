class_name Enemy
extends Damageable

@onready var shape_drawer: ShapeDrawer = $ShapeDrawer

@export var move_speed: float = 100.0
@export var attack_damage: float = 10.0
@export var enemy_size: Vector2 = Vector2(Constants.grid_size, Constants.grid_size)

# 随机旋转功能
@export var random_initial_rotation: bool = false
"""
是否在敌人初始生成时对绘制的图形应用随机旋转效果
- true: 启用随机旋转，范围为0-360度
- false: 保持原始旋转角度不变
"""

var direction: Vector2
var base_position: Vector2 = Vector2.ZERO

# 屏障相关
var _blocked_by_barrier: bool = false
var _barrier_hit_cooldown: float = 0.0
var _current_barrier: Node2D = null
var _attack_interval: float = 1.0  # 攻击间隔（秒）
var _attack_timer: float = 0.0

# 避障相关
var _is_avoiding: bool = false  # 是否正在绕行
var _avoid_attempts: int = 0  # 绕行尝试次数
var _crystal_position: Vector2 = Vector2.ZERO  # 缓存的Crystal位置
@export var check_distance: float = 256.0  # 检测距离
@export var max_avoid_attempts: int = 3  # 最大绕行尝试次数

# 优先级管理
var _attack_priority: bool = false  # 是否处于攻击优先状态
var _priority_target: Node2D = null  # 优先级目标
var _last_path_update: float = 0.0  # 上次路径更新时间
var _path_update_interval: float = 1.0  # 路径更新间隔（秒）

# 路径可视化控制
@export var show_path_visualization: bool = false
"""
是否显示敌人路径预览
- true: 显示红色线条表示敌人规划的路径
- false: 不显示路径预览
"""

# A*寻路相关
var _current_path: Array[Vector2] = []  # 当前路径
var _path_index: int = 0  # 当前路径索引
var _grid_size: float = 64.0  # 网格大小
var _search_range: int = 20  # 搜索范围（网格数）
var _path_finding_enabled: bool = true  # 是否启用寻路
var _path_visualization: Line2D = null  # 路径可视化

func _initialize_shape() -> void:
	shape_drawer.shape_size = enemy_size

func set_base_position(dest_position: Vector2) -> void:
	base_position = dest_position

func _ready() -> void:
	super._ready()
	_initialize_shape()
	
	# 添加到enemy组，让结构管理器能够找到
	add_to_group("enemy")
	
	# 应用随机旋转效果（如果启用）
	if random_initial_rotation and shape_drawer:
		var random_angle = randf_range(0.0, 360.0)
		shape_drawer.rotation_degrees = random_angle
		print("敌人随机旋转角度: ", random_angle, " 度")
	
	# 初始化Crystal位置
	_crystal_position = _get_crystal_position()
	
	# 创建路径可视化Line2D
	_path_visualization = Line2D.new()
	_path_visualization.name = "PathVisualization"
	_path_visualization.width = 2.0
	_path_visualization.default_color = Color(1, 0, 0)
	_path_visualization.antialiased = true
	add_child(_path_visualization)
	
	died.connect(_on_damageable_died)

func _on_damageable_died(source: Node) -> void:
	# 断开屏障的死亡信号连接
	if _current_barrier and _current_barrier.has_signal("died"):
		if _current_barrier.died.is_connected(_on_barrier_destroyed):
			_current_barrier.died.disconnect(_on_barrier_destroyed)
	
	queue_free()

func _process(delta: float) -> void:
	# 更新屏障冷却计时器
	if _barrier_hit_cooldown > 0:
		_barrier_hit_cooldown -= delta
	
	# 检查当前屏障是否仍然有效
	_check_barrier_validity()
	
	# 更新路径规划
	_update_path_planning(delta)
	
	# 攻击优先处理
	_handle_attack_priority()
	
	# 如果有当前屏障，持续攻击
	if _current_barrier:
		_attack_timer += delta
		if _attack_timer >= _attack_interval:
			_attack_timer = 0.0
			_attack_barrier(_current_barrier)
	
	_update_movement(delta)

func _check_barrier_validity() -> void:
	"""检查屏障是否仍然有效"""
	if _current_barrier:
		# 检查屏障是否在场景树中
		if not _current_barrier.is_inside_tree():
			# 屏障已被删除，恢复移动
			print("屏障已被删除，恢复移动")
			_current_barrier = null
			_blocked_by_barrier = false
			# 攻击完成后重新规划路径
			_attack_priority = false
			_priority_target = null
			_update_crystal_position()
			# 立即重新规划路径
			_update_path()
			_last_path_update = 0.0
			return
		
		# 检查屏障是否有生命值且生命值大于0
		if _current_barrier.has_method("get_health"):
			if _current_barrier.get_health() <= 0:
				# 屏障已被摧毁，恢复移动
				print("屏障生命值为0，恢复移动")
				_current_barrier = null
				_blocked_by_barrier = false
				# 攻击完成后重新规划路径
				_attack_priority = false
				_priority_target = null
				_update_crystal_position()
				# 立即重新规划路径
				_update_path()
				_last_path_update = 0.0

func _update_movement(delta: float) -> void:
	# 如果有攻击优先级，继续攻击逻辑
	if _attack_priority:
		return
	
	# 如果没有攻击优先级，使用A*寻路
	if _current_path.size() > 0:
		# 跟随路径移动
		var following = _follow_path(delta)
		if not following:
			# 路径完成，重新规划
			_update_path()
	else:
		# 没有路径，尝试直接移动到Crystal
		if _crystal_position != Vector2(114514, 1919810):
			direction = (_crystal_position - global_position).normalized()
			_avoid_conduits(direction)
			if not _blocked_by_barrier and not _is_avoiding:
				global_position += direction * move_speed * delta

func _avoid_conduits(direction: Vector2) -> void:
	# 如果正在攻击屏障，尝试寻找绕行路径
	if _current_barrier and not _is_avoiding:
		_try_avoid_barrier()
	
	# 如果正在绕行，持续检查路径并移动
	if _is_avoiding:
		_continue_avoidance(direction)

func _try_avoid_barrier() -> void:
	"""尝试寻找绕过屏障的路径"""
	# 检查是否达到最大尝试次数
	if _avoid_attempts >= max_avoid_attempts:
		print("达到最大绕行尝试次数，开始攻击屏障")
		_avoid_attempts = 0
		_is_avoiding = false
		return
	
	# 获取Crystal位置
	_crystal_position = _get_crystal_position()
	if _crystal_position == Vector2(114514,1919810):
		print("未找到Crystal，无法进行避障")
		return
	
	# 生成可能的绕行方向
	var avoid_directions = _get_avoid_directions(direction)
	var best_direction = null
	var best_distance = 1000000  # 一个很大的数字，代表无穷远
	
	# 检测每个方向的路径
	for avoid_dir in avoid_directions:
		var test_pos = global_position + avoid_dir * check_distance
		
		# 检查路径是否清除
		if _is_path_clear(test_pos):
			# 计算到Crystal的距离
			var dist = test_pos.distance_to(_crystal_position)
			if dist < best_distance:
				best_distance = dist
				best_direction = avoid_dir
	
	if best_direction:
		# 找到有效路径，开始绕行
		print("找到绕行路径，方向: ", best_direction)
		_is_avoiding = true
		_avoid_attempts = 0
		# 绕行时不攻击屏障
		_current_barrier = null
		_blocked_by_barrier = false
	else:
		# 没有找到路径，增加尝试次数
		print("未找到绕行路径，尝试次数: ", _avoid_attempts + 1)
		_avoid_attempts += 1

func _continue_avoidance(original_direction: Vector2) -> void:
	"""继续绕行移动"""
	# 持续追踪Crystal方向
	var crystal_dir = (_crystal_position - global_position).normalized()
	
	# 检查直接路径是否清除
	if _is_path_clear(global_position + crystal_dir * check_distance):
		# 直接路径清除，结束绕行
		print("直接路径清除，结束绕行")
		_is_avoiding = false
		_avoid_attempts = 0
		return
	
	# 生成可能的绕行方向
	var avoid_directions = _get_avoid_directions(crystal_dir)
	var best_direction = null
	var best_distance = 1000000
	
	# 检测每个方向的路径
	for avoid_dir in avoid_directions:
		var test_pos = global_position + avoid_dir * check_distance
		
		# 检查路径是否清除
		if _is_path_clear(test_pos):
			# 计算到Crystal的距离
			var dist = test_pos.distance_to(_crystal_position)
			if dist < best_distance:
				best_distance = dist
				best_direction = avoid_dir
	
	if best_direction:
		# 向最佳绕行方向移动
		global_position += best_direction * move_speed * 0.8
	else:
		# 没有找到路径，尝试向Crystal方向移动
		global_position += crystal_dir * move_speed * 0.5

func _get_crystal_position() -> Vector2:
	"""获取Crystal的位置"""
	var crystals = get_tree().get_nodes_in_group("crystal")
	if crystals.size() > 0:
		return crystals[0].global_position
	return Vector2(114514,1919810)

func _get_avoid_directions(current_dir: Vector2) -> Array[Vector2]:
	"""生成可能的绕行方向"""
	var directions : Array[Vector2] = []
	
	# 垂直方向（左转和右转）
	var left_dir = Vector2(-current_dir.y, current_dir.x)
	var right_dir = Vector2(current_dir.y, -current_dir.x)
	directions.append(left_dir)
	directions.append(right_dir)
	
	# 对角线方向
	var diag_left = (current_dir + left_dir).normalized()
	var diag_right = (current_dir + right_dir).normalized()
	directions.append(diag_left)
	directions.append(diag_right)
	
	# 反向对角线
	var diag_left_back = (current_dir - left_dir).normalized()
	var diag_right_back = (current_dir - right_dir).normalized()
	directions.append(diag_left_back)
	directions.append(diag_right_back)
	
	return directions

func _is_path_clear(target_pos: Vector2) -> bool:
	"""检测路径是否清除"""
	var space_state = get_world_2d().direct_space_state
	
	# 创建射线查询参数
	var query = PhysicsRayQueryParameters2D.new()
	query.from = global_position
	query.to = target_pos
	query.exclude = [self]
	query.collision_mask = Constants.STRUCTURE_LAYER
	
	# 从当前位置到目标位置发射射线
	var result = space_state.intersect_ray(query)
	
	# 如果没有碰撞，路径是清除的
	return result.is_empty()

func _on_hitbox_area_entered(area: Area2D) -> void:
	# 获取Area2D的父节点（实际的Structure对象）
	var body = area.get_parent()
	if body and body.has_method("get_structure_type"):
		if body.get_structure_type() == Enums.StructureType.CRYSTAL:
			body.take_damage(attack_damage, self)
			take_damage(max_health, self) # 自毁

func on_barrier_hit(barrier: Node2D) -> void:
	"""被屏障阻挡时的回调"""
	if _barrier_hit_cooldown > 0:
		return
	
	print("敌人被屏障阻挡")
	_blocked_by_barrier = true
	_current_barrier = barrier
	_barrier_hit_cooldown = 0.5  # 冷却时间0.5秒
	_attack_timer = 0.0  # 重置攻击计时器
	
	# 连接屏障的死亡信号
	if barrier.has_signal("died") and not barrier.died.is_connected(_on_barrier_destroyed):
		barrier.died.connect(_on_barrier_destroyed)
	
	# 立即进行第一次攻击
	_attack_barrier(barrier)

func _on_barrier_destroyed(source: Node) -> void:
	"""屏障被摧毁时的回调"""
	print("屏障被摧毁信号触发")
	_current_barrier = null
	_blocked_by_barrier = false
	_attack_priority = false
	_priority_target = null
	_update_crystal_position()
	_update_path()
	_last_path_update = 0.0

func _attack_barrier(barrier: Node2D) -> void:
	"""攻击屏障"""
	if barrier and barrier.has_method("take_damage"):
		barrier.take_damage(attack_damage, self)
		print("敌人攻击屏障，造成伤害: ", attack_damage)

func _update_path_planning(delta: float) -> void:
	"""更新路径规划"""
	_last_path_update += delta
	if _last_path_update >= _path_update_interval:
		_last_path_update = 0.0
		# 定期更新Crystal位置
		_update_crystal_position()
		# 更新路径（如果不在攻击优先级状态）
		if not _attack_priority:
			_update_path()

func _handle_attack_priority() -> void:
	"""处理攻击优先级"""
	# 如果正在攻击屏障，设置攻击优先级
	if _current_barrier and not _attack_priority:
		print("设置攻击优先级，目标: ", _current_barrier.name)
		_attack_priority = true
		_priority_target = _current_barrier
	# 如果屏障已经消失，解除攻击优先级
	if _attack_priority and not _current_barrier:
		print("屏障已消失，解除攻击优先级")
		_attack_priority = false
		_priority_target = null

func _update_crystal_position() -> void:
	"""更新Crystal位置"""
	_crystal_position = _get_crystal_position()
	if _crystal_position != Vector2(114514, 1919810):
		print("更新Crystal位置: ", _crystal_position)

# A*寻路相关方法
class PathNode:
	var position: Vector2
	var parent: PathNode
	var g: float  # 从起点到当前节点的代价
	var h: float  # 从当前节点到目标的估计代价
	var f: float  # 总代价 f = g + h

	func _init(pos: Vector2, p: PathNode = null, g_cost: float = 0.0, h_cost: float = 0.0):
		position = pos
		parent = p
		g = g_cost
		h = h_cost
		f = g + h

func _calculate_heuristic(pos1: Vector2, pos2: Vector2) -> float:
	"""计算启发式代价（曼哈顿距离）"""
	return abs(pos1.x - pos2.x) + abs(pos1.y - pos2.y)

func _is_walkable(pos: Vector2) -> bool:
	"""检查位置是否可通行"""
	# 检查是否在搜索范围内
	if _crystal_position != Vector2(114514, 1919810):
		var distance = pos.distance_to(_crystal_position)
		if distance > _search_range * _grid_size:
			return false
	
	# 检查是否有障碍物（使用点碰撞检测）
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collision_mask = Constants.STRUCTURE_LAYER
	query.exclude = [self]
	var result = space_state.intersect_point(query)
	return result.is_empty()

func _get_neighbors(pos: Vector2) -> Array[Vector2]:
	"""获取相邻位置"""
	var neighbors : Array[Vector2] = []
	var directions = [
		Vector2(_grid_size, 0),       # 右
		Vector2(-_grid_size, 0),      # 左
		Vector2(0, _grid_size),       # 下
		Vector2(0, -_grid_size),      # 上
		Vector2(_grid_size, _grid_size),    # 右下
		Vector2(-_grid_size, _grid_size),   # 左下
		Vector2(_grid_size, -_grid_size),   # 右上
		Vector2(-_grid_size, -_grid_size)   # 左上
	]
	
	for dir in directions:
		var neighbor_pos = pos + dir
		if _is_walkable(neighbor_pos):
			neighbors.append(neighbor_pos)
	
	return neighbors

func _find_path(start: Vector2, goal: Vector2) -> Array[Vector2]:
	"""A*寻路算法"""
	if start == goal:
		return [start]
	
	if goal == Vector2(114514, 1919810):
		return []
	
	# 初始化开放列表和关闭列表
	var open_list = []
	var closed_list = []
	
	# 添加起点到开放列表
	var start_node = PathNode.new(start, null, 0.0, _calculate_heuristic(start, goal))
	open_list.append(start_node)
	
	# 主循环
	while open_list.size() > 0:
		# 找到F值最小的节点
		var current_node = open_list[0]
		var current_index = 0
		for i in range(1, open_list.size()):
			if open_list[i].f < current_node.f:
				current_node = open_list[i]
				current_index = i
		
		# 从开放列表中移除当前节点
		open_list.remove_at(current_index)
		# 添加到关闭列表
		closed_list.append(current_node)
		
		# 检查是否到达目标
		if current_node.position.distance_to(goal) < _grid_size:
			# 回溯构建路径
			var path :Array[Vector2]= []
			var current = current_node
			while current != null:
				path.append(current.position)
				current = current.parent
			path.reverse()
			return path
		
		# 获取相邻节点
		var neighbors = _get_neighbors(current_node.position)
		for neighbor_pos in neighbors:
			# 检查是否在关闭列表中
			var in_closed = false
			for closed_node in closed_list:
				if closed_node.position == neighbor_pos:
					in_closed = true
					break
			if in_closed:
				continue
			
			# 计算代价
			var g_cost = current_node.g + neighbor_pos.distance_to(current_node.position)
			var h_cost = _calculate_heuristic(neighbor_pos, goal)
			var neighbor_node = PathNode.new(neighbor_pos, current_node, g_cost, h_cost)
			
			# 检查是否在开放列表中
			var in_open = false
			var existing_index = -1
			for i in range(open_list.size()):
				if open_list[i].position == neighbor_pos:
					in_open = true
					existing_index = i
					break
			
			if not in_open:
				open_list.append(neighbor_node)
			else:
				# 如果有更优路径，更新节点
				if g_cost < open_list[existing_index].g:
					open_list[existing_index].g = g_cost
					open_list[existing_index].f = g_cost + open_list[existing_index].h
					open_list[existing_index].parent = current_node
	
	# 没有找到路径
	return []

func _update_path() -> void:
	"""更新路径"""
	if not _path_finding_enabled:
		return
	
	var start = global_position
	var goal = _crystal_position
	
	if goal == Vector2(114514, 1919810):
		return
	
	_current_path = _find_path(start, goal)
	_path_index = 0
	
	# 更新路径可视化
	_update_path_visualization()
	
	if _current_path.size() == 0:
		print("未找到路径")

func _update_path_visualization() -> void:
	"""更新路径可视化"""
	if not _path_visualization:
		return
	
	_path_visualization.clear_points()
	
	if show_path_visualization and _current_path.size() > 0:
		for pos in _current_path:
			# 将全局坐标转换为本地坐标
			_path_visualization.add_point(to_local(pos))
		_path_visualization.visible = true
	else:
		_path_visualization.visible = false

func _follow_path(delta: float) -> bool:
	"""跟随路径移动"""
	if _current_path.size() == 0 or _path_index >= _current_path.size():
		return false
	
	var target_pos = _current_path[_path_index]
	var move_dir = (target_pos - global_position).normalized()
	
	# 向目标移动
	global_position += move_dir * move_speed * delta
	
	# 检查是否到达当前目标
	if global_position.distance_to(target_pos) < 10:
		_path_index += 1
		# 如果到达路径终点，返回false
		if _path_index >= _current_path.size():
			return false
	
	return true
