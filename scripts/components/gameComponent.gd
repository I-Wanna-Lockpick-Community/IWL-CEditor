extends Node2D
class_name GameComponent
# game objects and also door locks

var id:int
var size:Vector2

@onready var editor:Editor = get_node("/root/editor")

func getDrawPosition() -> Vector2: return position

func receiveMouseInput(_event:InputEventMouse) -> bool: return false

func propertyChanged(_property:StringName) -> void: pass
func propertyGameChanged(_property:StringName) -> void: pass
