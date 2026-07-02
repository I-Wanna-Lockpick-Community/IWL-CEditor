extends HBoxContainer
class_name Modes

func _setMode(mode:Editor.MODE) -> void:
	if mode == Editor.MODE.OTHER: %other.button_pressed = true
	else: get_child(mode+2).button_pressed = true
	Game.editor.multiselect.deselect()
	Game.editor.mode = mode
	Game.editor.placePreviewWorld.tiles.clear()
	Game.editor.placePreviewWorld.tilesDropShadow.clear()
	for child in Game.editor.placePreviewWorld.objectsParent.get_children(): child.queue_free() 
	match mode:
		Editor.MODE.TILE:
			Game.editor.placePreviewWorld.tiles.set_cell(Vector2.ZERO,1,Vector2i(1,1))
			Game.editor.placePreviewWorld.tilesDropShadow.set_cell(Vector2.ZERO,1,Vector2i(1,1))
		Editor.MODE.KEY:
			Game.editor.placePreviewWorld.objectsParent.add_child(KeyBulk.SCENE.instantiate())
		Editor.MODE.DOOR:
			var door = Door.SCENE.instantiate()
			Game.editor.placePreviewWorld.objectsParent.add_child(door)
			addLock(door)
		Editor.MODE.OTHER:
			var object:GameObject = Game.editor.otherObjects.selected.SCENE.instantiate()
			Game.editor.placePreviewWorld.objectsParent.add_child(object)
			if object is KeyCounter: addElement(object)
			elif object is PlayerSpawn and !Game.levelStart: object.forceDrawStart = true
		Editor.MODE.PASTE:
			for copy in Game.editor.multiselect.clipboard:
				if copy is Multiselect.TileCopy:
						Game.editor.placePreviewWorld.tiles.set_cell(copy.position/32,1,Vector2i(1,1))
						Game.editor.placePreviewWorld.tilesDropShadow.set_cell(copy.position/32,1,Vector2i(1,1))
				elif copy is Multiselect.ObjectCopy:
					var object:GameObject = copy.type.SCENE.instantiate()
					for property in object.PROPERTIES:
						object.set(property, copy.properties[property])
					Game.editor.placePreviewWorld.objectsParent.add_child(object)
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
