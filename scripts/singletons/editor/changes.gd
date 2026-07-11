extends Node

var undoStack:Array[RefCounted] = [UndoSeparator.new()]
var stackPosition:int = 0

var saveBuffered:bool = false

# handles the undo system for the editor

func bufferSave() -> void:
	saveBuffered = true

func addChange(change:Change) -> Change:
	if change.cancelled: return null
	Game.anyChanges = true
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
	if Game.editor.componentDragged: Game.editor.stopDrag()
	if stackPosition == 0: return
	Game.anyChanges = true
	if undoStack[stackPosition] is UndoSeparator: stackPosition -= 1
	else:
		assert(stackPosition == len(undoStack)-1) # new Changes havent been saved yet
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

func copy(value:Variant) -> Variant:
	if value is Array: return value.duplicate()
	else: return value

@abstract class Change extends RefCounted:
	var cancelled:bool = false
	# is a singular recorded change
	@abstract func do() -> void
	@abstract func undo() -> void

class UndoSeparator extends RefCounted:
	# indicates the start/end of an undo in the stack
	func _to_string() -> String:
		return "<UndoSeparator>"

class TileChange extends Change:
	var position:Vector2i
	var beforeTile:bool # probably make a tile enum at some point but right now we either have tile or not
	var afterTile:bool # same as above

	func _init(_position:Vector2i,_afterTile:bool) -> void:
		position = _position
		afterTile = _afterTile
		beforeTile = Game.tiles.get_cell_source_id(position) != -1
		if afterTile == beforeTile:
			cancelled = true
			return
		do()

	func do() -> void:
		if afterTile:
			Game.tiles.set_cell(position,1,Vector2i(1,1))
			Game.tilesDropShadow.set_cell(position,1,Vector2i(1,1))
		else:
			Game.tiles.erase_cell(position)
			Game.tilesDropShadow.erase_cell(position)

	func undo() -> void:
		if beforeTile:
			Game.tiles.set_cell(position,1,Vector2i(1,1))
			Game.tilesDropShadow.set_cell(position,1,Vector2i(1,1))
		else:
			Game.tiles.erase_cell(position)
			Game.tilesDropShadow.erase_cell(position)

	func _to_string() -> String:
		return "<TileChange:"+str(position.x)+","+str(position.y)+">"

class CreateComponentChange extends Change:
	var type:GDScript
	var prop:Dictionary[StringName, Variant] = {}
	var dictionary:Dictionary
	var id:int
	var result:GameComponent

	func _init(_type:GDScript,parameters:Dictionary[StringName, Variant]) -> void:
		type = _type
		
		if type in Game.NON_OBJECT_COMPONENTS: id = Game.componentIdIter; Game.componentIdIter += 1
		elif type in Game.NOTE_COMPONENTS: id = Game.noteIdIter; Game.noteIdIter += 1
		else: id = Game.objectIdIter; Game.objectIdIter += 1

		for property in type.CREATE_PARAMETERS:
			prop[property] = Changes.copy(parameters[property])
		
		if type in Game.NON_OBJECT_COMPONENTS: dictionary = Game.components
		elif type in Game.NOTE_COMPONENTS: dictionary = Game.notes
		else: dictionary = Game.objects

		do()
		if type == PlayerSpawn and !Game.levelStart and !parameters.get(&"forceState"):
			Changes.addChange(GlobalObjectChange.new(Game,&"levelStart",result))
		elif type == KeyCounterElement:
			Game.objects[prop[&"parentId"]]._elementsChanged()

	func do() -> void:
		var component:GameComponent
		var parent:Node = Game.notesParent if type in Game.NOTE_COMPONENTS else Game.objectsParent
		if type in Game.NON_OBJECT_COMPONENTS: component = type.new()
		else: component = type.SCENE.instantiate()

		component.editor = Game.editor

		component.id = id
		for property in component.CREATE_PARAMETERS:
			component.set(property, Changes.copy(prop[property]))
			component.propertyChangedDo(property)
		dictionary[id] = component

		if type == Lock:
			parent = Game.objects[prop[&"parentId"]]
			component.parent = parent
			prop[&"index"] = len(parent.locks)
			component.index = prop[&"index"]
			parent.locks.insert(prop[&"index"], component)
			parent.add_child(component)
			parent.reindexLocks()
		elif type == KeyCounterElement:
			parent = Game.objects[prop[&"parentId"]]
			component.parent = parent
			prop[&"index"] = len(parent.elements)
			parent.elements.insert(prop[&"index"], component)
			parent.add_child(component)
			parent.reindexElements()
		else: parent.add_child(component)

		result = component
		if parent == Game.editor.focusDialog.focused: Game.editor.focusDialog.focusHandlerAdded(type, prop[&"index"])

		await component.ready
		component.isReady = true
		if Game.editor.findProblems: Game.editor.findProblems.findProblems(component)

	func undo() -> void:
		Game.editor.objectHovered = null
		Game.editor.componentDragged = null

		if dictionary[id] == Game.editor.focusDialog.focused: Game.editor.focusDialog.defocus()
		elif dictionary[id] == Game.editor.focusDialog.componentFocused: Game.editor.focusDialog.defocusComponent()

		var parent:GameObject
		if type == Lock:
			parent = Game.objects[prop[&"parentId"]]
			parent.locks.pop_at(prop[&"index"])
			parent.reindexLocks()
		elif type == KeyCounterElement:
			parent = Game.objects[prop[&"parentId"]]
			parent.elements.pop_at(prop[&"index"])
			parent.reindexElements()

		if Game.editor.findProblems: Game.editor.findProblems.componentRemoved(dictionary[id])

		dictionary[id].queue_free()
		dictionary.erase(id)

		if parent and parent == Game.editor.focusDialog.focused: Game.editor.focusDialog.focusHandlerRemoved(type, prop[&"index"])
	
	func _to_string() -> String:
		return "<CreateComponentChange:"+str(id)+">"

