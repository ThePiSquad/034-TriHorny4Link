extends Node2D

@export var state: GameState = GameState.new()

@onready var input_manager: InputManager = $InputManager
@onready var placement_preview: PlacementPreview = $PlacementPreview
@onready var structure_manager: StructureManager = $WorldPainter/StructureManager
@onready var hud: HUD = $HUD
@onready var camera: Camera2D = $Camera2D
@onready var resource_manager: ResourceManager = $ResourceManager
@onready var screen_shake_manager: ScreenShakeManager = $ScreenShakeManager

func _ready() -> void:
	# 连接 InputManager 的引用
	input_manager.structure_manager = structure_manager
	input_manager.placement_preview = placement_preview
	input_manager.hud = hud
	input_manager.camera = camera
	input_manager.resource_manager = resource_manager
	
	# 初始化 PlacementPreview
	placement_preview.set_structure_type(Enums.StructureType.TURRET)
	
	# 连接资源管理器到 HUD
	resource_manager.resource_changed.connect(_on_resource_changed)
	_update_hud_resources()
	
	# 设置屏幕抖动管理器的相机引用
	screen_shake_manager.camera = camera
	
	# 将 World 节点添加到 world 组
	add_to_group("world")

func _on_resource_changed() -> void:
	_update_hud_resources()

func _update_hud_resources() -> void:
	var red_ratio = resource_manager.get_resource_ratio("red")
	var blue_ratio = resource_manager.get_resource_ratio("blue")
	var yellow_ratio = resource_manager.get_resource_ratio("yellow")
	hud.set_resource_ratios(red_ratio, blue_ratio, yellow_ratio)
