extends Node
class_name ObjectPoolManager

## 全局对象池管理器
## 管理各种游戏对象的对象池

static var instance: ObjectPoolManager = null

# 对象池字典 {scene_path: ObjectPool}
var _pools: Dictionary = {}
# 默认池大小配置
var _default_pool_sizes: Dictionary = {
	"res://src/bullets/bullet.tscn": 100,
	"res://src/bullets/homing_bullet.tscn": 50,
	"res://src/bullets/magic_bullet.tscn": 30,
	"res://src/bullets/lightning_bullet.tscn": 50,
	"res://src/bullets/explosive_bullet.tscn": 50,
	"res://src/bullets/splitting_homing_bullet.tscn": 30,
	"res://src/bullets/penetrating_bullet.tscn": 50,
	"res://src/bullets/bouncing_lightning_bullet.tscn": 30,
	"res://src/bullets/charging_laser_bullet.tscn": 20,
	"res://src/bullets/cluster_bomb_bullet.tscn": 30,
	"res://src/bullets/continuous_explosive_bullet.tscn": 30,
	"res://src/bullets/splitting_bullet.tscn": 50,
	"res://src/particles/hit_ptc.tscn": 100,
	"res://src/particles/broken_ptc.tscn": 50,
	"res://src/bullets/explosive_purple_particle.tscn": 50,
	"res://src/bullets/explosive_purple_red_particle.tscn": 50,
	"res://src/bullets/explosive_purple_blue_particle.tscn": 50,
}

# 定期清理配置
var _cleanup_timer: float = 0.0
var _cleanup_interval: float = 2.0  # 每 2 秒清理一次无效对象

func _ready() -> void:
	if instance == null:
		instance = self
	else:
		queue_free()
		return
	
	# 初始化所有对象池
	_initialize_all_pools()

func _process(delta: float) -> void:
	"""定期清理无效对象"""
	_cleanup_timer += delta
	if _cleanup_timer >= _cleanup_interval:
		_cleanup_timer = 0.0
		_cleanup_all_pools()

func _cleanup_all_pools() -> void:
	"""清理所有池中的无效对象"""
	for pool in _pools.values():
		pool.cleanup_invalid_objects()

func _initialize_all_pools() -> void:
	"""初始化所有对象池"""
	for scene_path in _default_pool_sizes:
		var pool_size = _default_pool_sizes[scene_path]
		create_pool(scene_path, pool_size)

func create_pool(scene_path: String, pool_size: int = 20) -> void:
	"""创建对象池"""
	if _pools.has(scene_path):
		return
	
	var scene = load(scene_path)
	if scene:
		var pool = ObjectPool.new(scene, self, pool_size)
		_pools[scene_path] = pool

func get_object(scene_path: String) -> Node:
	"""从指定池获取对象"""
	if not _pools.has(scene_path):
		# 自动创建默认大小的池
		var default_size = _default_pool_sizes.get(scene_path, 20)
		create_pool(scene_path, default_size)
	
	var pool: ObjectPool = _pools[scene_path]
	return pool.get_object()

func return_object(scene_path: String, obj: Node) -> void:
	"""归还对象到指定池"""
	if not _pools.has(scene_path):
		obj.queue_free()
		return
	
	var pool: ObjectPool = _pools[scene_path]
	pool.return_object(obj)

func get_pool_stats() -> Dictionary:
	"""获取所有池的统计信息（优化版）"""
	var stats = {}
	for scene_path in _pools:
		var pool: ObjectPool = _pools[scene_path]
		# 使用公共方法获取统计信息
		stats[scene_path] = pool.get_stats()
	return stats

func clear_all_pools() -> void:
	"""清理所有对象池"""
	for pool in _pools.values():
		pool.clear_pool()
	_pools.clear()
	
	print("对象池已清理")

func enable_all_debug_logs(enable: bool) -> void:
	"""启用或禁用所有对象池的调试日志"""
	for pool in _pools.values():
		pool.enable_debug_log(enable)
