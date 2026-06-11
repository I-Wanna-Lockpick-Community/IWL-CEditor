extends Node
class_name LoadV1toCurrent

static var COMPONENTS:Array[GDScript] = [Lock, KeyCounterElement, KeyBulk, Door, Goal, KeyCounter, PlayerSpawn, FloatingTile, RemoteLock]
static var NON_OBJECT_COMPONENTS:Array[GDScript] = [Lock, KeyCounterElement]

static var BASE_PROPERTIES:Dictionary[GDScript,Array] = {
	Lock: [
		&"id", &"position", &"size",
		&"parentId", &"color", &"type", &"sizeType", &"count", &"configuration", &"zeroI", &"isPartial", &"denominator", &"negated", &"armament",
		&"index", &"displayIndex"
	],
	KeyCounterElement: [
		&"id", &"position", &"size",
		&"parentId", &"color",
		&"index"
	],
	KeyBulk: [
		&"id", &"position", &"size",
		&"color", &"type", &"count", &"infinite", &"un"
	],
	Door: [
		&"id", &"position", &"size",
		&"colorSpend", &"copies", &"infCopies", &"type",
		&"frozen", &"crumbled", &"painted"
	],
	Goal: [
		&"id", &"position", &"size",
		&"type"
	],
	KeyCounter: [
		&"id", &"position", &"size",
	],
	PlayerSpawn: [
		&"id", &"position", &"size", &"undoStack", &"saveBuffered"
	],
	FloatingTile: [
		&"id", &"position", &"size",
	],
	RemoteLock: [
		&"id", &"position", &"size",
		&"color", &"type", &"configuration", &"sizeType", &"count", &"zeroI", &"isPartial", &"denominator", &"negated", &"armament",
		&"frozen", &"crumbled", &"painted"
	]
}
static var BASE_ARRAYS:Dictionary[GDScript,Dictionary] = {
	Lock: {},
	KeyCounterElement: {},
	KeyBulk: {},
	Door: {&"remoteLocks":RemoteLock},
	Goal: {},
	KeyCounter: {},
	PlayerSpawn: {&"key":TYPE_PACKED_INT64_ARRAY,&"star":TYPE_BOOL,&"curse":TYPE_BOOL},
	FloatingTile: {},
	RemoteLock: {&"doors":Door},
}

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

static func loadFile(file:FileAccess, formatVersion:int) -> void:
	var PROPERTIES:Dictionary[GDScript,Array] = BASE_PROPERTIES.duplicate(true)
	var ARRAYS:Dictionary[GDScript, Dictionary] = BASE_ARRAYS.duplicate(true)
	# format version 2 is v1.0.18
	if formatVersion > 1:
		PROPERTIES.get(KeyBulk).insert(7, &"glistening")
		ARRAYS.get(PlayerSpawn)[&"glisten"] = TYPE_PACKED_INT64_ARRAY
	# format version 3 is v1.1.0
	if formatVersion > 2:
		PROPERTIES.get(KeyBulk).append_array([&"altColor", &"operation"])
	# LEVEL DATA
	# tiles
	Game.tiles.tile_map_data = file.get_var()
	Game.tilesDropShadow.tile_map_data = Game.tiles.tile_map_data
	# components
	Game.componentIdIter = file.get_64()
	var componentBufferedArrays:Dictionary[int,Dictionary] = {} # dictionary[object id, dictionary[property name, array]]
	for _i in file.get_64():
		var type:GDScript = COMPONENTS[file.get_16()]
		var component = type.new()
		if Game.editor: component.editor = Game.editor
		for property in PROPERTIES[type]:
			var value = file.get_var(true)
			if property == &"id":
				Game.components[value] = component
			component.set(property, value)
			component.propertyChangedDo(property)
		for array in ARRAYS[type].keys():
			componentBufferedArrays[component.id][array] = file.get_var() # handle it at the end; not all components will be ready
	# objects
	Game.objectIdIter = file.get_64()
	var objectBufferedArrays:Dictionary[int,Dictionary] = {} # dictionary[object id, dictionary[property name, array]]
	var otherBuffers:Array[Array] # array[component, property name, value]
	for _i in file.get_64():
		var type:GDScript = COMPONENTS[file.get_16()]
		var object = type.SCENE.instantiate()
		if Game.editor: object.editor = Game.editor
		for property in PROPERTIES[type]:
			var value = file.get_var(true)
			if property == &"id":
				Game.objects[value] = object
				Game.objectsParent.add_child(object)
			if type == PlayerSpawn and property == &"undoStack" and value: otherBuffers.append([object, property, value])
			else: object.set(property, value)
			object.propertyChangedDo(property)
		objectBufferedArrays[object.id] = {}
		for array in ARRAYS[type].keys():
			objectBufferedArrays[object.id][array] = file.get_var() # handle it at the end
		if type == Door:
			object.locks.assign(Saving.IDArraytoComponents(Lock, file.get_var()))
			for lock in object.locks:
				lock.parent = object
				object.add_child(lock)
			object.reindexLocks()
		if type == KeyCounter:
			object.elements.assign(Saving.IDArraytoComponents(KeyCounterElement, file.get_var()))
			for element in object.elements:
				element.parent = object
				object.add_child(element)
	
	for componentId in componentBufferedArrays.keys():
		var component:GameComponent = Game.components[componentId]
		for array in ARRAYS[component.get_script()]:
			var value:Array = componentBufferedArrays[componentId][array]
			var arrayType = ARRAYS[component.get_script()][array]
			if Saving.arrayTypeIsComponent(arrayType): value = Saving.IDArraytoComponents(arrayType,value)
			component.get(array).assign(value)

	for objectId in objectBufferedArrays.keys():
		var object:GameObject = Game.objects[objectId]
		for array in ARRAYS[object.get_script()]:
			var value:Array = objectBufferedArrays[objectId][array]
			var arrayType = ARRAYS[object.get_script()][array]
			if Saving.arrayTypeIsComponent(arrayType): value = Saving.IDArraytoComponents(arrayType,value)
			object.get(array).assign(value)

	for buffer in otherBuffers:
		if buffer[0] is PlayerSpawn and buffer[1] == &"undoStack": buffer[0].undoStack.assign(buffer[2].build())

	#if levelStart != -1:
	#	Game.levelStart = Game.objects[levelStart]
	#	if Game.editor: Game.editor.topBar._updateButtons()
	
	Game.updateWindowName()
	if Game.editor:
		Game.editor.settingsMenu.opened()
	Game.get_tree().call_group("modUI", "changedMods")
