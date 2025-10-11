extends Node
class_name Changes

var undoStack:Array[RefCounted] = [UndoSeperator.new()]
var stackPosition:int = 0

var saveBuffered:bool = false

# handles the undo system for the editor

func bufferSave() -> void:
	saveBuffered = true

func addChange(change:Change) -> void:
	if change.cancelled: return
	if stackPosition != len(undoStack) - 1: undoStack = undoStack.slice(0,stackPosition+1)
	undoStack.append(change)
	stackPosition += 1

func _process(_delta) -> void:
	if saveBuffered:
		saveBuffered = false
		if undoStack[len(undoStack)-1] is UndoSeperator: return
		undoStack.append(UndoSeperator.new())
		stackPosition += 1

func undo() -> void:
	if undoStack[stackPosition] is UndoSeperator: stackPosition -= 1
	while true:
		var change = undoStack[stackPosition]
		if change is UndoSeperator: return
		change.undo()
		stackPosition -= 1

func redo() -> void:
	if stackPosition == len(undoStack) - 1: return
	stackPosition += 1
	while true:
		var change = undoStack[stackPosition]
		if change is UndoSeperator: return
		change.do()
		stackPosition += 1


class Change extends RefCounted:
	var level:Level
	var cancelled:bool = false
	# is a singular recorded change
	func do() -> void: pass
	func undo() -> void: pass

class UndoSeperator extends RefCounted:
	# indicates the start/end of an undo in the stack
	func _to_string() -> String:
		return "<UndoSeperator>"

class TileChange extends Change:
	var position:Vector2i
	var beforeTile:bool # probably make a tile enum at some point but right now we either have tile or not
	var afterTile:bool # same as above

	func _init(_level:Level,_position:Vector2i,_afterTile:bool) -> void:
		level = _level
		position = _position
		afterTile = _afterTile
		beforeTile = level.tiles.get_cell_source_id(position) != -1
		if afterTile == beforeTile:
			cancelled = true
			return
		do()

	func do() -> void:
		if afterTile: level.tiles.set_cell(position,1,Vector2i(1,1))
		else: level.tiles.erase_cell(position)

	func undo() -> void:
		if beforeTile: level.tiles.set_cell(position,1,Vector2i(1,1))
		else: level.tiles.erase_cell(position)

	func _to_string() -> String:
		return "<TileChange>"

class CreateKeyChange extends Change:
	var position:Vector2i
	var id:int

	func _init(_level:Level,_position:Vector2i) -> void:
		level = _level
		position = _position
		id = level.objIdIter
		level.objIdIter += 1
		do()
	
	func do() -> void:
		var key:oKey = preload("res://scenes/objects/oKey.tscn").instantiate()
		key.position = position
		level.keys[id] = key
		level.add_child(key)

	func undo() -> void:
		level.keys[id].queue_free()
		level.keys.erase(id)
