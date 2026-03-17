# 资源管理模块使用指南

## 概述

资源管理模块（ResourceManager）提供了完整的关卡制游戏出怪逻辑支持，包括：
- 关卡配置管理
- 波次参数设计
- 资源加载和缓存
- 动态配置修改

## 核心类

### 1. LevelData（关卡数据）
定义单个关卡的所有配置信息。

**主要属性：**
- `level_id`: 关卡唯一标识符
- `level_name`: 关卡名称
- `level_description`: 关卡描述
- `waves`: 关卡包含的所有波次（Array[WaveData]）
- `difficulty`: 关卡难度等级（1-10）
- `recommended_level`: 推荐玩家等级
- `boss_wave_index`: Boss 波次索引（-1 表示无 Boss）

**主要方法：**
```gdscript
# 获取指定波次的数据
var wave_data = level_data.get_wave(0)

# 获取波次总数
var count = level_data.get_wave_count()

# 检查是否包含 Boss 波次
if level_data.has_boss_wave():
    var boss_wave = level_data.get_boss_wave()
```

### 2. WaveData（波次数据）
定义单个波次的所有配置信息。

**主要属性：**
- `wave_index`: 波次索引
- `wave_name`: 波次名称
- `is_boss_wave`: 是否是 Boss 波次
- `enemy_configs`: 敌人生成配置列表（Array[EnemySpawnConfig]）

**波次间隔参数：**
- `preparation_time`: 波次准备时间（秒）
- `spawn_interval`: 敌人生成间隔（秒）
- `wave_interval`: 波次间隔时间（秒）

**波次触发条件：**
- `require_clear_previous`: 是否需要清除上一波所有敌人
- `min_enemies_alive`: 最小存活敌人数（低于此值才触发下一波）

**刷怪区域参数：**
- `spawn_center`: 刷怪中心点（默认为水晶位置）
- `min_spawn_radius`: 最小生成半径
- `max_spawn_radius`: 最大生成半径

**波次特殊属性：**
- `difficulty_multiplier`: 难度倍数（影响敌人属性）
- `speed_multiplier`: 速度倍数
- `health_multiplier`: 血量倍数

**主要方法：**
```gdscript
# 计算该波次的总敌人数量
var total_count = wave_data.get_total_enemy_count()

# 获取指定类型的敌人生成配置
var config = wave_data.get_enemy_config("rect_enemy")

# 添加敌人生成配置
wave_data.add_enemy_config(enemy_config)
```

### 3. EnemySpawnConfig（敌人生成配置）
定义单个波次中某种敌人的生成参数。

**主要属性：**
- `enemy_type`: 敌人类型标识符（如 "rect_enemy", "circle_enemy"）
- `enemy_scene_path`: 敌人场景文件路径

**敌人数量配置：**
- `count`: 敌人数量（精确值）
- `count_min`: 最小敌人数量（随机范围）
- `count_max`: 最大敌人数量（随机范围）
- `use_random_count`: 是否使用随机数量

**敌人体型配置：**
- `size_level`: 敌人体型等级（1-20）
- `size_level_min`: 最小体型等级
- `size_level_max`: 最大体型等级
- `use_random_size`: 是否使用随机体型

**敌人属性调整：**
- `health_multiplier`: 血量倍数
- `speed_multiplier`: 速度倍数
- `damage_multiplier`: 伤害倍数

**生成优先级和权重：**
- `spawn_priority`: 生成优先级（数值越大越优先）
- `spawn_weight`: 生成权重（影响随机选择概率）

**特殊标记：**
- `is_elite`: 是否是精英敌人
- `is_boss`: 是否是 Boss

**主要方法：**
```gdscript
# 计算实际生成的敌人数量
var count = config.get_actual_count()

# 计算实际的体型等级
var size_level = config.get_actual_size_level()

# 加载敌人场景
var scene = config.load_enemy_scene()

# 验证配置有效性
if config.is_valid():
    print("配置有效")
```

### 4. ResourceManager（资源管理器）
负责加载、缓存和管理关卡及波次配置资源。

