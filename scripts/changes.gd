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
		if undoStack[stackPosition] is UndoSeperator: return
		undoStack.append(UndoSeperator.new())
		stackPosition += 1

func undo() -> void:
	if stackPosition == 0: return
	if undoStack[stackPosition] is UndoSeperator: stackPosition -= 1
	else:
		assert(stackPosition == len(undoStack)-1)
		undoStack.append(UndoSeperator.new())
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
	var game:Game
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

	func _init(_game:Game,_position:Vector2i,_afterTile:bool) -> void:
		game = _game
		position = _position
		afterTile = _afterTile
		beforeTile = game.tiles.get_cell_source_id(position) != -1
		if afterTile == beforeTile:
			cancelled = true
			return
		do()

	func do() -> void:
		if afterTile: game.tiles.set_cell(position,1,Vector2i(1,1))
		else: game.tiles.erase_cell(position)

	func undo() -> void:
		if beforeTile: game.tiles.set_cell(position,1,Vector2i(1,1))
		else: game.tiles.erase_cell(position)

	func _to_string() -> String:
		return "<TileChange>"

class CreateKeyChange extends Change:
	var position:Vector2i
	var id:int

	func _init(_game:Game,_position:Vector2i) -> void:
		game = _game
		position = _position
		id = game.objIdIter
		game.objIdIter += 1
		do()
	
	func do() -> void:
		var key:KeyBulk = preload("res://scenes/objects/KeyBulk.tscn").instantiate()
		key.position = position
		key.id = id
		game.keys[id] = key
		game.objects.add_child(key)

	func undo() -> void:
		game.keys[id].queue_free()
		game.keys.erase(id)

class DeleteKeyChange extends Change:
	var position:Vector2i
	var id:int
	var color:Game.COLOR

	func _init(_game:Game,key:KeyBulk) -> void:
		game = _game
		position = key.position
		id = key.id
		color = key.color
		do()

	func do() -> void:
		game.keys[id].queue_free()
		game.keys.erase(id)
	
	func undo() -> void:
		var key:KeyBulk = preload("res://scenes/objects/KeyBulk.tscn").instantiate()
		key.position = position
		key.id = id
		key.color = color
		game.keys[id] = key
		game.objects.add_child(key)

class KeyPropertyChange extends Change:
	var id:int
	var property:StringName
	var before:Variant
	var after:Variant
	
	func _init(_game:Game,key:KeyBulk,_property:StringName,_after:Variant) -> void:
		game = _game
		id = key.id
		property = _property
		before = key.get(property)
		after = _after
		do()

	func do() -> void:
		var key:KeyBulk = game.keys[id]
		key.set(property, after)
		if property != &"position": key.updateDraw()
		if game.editor.focusDialog.focused == key: game.editor.focusDialog.focus(key)
	
	func undo() -> void:
		var key:KeyBulk = game.keys[id]
		key.set(property, before)
		if property != &"position": key.updateDraw()
		if game.editor.focusDialog.focused == key: game.editor.focusDialog.focus(key)
