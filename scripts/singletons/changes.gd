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

static func copy(value:Variant) -> Variant:
	if value is C || value is Q: return value.copy()
	else: return value

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
		return "<TileChange:"+str(position.x)+","+str(position.y)+">"

class CreateComponentChange extends Change:
	var type:Variant
	var prop:Dictionary[StringName, Variant] = {}
	var dictionary:Dictionary
	var id:int
	var result:GameComponent

	func _init(_game:Game,_type:Variant,parameters:Dictionary[StringName, Variant]) -> void:
		game = _game
		type = _type
		
		if type == Lock: id = game.lockIdIter; game.lockIdIter += 1
		else: id = game.objIdIter; game.objIdIter += 1

		for property in type.CREATE_PARAMETERS:
			prop[property] = Changes.copy(parameters[property])
		
		match type:
			KeyBulk: dictionary = game.keys
			Door: dictionary = game.doors
			Lock: dictionary = game.locks
		do()
	
	func do() -> void:
		var component:Variant
		var parent:Variant = game.objects
		match type:
			KeyBulk: component = preload("res://scenes/objects/keyBulk.tscn").instantiate()
			Door: component = preload("res://scenes/objects/door.tscn").instantiate()
			Lock:
				parent = game.doors[prop[&"doorId"]]
				prop[&"index"] = len(parent.locks)
				component = Lock.new(parent,prop[&"index"])
		
		component.id = id
		for property in component.CREATE_PARAMETERS:
			component.set(property, Changes.copy(prop[property]))
		dictionary[id] = component
		
		if type == Lock:
			parent.locks.insert(prop[&"index"], component)
			for lockIndex in range(prop[&"index"]+1, len(game.doors[prop[&"doorId"]].locks)):
				game.doors[prop[&"doorId"]].locks[lockIndex].index += 1
		
		result = component
		parent.add_child(component)

	func undo() -> void:
		game.editor.objectHovered = null
		game.editor.componentDragged = null

		if dictionary[id] is GameObject: game.editor.focusDialog.defocus()
		else: game.editor.focusDialog.defocusComponent()

		if type == Lock:
			game.doors[prop[&"doorId"]].locks.pop_at(prop[&"index"])
			for lockIndex in range(prop[&"index"], len(game.doors[prop[&"doorId"]].locks)):
				game.doors[prop[&"doorId"]].locks[lockIndex].index -= 1
		
		dictionary[id].queue_free()
		dictionary.erase(id)
	
	func _to_string() -> String:
		return "<CreateComponentChange:"+str(id)+">"

class DeleteComponentChange extends Change:
	var type:Variant
	var prop:Dictionary[StringName, Variant] = {}
	var dictionary:Dictionary

	func _init(_game:Game,component:GameComponent,_type:Variant) -> void:
		type = _type
		game = _game
		for property in component.EDITOR_PROPERTIES:
			prop[property] = Changes.copy(component.get(property))
		
		match type:
			KeyBulk: dictionary = game.keys
			Door: dictionary = game.doors
			Lock: dictionary = game.locks
		do()

	func do() -> void:
		game.editor.objectHovered = null
		game.editor.componentDragged = null

		if dictionary[prop[&"id"]] is GameObject: game.editor.focusDialog.defocus()
		else: game.editor.focusDialog.defocusComponent()

		if type == Lock:
			game.doors[prop[&"doorId"]].locks.pop_at(prop[&"index"])
			for lockIndex in range(prop[&"index"], len(game.doors[prop[&"doorId"]].locks)):
				game.doors[prop[&"doorId"]].locks[lockIndex].index -= 1
		
		dictionary[prop[&"id"]].queue_free()
		dictionary.erase(prop[&"id"])
	
	func undo() -> void:
		var component:Variant
		var parent:Variant = game.objects
		match type:
			KeyBulk: component = preload("res://scenes/objects/keyBulk.tscn").instantiate()
			Door: component = preload("res://scenes/objects/door.tscn").instantiate()
			Lock:
				parent = game.doors[prop[&"doorId"]]
				component = Lock.new(parent,prop[&"index"])
		
		for property in component.EDITOR_PROPERTIES:
			component.set(property, Changes.copy(prop[property]))
		dictionary[prop[&"id"]] = component
		
		if type == Lock:
				parent.locks.insert(prop[&"index"], component)
				for lockIndex in range(prop[&"index"]+1, len(parent.locks)):
					parent.locks[lockIndex].index += 1
		
		parent.add_child(component)
	
	func _to_string() -> String:
		return "<DeleteComponentChange:"+str(prop[&"id"])+">"

class PropertyChange extends Change:
	var id:int
	var property:StringName
	var before:Variant
	var after:Variant
	var componentType:GameComponent.COMPONENT
	
	func _init(_game:Game,component:GameComponent,_property:StringName,_after:Variant) -> void:
		game = _game
		id = component.id
		property = _property
		before = component.get(property)
		after = _after
		if component is KeyBulk: componentType = GameComponent.COMPONENT.KEY
		elif component is Door: componentType = GameComponent.COMPONENT.DOOR
		elif component is Lock: componentType = GameComponent.COMPONENT.LOCK
		if before == after:
			cancelled = true
			return
		do()

	func do() -> void: changeValue(after)
	func undo() -> void: changeValue(before)
	
	func changeValue(value:Variant) -> void:
		var component:GameComponent
		match componentType:
			GameComponent.COMPONENT.KEY: component = game.keys[id]
			GameComponent.COMPONENT.DOOR: component = game.doors[id]
			GameComponent.COMPONENT.LOCK: component = game.locks[id]
		if value is C or value is Q: component.set(property, value.copy())
		else: component.set(property, value)
		if property == &"size" and component is GameObject: component.shape.shape.size = value
		component.queue_redraw()
		if game.editor.focusDialog.focused == component: game.editor.focusDialog.focus(component)
		elif game.editor.focusDialog.componentFocused == component: game.editor.focusDialog.focusComponent(component)
	
	func _to_string() -> String:
		return "<PropetyChange:"+str(id)+"."+str(property)+"->"+str(after)+">"
