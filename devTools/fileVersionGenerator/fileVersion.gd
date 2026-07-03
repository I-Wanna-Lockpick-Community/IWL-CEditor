class_name FileVersion
extends Resource

@export var version:int
@export var typeDefs:Dictionary[GDScript, ComponentTypeDef] = {}

func _init(_version:int) -> void:
	version = _version
