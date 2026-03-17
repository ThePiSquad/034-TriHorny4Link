# 关卡敌人刷新流程梳理

## 流程概述

当前关卡敌人刷新系统采用**波次制**设计，通过 WaveSystem 和 EnemyManager 协作实现敌人生成和管理。系统支持默认配置和关卡配置文件两种模式。

---

## 完整流程图

```
游戏启动
    ↓
World._ready()
    ↓
初始化 GameManager
    ↓
EnemyManager.start_game()
    ↓
查找水晶位置
    ↓
重置波次系统
    ↓
wave_system.advance_to_next_wave() [开始第1波]
    ↓
┌─────────────────────────────────────┐
│  波次循环（每波重复以下流程）        │
└─────────────────────────────────────┘
    ↓
【阶段1：波次准备】
    ↓
wave_system.current_state = PREPARING
    ↓
发射 wave_preparing 信号
    ↓
EnemyManager._on_wave_preparing()
    ↓
播放准备音效
    ↓
wave_system.update(delta) 每帧更新
    ↓
等待 preparation_time 秒
    ↓
【阶段2：开始生成】
    ↓
wave_system.current_state = SPAWNING
    ↓
发射 wave_started 信号
    ↓
EnemyManager._on_wave_started()
    ↓
打印波次信息
    ↓
【阶段3：敌人生成循环】
    ↓
EnemyManager._process(delta) 每帧更新
    ↓
检查 wave_system.current_state == SPAWNING
    ↓
检查 _spawn_timer >= spawn_interval
    ↓
调用 _spawn_wave_enemy()
    ↓
获取当前波次信息
    ↓
检查是否已生成足够敌人
    ↓
┌─────────────────────┐
│ 判断波次类型         │
└─────────────────────┘
    ↓
    ├─→ Boss 波次 → _spawn_boss_enemy()
    │                 ↓
    │             生成 Boss 敌人
    │                 ↓
    │             设置 Boss 属性
    │                 ↓
    │             连接 Boss 死亡信号
    │                 ↓
    │             wave_system.update() 继续更新
    │                 ↓
    │             进入 COMPLETED 状态
    │                 ↓
    │             等待 Boss 被击败
    │                 ↓
    │             _on_boss_died()
    │                 ↓
    │             GameManager.end_game()
    │                 ↓
    │             游戏胜利
    │
    └─→ 普通波次 → _spawn_normal_enemy(size_level)
                      ↓
                  随机选择敌人类型
                      ↓
                  计算生成位置
                      ↓
                  实例化敌人
                      ↓
                  设置敌人属性
                      ↓
                  添加到场景树
                      ↓
                  wave_system.update() 继续更新
                      ↓
                  current_wave_progress += 1
                      ↓
                  检查是否完成所有敌人生成
                      ↓
                  ├─ 未完成 → 继续生成循环
                  │
                  └─ 完成 → 进入 COMPLETED 状态
                              ↓
                          发射 wave_completed 信号
                              ↓
                          EnemyManager._on_wave_completed()
                              ↓
                          延迟 2 秒
                              ↓
                          wave_system.advance_to_next_wave()
                              ↓
                          【回到阶段1，开始下一波】
```

---

## 详细流程说明

### 1. 游戏初始化阶段

#### 1.1 World._ready()
```gdscript
func _ready() -> void:
    # 初始化 GameManager
    _initialize_game_manager()
    
    # 启动 EnemyManager 的波次系统
    var enemy_manager = $WorldPainter/EnemyManager
    if enemy_manager and enemy_manager.has_method("start_game"):
        enemy_manager.start_game()
```

**作用**：游戏启动时初始化 GameManager 和 EnemyManager。

---

