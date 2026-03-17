# 关卡波次系统修改操作指南

## 目录
1. [系统架构概述](#系统架构概述)
2. [创建新关卡](#创建新关卡)
3. [修改现有关卡](#修改现有关卡)
4. [波次配置详解](#波次配置详解)
5. [敌人配置详解](#敌人配置详解)
6. [高级配置技巧](#高级配置技巧)
7. [测试与调试](#测试与调试)
8. [常见问题](#常见问题)

---

## 系统架构概述

### 核心组件

```
关卡波次系统
├── 关卡配置文件 (JSON)
│   └── res://config/levels/level_*.json
├── 数据结构类
│   ├── LevelData (src/data/level_data.gd)
│   ├── WaveData (src/data/wave_data.gd)
│   └── EnemySpawnConfig (src/data/enemy_spawn_config.gd)
├── 资源管理器
│   └── ResourceManager (src/managers/resource_manager.gd)
└── 波次系统
    └── WaveSystem (src/systems/wave_system.gd)
```

### 配置模式

系统支持两种配置模式：

#### 1. 默认配置模式
- **位置**: [`wave_system.gd`](file:///d:/WorkProject/034GameJam/034-game-jam/src/systems/wave_system.gd#L25-L41)
- **特点**: 内置配置，无需额外文件
- **适用**: 快速原型开发、测试

#### 2. 关卡配置模式（推荐）
- **位置**: `res://config/levels/level_*.json`
- **特点**: 灵活配置，支持多关卡
- **适用**: 正式游戏开发、关卡设计

---

## 创建新关卡

### 步骤 1: 创建关卡配置文件

**文件路径**: `res://config/levels/`

**命名规则**: `level_{编号}.json`（如 `level_2.json`）

**操作方法**:

1. 复制现有关卡文件作为模板：
   ```
   复制: res://config/levels/level_1.json
   到: res://config/levels/level_2.json
   ```

2. 编辑新文件，修改关卡基本信息：

```json
{
    "level_id": "level_2",
    "level_name": "第二章：新的挑战",
    "level_description": "更强大的敌人即将到来",
    "difficulty": 2,
    "recommended_level": 2,
    "boss_wave_index": 10,
    "waves": [...]
}
```

### 步骤 2: 配置关卡基本信息

**关键参数说明**:

| 参数 | 类型 | 说明 | 示例 |
|------|------|------|------|
| `level_id` | String | 关卡唯一标识符 | `"level_2"` |
| `level_name` | String | 关卡显示名称 | `"第二章：新的挑战"` |
| `level_description` | String | 关卡描述 | `"更强大的敌人即将到来"` |
| `difficulty` | int | 关卡难度等级（1-10） | `2` |
| `recommended_level` | int | 推荐玩家等级 | `2` |
| `boss_wave_index` | int | Boss 波次索引（-1表示无Boss） | `10` |

**代码位置**: [`level_data.gd`](file:///d:/WorkProject/034GameJam/034-game-jam/src/data/level_data.gd#L8-L15)

### 步骤 3: 配置波次

**波次数据结构**:

```json
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
    "enemies": [...]
}
```

**代码位置**: [`wave_data.gd`](file:///d:/WorkProject/034GameJam/034-game-jam/src/data/wave_data.gd#L8-L35)

### 步骤 4: 配置敌人

**敌人生成配置**:

```json
{
    "enemy_type": "rect_enemy",
    "enemy_scene_path": "res://src/enemies/rect_enemy.tscn",
    "count": 5,
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
```

**代码位置**: [`enemy_spawn_config.gd`](file:///d:/WorkProject/034GameJam/034-game-jam/src/data/enemy_spawn_config.gd#L8-L35)

### 步骤 5: 加载新关卡

**方法 1: 在代码中加载**

**文件**: [`world.gd`](file:///d:/WorkProject/034GameJam/034-game-jam/src/world.gd)

**位置**: `_initialize_game_manager()` 函数

```gdscript
func _initialize_game_manager() -> void:
    var game_manager = GameManager.instance
    if not game_manager:
        game_manager = GameManager.new()
        add_child(game_manager)
        game_manager.start_game()
        print("GameManager 初始化完成")
    
    # 加载关卡
    var enemy_manager = $WorldPainter/EnemyManager
    if enemy_manager:
        var wave_system = enemy_manager.get_wave_system()
        if wave_system:
            wave_system.load_level("level_2")  # 加载新关卡
    
    # 启动 EnemyManager 的波次系统
    if enemy_manager and enemy_manager.has_method("start_game"):
        enemy_manager.start_game()
```

**方法 2: 在场景编辑器中配置**

1. 打开 `world.tscn`
2. 选择 `WorldPainter/EnemyManager` 节点
3. 在 Inspector 中找到 `WaveSystem` 相关配置
4. 添加 `level_id` 属性（需要扩展）

---

## 修改现有关卡

### 步骤 1: 打开关卡配置文件

**文件路径**: `res://config/levels/level_*.json`

**操作**: 使用文本编辑器打开要修改的关卡文件

### 步骤 2: 修改波次数量

**方法 1: 添加新波次**

在 `waves` 数组中添加新的波次对象：

```json
{
    "waves": [
        {...},  // 现有波次
        {
            "wave_index": 11,
            "wave_name": "第十一波：额外挑战",
            "is_boss_wave": false,
            ...
        }
    ]
}
```

**重要**: 确保 `wave_index` 连续且从 0 开始

**方法 2: 删除波次**

从 `waves` 数组中删除不需要的波次对象

**方法 3: 调整波次顺序**

重新排列 `waves` 数组中的波次对象，并更新 `wave_index`

### 步骤 3: 修改 Boss 波次

**方法 1: 设置 Boss 波次索引**

修改 `boss_wave_index` 参数：

```json
{
    "boss_wave_index": 15  // Boss 在第 16 波（索引从 0 开始）
}
```

**方法 2: 配置 Boss 波次**

在指定索引处添加 Boss 波次：

```json
{
    "wave_index": 15,
    "wave_name": "Boss 战：最终决战",
    "is_boss_wave": true,
    "preparation_time": 5.0,
    "spawn_interval": 0.0,
    "wave_interval": 0.0,
    "require_clear_previous": true,
    "min_enemies_alive": 0,
    "spawn_center": [0, 0],
    "min_spawn_radius": 1000.0,
    "max_spawn_radius": 1500.0,
    "difficulty_multiplier": 1.0,
    "speed_multiplier": 1.0,
    "health_multiplier": 1.0,
    "enemies": [
        {
            "enemy_type": "circle_enemy",
            "enemy_scene_path": "res://src/enemies/circle_enemy.tscn",
            "count": 1,
            "size_level": 20,
            "health_multiplier": 10.0,
            "speed_multiplier": 1.0,
            "damage_multiplier": 2.0,
            "spawn_priority": 10,
            "spawn_weight": 1.0,
            "is_elite": false,
            "is_boss": true
        }
    ]
}
```

### 步骤 4: 保存并测试

1. 保存 JSON 文件
2. 重新加载关卡（或重启游戏）
3. 测试波次流程

---

## 波次配置详解

### 波次间隔参数

#### 1. 准备时间 (preparation_time)

**说明**: 波次开始前的准备时间

**单位**: 秒

**推荐值**:
- 普通波次: 2.0 - 4.0 秒
- Boss 波次: 5.0 - 8.0 秒

**示例**:
```json
{
    "preparation_time": 3.0  // 3 秒准备时间
}
```

#### 2. 生成间隔 (spawn_interval)

**说明**: 敌人生成之间的时间间隔

**单位**: 秒

**推荐值**:
- 敌人数量少（< 10）: 0.5 - 0.8 秒
- 敌人数量中等（10-20）: 0.6 - 1.0 秒
- 敌人数量多（> 20）: 0.8 - 1.5 秒

**示例**:
```json
{
    "spawn_interval": 0.8  // 每 0.8 秒生成一个敌人
}
```

#### 3. 波次间隔 (wave_interval)

**说明**: 当前波次完成后，到下一波开始的时间间隔

**单位**: 秒

**推荐值**: 2.0 - 5.0 秒

**示例**:
```json
{
    "wave_interval": 2.0  // 波次完成后等待 2 秒
}
```

**代码位置**: [`wave_data.gd`](file:///d:/WorkProject/034GameJam/034-game-jam/src/data/wave_data.gd#L16-L18)

### 波次触发条件

#### 1. 清除上一波 (require_clear_previous)

**说明**: 是否需要清除上一波所有敌人才能开始下一波

**类型**: boolean

**推荐值**:
- 普通波次: `false`（允许波次重叠）
- Boss 波次: `true`（确保 Boss 战前清理战场）

**示例**:
```json
{
    "require_clear_previous": false  // 不需要清除上一波
}
```

#### 2. 最小存活敌人数 (min_enemies_alive)

**说明**: 下一波开始时，场上允许的最小敌人数

**类型**: int

**推荐值**:
- 普通波次: `0`（无限制）
- 特殊波次: `3-5`（保留少量敌人增加难度）

**示例**:
```json
{
    "min_enemies_alive": 0  // 无限制
}
```

**代码位置**: [`wave_data.gd`](file:///d:/WorkProject/034GameJam/034-game-jam/src/data/wave_data.gd#L23-L24)

### 刷怪区域参数

#### 1. 刷怪中心点 (spawn_center)

**说明**: 敌人生成的中心位置

**类型**: Array[float] [x, y]

**推荐值**: `[0, 0]`（水晶位置）

**示例**:
```json
{
    "spawn_center": [0, 0]  // 以 (0, 0) 为中心生成敌人
}
```

#### 2. 最小生成半径 (min_spawn_radius)

**说明**: 敌人生成的最小距离

**单位**: 像素

**推荐值**:
- 早期波次: 300 - 500
- 中期波次: 500 - 700
- 后期波次: 700 - 900
- Boss 波次: 1000 - 1200

**示例**:
```json
{
    "min_spawn_radius": 400.0  // 最小生成距离 400 像素
}
```

#### 3. 最大生成半径 (max_spawn_radius)

**说明**: 敌人生成的最大距离

**单位**: 像素

**推荐值**:
- 早期波次: 600 - 800
- 中期波次: 800 - 1000
- 后期波次: 1000 - 1200
- Boss 波次: 1400 - 1600

**示例**:
```json
{
    "max_spawn_radius": 800.0  // 最大生成距离 800 像素
}
```

**代码位置**: [`wave_data.gd`](file:///d:/WorkProject/034GameJam/034-game-jam/src/data/wave_data.gd#L26-L28)

### 波次特殊属性

#### 1. 难度倍数 (difficulty_multiplier)

**说明**: 整体难度倍数，影响敌人属性

**类型**: float

**推荐值**:
- 简单: 0.8 - 1.0
- 普通: 1.0 - 1.2
- 困难: 1.2 - 1.5
- 极难: 1.5 - 2.0

**示例**:
```json
{
    "difficulty_multiplier": 1.2  // 难度提升 20%
}
```

#### 2. 速度倍数 (speed_multiplier)

**说明**: 敌人移动速度倍数

**类型**: float

**推荐值**:
- 慢速: 0.8 - 1.0
- 正常: 1.0 - 1.2
- 快速: 1.2 - 1.5

**示例**:
```json
{
    "speed_multiplier": 1.2  // 速度提升 20%
}
```

#### 3. 血量倍数 (health_multiplier)

**说明**: 敌人血量倍数

**类型**: float

**推荐值**:
- 脆弱: 0.8 - 1.0
- 正常: 1.0 - 1.5
- 坚韧: 1.5 - 2.0

**示例**:
```json
{
    "health_multiplier": 1.5  // 血量提升 50%
}
```

**代码位置**: [`wave_data.gd`](file:///d:/WorkProject/034GameJam/034-game-jam/src/data/wave_data.gd#L30-L32)

---

## 敌人配置详解

### 敌人类型配置

#### 1. 敌人类型标识符 (enemy_type)

**说明**: 敌人类型的唯一标识符

**类型**: String

**可用值**:
- `"rect_enemy"`: 方形敌人
- `"triangle_enemy"`: 三角形敌人
- `"circle_enemy"`: 圆形敌人（Boss）

**示例**:
```json
{
    "enemy_type": "rect_enemy"
}
```

#### 2. 敌人场景路径 (enemy_scene_path)

**说明**: 敌人场景文件的路径

**类型**: String

**可用路径**:
- `"res://src/enemies/rect_enemy.tscn"`
- `"res://src/enemies/triangle_enemy.tscn"`
- `"res://src/enemies/circle_enemy.tscn"`

**示例**:
```json
{
    "enemy_scene_path": "res://src/enemies/rect_enemy.tscn"
}
```

**代码位置**: [`enemy_spawn_config.gd`](file:///d:/WorkProject/034GameJam/034-game-jam/src/data/enemy_spawn_config.gd#L8-L9)

### 敌人数量配置

#### 1. 精确数量 (count)

**说明**: 敌人的精确生成数量

**类型**: int

**使用条件**: `use_random_count = false`

**示例**:
```json
{
    "count": 5,
    "use_random_count": false
}
```

#### 2. 随机数量范围 (count_min, count_max)

**说明**: 敌人生成数量的随机范围

**类型**: int

**使用条件**: `use_random_count = true`

**示例**:
```json
{
    "count_min": 3,
    "count_max": 7,
    "use_random_count": true
}
```

**代码位置**: [`enemy_spawn_config.gd`](file:///d:/WorkProject/034GameJam/034-game-jam/src/data/enemy_spawn_config.gd#L12-L15)

### 敌人体型配置

#### 1. 体型等级 (size_level)

**说明**: 敌人的体型等级（1-20）

**类型**: int

**体型对照表**:

| 体型等级 | 尺寸 | 说明 |
|---------|------|------|
| 1 | 32x32 | 最小 |
| 5 | 64x64 | 小型 |
| 10 | 128x128 | 中型 |
| 15 | 192x192 | 大型 |
| 20 | 256x256 | 最大（Boss） |

**示例**:
```json
{
    "size_level": 5,
    "use_random_size": false
}
```

#### 2. 随机体型范围 (size_level_min, size_level_max)

**说明**: 敌人体型的随机范围

**类型**: int

**使用条件**: `use_random_size = true`

**示例**:
```json
{
    "size_level_min": 3,
    "size_level_max": 7,
    "use_random_size": true
}
```

**代码位置**: [`enemy_spawn_config.gd`](file:///d:/WorkProject/034GameJam/034-game-jam/src/data/enemy_spawn_config.gd#L17-L20)

### 敌人属性调整

#### 1. 血量倍数 (health_multiplier)

**说明**: 敌人血量倍数

**类型**: float

**推荐值**:
- 普通敌人: 1.0
- 精英敌人: 1.5 - 2.0
- Boss: 10.0

**示例**:
```json
{
    "health_multiplier": 1.5
}
```

#### 2. 速度倍数 (speed_multiplier)

**说明**: 敌人移动速度倍数

**类型**: float

**推荐值**:
- 慢速敌人: 0.8
- 正常速度: 1.0
- 快速敌人: 1.2 - 1.5

**示例**:
```json
{
    "speed_multiplier": 1.2
}
```

#### 3. 伤害倍数 (damage_multiplier)

**说明**: 敌人伤害倍数

**类型**: float

**推荐值**:
- 普通敌人: 1.0
- 精英敌人: 1.2 - 1.5
- Boss: 2.0

**示例**:
```json
{
    "damage_multiplier": 1.5
}
```

**代码位置**: [`enemy_spawn_config.gd`](file:///d:/WorkProject/034GameJam/034-game-jam/src/data/enemy_spawn_config.gd#L22-L24)

### 生成优先级和权重

#### 1. 生成优先级 (spawn_priority)

**说明**: 敌人生成的优先级（数值越大越优先）

**类型**: int

**推荐值**:
- 普通敌人: 0
- 精英敌人: 5
- Boss: 10

**示例**:
```json
{
    "spawn_priority": 5
}
```

#### 2. 生成权重 (spawn_weight)

**说明**: 敌人生成的权重（影响随机选择概率）

**类型**: float

**推荐值**:
- 普通敌人: 1.0
- 稀有敌人: 0.5
- 超稀有敌人: 0.2

**示例**:
```json
{
    "spawn_weight": 0.5
}
```

**代码位置**: [`enemy_spawn_config.gd`](file:///d:/WorkProject/034GameJam/034-game-jam/src/data/enemy_spawn_config.gd#L26-L27)

### 特殊标记

#### 1. 精英标记 (is_elite)

**说明**: 是否是精英敌人

**类型**: boolean

**示例**:
```json
{
    "is_elite": true
}
```

#### 2. Boss 标记 (is_boss)

**说明**: 是否是 Boss

**类型**: boolean

**示例**:
```json
{
    "is_boss": true
}
```

**代码位置**: [`enemy_spawn_config.gd`](file:///d:/WorkProject/034GameJam/034-game-jam/src/data/enemy_spawn_config.gd#L29-L30)

---

## 高级配置技巧

### 技巧 1: 难度曲线设计

**目标**: 创建平滑的难度提升曲线

**方法**: 逐步增加敌人数量、体型和属性

**示例**:

```json
{
    "waves": [
        {
            "wave_index": 0,
            "wave_name": "第一波",
            "enemies": [
                {
                    "count": 3,
                    "size_level": 1
                }
            ]
        },
        {
            "wave_index": 1,
            "wave_name": "第二波",
            "enemies": [
                {
                    "count": 4,
                    "size_level": 2
                }
            ]
        },
        {
            "wave_index": 2,
            "wave_name": "第三波",
            "enemies": [
                {
                    "count": 5,
                    "size_level": 3,
                    "health_multiplier": 1.1
                }
            ]
        }
    ]
}
```

### 技巧 2: 敌人类型混合

**目标**: 创建多样化的敌人组合

**方法**: 在同一波次中配置多种敌人类型

**示例**:

```json
{
    "wave_index": 5,
    "wave_name": "混合编队",
    "enemies": [
        {
            "enemy_type": "rect_enemy",
            "count": 5,
            "size_level": 5,
            "spawn_priority": 0
        },
        {
            "enemy_type": "triangle_enemy",
            "count": 3,
            "size_level": 6,
            "spawn_priority": 1
        },
        {
            "enemy_type": "rect_enemy",
            "count": 2,
            "size_level": 7,
            "is_elite": true,
            "spawn_priority": 2
        }
    ]
}
```

### 技巧 3: 随机化配置

**目标**: 增加关卡的重玩性

**方法**: 使用随机数量和随机体型

**示例**:

```json
{
    "wave_index": 3,
    "wave_name": "随机挑战",
    "enemies": [
        {
            "count_min": 4,
            "count_max": 8,
            "use_random_count": true,
            "size_level_min": 3,
            "size_level_max": 6,
            "use_random_size": true
        }
    ]
}
```

### 技巧 4: 特殊波次设计

**目标**: 创建独特的波次体验

**方法 1: 精英波次**

```json
{
    "wave_index": 4,
    "wave_name": "精英小队",
    "preparation_time": 4.0,
    "enemies": [
        {
            "count": 3,
            "size_level": 5,
            "health_multiplier": 1.5,
            "damage_multiplier": 1.2,
            "is_elite": true
        }
    ]
}
```

**方法 2: 快速波次**

```json
{
    "wave_index": 6,
    "wave_name": "快速突袭",
    "spawn_interval": 0.5,
    "speed_multiplier": 1.3,
    "enemies": [
        {
            "count": 10,
            "size_level": 4,
            "speed_multiplier": 1.3
        }
    ]
}
```

**方法 3: 坦克波次**

```json
{
    "wave_index": 7,
    "wave_name": "坦克大军",
    "spawn_interval": 1.5,
    "health_multiplier": 2.0,
    "enemies": [
        {
            "count": 5,
            "size_level": 8,
            "health_multiplier": 2.0,
            "speed_multiplier": 0.8
        }
    ]
}
```

### 技巧 5: Boss 战设计

**目标**: 创建具有挑战性的 Boss 战

**方法**: 配置 Boss 波次和前置波次

**前置波次**:

```json
{
    "wave_index": 9,
    "wave_name": "Boss 前奏",
    "require_clear_previous": true,
    "enemies": [
        {
            "count": 15,
            "size_level": 9,
            "health_multiplier": 1.2
        }
    ]
}
```

**Boss 波次**:

```json
{
    "wave_index": 10,
    "wave_name": "Boss 战：最终决战",
    "is_boss_wave": true,
    "preparation_time": 8.0,
    "require_clear_previous": true,
    "spawn_center": [0, 0],
    "min_spawn_radius": 1200.0,
    "max_spawn_radius": 1600.0,
    "enemies": [
        {
            "enemy_type": "circle_enemy",
            "enemy_scene_path": "res://src/enemies/circle_enemy.tscn",
            "count": 1,
            "size_level": 20,
            "health_multiplier": 10.0,
            "speed_multiplier": 1.0,
            "damage_multiplier": 2.0,
            "spawn_priority": 10,
            "is_boss": true
        }
    ]
}
```

---

## 测试与调试

### 测试步骤

#### 1. 加载关卡

**方法**: 在 [`world.gd`](file:///d:/WorkProject/034GameJam/034-game-jam/src/world.gd) 中加载关卡

```gdscript
func _initialize_game_manager() -> void:
    var game_manager = GameManager.instance
    if not game_manager:
        game_manager = GameManager.new()
        add_child(game_manager)
        game_manager.start_game()
    
    # 加载关卡
    var enemy_manager = $WorldPainter/EnemyManager
    if enemy_manager:
        var wave_system = enemy_manager.get_wave_system()
        if wave_system:
            wave_system.load_level("level_2")  // 修改这里
    
    # 启动 EnemyManager
    if enemy_manager and enemy_manager.has_method("start_game"):
        enemy_manager.start_game()
```

#### 2. 观察日志输出

**位置**: Godot 编辑器输出窗口

**关键日志**:
```
关卡加载成功: 第二章：新的挑战 (11 波)
第 1 波准备中...
第 1 波开始！将生成 5 个敌人，体型等级：1
第 1 波完成！
```

#### 3. 检查波次信息

**方法**: 使用调试工具查看波次信息

**代码位置**: [`wave_system.gd`](file:///d:/WorkProject/034GameJam/034-game-jam/src/systems/wave_system.gd#L138-L175)

**示例**:

```gdscript
func _debug_print_wave_info() -> void:
    var wave_info = wave_system.get_current_wave_info()
    print("=== 波次信息 ===")
    print("波次编号: ", wave_info.wave_number)
    print("波次名称: ", wave_info.wave_name)
    print("敌人总数: ", wave_info.total_count)
    print("已生成: ", wave_info.spawned_count)
    print("剩余: ", wave_info.remaining_count)
    print("是否 Boss: ", wave_info.is_boss)
```

### 调试技巧

#### 技巧 1: 验证 JSON 格式

**工具**: JSON 验证器

**检查项**:
- 括号匹配
- 逗号位置
- 引号闭合
- 数据类型正确

#### 技巧 2: 检查关卡加载

**方法**: 监听 ResourceManager 信号

**代码位置**: [`resource_manager.gd`](file:///d:/WorkProject/034GameJam/034-game-jam/src/managers/resource_manager.gd#L26-L27)

**示例**:

```gdscript
func _ready() -> void:
    if ResourceManager.instance:
        ResourceManager.instance.level_loaded.connect(_on_level_loaded)
        ResourceManager.instance.level_load_failed.connect(_on_level_load_failed)

func _on_level_loaded(level_id: String) -> void:
    print("关卡加载成功: ", level_id)

func _on_level_load_failed(level_id: String, error: String) -> void:
    print("关卡加载失败: ", level_id, " 错误: ", error)
```

#### 技巧 3: 快速测试波次

**方法**: 跳过前面的波次，直接测试目标波次

**代码位置**: [`wave_system.gd`](file:///d:/WorkProject/034GameJam/034-game-jam/src/systems/wave_system.gd#L89-L123)

**示例**:

```gdscript
func _test_specific_wave(wave_index: int) -> void:
    wave_system.current_wave = wave_index - 1
    wave_system.advance_to_next_wave()
```

#### 技巧 4: 监控敌人生成

**方法**: 在 [`enemy_manager.gd`](file:///d:/WorkProject/034GameJam/034-game-jam/src/enemy_manager.gd) 中添加日志

**代码位置**: [`enemy_manager.gd`](file:///d:/WorkProject/034GameJam/034-game-jam/src/enemy_manager.gd#L85-L108)

**示例**:

```gdscript
func _spawn_wave_enemy() -> void:
    var wave_info = wave_system.get_current_wave_info()
    print("生成敌人: ", wave_info.spawned_count, "/", wave_info.total_count)
    
    if wave_info.is_boss:
        _spawn_boss_enemy()
    else:
        _spawn_normal_enemy(wave_info.size)
```

---

## 常见问题

### 问题 1: 关卡加载失败

**错误信息**:
```
关卡配置文件不存在: res://config/levels/level_2.json
```

**原因**: JSON 文件不存在或路径错误

**解决方法**:
1. 检查文件路径是否正确
2. 确认文件名拼写正确
3. 检查文件是否在 `res://config/levels/` 目录下

### 问题 2: JSON 解析失败

**错误信息**:
```
关卡配置 JSON 解析失败: ...
```

**原因**: JSON 格式错误

**解决方法**:
1. 使用 JSON 验证器检查格式
2. 检查括号、逗号、引号
3. 确认数据类型正确（字符串用引号，数字不用）

### 问题 3: 敌人不生成

**现象**: 波次开始但没有敌人出现

**原因**:
1. 敌人场景路径错误
2. 敌人数量设置为 0
3. 生成间隔设置过大

**解决方法**:
1. 检查 `enemy_scene_path` 是否正确
2. 确认 `count` 大于 0
3. 检查 `spawn_interval` 是否合理

### 问题 4: 波次不推进

**现象**: 波次完成后不进入下一波

**原因**:
1. `wave_interval` 设置过大
2. `require_clear_previous` 为 true 但敌人未清除
3. Boss 波次未等待 Boss 被击败

**解决方法**:
1. 调整 `wave_interval` 为合理值
2. 检查 `require_clear_previous` 设置
3. 确认 Boss 死亡信号正确连接

### 问题 5: Boss 生成失败

**现象**: Boss 波次开始但没有 Boss 出现

**原因**:
1. Boss 场景路径错误
2. `is_boss_wave` 未设置为 true
3. Boss 场景未在 world.tscn 中配置

**解决方法**:
1. 检查 Boss 场景路径
2. 确认 `is_boss_wave: true`
3. 在 [`world.tscn`](file:///d:/WorkProject/034GameJam/034-game-jam/src/world.tscn) 中配置 Boss 场景

### 问题 6: 难度不均衡

**现象**: 某些波次太简单或太难

**原因**: 敌人数量、体型、属性配置不合理

**解决方法**:
1. 调整敌人数量
2. 修改体型等级
3. 调整属性倍数
4. 使用 `difficulty_multiplier` 整体调整

### 问题 7: 性能问题

**现象**: 大量敌人时游戏卡顿

**原因**: 敌人数量过多或生成间隔过短

**解决方法**:
1. 减少单波敌人数量
2. 增加 `spawn_interval`
3. 使用 `require_clear_previous` 限制同时在场敌人数

---

## 附录

### A. 完整配置示例

**文件**: `res://config/levels/level_2.json`

```json
{
    "level_id": "level_2",
    "level_name": "第二章：新的挑战",
    "level_description": "更强大的敌人即将到来",
    "difficulty": 2,
    "recommended_level": 2,
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
                    "count": 4,
                    "size_level": 2,
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

### B. 相关文件路径

| 文件 | 路径 | 说明 |
|------|------|------|
| 关卡配置文件 | `res://config/levels/level_*.json` | 关卡和波次配置 |
| 关卡数据类 | `src/data/level_data.gd` | 关卡数据结构 |
| 波次数据类 | `src/data/wave_data.gd` | 波次数据结构 |
| 敌人配置类 | `src/data/enemy_spawn_config.gd` | 敌人生成配置 |
| 资源管理器 | `src/managers/resource_manager.gd` | 关卡加载管理 |
| 波次系统 | `src/systems/wave_system.gd` | 波次逻辑控制 |
| 敌人管理器 | `src/enemy_manager.gd` | 敌人生成管理 |
| 世界场景 | `src/world.tscn` | 游戏主场景 |

### C. 快速参考

#### 波次参数速查

| 参数 | 类型 | 默认值 | 推荐范围 |
|------|------|--------|----------|
| preparation_time | float | 3.0 | 2.0 - 8.0 |
| spawn_interval | float | 0.8 | 0.5 - 1.5 |
| wave_interval | float | 2.0 | 2.0 - 5.0 |
| min_spawn_radius | float | 400.0 | 300.0 - 1200.0 |
| max_spawn_radius | float | 800.0 | 600.0 - 1600.0 |
| difficulty_multiplier | float | 1.0 | 0.8 - 2.0 |
| speed_multiplier | float | 1.0 | 0.8 - 1.5 |
| health_multiplier | float | 1.0 | 0.8 - 2.0 |

#### 敌人参数速查

| 参数 | 类型 | 默认值 | 推荐范围 |
|------|------|--------|----------|
| count | int | 1 | 1 - 20 |
| size_level | int | 1 | 1 - 20 |
| health_multiplier | float | 1.0 | 0.8 - 10.0 |
| speed_multiplier | float | 1.0 | 0.8 - 1.5 |
| damage_multiplier | float | 1.0 | 1.0 - 2.0 |
| spawn_priority | int | 0 | 0 - 10 |
| spawn_weight | float | 1.0 | 0.2 - 1.0 |

---

## 总结

本指南提供了完整的关卡波次系统修改方案，包括：

✅ **系统架构概述**: 清晰的组件结构和配置模式
✅ **创建新关卡**: 详细的步骤和代码示例
✅ **修改现有关卡**: 波次增删改查方法
✅ **波次配置详解**: 所有参数的详细说明
✅ **敌人配置详解**: 敌人类型、数量、属性配置
✅ **高级配置技巧**: 难度曲线、敌人混合、随机化等
✅ **测试与调试**: 测试步骤和调试技巧
✅ **常见问题**: 问题诊断和解决方法

通过本指南，您可以轻松创建和修改关卡，设计出多样化的波次体验！