**主要功能：**
- 从 JSON 配置文件加载关卡数据
- 资源缓存机制（关卡数据、敌人场景）
- 动态修改和保存关卡配置
- 信号通知加载状态

**主要方法：**
```gdscript
# 加载关卡数据
var level_data = ResourceManager.instance.load_level("level_1")

# 强制重新加载（忽略缓存）
var level_data = ResourceManager.instance.load_level("level_1", true)

# 加载敌人场景
var enemy_scene = ResourceManager.instance.load_enemy_scene("res://src/enemies/rect_enemy.tscn")

# 清除关卡缓存
ResourceManager.instance.clear_level_cache("level_1")
ResourceManager.instance.clear_level_cache()  # 清除所有

# 清除敌人场景缓存
ResourceManager.instance.clear_enemy_scene_cache("res://src/enemies/rect_enemy.tscn")
ResourceManager.instance.clear_enemy_scene_cache()  # 清除所有

# 保存关卡配置到文件
var success = ResourceManager.instance.save_level_config(level_data)

# 获取已缓存的关卡列表
var cached_levels = ResourceManager.instance.get_cached_levels()
```

**信号：**
- `level_loaded(level_id: String)`: 关卡加载成功
- `level_load_failed(level_id: String, error: String)`: 关卡加载失败
- `cache_cleared()`: 缓存已清除

## 使用示例

### 示例 1：加载并开始关卡

```gdscript
# 在 EnemyManager 或 GameManager 中
func start_level(level_id: String) -> void:
    # 加载关卡数据
    if wave_system.load_level(level_id):
        print("关卡加载成功")
        # 开始第一波
        wave_system.advance_to_next_wave()
    else:
        print("关卡加载失败")
```

### 示例 2：动态创建关卡

```gdscript
# 创建新关卡数据
var level_data = LevelData.new()
level_data.level_id = "custom_level"
level_data.level_name = "自定义关卡"
level_data.difficulty = 3
level_data.boss_wave_index = 5

# 创建波次数据
var wave_data = WaveData.new()
wave_data.wave_index = 0
wave_data.wave_name = "第一波"
wave_data.preparation_time = 3.0
wave_data.spawn_interval = 0.8

# 创建敌人生成配置
var enemy_config = EnemySpawnConfig.new()
enemy_config.enemy_type = "rect_enemy"
enemy_config.enemy_scene_path = "res://src/enemies/rect_enemy.tscn"
enemy_config.count = 5
enemy_config.size_level = 1

# 添加到波次
wave_data.add_enemy_config(enemy_config)

# 添加波次到关卡
level_data.waves.append(wave_data)

# 保存关卡配置
ResourceManager.instance.save_level_config(level_data)
```

### 示例 3：在 EnemyManager 中使用关卡数据

```gdscript
# 修改 _spawn_wave_enemy 函数以支持关卡数据
func _spawn_wave_enemy() -> void:
    if not wave_system:
        return
    
    var wave_info = wave_system.get_current_wave_info()
    if wave_info.is_empty():
        return
    
    # 检查是否已经生成了足够的敌人
    if wave_info.spawned_count >= wave_info.total_count:
        return
    
    # 获取波次数据
    var wave_data = wave_system.get_wave_data(wave_info.wave_number)
    if wave_data:
        # 使用关卡数据中的敌人生成配置
        for enemy_config in wave_data.enemy_configs:
            var count = enemy_config.get_actual_count()
            for i in range(count):
                _spawn_enemy_from_config(enemy_config)
    else:
        # 使用默认配置
        _spawn_normal_enemy(wave_info.size)
```

### 示例 4：监听关卡加载事件

```gdscript
# 在 GameManager 或其他管理器中
func _ready() -> void:
    if ResourceManager.instance:
        ResourceManager.instance.level_loaded.connect(_on_level_loaded)
        ResourceManager.instance.level_load_failed.connect(_on_level_load_failed)

func _on_level_loaded(level_id: String) -> void:
    print("关卡加载成功: ", level_id)

func _on_level_load_failed(level_id: String, error: String) -> void:
    print("关卡加载失败: ", level_id, " 错误: ", error)
```

