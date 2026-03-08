extends Node2D

@export var state: GameState = GameState.new()

@onready var input_manager: InputManager = $InputManager
@onready var placement_preview: PlacementPreview = $PlacementPreview
@onready var structure_manager: StructureManager = $WorldPainter/StructureManager
@onready var hud: HUD = $HUD
@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	# 连接 InputManager 的引用
	input_manager.structure_manager = structure_manager
	input_manager.placement_preview = placement_preview
	input_manager.hud = hud
	input_manager.camera = camera
	
	# 初始化 PlacementPreview
	placement_preview.set_structure_type(Enums.StructureType.TURRET)
