extends EnergyTransmitter
class_name Conduit

func _ready() -> void:
	super._ready()
	structure_type = Enums.StructureType.CONDUIT

func _init() -> void:
	structure_type = Enums.StructureType.CONDUIT