class DeleteComponentChange extends Change:
	var type:GDScript
	var prop:Dictionary[StringName, Variant] = {}
	var dictionary:Dictionary
	var arrays:Dictionary[StringName, Array] = {} # dictionary[property, array]
	var componentArrays:Dictionary[StringName, Array] = {} # dictionary[property, array]

	func _init(component:GameComponent) -> void:
		if component is PlayerPlaceholderObject:
			component.delete()
			cancelled = true
			return

		type = component.get_script()

		if type == Door:
			for lock in component.locks.duplicate():
				Changes.addChange(DeleteComponentChange.new(lock))
		elif type == KeyCounter:
			for element in component.elements.duplicate():
				Changes.addChange(DeleteComponentChange.new(element))
		

		for property in Saving.FILE_VERSION.typeDefs[type].savedProperties:
			prop[property] = Changes.copy(component.get(property))
		for array in Saving.FILE_VERSION.typeDefs[type].savedArrays:
			arrays[array] = component.get(array).map(Changes.copy)
		for array in Saving.FILE_VERSION.typeDefs[type].savedComponentArrays:
			componentArrays[array] = Saving.componentArrayToIDs(component.get(array))

		if component.get_script() in Game.NON_OBJECT_COMPONENTS: dictionary = Game.components
		elif type in Game.NOTE_COMPONENTS: dictionary = Game.notes
		else: dictionary = Game.objects

		if type == PlayerSpawn and component == Game.levelStart:
			Changes.addChange(GlobalObjectChange.new(Game,&"levelStart",null))
		
		component.deletedInit()
		do()
		if type == KeyCounterElement:
			Game.objects[prop[&"parentId"]]._elementsChanged()

	func do() -> void:
		Game.editor.objectHovered = null
		Game.editor.componentDragged = null

		if dictionary[prop[&"id"]] == Game.editor.focusDialog.focused: Game.editor.focusDialog.defocus()
		elif dictionary[prop[&"id"]] == Game.editor.focusDialog.componentFocused: Game.editor.focusDialog.defocusComponent()

		var parent:GameObject
		if type == Lock:
			parent = Game.objects[prop[&"parentId"]]
			parent.locks.pop_at(prop[&"index"])
			parent.reindexLocks()
		elif type == KeyCounterElement:
			parent = Game.objects[prop[&"parentId"]]
			parent.elements.pop_at(prop[&"index"])
			parent.reindexElements()
		
		if Game.editor.findProblems: Game.editor.findProblems.componentRemoved(dictionary[prop[&"id"]])

		dictionary[prop[&"id"]].queue_free()
		dictionary.erase(prop[&"id"])

		if parent and parent == Game.editor.focusDialog.focused: Game.editor.focusDialog.focusHandlerRemoved(type, prop[&"index"])
	
	func undo() -> void:
		var component:Variant
		var parent:Variant = Game.notesParent if type in Game.NOTE_COMPONENTS else Game.objectsParent
		if type in Game.NON_OBJECT_COMPONENTS: component = type.new()
		else: component = type.SCENE.instantiate()
		
		component.editor = Game.editor

		for property in Saving.FILE_VERSION.typeDefs[type].savedProperties:
			component.set(property, Changes.copy(prop[property]))
			component.propertyChangedDo(property)
		for array in Saving.FILE_VERSION.typeDefs[type].savedArrays:
			component.get(array).assign(arrays[array].map(Changes.copy))
		for array in Saving.FILE_VERSION.typeDefs[type].savedComponentArrays:
			var arrayType:GDScript = Saving.FILE_VERSION.typeDefs[type].savedComponentArrays[array]
			component.get(array).assign(Saving.IDArraytoComponents(arrayType, componentArrays[array]))
		dictionary[prop[&"id"]] = component
		
		if type == Lock:
			parent = Game.objects[prop[&"parentId"]]
			component.parent = parent
			component.index = prop[&"index"]
			parent.locks.insert(prop[&"index"], component)
			parent.add_child(component)
			parent.reindexLocks()
		elif type == KeyCounterElement:
			parent = Game.objects[prop[&"parentId"]]
			component.parent = parent
			parent.elements.insert(prop[&"index"], component)
			parent.add_child(component)
			parent.reindexElements()
		else: parent.add_child(component)

		if parent == Game.editor.focusDialog.focused: Game.editor.focusDialog.focusHandlerAdded(type, prop[&"index"])

		await component.ready
		component.isReady = true
		if Game.editor.findProblems: Game.editor.findProblems.findProblems(component)

	func _to_string() -> String:
		return "<DeleteComponentChange:"+str(prop[&"id"])+">"

