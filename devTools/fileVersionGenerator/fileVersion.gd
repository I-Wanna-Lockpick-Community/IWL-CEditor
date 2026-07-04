class_name FileVersion
extends Resource

@export var version:int
@export var firstEditorVersion:String
@export var componentTypes:Array[GDScript] = []
@export var typeDefs:Dictionary[GDScript, ComponentTypeDef] = {}
