extends Node
class_name LoadV1toCurrent

const TEST_PRINTING:bool = false

# LEVEL METADATA:
# - level name
# - level description
# - level author
# - level size
# - active mods
# - modpack
# - modpack version
# LEVEL DATA:
# - tiles
# - components
# - objects

# TODO: move keybulk un

static func loadFile(file:FileAccess, fileVersion:FileVersion) -> void:
	# LEVEL DATA
	# tiles
	Game.tiles.tile_map_data = getVar(file, "tile map data")
	Game.tilesDropShadow.tile_map_data = Game.tiles.tile_map_data
	# components
	Game.componentIdIter = file.get_64()
	var componentBufferedArrays:Dictionary[int,Dictionary] = {} # dictionary[object id, dictionary[property name, array]]
	for _i in file.get_64():
		var type:GDScript = fileVersion.componentTypes[file.get_16()]
		var component = type.new()
		if Game.editor: component.editor = Game.editor
		var typeDef:ComponentTypeDef = fileVersion.typeDefs[type]
		for property in typeDef.savedProperties:
			var value = migrateProperty(getVar(file, "comprop %s %s" % [type, property], true), component, property, fileVersion)
			if property == &"id":
				Game.components[value] = component
			if value is Array: component.get(property).assign(value)
			else: component.set(property, value)
			component.propertyChangedDo(property)
		for array in typeDef.savedArrays: component.get(array).assign(getVar(file, "comarray %s %s" % [type, array]))
		# handle it at the end; not all referenced components will be ready
		for array in typeDef.savedComponentArrays: componentBufferedArrays[component.id][array] = getVar(file, "comcomarray %s %s" % [type, array])
	# objects
	Game.objectIdIter = file.get_64()
	var objectBufferedArrays:Dictionary[int,Dictionary] = {} # dictionary[object id, dictionary[property name, array]]
	for _i in file.get_64():
		var type:GDScript = fileVersion.componentTypes[file.get_16()]
		var object = type.SCENE.instantiate()
		if Game.editor: object.editor = Game.editor
		var typeDef:ComponentTypeDef = fileVersion.typeDefs[type]
		for property in typeDef.savedProperties:
			var value = migrateProperty(getVar(file, "objprop %s %s" % [type, property], true), object, property, fileVersion)
			if property == &"id":
				Game.objects[value] = object
				Game.objectsParent.add_child(object)
			if value is Array: object.get(property).assign(value)
			else: object.set(property, value)
			object.propertyChangedDo(property)
		objectBufferedArrays[object.id] = {}
		for array in typeDef.savedArrays: object.get(array).assign(getVar(file, "objarray %s %s" % [type, array]))
		# handle it at the end; not all referenced components will be ready
		for array in typeDef.savedComponentArrays: objectBufferedArrays[object.id][array] = getVar(file, "objcomarray %s %s" % [type, array])
	
	var noteBufferedArrays:Dictionary[int,Dictionary] = {} # dictionary[note id, dictionary[property name, array]]
	if fileVersion.version >= 3:
		Game.noteIdIter = file.get_64()
		for _i in file.get_64():
			var type:GDScript = fileVersion.componentTypes[file.get_16()]
			var note = type.SCENE.instantiate()
			if Game.editor: note.editor = Game.editor
			var typeDef:ComponentTypeDef = fileVersion.typeDefs[type]
			for property in typeDef.savedProperties:
				var value = migrateProperty(getVar(file, "notprop %s %s" % [type, property], true), note, property, fileVersion)
				if property == &"id":
					Game.notes[value] = note
					Game.notesParent.add_child(note)
				if value is Array: note.get(property).assign(value)
				else: note.set(property, value)
				note.propertyChangedDo(property)
			noteBufferedArrays[note.id] = {}
			for array in typeDef.savedArrays: note.get(array).assign(getVar(file, "notarray %s %s" % [type, array]))
			# handle it at the end; not all referenced components will be ready
			for array in typeDef.savedComponentArrays: noteBufferedArrays[note.id][array] = getVar(file, "notcomarray %s %s" % [type, array])
	
	handleBufferedArrays(fileVersion, componentBufferedArrays, Game.components)
	handleBufferedArrays(fileVersion, objectBufferedArrays, Game.objects)
	handleBufferedArrays(fileVersion, noteBufferedArrays, Game.notes)

	#if levelStart != -1:
	#	Game.levelStart = Game.objects[levelStart]
	#	if Game.editor: Game.editor.topBar._updateButtons()
	
	Game.updateWindowName()
	if Game.editor:
		Game.editor.settingsMenu.opened()
	Game.get_tree().call_group("modUI", "changedMods")

static func handleBufferedArrays(fileVersion:FileVersion, bufferedArrays:Dictionary[int,Dictionary], dictionary:Dictionary) -> void:
	for componentId in bufferedArrays.keys():
		var component:GameComponent = dictionary[componentId]
		var typeDef:ComponentTypeDef = fileVersion.typeDefs[component.get_script()]
		for array in typeDef.savedComponentArrays:
			var value:Array = bufferedArrays[componentId][array]
			var arrayType = typeDef.savedComponentArrays[array]
			component.get(array).assign(Saving.IDArraytoComponents(arrayType,value))
			if component is Door and array == &"locks":
				for lock in component.locks:
					lock.parent = component
					component.add_child(lock)
				component.reindexLocks()
			elif component is KeyCounter and array == &"elements":
				for element in component.elements:
					element.parent = component
					component.add_child(element)

static func getVar(file:FileAccess, reason:String, allowObjects:bool=false):
	var value = file.get_var(allowObjects)
	if TEST_PRINTING: print(reason, value)
	return value

static func migrateProperty(value, component:GameComponent, property:StringName, fileVersion:FileVersion):
	if fileVersion.version < 3 and component is PlayerSpawn and property == &"undoStack": return migrateSerialisedUndoStack(value) if value else []
	elif fileVersion.version < 3 and component is KeyBulk and property == &"boolType": return int(value)
	else: return value

static func migrateSerialisedUndoStack(stack:SerialisedUndoStack) -> Array[Array]:
	for change in stack.serialisedStack:
		if change[0] == GameChanges.PropertyChange: change[1] = Lock if change[1] else Door # lie because we arent doing anything with it anyway
	return stack.serialisedStack