class PropertyChange extends Change:
	var id:int
	var property:StringName
	var before:Variant
	var after:Variant
	var type:GDScript
	
	func _init(component:GameComponent,_property:StringName,_after:Variant,fromInput:Control=null) -> void:
		if component is PlayerPlaceholderObject:
			component.set(_property, _after)
			component.propertyChangedDo(_property)
			cancelled = true
			return
		id = component.id
		property = _property
		before = Changes.copy(component.get(property))
		after = Changes.copy(_after)
		type = component.get_script()
		if before == after:
			cancelled = true
			return
		if fromInput: Game.editor.focusDialog.bufferSkipInput = fromInput
		do()
		component.propertyChangedInit(property)

	func do() -> void: changeValue(Changes.copy(after))
	func undo() -> void: changeValue(Changes.copy(before))
	
	func changeValue(value:Variant) -> void:
		var component:GameComponent
		if type in Game.NON_OBJECT_COMPONENTS: component = Game.components[id]
		elif type in Game.NOTE_COMPONENTS: component = Game.notes[id]
		else: component = Game.objects[id]
		if value is Array: component.get(property).assign(value)
		else: component.set(property, value)
		component.propertyChangedDo(property)
		component.queue_redraw()
		if Game.editor.focusDialog.focused == component: Game.editor.focusDialog.bufferFocusObject = true
		if Game.editor.focusDialog.componentFocused == component: Game.editor.focusDialog.bufferFocusComponent = true
		if Game.editor.findProblems: Game.editor.findProblems.findProblems(component)
	
	func _to_string() -> String:
		return "<PropertyChange:"+str(id)+"."+str(property)+"->"+str(after)+">"

class GlobalObjectChange extends Change:
	# Changes a property that points to a Gameobject in some singleton; -1 for null

	var singleton:Node
	var property:StringName
	var beforeId:int
	var afterId:int

	func _init(_singleton:Node, _property:StringName, after:GameObject) -> void:
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
		else: singleton.set(property, Game.objects[id])

		if singleton == Game and property == &"levelStart":
			Game.editor.topBar._updateButtons()
			var toRedraw:PlayerSpawn
			if beforeId != -1: toRedraw = Game.objects.get(beforeId)
			if toRedraw: toRedraw.queue_redraw()
			if afterId != -1: toRedraw = Game.objects[afterId]
			if toRedraw: toRedraw.queue_redraw()

	func _to_string() -> String:
		return "<GlobalObjectChange:"+str(singleton)+"."+str(property)+"->"+str(afterId)+">"

