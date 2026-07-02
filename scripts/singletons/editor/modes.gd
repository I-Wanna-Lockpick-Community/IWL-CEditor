extends HBoxContainer
class_name Modes

@onready var editor:Editor = get_node("/root/editor")

func _setMode(mode:Editor.MODE) -> void:
	if mode == Editor.MODE.OTHER: %other.button_pressed = true
	else: get_child(mode+2).button_pressed = true
	editor.multiselect.deselect()
	editor.mode = mode
	editor.placePreviewWorld.tiles.clear()
	editor.placePreviewWorld.tilesDropShadow.clear()
	for child in editor.placePreviewWorld.objectsParent.get_children(): child.queue_free() 
	match mode:
		Editor.MODE.TILE:
			editor.placePreviewWorld.tiles.set_cell(Vector2.ZERO,1,Vector2i(1,1))
			editor.placePreviewWorld.tilesDropShadow.set_cell(Vector2.ZERO,1,Vector2i(1,1))
		Editor.MODE.KEY:
			editor.placePreviewWorld.objectsParent.add_child(KeyBulk.SCENE.instantiate())
		Editor.MODE.DOOR:
			var door = Door.SCENE.instantiate()
			editor.placePreviewWorld.objectsParent.add_child(door)
			addLock(door)
		Editor.MODE.OTHER:
			var object:GameObject = editor.otherObjects.selected.SCENE.instantiate()
			editor.placePreviewWorld.objectsParent.add_child(object)
			if object is KeyCounter: addElement(object)
			elif object is PlayerSpawn and !Game.levelStart: object.forceDrawStart = true
		Editor.MODE.PASTE:
			for copy in editor.multiselect.clipboard:
				if copy is Multiselect.TileCopy:
						editor.placePreviewWorld.tiles.set_cell(copy.position/32,1,Vector2i(1,1))
						editor.placePreviewWorld.tilesDropShadow.set_cell(copy.position/32,1,Vector2i(1,1))
				elif copy is Multiselect.ObjectCopy:
					var object:GameObject = copy.type.SCENE.instantiate()
					for property in object.PROPERTIES:
						object.set(property, copy.properties[property])
					editor.placePreviewWorld.objectsParent.add_child(object)
					if object is PlayerSpawn and !Game.levelStart: object.forceDrawStart = true
					elif copy is Multiselect.DoorCopy:
						for lockCopy in copy.locks:
							var lock = addLock(object)
							for property in lock.PROPERTIES:
								lock.set(property, lockCopy.properties[property])
					elif copy is Multiselect.KeyCounterCopy:
						for elementCopy in copy.elements:
							var element = addElement(object)
							for property in element.PROPERTIES:
								element.set(property, elementCopy.properties[property])

func addLock(door:Door) -> Lock:
	var lock = Lock.new()
	lock.parent = door
	door.locks.append(lock)
	door.locksParent.add_child(lock)
	return lock

func addElement(keyCounter:KeyCounter) -> KeyCounterElement:
	var element = KeyCounterElement.new()
	element.position = Vector2(12,12+len(keyCounter.elements)*40)
	element.parent = keyCounter
	keyCounter.elements.append(element)
	keyCounter.add_child(element)
	return element
