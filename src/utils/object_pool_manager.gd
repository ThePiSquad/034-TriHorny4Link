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
}

func _ready() -> void:
	if instance == null:
		instance = self
	else:
		queue_free()
		return
	
	# 初始化所有对象池
	_initialize_all_pools()

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
	"""获取所有池的统计信息"""
	var stats = {}
	for scene_path in _pools:
		var pool: ObjectPool = _pools[scene_path]
		stats[scene_path] = {
			"active": pool.get_active_count(),
			"pooled": pool.get_pool_count()
		}
	return stats

func clear_all_pools() -> void:
	"""清理所有对象池"""
	for pool in _pools.values():
		pool.clear_pool()
	_pools.clear()