class GlobalPropertyChange extends Change:
	# Changes a property in some singleton

	var singleton:Variant
	var property:StringName
	var before:Variant
	var after:Variant

	func _init(_singleton:Variant, _property:StringName, _after:Variant) -> void:
		singleton = _singleton
		property = _property
		before = singleton.get(property)
		after = _after
		if before == after:
			cancelled = true
			return
		do()

	func do() -> void: singleton.set(property, after); check()
	func undo() -> void: singleton.set(property, before); check()

	func check() -> void:
		if singleton is Mods.Mod and property == &"active": Mods.bufferModsChanged()

	func _to_string() -> String:
		return "<GlobalPropertyChange:"+str(singleton)+"."+str(property)+"->"+str(after)+">"

class ArrayAppendChange extends Change:
	# appends to array
	var id:int
	var array:StringName
	var after:Variant
	var dictionary:Dictionary

	func _init(component:GameComponent,_array:StringName,_after:Variant) -> void:
		id = component.id
		after = _after
		array = _array
		if component.get_script() in Game.NON_OBJECT_COMPONENTS: dictionary = Game.components
		elif component.get_script() in Game.NOTE_COMPONENTS: dictionary = Game.notes
		else: dictionary = Game.objects
		do()

	func do() -> void: dictionary[id].get(array).append(after); dictionary[id].queue_redraw()
	func undo() -> void: dictionary[id].get(array).pop_back(); dictionary[id].queue_redraw()

	func _to_string() -> String:
		return "<ArrayAppendChange:"+str(id)+"."+str(array)+"+="+str(after)+">"

class ArrayElementChange extends Change:
	# Changes element of array
	var id:int
	var array:StringName
	var index:int
	var before:Variant
	var after:Variant
	var dictionary:Dictionary

	func _init(component:GameComponent,_array:StringName,_index:int,_after:Variant,fromInput:Control=null) -> void:
		id = component.id
		index = _index
		array = _array
		before = Changes.copy(component.get(array)[index])
		after = Changes.copy(_after)
		if before == after:
			cancelled = true
			return
		if component.get_script() in Game.NON_OBJECT_COMPONENTS: dictionary = Game.components
		elif component.get_script() in Game.NOTE_COMPONENTS: dictionary = Game.notes
		else: dictionary = Game.objects
		if fromInput: Game.editor.focusDialog.bufferSkipInput = fromInput
		do()

	func do() -> void: changeValue(after)
	func undo() -> void: changeValue(before)

	func changeValue(toValue:Variant) -> void:
		var component:GameComponent = dictionary[id]
		dictionary[id].get(array)[index] = Changes.copy(toValue)
		if Game.editor.focusDialog.focused == component:
			Game.editor.focusDialog.focus(component)
		elif Game.editor.focusDialog.componentFocused == component: Game.editor.focusDialog.focusComponent(component)
		if Game.editor.findProblems: Game.editor.findProblems.findProblems(component)
		dictionary[id].queue_redraw()

	func _to_string() -> String:
		return "<ArrayElementChange:"+str(id)+"."+str(array)+"."+str(index)+"->"+str(after)+">"

class ArrayPopAtChange extends Change:
	# pops at array index
	var id:int
	var array:StringName
	var index:int
	var before:Variant
	var dictionary:Dictionary

	func _init(component:GameComponent,_array:StringName,_index:int) -> void:
		id = component.id
		array = _array
		index = _index
		before = Changes.copy(component.get(array)[index])
		if component.get_script() in Game.NON_OBJECT_COMPONENTS: dictionary = Game.components
		elif component.get_script() in Game.NOTE_COMPONENTS: dictionary = Game.notes
		else: dictionary = Game.objects
		do()

	func do() -> void: dictionary[id].get(array).pop_at(index); dictionary[id].queue_redraw()
	func undo() -> void: dictionary[id].get(array).insert(index,Changes.copy(before)); dictionary[id].queue_redraw()

	func _to_string() -> String:
		return "<ArrayPopAtChange:"+str(id)+"."+str(array)+"-="+str(index)+">"

