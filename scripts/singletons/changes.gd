extends Node
class_name Changes

var undoStack:Array[RefCounted] = [UndoSeparator.new()]
var stackPosition:int = 0

var saveBuffered:bool = false

# handles the undo system for the editor

func bufferSave() -> void:
	saveBuffered = true

func addChange(change:Change) -> Change:
	if change.cancelled: return change
	if stackPosition != len(undoStack) - 1: undoStack = undoStack.slice(0,stackPosition+1)
	undoStack.append(change)
	stackPosition += 1
	return change

func _process(_delta) -> void:
	if saveBuffered:
		saveBuffered = false
		if undoStack[stackPosition] is UndoSeparator: return
		undoStack.append(UndoSeparator.new())
		stackPosition += 1

func undo() -> void:
	if stackPosition == 0: return
	if undoStack[stackPosition] is UndoSeparator: stackPosition -= 1
	else:
		assert(stackPosition == len(undoStack)-1)
		undoStack.append(UndoSeparator.new())
	while true:
		var change = undoStack[stackPosition]
		if change is UndoSeparator: return
		change.undo()
		stackPosition -= 1

func redo() -> void:
	if stackPosition == len(undoStack) - 1: return
	stackPosition += 1
	while true:
		var change = undoStack[stackPosition]
		if change is UndoSeparator: return
		change.do()
		stackPosition += 1


class Change extends RefCounted:
	var game:Game
	var cancelled:bool = false
	# is a singular recorded change
	func do() -> void: pass
	func undo() -> void: pass

class UndoSeparator extends RefCounted:
	# indicates the start/end of an undo in the stack
	func _to_string() -> String:
		return "<UndoSeparator>"

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
		var key:KeyBulk = preload("res://scenes/objects/keyBulk.tscn").instantiate()
		key.position = position
		key.id = id
		game.keys[id] = key
		game.objects.add_child(key)

	func undo() -> void:
		game.editor.objectHovered = null
		game.editor.objectDragged = null
		game.editor.focusDialog.defocus()
		game.keys[id].queue_free()
		game.keys.erase(id)

class DeleteKeyChange extends Change:
	var position:Vector2i
	var id:int
	var color:Game.COLOR
	var type:Game.KEY
	var count:C
	var infinite:bool

	func _init(_game:Game,key:KeyBulk) -> void:
		game = _game
		position = key.position
		id = key.id
		color = key.color
		type = key.type
		count = key.count
		infinite = key.infinite
		do()

	func do() -> void:
		game.editor.objectHovered = null
		game.editor.objectDragged = null
		game.editor.focusDialog.defocus()
		game.keys[id].queue_free()
		game.keys.erase(id)
	
	func undo() -> void:
		var key:KeyBulk = preload("res://scenes/objects/keyBulk.tscn").instantiate()
		key.position = position
		key.id = id
		key.color = color
		key.type = type
		key.count = count.copy()
		key.infinite = infinite
		game.keys[id] = key
		game.objects.add_child(key)

class CreateDoorChange extends Change:
	var position:Vector2i
	var id:int

	func _init(_game:Game,_position:Vector2i) -> void:
		game = _game
		position = _position
		id = game.objIdIter
		game.objIdIter += 1
		do()
	
	func do() -> void:
		var door:Door = preload("res://scenes/objects/door.tscn").instantiate()
		door.position = position
		door.id = id
		game.doors[id] = door
		game.objects.add_child(door)

	func undo() -> void:
		game.editor.objectHovered = null
		game.editor.objectDragged = null
		game.editor.focusDialog.defocus()
		game.doors[id].queue_free()
		game.doors.erase(id)

class DeleteDoorChange extends Change:
	var position:Vector2i
	var id:int
	var size:Vector2
	var colorSpend:Game.COLOR
	var copies:C

	func _init(_game:Game,door:Door) -> void:
		game = _game
		position = door.position
		id = door.id
		size = door.size
		colorSpend = door.colorSpend
		copies = door.copies
		do()

	func do() -> void:
		game.editor.objectHovered = null
		game.editor.objectDragged = null
		game.editor.focusDialog.defocus()
		game.doors[id].queue_free()
		game.doors.erase(id)
	
	func undo() -> void:
		var door:Door = preload("res://scenes/objects/door.tscn").instantiate()
		door.position = position
		door.id = id
		door.size = size
		door.colorSpend = colorSpend
		door.copies = copies
		game.doors[id] = door
		game.objects.add_child(door)

class CreateLockChange extends Change:
	var position:Vector2i
	var id:int
	var doorId:int

	func _init(_game:Game,_position:Vector2i, _doorId:int) -> void:
		game = _game
		position = _position
		id = game.lockIdIter
		game.lockIdIter += 1
		doorId = _doorId
		do()
	
	func do() -> void:
		var lock:Lock = Lock.new(game.doors[doorId])
		lock.position = position
		lock.id = id
		lock.doorId = doorId
		game.locks[id] = lock
		game.doors[doorId].add_child(lock)

	func undo() -> void:
		game.editor.objectHovered = null
		game.editor.objectDragged = null
		game.locks[id].queue_free()
		game.locks.erase(id)

class DeleteLockChange extends Change:
	var position:Vector2i
	var id:int
	var doorId:int
	var color:Game.COLOR
	var type:Game.LOCK
	var configuration:Lock.CONFIGURATION
	var sizeType:Lock.SIZE_TYPE
	var count:C

	func _init(_game:Game,lock:Lock) -> void:
		game = _game
		position = lock.position
		id = lock.id
		doorId = lock.doorId
		color = lock.color
		type = lock.type
		configuration = lock.configuration
		sizeType = lock.sizeType
		count = lock.count
		do()

	func do() -> void:
		game.editor.objectHovered = null
		game.editor.objectDragged = null
		game.locks[id].queue_free()
		game.locks.erase(id)
	
	func undo() -> void:
		var lock:Lock = Lock.new(game.doors[doorId])
		lock.position = position
		lock.id = id
		lock.doorId = doorId
		lock.color = color
		lock.type = type
		lock.configuration = configuration
		lock.sizeType = sizeType
		lock.count = count
		game.locks[id] = lock
		game.doors[doorId].add_child(lock)

class PropertyChange extends Change:
	var id:int
	var property:StringName
	var before:Variant
	var after:Variant
	var componentType:GameComponent.TYPES
	
	func _init(_game:Game,component:GameComponent,_property:StringName,_after:Variant) -> void:
		game = _game
		id = component.id
		property = _property
		before = component.get(property)
		after = _after
		if component is KeyBulk: componentType = GameComponent.TYPES.KEY
		elif component is Door: componentType = GameComponent.TYPES.DOOR
		elif component is Lock: componentType = GameComponent.TYPES.LOCK
		if before == after:
			cancelled = true
			return
		do()

	func do() -> void: changeValue(after)
	func undo() -> void: changeValue(before)
	
	func changeValue(value:Variant) -> void:
		var component:GameComponent
		match componentType:
			GameComponent.TYPES.KEY: component = game.keys[id]
			GameComponent.TYPES.DOOR: component = game.doors[id]
			GameComponent.TYPES.LOCK: component = game.locks[id]
		if value is C or value is Q: component.set(property, value.copy())
		else: component.set(property, value)
		if property == &"size" and component is GameObject: component.shape.shape.size = value
		component.changedValue(property,value)
		component.queue_redraw()
		if game.editor.focusDialog.focused == component: game.editor.focusDialog.focus(component, false)
