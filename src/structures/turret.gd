extends EnergyTransmitter
class_name Turret

func _ready() -> void:
	super._ready()
	structure_type = Enums.StructureType.TURRET

func _init() -> void:
	structure_type = Enums.StructureType.TURRET
