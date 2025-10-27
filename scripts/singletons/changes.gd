extends Node
class_name Changes

var undoStack:Array[RefCounted] = [UndoSeparator.new()]
var stackPosition:int = 0

var saveBuffered:bool = false

# handles the undo system for the editor

func bufferSave() -> void:
	saveBuffered = true

func addChange(change:Change) -> Change:
	if change.cancelled: return null
	if stackPosition != len(undoStack) - 1: undoStack = undoStack.slice(0,stackPosition+1)
	undoStack.append(change)
	stackPosition += 1
	return change

func _process(_delta) -> void:
	if saveBuffered:
		saveBuffered = false
		if undoStack[stackPosition] is UndoSeparator: return # nothing new happened
		undoStack.append(UndoSeparator.new())
		stackPosition += 1

func undo() -> void:
	if stackPosition == 0: return
	if undoStack[stackPosition] is UndoSeparator: stackPosition -= 1
	else:
		assert(stackPosition == len(undoStack)-1) # new changes havent been saved yet
		undoStack.append(UndoSeparator.new()) # [sep] [chg] <[chg]> -> [sep] [chg] <[chg]> [sep]
	saveBuffered = false
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
	elif value is Array: return value.duplicate()
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
	var type:GDScript
	var prop:Dictionary[StringName, Variant] = {}
	var dictionary:Dictionary
	var id:int
	var result:GameComponent

	func _init(_game:Game,_type:GDScript,parameters:Dictionary[StringName, Variant]) -> void:
		game = _game
		type = _type
		
		if type == Lock or type == KeyCounterElement: id = game.componentIdIter; game.componentIdIter += 1
		else: id = game.objectIdIter; game.objectIdIter += 1

		for property in type.CREATE_PARAMETERS:
			prop[property] = Changes.copy(parameters[property])
		
		match type:
			Lock, KeyCounterElement: dictionary = game.components
			_: dictionary = game.objects

		do()
		if type == PlayerSpawn and !game.levelStart:
			changes.addChange(GlobalObjectChange.new(game,game,&"levelStart",result))
		elif type == KeyCounterElement:
			game.objects[prop[&"parentId"]]._elementsChanged()

	func do() -> void:
		var component:GameComponent
		var parent:Node = game.objectsParent
		match type:
			Lock:
				parent = game.objects[prop[&"parentId"]]
				prop[&"index"] = len(parent.locks)
				component = Lock.new(parent,prop[&"index"])
			KeyCounterElement:
				parent = game.objects[prop[&"parentId"]]
				prop[&"index"] = len(parent.elements)
				component = KeyCounterElement.new(parent,prop[&"index"])
			_: component = type.SCENE.instantiate()

		component.id = id
		for property in component.CREATE_PARAMETERS:
			component.set(property, Changes.copy(prop[property]))
			component.propertyChangedDo(property)
		dictionary[id] = component
		
		if type == Lock:
			parent.locks.insert(prop[&"index"], component)
			for lockIndex in range(prop[&"index"]+1, len(game.objects[prop[&"parentId"]].locks)):
				game.objects[prop[&"parentId"]].locks[lockIndex].index += 1
		elif type == KeyCounterElement:
			parent.elements.insert(prop[&"index"], component)
			for elementIndex in range(prop[&"index"]+1, len(game.objects[prop[&"parentId"]].elements)):
				game.objects[prop[&"parentId"]].elements[elementIndex].index += 1
		
		result = component
		parent.add_child(component)

		if parent == game.editor.focusDialog.focused: game.editor.focusDialog.focusComponentAdded(type, prop[&"index"])

		await component.ready
		component.isReady = true
		if game.editor.findProblems: game.editor.findProblems.findProblems(component)

	func undo() -> void:
		game.editor.objectHovered = null
		game.editor.componentDragged = null

		if dictionary[id] is GameObject: game.editor.focusDialog.defocus()
		else: game.editor.focusDialog.defocusComponent()

		var parent:GameObject
		if type == Lock:
			parent = game.objects[prop[&"parentId"]]
			parent.locks.pop_at(prop[&"index"])
			for lockIndex in range(prop[&"index"], len(parent.locks)):
				parent.locks[lockIndex].index -= 1
		elif type == KeyCounterElement:
			parent = game.objects[prop[&"parentId"]]
			parent.elements.pop_at(prop[&"index"])
			for elementIndex in range(prop[&"index"], len(parent.elements)):
				parent.elements[elementIndex].index -= 1

		dictionary[id].queue_free()
		dictionary.erase(id)

		if parent and parent == game.editor.focusDialog.focused: game.editor.focusDialog.focusComponentRemoved(type, prop[&"index"])
	
	func _to_string() -> String:
		return "<CreateComponentChange:"+str(id)+">"