class ComponentArrayAppendChange extends Change:
	# appends to array of components
	var id:int
	var array:StringName
	var afterId:int
	var dictionary:Dictionary
	var elementDictionary:Dictionary
	var elementType:GDScript
	var index:int

	func _init(component:GameComponent,_array:StringName,after:GameComponent) -> void:
		id = component.id
		afterId = after.id
		array = _array
		elementType = after.get_script()
		if component.get_script() in Game.NON_OBJECT_COMPONENTS: dictionary = Game.components
		elif component.get_script() in Game.NOTE_COMPONENTS: dictionary = Game.notes
		else: dictionary = Game.objects
		if elementType in Game.NON_OBJECT_COMPONENTS: elementDictionary = Game.components
		elif elementType in Game.NOTE_COMPONENTS: elementDictionary = Game.notes
		else: elementDictionary = Game.objects
		index = len(component.get(array))
		do()

	func do() -> void:
		dictionary[id].get(array).append(elementDictionary[afterId])
		if dictionary[id] == Game.editor.focusDialog.focused or dictionary[id] == Game.editor.focusDialog.componentFocused:
			Game.editor.focusDialog.focusHandlerAdded(elementType, index)
		dictionary[id].queue_redraw()
	func undo() -> void:
		dictionary[id].get(array).pop_back()
		if dictionary[id] == Game.editor.focusDialog.focused or dictionary[id] == Game.editor.focusDialog.componentFocused:
			Game.editor.focusDialog.focusHandlerRemoved(elementType, index)
		dictionary[id].queue_redraw()

	func _to_string() -> String:
		return "<ComponentArrayAppendChange:"+str(id)+"."+str(array)+"+="+str(afterId)+">"

class ComponentArrayElementChange extends Change:
	# Changes element of array of components
	var id:int
	var array:StringName
	var index:int
	var beforeId:int
	var afterId:int
	var dictionary:Dictionary
	var elementDictionary:Dictionary

	func _init(component:GameComponent,_array:StringName,_index:int,after:GameComponent) -> void:
		id = component.id
		index = _index
		array = _array
		beforeId = component.get(array)[index].id
		afterId = after.id
		if component.get_script() in Game.NON_OBJECT_COMPONENTS: dictionary = Game.components
		elif component.get_script() in Game.NOTE_COMPONENTS: dictionary = Game.notes
		else: dictionary = Game.objects
		if after.get_script() in Game.NON_OBJECT_COMPONENTS: elementDictionary = Game.components
		elif after.get_script() in Game.NOTE_COMPONENTS: elementDictionary = Game.notes
		else: elementDictionary = Game.objects
		do()

	func do() -> void: dictionary[id].get(array)[index] = elementDictionary[afterId]; dictionary[id].queue_redraw()
	func undo() -> void: dictionary[id].get(array)[index] = elementDictionary[beforeId]; dictionary[id].queue_redraw()

	func _to_string() -> String:
		return "<ComponentArrayElementChange:"+str(id)+"."+str(array)+"."+str(index)+"->"+str(afterId)+">"

class ComponentArrayPopAtChange extends Change:
	# pops at array of components index
	var id:int
	var array:StringName
	var index:int
	var beforeId:int
	var dictionary:Dictionary
	var elementDictionary:Dictionary
	var elementType:GDScript

	func _init(component:GameComponent,_array:StringName,_index:int) -> void:
		id = component.id
		array = _array
		index = _index
		beforeId = component.get(array)[index].id
		elementType = component.get(array)[index].get_script()
		if component.get_script() in Game.NON_OBJECT_COMPONENTS: dictionary = Game.components
		elif component.get_script() in Game.NOTE_COMPONENTS: dictionary = Game.notes
		else: dictionary = Game.objects
		if elementType in Game.NON_OBJECT_COMPONENTS: elementDictionary = Game.components
		elif elementType in Game.NOTE_COMPONENTS: elementDictionary = Game.notes
		else: elementDictionary = Game.objects
		do()

	func do() -> void:
		dictionary[id].get(array).pop_at(index)
		if dictionary[id] == Game.editor.focusDialog.focused or dictionary[id] == Game.editor.focusDialog.componentFocused:
			Game.editor.focusDialog.focusHandlerRemoved(elementType, index)
		dictionary[id].queue_redraw()
	
	func undo() -> void:
		dictionary[id].get(array).insert(index,elementDictionary[beforeId])
		if dictionary[id] == Game.editor.focusDialog.focused or dictionary[id] == Game.editor.focusDialog.componentFocused:
			Game.editor.focusDialog.focusHandlerAdded(elementType, index)
		dictionary[id].queue_redraw()

	func _to_string() -> String:
		return "<ComponentArrayPopAtChange:"+str(id)+"."+str(array)+"-="+str(index)+">"

class LevelResizeChange extends Change:
	var before:Rect2
	var after:Rect2

	func _init(_after:Rect2) -> void:
		before = Game.levelBounds
		after = _after
		if before == after:
			cancelled = true
			return
		do()
	
	func do() -> void:
		Game.level.position = after.position
		Game.level.size = after.size
	
	func undo() -> void:
		Game.level.position = before.position
		Game.level.size = before.size
	
	func _to_string() -> String:
		return "<LeveLResizeChange:"+str(before)+"->"+str(after)+">"