#### 1.2 EnemyManager._ready()
```gdscript
func _ready() -> void:
    # 验证敌人列表
    if enemy_list.is_empty():
        push_warning("EnemyManager: 敌人列表为空，无法生成敌人")
    
    # 初始化波次系统
    wave_system = WaveSystem.new()
    
    # 连接波次信号
    wave_system.wave_preparing.connect(_on_wave_preparing)
    wave_system.wave_started.connect(_on_wave_started)
    wave_system.wave_completed.connect(_on_wave_completed)
    wave_system.all_waves_completed.connect(_on_all_waves_completed)
    wave_system.boss_wave_started.connect(_on_boss_wave_started)
    wave_system.boss_defeated.connect(_on_boss_defeated)
```

**作用**：初始化 WaveSystem 并连接所有波次相关信号。

---

#### 1.3 EnemyManager.start_game()
```gdscript
func start_game() -> void:
    # 确保水晶位置已设置
    _find_crystal_position()
    
    game_started = true
    wave_system.reset()
    # 开始第一波
    wave_system.advance_to_next_wave()
```

**作用**：查找水晶位置，重置波次系统，开始第一波。

---

### 2. 波次准备阶段

#### 2.1 WaveSystem.advance_to_next_wave()
```gdscript
func advance_to_next_wave() -> bool:
    if current_level_data:
        # 使用关卡数据
        if current_wave >= current_level_data.get_wave_count():
            return false
        
        current_wave += 1
        current_state = WaveState.PREPARING
        preparation_timer = 0.0
        current_wave_progress = 0
        
        # 发射准备信号
        wave_preparing.emit(current_wave)
        
        if current_level_data.has_boss_wave() and current_wave > current_level_data.boss_wave_index:
            boss_wave_started.emit()
        
        return true
    else:
        # 使用默认配置
        if current_wave >= total_wave_count + boss_wave_count:
            return false
        
        current_wave += 1
        current_state = WaveState.PREPARING
        preparation_timer = 0.0
        current_wave_progress = 0
        
        # 发射准备信号
        wave_preparing.emit(current_wave)
        
        if current_wave > total_wave_count:
            boss_wave_started.emit()
        
        return true
```

**作用**：
- 增加当前波次索引
- 设置状态为 PREPARING
- 重置准备计时器和进度
- 发射 wave_preparing 信号
- 检查是否是 Boss 波次

---

#### 2.2 EnemyManager._on_wave_preparing()
```gdscript
func _on_wave_preparing(wave_number: int) -> void:
    """波次准备开始"""
    print("第 ", wave_number, " 波准备中...")
    # 播放准备音效
    if wave_number > 10:
        AudioManager.play_wave_start("boss")
    else:
        AudioManager.play_wave_start("normal")
```

**作用**：播放波次准备音效。

---

#### 2.3 WaveSystem.update(delta) - PREPARING 状态
```gdscript
func update(delta: float) -> void:
    match current_state:
        WaveState.PREPARING:
            var prep_time = _get_preparation_time()
            preparation_timer += delta
            if preparation_timer >= prep_time:
                # 准备时间结束，进入生成阶段
                current_state = WaveState.SPAWNING
                spawn_timer = 0.0
                wave_started.emit(current_wave)
```

**作用**：
- 每帧累加准备时间
- 达到准备时间后，切换到 SPAWNING 状态
- 发射 wave_started 信号

---

### 3. 敌人生成阶段

#### 3.1 EnemyManager._on_wave_started()
```gdscript
func _on_wave_started(wave_number: int) -> void:
    """波次开始生成敌人"""
    var wave_info = wave_system.get_current_wave_info()
    print("第 ", wave_number, " 波开始！将生成 ", wave_info.total_count, " 个敌人，体型等级：", wave_info.size)
```

**作用**：打印波次开始信息。

---

