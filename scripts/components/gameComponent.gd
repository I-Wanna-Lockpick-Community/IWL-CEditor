extends Node2D
class_name GameComponent
# game objects and also door locks

var id:int
var size:Vector2
var problems:Array[Array] = [] # array[array[mod, problemtype]]

var isReady:bool = false

var editor:Editor
var game:Game

func getDrawPosition() -> Vector2: return position

func receiveMouseInput(_event:InputEventMouse) -> bool: return false

func propertyChangedInit(_property:StringName) -> void: pass
func propertyChangedDo(_property:StringName) -> void:
	if editor and editor.findProblems: editor.findProblems.findProblems(self)
func propertyGameChangedDo(_property:StringName) -> void: pass

func start() -> void: pass
func stop() -> void: pass