class DeleteComponentChange extends Change: # TODO: FIX LOCKSELECTOR and KEYCOUNTERSELECTOR WITH UNDO/REDO
	var type:GDScript
	var prop:Dictionary[StringName, Variant] = {}
	var dictionary:Dictionary

	func _init(_game:Game,component:GameComponent) -> void:
		type = component.get_script()
		game = _game
		for property in component.EDITOR_PROPERTIES:
			prop[property] = Changes.copy(component.get(property))
		
		match type:
			Lock, KeyCounterElement: dictionary = game.components
			_: dictionary = game.objects
		
		if type == Door:
			for lock in component.locks:
				changes.addChange(DeleteComponentChange.new(game,lock))
		elif type == KeyCounter:
			for element in component.elements:
				changes.addChange(DeleteComponentChange.new(game,element))
		
		do()
		if type == PlayerSpawn and component == game.levelStart:
			changes.addChange(GlobalObjectChange.new(game,game,&"levelStart",null))
		elif type == KeyCounterElement:
			game.objects[prop[&"parentId"]]._elementsChanged()

	func do() -> void:
		game.editor.objectHovered = null
		game.editor.componentDragged = null

		if dictionary[prop[&"id"]] is GameObject: game.editor.focusDialog.defocus()
		else: game.editor.focusDialog.defocusComponent()

		var parent:GameObject
		if type == Lock:
			parent = game.objects[prop[&"parentId"]]
			parent.locks.pop_at(prop[&"index"])
			for lockIndex in range(prop[&"index"], len(parent.locks)):
				parent.locks[lockIndex].index -= 1
		elif type == KeyCounterElement:
			parent = game.objects[prop[&"parentId"]]
			game.objects[prop[&"parentId"]].elements.pop_at(prop[&"index"])
			for elementIndex in range(prop[&"index"], len(parent.elements)):
				parent.elements[elementIndex].index -= 1
		
		dictionary[prop[&"id"]].queue_free()
		dictionary.erase(prop[&"id"])

		if parent and parent == game.editor.focusDialog.focused: game.editor.focusDialog.focusComponentRemoved(type, prop[&"index"])
	
	func undo() -> void:
		var component:Variant
		var parent:Variant = game.objectsParent
		match type:
			Lock:
				parent = game.objects[prop[&"parentId"]]
				component = Lock.new(parent,prop[&"index"])
			KeyCounterElement:
				parent = game.objects[prop[&"parentId"]]
				component = KeyCounterElement.new(parent,prop[&"index"])
			_: component = type.SCENE.instantiate()
		
		for property in component.EDITOR_PROPERTIES:
			component.set(property, Changes.copy(prop[property]))
			component.propertyChangedDo(property)
		dictionary[prop[&"id"]] = component
		
		if type == Lock:
			parent.locks.insert(prop[&"index"], component)
			for lockIndex in range(prop[&"index"]+1, len(parent.locks)):
				parent.locks[lockIndex].index += 1
		elif type == KeyCounterElement:
			parent.elements.insert(prop[&"index"], component)
			for elementIndex in range(prop[&"index"]+1, len(game.objects[prop[&"parentId"]].elements)):
				game.objects[prop[&"parentId"]].elements[elementIndex].index += 1
		
		parent.add_child(component)

		if parent == game.editor.focusDialog.focused: game.editor.focusDialog.focusComponentAdded(type, prop[&"index"])

		await component.ready
		component.isReady = true
		if game.editor.findProblems: game.editor.findProblems.findProblems(component)

	func _to_string() -> String:
		return "<DeleteComponentChange:"+str(prop[&"id"])+">"