#### 3.2 EnemyManager._process(delta) - 敌人生成循环
```gdscript
func _process(delta: float) -> void:
    if not game_started:
        return
    
    # 更新波次系统
    if wave_system:
        wave_system.update(delta)
        
        # 如果波次系统正在生成敌人
        if wave_system.current_state == WaveSystem.WaveState.SPAWNING:
            _spawn_timer += delta
            if _spawn_timer >= wave_system.wave_intervals.spawn_interval:
                _spawn_timer = 0.0
                _spawn_wave_enemy()
```

**作用**：
- 每帧更新波次系统
- 如果是 SPAWNING 状态，检查生成间隔
- 达到间隔时，调用 _spawn_wave_enemy()

---

#### 3.3 _spawn_wave_enemy()
```gdscript
func _spawn_wave_enemy() -> void:
    """生成波次敌人"""
    if not wave_system:
        push_warning("EnemyManager: wave_system 为空！")
        return
    
    var wave_info = wave_system.get_current_wave_info()
    if wave_info.is_empty():
        push_warning("EnemyManager: wave_info 为空！")
        return
    
    # 检查是否已经生成了足够的敌人
    if wave_info.spawned_count >= wave_info.total_count:
        return
    
    # Boss 波次特殊处理
    if wave_info.is_boss:
        _spawn_boss_enemy()
    else:
        _spawn_normal_enemy(wave_info.size)
```

**作用**：
- 获取当前波次信息
- 检查是否已生成足够敌人
- 根据波次类型调用不同的生成函数

---

### 4. 普通敌人生成流程

#### 4.1 _spawn_normal_enemy(size_level)
```gdscript
func _spawn_normal_enemy(size_level: int) -> void:
    """生成普通敌人"""
    if enemy_list.is_empty():
        push_warning("EnemyManager: 敌人列表为空！")
        return
    
    # 随机选择敌人类型
    var enemy_index = randi() % enemy_list.size()
    var enemy_scene = enemy_list[enemy_index]
    
    var enemy = enemy_scene.instantiate()
    if enemy:
        var spawn_position = _generate_spawn_position_for_size(size_level)
        enemy.global_position = spawn_position
        
        # 设置基地位置
        if enemy.has_method("set_base_position"):
            enemy.set_base_position(_crystal_position)
        
        # 设置敌人体型
        if enemy.has_method("set_size_level"):
            enemy.set_size_level(size_level)
        
        add_child(enemy)
    else:
        push_error("EnemyManager: 敌人实例化失败")
```

**作用**：
- 随机选择敌人类型
- 根据体型等级计算生成位置
- 实例化敌人并设置属性
- 添加到场景树

---

#### 4.2 _generate_spawn_position_for_size(size_level)
```gdscript
func _generate_spawn_position_for_size(size_level: int) -> Vector2:
    """根据体型等级生成位置 - 大体型敌人生成更远"""
    var spawn_position: Vector2 = Vector2.ZERO
    var attempts: int = 0
    
    var size_ratio = float(size_level) / float(Constants.EnemyConstants.MAX_SIZE_LEVEL)
    
    var extra_distance = 0.0
    if size_level >= Constants.EnemyConstants.SIZE_LEVEL_11:
        extra_distance = (float(size_level - Constants.EnemyConstants.SIZE_LEVEL_10) / 10.0) * 0.5
    
    var min_dist = Constants.EnemyConstants.MIN_SPAWN_DISTANCE * (1.0 + size_ratio * 0.3)
    var max_dist = Constants.EnemyConstants.MAX_SPAWN_DISTANCE * (1.0 + extra_distance)
    
    max_dist = max(max_dist, min_dist * 1.5)
    
    while attempts < _max_spawn_attempts:
        var distance_bias = pow(randf(), Constants.EnemyConstants.SPAWN_DISTANCE_BIAS)
        var spawn_distance = lerp(min_dist, max_dist, distance_bias)
        
        var spawn_angle = randf() * 2.0 * PI
        
        spawn_position = _crystal_position + Vector2(
            cos(spawn_angle) * spawn_distance,
            sin(spawn_angle) * spawn_distance
        )
        
        # 检查是否在地图范围内
        if spawn_position.x >= Constants.CameraConstants.MIN_X and \
           spawn_position.x <= Constants.CameraConstants.MAX_X and \
           spawn_position.y >= Constants.CameraConstants.MIN_Y and \
           spawn_position.y <= Constants.CameraConstants.MAX_Y:
            return spawn_position
        
        attempts += 1
    
    # 如果多次尝试都失败，使用备选方案：在最小距离处生成
    var fallback_angle = randf() * 2.0 * PI
    spawn_position = _crystal_position + Vector2(
        cos(fallback_angle) * min_dist,
        sin(fallback_angle) * min_dist
    )
    return spawn_position
```

