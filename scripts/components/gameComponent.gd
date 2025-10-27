extends Node2D
class_name GameComponent
# game objects and also door locks

var id:int
var size:Vector2
var problems:Array[Array] = [] # array[array[mod, problemtype]]

var isReady:bool = false

@onready var editor:Editor = get_node("/root/editor")

func getDrawPosition() -> Vector2: return position

func receiveMouseInput(_event:InputEventMouse) -> bool: return false

func propertyChangedInit(_property:StringName) -> void: pass
func propertyChangedDo(_property:StringName) -> void: if isReady and editor.findProblems: editor.findProblems.findProblems(self)
func propertyGameChangedDo(_property:StringName) -> void: pass