class PropertyChange extends Change:
	var id:int
	var property:StringName
	var before:Variant
	var after:Variant
	var type:GDScript
	
	func _init(_game:Game,component:GameComponent,_property:StringName,_after:Variant) -> void:
		game = _game
		id = component.id
		property = _property
		before = Changes.copy(component.get(property))
		after = Changes.copy(_after)
		type = component.get_script()
		if before == after:
			cancelled = true
			return
		do()
		component.propertyChangedInit(property)

	func do() -> void: changeValue(Changes.copy(after))
	func undo() -> void: changeValue(Changes.copy(before))
	
	func changeValue(value:Variant) -> void:
		var component:GameComponent
		match type:
			Lock, KeyCounterElement: component = game.components[id]
			_: component = game.objects[id]
		component.set(property, value)
		component.propertyChangedDo(property)
		component.queue_redraw()
		if game.editor.focusDialog.focused == component: game.editor.focusDialog.focus(component)
		elif game.editor.focusDialog.componentFocused == component: game.editor.focusDialog.focusComponent(component)
	
	func _to_string() -> String:
		return "<PropetyChange:"+str(id)+"."+str(property)+"->"+str(after)+">"

class GlobalObjectChange extends Change:
	# changes a property that points to a gameobject in some singleton; -1 for null

	var singleton:Node
	var property:StringName
	var beforeId:int
	var afterId:int

	func _init(_game:Game, _singleton:Node, _property:StringName, after:GameObject) -> void:
		game =_game
		singleton = _singleton
		property = _property
		if singleton.get(property): beforeId = singleton.get(property).id
		else: beforeId = -1
		if after: afterId = after.id
		else: afterId = -1
		if beforeId == afterId:
			cancelled = true
			return
		do()
	
	func do() -> void: changePointer(afterId)
	func undo() -> void: changePointer(beforeId)

	func changePointer(id:int) -> void:
		if id == -1: singleton.set(property, null)
		else: singleton.set(property, game.objects[id])

		if singleton == game and property == &"levelStart":
			game.editor.topBar.updatePlayButton()

class ArrayAppendChange extends Change:
	# appends to array
	var id:int
	var array:StringName
	var after:Variant
	var dictionary:Dictionary


	func _init(_game:Game,component:GameComponent,_array:StringName,_after:Variant) -> void:
		game = _game
		id = component.id
		after = _after
		array = _array
		match component.get_script():
			Lock: dictionary = game.components
			_: dictionary = game.objects
		do()

	func do() -> void: dictionary[id].get(array).append(after)
	func undo() -> void: dictionary[id].get(array).pop_back()

class ArrayElementChange extends Change:
	# changes element of array
	var id:int
	var array:StringName
	var index:int
	var before:Variant
	var after:Variant
	var dictionary:Dictionary

	func _init(_game:Game,component:GameComponent,_array:StringName,_index:int,_after:Variant) -> void:
		game = _game
		id = component.id
		index = _index
		array = _array
		before = Changes.copy(component.get(array)[index])
		after = Changes.copy(_after)
		match component.get_script():
			Lock: dictionary = game.components
			_: dictionary = game.objects
		do()

	func do() -> void: dictionary[id].get(array)[index] = Changes.copy(after)
	func undo() -> void: dictionary[id].get(array)[index] = Changes.copy(before)

class ArrayPopAtChange extends Change:
	# pops at array index
	var id:int
	var array:StringName
	var index:int
	var before:Variant
	var dictionary:Dictionary


	func _init(_game:Game,component:GameComponent,_array:StringName,_index:int) -> void:
		game = _game
		id = component.id
		array = _array
		index = _index
		before = Changes.copy(component.get(array)[index])
		match component.get_script():
			Lock: dictionary = game.components
			_: dictionary = game.objects
		do()

	func do() -> void: dictionary[id].get(array).pop_at(index)
	func undo() -> void: dictionary[id].get(array).insert(index,Changes.copy(before))