**作用**：
- 根据体型等级计算生成距离（大体型敌人生成更远）
- 在地图范围内随机生成位置
- 最多尝试 10 次，失败则使用备选位置

---

### 5. Boss 敌人生成流程

#### 5.1 _spawn_boss_enemy()
```gdscript
func _spawn_boss_enemy() -> void:
    """生成 Boss 敌人"""
    var boss_to_spawn = boss_enemy_scene
    if not boss_to_spawn:
        # 如果没有指定 Boss 场景，使用第一个敌人
        boss_to_spawn = enemy_list[0] if not enemy_list.is_empty() else null
    
    if not boss_to_spawn:
        push_error("EnemyManager: Boss 场景未设置！")
        return
    
    var boss = boss_to_spawn.instantiate()
    if boss:
        # Boss 生成在边缘
        var spawn_position = _generate_spawn_position_for_size(20)
        boss.global_position = spawn_position
        
        # 设置基地位置
        if boss.has_method("set_base_position"):
            boss.set_base_position(_crystal_position)
        
        # 设置 Boss 体型 (256x256)
        if boss.has_method("set_size_level"):
            boss.set_size_level(20)
        
        add_child(boss)
        
        # 连接 Boss 死亡信号
        if boss.has_signal("died"):
            boss.died.connect(_on_boss_died)
    else:
        push_error("EnemyManager: Boss 实例化失败")
```

**作用**：
- 获取 Boss 场景
- 生成 Boss 在边缘位置
- 设置 Boss 属性（体型等级 20）
- 连接 Boss 死亡信号

---

#### 5.2 _on_boss_died()
```gdscript
func _on_boss_died(_source: Node) -> void:
    """Boss 被击败"""
    # 更新波次系统状态为所有波次完成
    if wave_system:
        wave_system.current_wave = wave_system.total_wave_count + wave_system.boss_wave_count
        wave_system.current_state = WaveSystem.WaveState.COMPLETED
        wave_system.boss_defeated.emit()
```

**作用**：
- Boss 被击败时调用
- 更新波次系统状态
- 发射 boss_defeated 信号

---

### 6. 波次完成阶段

#### 6.1 WaveSystem.update(delta) - SPAWNING 状态
```gdscript
WaveState.SPAWNING:
    # 检查是否应该生成下一个敌人
    var spawn_interval = _get_spawn_interval()
    spawn_timer += delta
    if spawn_timer >= spawn_interval:
        spawn_timer = 0.0
        
        # 获取当前波次配置
        if current_level_data:
            var wave_data = current_level_data.get_wave(current_wave)
            if wave_data:
                # 检查是否已完成当前波次的所有敌人生成
                if current_wave_progress < wave_data.get_total_enemy_count():
                    current_wave_progress += 1
                else:
                    # 当前波次完成
                    current_state = WaveState.COMPLETED
                    wave_completed.emit(current_wave)
        else:
            # 使用默认配置
            var wave_config = wave_intervals.waves.get(current_wave, {})
            var total_count = wave_config.get("count", 0)
            if current_wave_progress < total_count:
                current_wave_progress += 1
            else:
                # 当前波次完成
                current_state = WaveState.COMPLETED
                wave_completed.emit(current_wave)
```

