@abstract
extends Node2D
class_name GameComponent
# game objects and also door locks

var id:int
var size:Vector2
var problems:Array[Array] = [] # array[array[mod, problemtype]]

var isReady:bool = false

var editor:Editor

func getDrawPosition() -> Vector2: return position
func getDrawSize() -> Vector2: return size

func receiveMouseInput(_event:InputEventMouse) -> bool: return false

func propertyChangedInit(_property:StringName) -> void: pass
func propertyChangedDo(_property:StringName) -> void:
	if editor and editor.findProblems: editor.findProblems.findProblems(self)
func propertyGameChangedDo(_property:StringName) -> void: pass

func start() -> void: pass
func stop() -> void: pass

func deletedInit() -> void: pass

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PREDELETE: _freed()

func _freed() -> void: pass

func getColors() -> Array[C.olors]: return []