class ComponentConvertNumberChange extends Change:
	var id:int
	var dictionary:Dictionary
	var before:PackedInt64Array
	var property:StringName
	var from:M.SYSTEM

	func _init(component:GameComponent, _from:M.SYSTEM, _property:StringName) -> void:
		id = component.id
		if component.get_script() in Game.NON_OBJECT_COMPONENTS: dictionary = Game.components
		elif component.get_script() in Game.NOTE_COMPONENTS: dictionary = Game.notes
		else: dictionary = Game.objects
		from = _from
		property = _property
		before = Changes.copy(component.get(property))
		do()
	
	func do() -> void: dictionary[id].set(property, M.convert(before, from))
	func undo() -> void: dictionary[id].set(property, before)
	
	func _to_string() -> String:
		return "<ComponentConvertNumberChange:"+str(before)+","+str(from)+">"

class ComponentConvertNumberArrayChange extends Change:
	var id:int
	var dictionary:Dictionary
	var before:Array[PackedInt64Array]
	var array:StringName
	var from:M.SYSTEM

	func _init(component:GameComponent, _from:M.SYSTEM, _array:StringName) -> void:
		id = component.id
		if component.get_script() in Game.NON_OBJECT_COMPONENTS: dictionary = Game.components
		elif component.get_script() in Game.NOTE_COMPONENTS: dictionary = Game.notes
		else: dictionary = Game.objects
		from = _from
		array = _array
		before = Changes.copy(component.get(array))
		do()
	
	func do() -> void: dictionary[id].get(array).assign(before.map(func(number): return M.convert(number, from)))
	func undo() -> void: dictionary[id].get(array).assign(before)
	
	func _to_string() -> String:
		return "<ComponentConvertNumberArrayChange:"+str(before)+","+str(from)+">"

class ConvertNumberChange extends Change:
	var singleton:Variant
	var before:PackedInt64Array
	var property:StringName
	var from:M.SYSTEM

	func _init(_singleton:Variant, _from:M.SYSTEM, _property:StringName) -> void:
		singleton = _singleton
		from = _from
		property = _property
		before = Changes.copy(singleton.get(property))
		do()
	
	func do() -> void: singleton.set(property, M.convert(before, from))
	func undo() -> void: singleton.set(property, before)
	
	func _to_string() -> String:
		return "<ComponentConvertNumberChange:"+str(before)+","+str(from)+">"

class ConvertNumberArrayChange extends Change:
	var singleton:Variant
	var before:Array[PackedInt64Array]
	var array:StringName
	var from:M.SYSTEM

	func _init(_singleton:Variant, _from:M.SYSTEM, _array:StringName) -> void:
		singleton = _singleton
		from = _from
		array = _array
		before = Changes.copy(singleton.get(array))
		do()
	
	func do() -> void: singleton.get(array).assign(before.map(func(number): return M.convert(number, from)))
	func undo() -> void: singleton.get(array).assign(before)
	
	func _to_string() -> String:
		return "<ConvertNumberArrayChange:"+str(before)+","+str(from)+">"

class NumberEditNumberChange extends Change:
	var numberEdit:NumberEdit
	var number:int
	var array:StringName
	var before:Variant
	var after:Variant

	## you still need to build the text manually afterwards
	func _init(_numberEdit:NumberEdit, _number:int, _array:StringName, _after:Variant) -> void:
		numberEdit = _numberEdit
		number = _number
		array = _array
		before = numberEdit.get(array)[number]
		after = _after
		do(false)
	
	func do(build:bool=true) -> void:
		numberEdit.get(array)[number] = after
		if build: numberEdit.buildText()
	
	func undo() -> void:
		numberEdit.get(array)[number] = before
		numberEdit.buildText()

## more expensive than a number change, since we have to parse the text
class NumberEditTextChange extends Change:
	var numberEdit:NumberEdit
	var before:String
	var after:String

	## dont parse if this is immediately followed by another text change
	func _init(_numberEdit:NumberEdit, _after:String, parse:bool=true) -> void:
		numberEdit = _numberEdit
		before = numberEdit.text
		after = _after
		do(parse)
		if parse: numberEdit.evaluate()
	
	func do(parse:bool=true) -> void:
		numberEdit.text = after
		if parse:
			numberEdit.parseText(true)
			numberEdit.buildText()
	
	func undo() -> void:
		numberEdit.text = before
		numberEdit.parseText(true)
		numberEdit.buildText()