**作用**：
- 每次生成敌人后，检查是否完成所有敌人生成
- 完成后切换到 COMPLETED 状态
- 发射 wave_completed 信号

---

#### 6.2 EnemyManager._on_wave_completed()
```gdscript
func _on_wave_completed(wave_number: int) -> void:
    """波次完成"""
    print("第 ", wave_number, " 波完成！")
    # Boss 波次完成后等待 Boss 被击败
    if wave_number >= 11:
        print("Boss 波次完成，等待 Boss 被击败...")
        return
    
    # 延迟进入下一波
    await get_tree().create_timer(2.0).timeout
    if wave_system and not wave_system.is_all_waves_completed():
        wave_system.advance_to_next_wave()
```

**作用**：
- Boss 波次完成后等待 Boss 被击败
- 普通波次完成后延迟 2 秒进入下一波

---

### 7. 游戏结束阶段

#### 7.1 _on_boss_defeated()
```gdscript
func _on_boss_defeated() -> void:
    """Boss 被击败"""
    print("Boss 被击败！游戏胜利！")
    # 触发游戏胜利逻辑
    if GameManager.instance:
        GameManager.instance.end_game()
```

**作用**：Boss 被击败时触发游戏胜利。

---

#### 7.2 _on_all_waves_completed()
```gdscript
func _on_all_waves_completed() -> void:
    """所有波次完成（胜利）"""
    print("所有波次完成！游戏胜利！")
    # 触发游戏胜利
    var game_manager = GameManager.instance
    if game_manager:
        game_manager.end_game()
```

**作用**：所有波次完成时触发游戏胜利。

---

## 配置模式

### 默认配置模式
- 使用 WaveSystem 内置的 `wave_intervals` 字典
- 11 个波次（10 波常规 + 1 波 Boss）
- 每波配置固定数量和体型

### 关卡配置模式
- 从 JSON 文件加载关卡数据
- 使用 `wave_system.load_level(level_id)` 加载
- 支持自定义波次数量、敌人类型、生成间隔等
- 更灵活的配置选项

---

## 关键参数

### 波次参数
- `preparation_time`: 波次准备时间（默认 3.0 秒）
- `spawn_interval`: 敌人生成间隔（默认 0.8 秒）
- `wave_interval`: 波次间隔时间（默认 2.0 秒）

### 生成参数
- `MIN_SPAWN_DISTANCE`: 最小生成距离
- `MAX_SPAWN_DISTANCE`: 最大生成距离
- `SPAWN_DISTANCE_BIAS`: 生成距离偏置（使敌人更倾向于在远处生成）
- `MAX_SPAWN_ATTEMPTS`: 最大生成尝试次数（10 次）

### 体型等级
- `SIZE_LEVEL_1`: 体型等级 1（32x32）
- `SIZE_LEVEL_10`: 体型等级 10（128x128）
- `SIZE_LEVEL_20`: 体型等级 20（256x256，Boss）

---

## 信号流程

```
wave_preparing → _on_wave_preparing → 播放音效
     ↓
wave_started → _on_wave_started → 打印信息
     ↓
（敌人生成循环）
     ↓
wave_completed → _on_wave_completed → 延迟 2 秒 → 下一波
     ↓
boss_defeated → _on_boss_defeated → 游戏胜利
```

---

## 总结

当前关卡敌人刷新系统采用**波次制**设计，具有以下特点：

1. **清晰的阶段划分**：准备 → 生成 → 完成
2. **灵活的配置模式**：支持默认配置和关卡配置
3. **完善的信号机制**：各阶段通过信号通知
4. **智能的生成逻辑**：根据体型等级调整生成距离
5. **Boss 特殊处理**：Boss 波次有独立的处理流程
6. **平滑的波次过渡**：延迟 2 秒进入下一波

系统设计合理，代码结构清晰，易于扩展和维护！