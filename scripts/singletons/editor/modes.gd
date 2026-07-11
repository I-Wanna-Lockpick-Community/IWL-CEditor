extends HBoxContainer
class_name Modes

@onready var otherObjects:OtherObjects = %otherObjects
@onready var paste:Button = %paste

const VIEW_HEIGHT:float = 40

const MODES_BY_VIEW:Array[Array] = [
	[Editor.MODE.TILE, Editor.MODE.KEY, Editor.MODE.DOOR, Editor.MODE.OTHER],
	[Editor.MODE.PENCILMARK]
]
@onready var MODE_BUTTONS_BY_VIEW:Array[Array] = [
	[%tile, %key, %door, %other],
	[%pencilmark]
]

func _ready() -> void:
	for view in Editor.VIEWS:
		%viewDots.add_child(ViewDot.new(view))

func _process(delta: float) -> void:
	%modesVerticalContainer.position.y += (-VIEW_HEIGHT*Game.editor.view - %modesVerticalContainer.position.y) * min(delta*10, 1)
	for view in Editor.VIEWS:
		var opacity:float = (1 - abs(view + %modesVerticalContainer.position.y/VIEW_HEIGHT)) ** 4
		for button in MODE_BUTTONS_BY_VIEW[view]: button.hotkeyOpacity = opacity

func _setMode(mode:Editor.MODE) -> void:
	Game.editor.multiselect.deselect()
	Game.editor.mode = mode
	Game.editor.placePreviewWorld.tiles.clear()
	Game.editor.placePreviewWorld.tilesDropShadow.clear()
	for child in Game.editor.placePreviewWorld.objectsParent.get_children(): child.queue_free() 
	setView(MODES_BY_VIEW.find_custom(func(a:Array)->bool:return a.has(mode)))
	match mode:
		Editor.MODE.SELECT:
			%select.button_pressed = true
		Editor.MODE.TILE:
			%tile.button_pressed = true
			Game.editor.placePreviewWorld.tiles.set_cell(Vector2.ZERO,1,Vector2i(1,1))
			Game.editor.placePreviewWorld.tilesDropShadow.set_cell(Vector2.ZERO,1,Vector2i(1,1))
		Editor.MODE.KEY:
			%key.button_pressed = true
			Game.editor.placePreviewWorld.objectsParent.add_child(KeyBulk.SCENE.instantiate())
		Editor.MODE.DOOR:
			%door.button_pressed = true
			var door = Door.SCENE.instantiate()
			Game.editor.placePreviewWorld.objectsParent.add_child(door)
			addLock(door)
		Editor.MODE.OTHER:
			%other.button_pressed = true
			var object:GameObject = otherObjects.selected.SCENE.instantiate()
			Game.editor.placePreviewWorld.objectsParent.add_child(object)
			if object is KeyCounter: addElement(object)
			elif object is PlayerSpawn and !Game.levelStart: object.forceDrawStart = true
		Editor.MODE.PASTE:
			%paste.button_pressed = true
			for copy in Game.editor.multiselect.clipboard:
				if copy is Multiselect.TileCopy:
						Game.editor.placePreviewWorld.tiles.set_cell(copy.position/32,1,Vector2i(1,1))
						Game.editor.placePreviewWorld.tilesDropShadow.set_cell(copy.position/32,1,Vector2i(1,1))
				elif copy is Multiselect.ObjectCopy:
					var object:GameObject = copy.type.SCENE.instantiate()
					for property in Saving.FILE_VERSION.typeDefs[copy.type].savedProperties:
						object.set(property, copy.properties[property])
					Game.editor.placePreviewWorld.objectsParent.add_child(object)
					if object is PlayerSpawn and !Game.levelStart: object.forceDrawStart = true
					elif copy is Multiselect.DoorCopy:
						for lockCopy in copy.locks:
							var lock = addLock(object)
							for property in Saving.FILE_VERSION.typeDefs[lock.get_script()].savedProperties:
								lock.set(property, lockCopy.properties[property])
					elif copy is Multiselect.KeyCounterCopy:
						for elementCopy in copy.elements:
							var element = addElement(object)
							for property in Saving.FILE_VERSION.typeDefs[element.get_script()].savedProperties:
								element.set(property, elementCopy.properties[property])
		Editor.MODE.PENCILMARK:
			%pencilmark.button_pressed = true

func previousView() -> void: setView(posmod(Game.editor.view-1,Editor.VIEWS))
func nextView() -> void: setView(posmod(Game.editor.view+1,Editor.VIEWS))

func setView(view:Editor.VIEW) -> void:
	if view == -1: return
	if view == Game.editor.view: return
	%viewDots.get_child(view).modulate.a = 1
	%viewDots.get_child(Game.editor.view).modulate.a = 0.5
	Game.editor.view = view
	var modeView:int = MODES_BY_VIEW.find_custom(func(a:Array)->bool:return a.has(Game.editor.mode))
	if modeView != -1 and modeView != view:
		_setMode(MODES_BY_VIEW[view][min(MODES_BY_VIEW[modeView].find(Game.editor.mode), len(MODES_BY_VIEW[view])-1)])

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

class ViewDot extends TextureRect:
	var view:Editor.VIEW

	func _init(_view:Editor.VIEW) -> void:
		view = _view
		stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture = preload("res://assets/ui/modes/dot.png")
		modulate.a = 1 if view == Editor.VIEW.NORMAL else 0.5