## 配置文件格式

关卡配置文件使用 JSON 格式，存放在 `res://config/levels/` 目录下。

**文件命名规则：**
- `level_1.json`
- `level_2.json`
- ...

**配置文件结构：**
```json
{
    "level_id": "level_1",
    "level_name": "第一章：初次入侵",
    "level_description": "敌人开始入侵，建立防线抵御第一波攻击",
    "difficulty": 1,
    "recommended_level": 1,
    "boss_wave_index": 10,
    "waves": [
        {
            "wave_index": 0,
            "wave_name": "第一波：小规模入侵",
            "is_boss_wave": false,
            "preparation_time": 3.0,
            "spawn_interval": 1.0,
            "wave_interval": 2.0,
            "require_clear_previous": false,
            "min_enemies_alive": 0,
            "spawn_center": [0, 0],
            "min_spawn_radius": 400.0,
            "max_spawn_radius": 800.0,
            "difficulty_multiplier": 1.0,
            "speed_multiplier": 1.0,
            "health_multiplier": 1.0,
            "enemies": [
                {
                    "enemy_type": "rect_enemy",
                    "enemy_scene_path": "res://src/enemies/rect_enemy.tscn",
                    "count": 3,
                    "use_random_count": false,
                    "size_level": 1,
                    "use_random_size": false,
                    "health_multiplier": 1.0,
                    "speed_multiplier": 1.0,
                    "damage_multiplier": 1.0,
                    "spawn_priority": 0,
                    "spawn_weight": 1.0,
                    "is_elite": false,
                    "is_boss": false
                }
            ]
        }
    ]
}
```

## 设计优化建议

### 1. 性能优化
- **资源缓存**：ResourceManager 自动缓存关卡数据和敌人场景，避免重复加载
- **按需加载**：只在需要时加载关卡，预加载默认关卡
- **缓存清理**：提供手动清理缓存接口，释放内存

### 2. 扩展性设计
- **灵活的配置结构**：支持添加新的敌人类型和属性
- **预留接口**：WaveData 和 EnemySpawnConfig 提供扩展方法
- **向后兼容**：WaveSystem 保留默认配置，支持无关卡文件的运行

### 3. 可维护性
- **清晰的类结构**：每个类职责单一，易于理解和修改
- **完整的注释**：所有属性和方法都有详细说明
- **错误处理**：提供详细的错误信息和警告

### 4. 使用建议
- **关卡设计**：从简单到复杂，逐步增加难度
- **波次平衡**：合理设置敌人数、体型和间隔
- **Boss 设计**：Boss 波次作为关卡高潮，提供挑战性
- **测试验证**：使用 `is_valid()` 方法验证配置有效性

## 常见问题

### Q1: 如何添加新的敌人类型？
A: 在关卡配置文件的 `enemies` 数组中添加新的敌人配置，设置 `enemy_type` 和 `enemy_scene_path`。

### Q2: 如何调整波次难度？
A: 修改 `difficulty_multiplier`、`speed_multiplier`、`health_multiplier` 参数，或调整敌人数和体型等级。

### Q3: 如何创建多关卡？
A: 创建多个 JSON 配置文件（如 `level_1.json`、`level_2.json`），使用不同的 `level_id`。

### Q4: 如何调试关卡配置？
A: 使用 `ResourceManager.instance.load_level()` 加载关卡，检查返回的 LevelData 对象，监听 `level_load_failed` 信号。

### Q5: 缓存如何工作？
A: 首次加载时缓存数据，后续访问直接从缓存读取。使用 `clear_level_cache()` 清除缓存。

## 总结

资源管理模块提供了完整的关卡制游戏支持，包括：
- ✅ 关卡配置管理（多关卡、独立标识符）
- ✅ 波次参数设计（数量、间隔、触发条件、敌人组合）
- ✅ 资源管理功能（加载、缓存、动态修改）
- ✅ 扩展性设计（预留接口、灵活配置）

通过合理使用这个模块，可以轻松创建多样化的关卡和波次配置！