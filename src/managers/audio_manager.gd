extends Node

## 音效管理器
## 统一管理游戏中的所有音效播放

# 单例模式
static var instance = AudioManager

# 音效播放器池
@export var max_players: int = 16
var _audio_players: Array[AudioStreamPlayer] = []
var _available_players: Array[AudioStreamPlayer] = []

# 音效资源缓存
var _sound_cache: Dictionary = {}

# 音效文件路径（可以根据实际路径修改）
const SOUND_PATHS = {
	"ui_click": "res://assets/audio/fx_du.ogg",
	"ui_hover": "res://assets/audio/fx_sec.ogg",
	"building_place": "res://assets/audio/放置装置.ogg",
	"turret_shoot_red": "res://assets/audio/etfx_explosion_fireball2.ogg",
	"turret_shoot_blue": "res://assets/audio/etfx_shoot_rocket03.ogg",
	"turret_shoot_yellow": "res://assets/audio/LaserShot04.ogg",
	"turret_shoot_green": "res://assets/audio/etfx_explosion_minimagic2_0.ogg",
	"turret_shoot_orange": "res://assets/audio/etfx_explosion_lightning.ogg",
	"turret_shoot_purple": "res://assets/audio/etfx_explosion_mystic02.ogg",
	"bullet_hit_green": "res://assets/audio/etfx_explosion_lava.ogg",
	"bullet_hit_purple": "res://assets/audio/etfx_explosion_plasma_0.ogg",
	"bullet_hit_orange": "res://assets/audio/etfx_explosion_storm.ogg",
	"enemy_hit": "res://assets/audio/怪物受击.ogg",
	"base_attacked": "res://assets/audio/玩家受击(猫叫）.ogg",
	"base_die": "res://assets/audio/fx_effect_explosion.ogg",
}

# BGM 文件路径
const BGM_PATH = "res://assets/audio/bgm.mp3"

# BGM 播放器
var _bgm_player: AudioStreamPlayer = null
var _bgm_volume_db: float = -10.0
var _bgm_pitch_scale: float = 1.0

func _ready() -> void:
	# 设置单例
	if instance == null:
		instance = self
	else:
		queue_free()
		return
	
	# 创建 BGM 播放器
	_create_bgm_player()
	
	# 创建音效播放器池
	_create_audio_player_pool()
	
	# 预加载常用音效
	_preload_sounds()
	
	print("音效管理器初始化完成")

func _create_audio_player_pool() -> void:
	"""创建音效播放器池"""
	for i in range(max_players):
		var player = AudioStreamPlayer.new()
		player.name = "AudioPlayer_" + str(i)
		add_child(player)
		_audio_players.append(player)
		_available_players.append(player)
		
		# 连接播放完成信号
		player.finished.connect(_on_player_finished.bind(player))

func _preload_sounds() -> void:
	"""预加载常用音效"""
	for sound_name in SOUND_PATHS.keys():
		var path = SOUND_PATHS[sound_name]
		if ResourceLoader.exists(path):
			var sound = load(path)
			if sound:
				_sound_cache[sound_name] = sound
				print("预加载音效: ", sound_name)
		else:
			push_warning("音效文件不存在: " + path)

func _on_player_finished(player: AudioStreamPlayer) -> void:
	"""播放器播放完成，归还到可用池"""
	if not _available_players.has(player):
		_available_players.append(player)

func play_sound(sound_name: String, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	"""播放指定音效
	
	参数:
		sound_name: 音效名称（对应 SOUND_PATHS 中的键）
		volume_db: 音量（分贝），默认 0.0
		pitch_scale: 音调缩放，默认 1.0
	"""
	# 获取音效资源
	var sound: AudioStream = null
	
	if _sound_cache.has(sound_name):
		sound = _sound_cache[sound_name]
	else:
		# 尝试从路径加载
		if SOUND_PATHS.has(sound_name):
			var path = SOUND_PATHS[sound_name]
			if ResourceLoader.exists(path):
				sound = load(path)
				if sound:
					_sound_cache[sound_name] = sound
		else:
			push_warning("未知音效: " + sound_name)
			return
	
	if not sound:
		push_warning("无法加载音效: " + sound_name)
		return
	
	# 获取可用的播放器
	var player = _get_available_player()
	if not player:
		push_warning("没有可用的音效播放器")
		return
	
	# 设置并播放
	player.stream = sound
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()

func _get_available_player() -> AudioStreamPlayer:
	"""获取一个可用的音效播放器"""
	if _available_players.size() > 0:
		return _available_players.pop_back()
	
	# 如果没有可用播放器，找一个已经停止的
	for player in _audio_players:
		if not player.playing:
			return player
	
	return null

func play_ui_click() -> void:
	"""播放UI点击音效"""
	play_sound("ui_click", -5.0)

func play_ui_hover() -> void:
	"""播放UI悬停音效"""
	play_sound("ui_hover", -8.0, 1.2)

func play_building_place() -> void:
	"""播放建筑放置音效"""
	play_sound("building_place", -6.0)

func play_turret_shoot(type: String) -> void:
	"""播放炮塔发射音效"""
	play_sound("turret_shoot_" + type, -16.0, randf_range(0.9, 1.1))

func play_bullet_hit(type: String) -> void:
	"""播放子弹命中音效"""
	play_sound("bullet_hit_" + type, -12.0, randf_range(0.8, 1.2))

func play_base_attacked() -> void:
	"""播放基地被攻击音效"""
	play_sound("base_attacked", -3.0)

func play_enemy_hit() -> void:
	"""播放敌人被攻击音效"""
	play_sound("enemy_hit", -8.0)

func set_master_volume(volume_db: float) -> void:
	"""设置主音量"""
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), volume_db)

func set_sound_volume(volume_db: float) -> void:
	"""设置音效音量"""
	# 可以创建单独的音效总线来控制
	pass

func _create_bgm_player() -> void:
	"""创建 BGM 播放器"""
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "BGMPlayer"
	_bgm_player.volume_db = _bgm_volume_db
	_bgm_player.pitch_scale = _bgm_pitch_scale
	_bgm_player.autoplay = false
	add_child(_bgm_player)

func play_bgm() -> void:
	"""播放 BGM"""
	if not _bgm_player:
		push_warning("BGM 播放器未初始化")
		return
	
	if _bgm_player.playing:
		return
	
	# 加载 BGM 文件
	if ResourceLoader.exists(BGM_PATH):
		var bgm = load(BGM_PATH)
		if bgm:
			_bgm_player.stream = bgm
			_bgm_player.play()
			print("BGM 开始播放")
		else:
			push_warning("无法加载 BGM 文件: " + BGM_PATH)
	else:
		push_warning("BGM 文件不存在: " + BGM_PATH)

func stop_bgm() -> void:
	"""停止 BGM"""
	if _bgm_player and _bgm_player.playing:
		_bgm_player.stop()
		print("BGM 已停止")

func pause_bgm() -> void:
	"""暂停 BGM"""
	if _bgm_player and _bgm_player.playing:
		_bgm_player.stream_paused = true
		print("BGM 已暂停")

func resume_bgm() -> void:
	"""恢复 BGM"""
	if _bgm_player and _bgm_player.stream_paused:
		_bgm_player.stream_paused = false
		print("BGM 已恢复")

func set_bgm_volume(volume_db: float) -> void:
	"""设置 BGM 音量"""
	_bgm_volume_db = volume_db
	if _bgm_player:
		_bgm_player.volume_db = volume_db

func set_bgm_pitch(pitch_scale: float) -> void:
	"""设置 BGM 音调"""
	_bgm_pitch_scale = pitch_scale
	if _bgm_player:
		_bgm_player.pitch_scale = pitch_scale
