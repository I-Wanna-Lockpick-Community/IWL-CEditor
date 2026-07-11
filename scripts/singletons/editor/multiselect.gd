extends Panel
class_name Multiselect
# also handles copypasting

enum STATE {SELECTING, HOLDING, DRAGGING}

var state:STATE = STATE.HOLDING
var pivot:Vector2
var selected:Array[Select] = []
var dragPosition:Vector2

var drawTiles:RID
var drawOutline:RID # just a highlight for now but ill figure it out maybe

var clipboard:Array[Copy] = []

var selectRect:Rect2

func _ready() -> void:
	drawTiles = RenderingServer.canvas_item_create()
	await Game.editor.ready
	drawOutline = Game.editor.outlineViewport1.createChild()
	RenderingServer.canvas_item_set_parent(drawTiles, Game.world.get_canvas_item())
	RenderingServer.canvas_item_set_z_index(drawTiles, -1)

func startSelect() -> void:
	pivot = Game.editor.mouseWorldPosition
	state = STATE.SELECTING
	visible = true
	selected = []
	continueSelect()

func hold() -> void:
	state = STATE.HOLDING
	visible = false
	if len(selected) > 0:
		if len(selected) == 1 and selected[0] is ObjectSelect:
			Game.editor.focusDialog.focus(selected[0].object)
			return deselect()
		selectRect = Rect2(selected[0].position,selected[0].size)
		for select in selected:
			selectRect = selectRect.expand(select.position).expand(select.position+select.size)
	else:
		selectRect = Rect2(Vector2.ZERO, Vector2.ZERO)

func drag() -> void:
	state = STATE.DRAGGING
	dragPosition = Game.editor.mouseTilePosition
	for select in selected: select.startDrag()
	draw()

func stopDrag() -> void:
	state = STATE.HOLDING
	Game.editor.mouse_default_cursor_shape = CURSOR_ARROW
	for select in selected: select.endDrag()
	Changes.bufferSave()

func continueSelect() -> void:
	var rect:Rect2 = Rect2(pivot,Vector2.ZERO).expand(Game.editor.mouseWorldPosition)
	position = Game.editor.worldspaceToScreenspace(rect.position) - Game.editor.gameCont.position
	size = Game.editor.worldspaceToScreenspace(rect.end) - position - Game.editor.gameCont.position
	selected = []
	# tiles
	if Game.editor.tilesInView():
		for x in range(floor(rect.position.x/32), ceil(rect.end.x/32)):
			for y in range(floor(rect.position.y/32), ceil(rect.end.y/32)):
				if Game.tiles.get_cell_source_id(Vector2i(x,y)) != -1: selected.append(TileSelect.new(Vector2i(x,y)*32))
	# objects
	for object in Game.editor.objectsInView():
		if Rect2(object.getDrawPosition(),object.size).intersects(rect):
			selected.append(ObjectSelect.new(object))
	draw()

func continueDrag() -> void:
	var difference:Vector2 = dragPosition - Vector2(Game.editor.mouseTilePosition)
	if difference == Vector2.ZERO: return
	dragPosition = Game.editor.mouseTilePosition
	for select in selected:
		select.position -= difference
		select.continueDrag()
	draw()

func update() -> void:
	if state == STATE.SELECTING: continueSelect()
	elif state == STATE.DRAGGING: continueDrag()
	else: draw()

func receiveMouseInput(event:InputEventMouse) -> bool:
	if event is InputEventMouseMotion:
		update()
		return false
	elif Editor.isLeftClick(event) and state == STATE.HOLDING:
		for select in selected:
			if Rect2i(select.position,select.size).has_point(Game.editor.mouseWorldPosition):
				drag()
				return true
	elif Editor.isLeftUnclick(event):
		if state == STATE.SELECTING: hold(); return true
		if state == STATE.DRAGGING: stopDrag(); return true
	return false

func draw() -> void: # cant be _draw since panel already has a _draw or something
	RenderingServer.canvas_item_clear(drawTiles)
	RenderingServer.canvas_item_clear(drawOutline)
	for select in selected:
		# because tiles are removed when you drag them
		if select is TileSelect: RenderingServer.canvas_item_add_texture_rect(drawTiles,Rect2(select.getDrawPosition(),select.getDrawSize()),TileSelect.TEXTURE)
		
		if select is ObjectSelect and select.object.get_script() not in Game.RECTANGLE_COMPONENTS:
			RenderingServer.canvas_item_add_texture_rect(drawOutline,Rect2(select.getDrawPosition(),select.getDrawSize()),select.object.outlineTex(),false,Color.RED)
		else: RenderingServer.canvas_item_add_rect(drawOutline,Rect2(select.getDrawPosition(),select.getDrawSize()),Color.RED)

func copySelection() -> void:
	if len(selected) == 0:
		if Game.editor.focusDialog.focused:
			selectRect.position = Game.editor.focusDialog.focused.position
			selected.assign([ObjectSelect.new(Game.editor.focusDialog.focused)])
		else: return
	clipboard = []
	for select in selected:
		if select is TileSelect: clipboard.append(TileCopy.new(select))
		elif select is ObjectSelect and select.object is not PlayerPlaceholderObject: clipboard.append(createObjectCopy(select.object))
	# itll only be disabled at the start
	if clipboard: Game.editor.modes.paste.disabled = false

func createObjectCopy(object:GameObject) -> ObjectCopy:
	# KeyBulk, Door, Goal, KeyCounter, PlayerSpawn, FloatingTile, RemoteLock
	match object.get_script():
		Door: return DoorCopy.new(object)
		KeyCounter: return KeyCounterCopy.new(object)
		_: return ObjectCopy.new(object)

func paste() -> void:
	for copy in clipboard: copy.paste()

func delete() -> void:
	for select in selected:	select.delete()
	selected = []
	draw()
	Changes.bufferSave()

func deselect() -> void:
	selected = []
	draw()
	hold()

func redrawClipboard() -> void:
	for copy in clipboard: copy.draw()

class Select extends RefCounted:
	# a link to a single thing, selected
	var position:Vector2
	var size:Vector2

	func _init(_position:Vector2) -> void:
		position = _position
	
	func startDrag() -> void: pass
	func continueDrag() -> void: pass
	func endDrag() -> void: pass

	func getDrawPosition() -> Vector2: return position
	func getDrawSize() -> Vector2: return size

	func delete() -> void: pass # delete the thing selected

class TileSelect extends Select:
	const TEXTURE:Texture2D = preload("res://assets/ui/multiselect/tile.png")
	
	func _init(_position:Vector2) -> void:
		super(Vector2i(_position/32)*32)
		size = Vector2(32,32)
	
	func startDrag() -> void:
		Changes.addChange(Changes.TileChange.new(position/32,false))
	func endDrag() -> void:
		Changes.addChange(Changes.TileChange.new(pos(),true))

	func getDrawPosition() -> Vector2: return pos()*32

	func delete() -> void: Changes.addChange(Changes.TileChange.new(pos(),false))

	func pos() -> Vector2i:
		if Mods.active(&"OutOfBounds"): return position/32
		return position.clamp(Game.levelBounds.position, Game.levelBounds.end-Vector2i(32,32))/32

class ObjectSelect extends Select:

	var startingPosition:Vector2
	var object:GameObject

	func _init(_object:GameObject) -> void:
		object = _object
		super(object.position)
		startingPosition = position
		size = object.size
	
	func continueDrag() -> void:
		object.position = pos()
		if object is PlayerPlaceholderObject: object.propertyChangedDo(&"position")
		if object is RemoteLock: object.queue_redraw()
		if object is Door: for lock in object.remoteLocks: lock.queue_redraw()

	func endDrag() -> void:
		object.position = startingPosition
		Changes.addChange(Changes.PropertyChange.new(object,&"position",pos()))
		startingPosition = object.position
	
	func delete() -> void: Changes.addChange(Changes.DeleteComponentChange.new(object))

	func getDrawPosition() -> Vector2:
		return pos()-object.getOffset()

	func getDrawSize() -> Vector2: return object.getDrawSize()

	func pos() -> Vector2:
		if Mods.active(&"OutOfBounds"): return position
		var rect:Rect2 = Rect2(position, size).grow(-1)
		if object is RemoteLock or object is PlayerPlaceholderObject: rect.position -= object.getOffset()
		return position + Editor.snappedAway(Vector2.ZERO.max(Vector2(Game.levelBounds.position) - rect.end) - Vector2.ZERO.max(rect.position - Vector2(Game.levelBounds.end)), Vector2(Game.editor.tileSize))

@abstract class Copy extends RefCounted:
	# a copy of a single thing
	pass

class TileCopy extends Copy: # definitely rethink this at some point
	var position:Vector2

	func _init(select:TileSelect) -> void:
		position = select.position - Game.editor.multiselect.selectRect.position

	func paste() -> void:
		@warning_ignore("integer_division")
		if Game.levelBounds.has_point(Vector2i(position)+Game.editor.mouseTilePosition): Changes.addChange(Changes.TileChange.new((Vector2i(position)+Game.editor.mouseTilePosition)/32,true))

class ObjectCopy extends Copy:
	var properties:Dictionary[StringName, Variant]
	var type:GDScript

	func _init(object:GameObject) -> void:
		type = object.get_script()

		for property in Saving.FILE_VERSION.typeDefs[type].savedProperties:
			properties[property] = object.get(property)
		
		properties[&"position"] -= Game.editor.multiselect.selectRect.position
	
	func paste() -> GameComponent:
		if Game.levelBounds.has_point(Vector2i(properties[&"position"])+Game.editor.mouseTilePosition):
			var object:GameObject = Changes.addChange(Changes.CreateComponentChange.new(type,{&"position":properties[&"position"]+Vector2(Game.editor.mouseTilePosition)})).result
			for property in Saving.FILE_VERSION.typeDefs[type].savedProperties:
				if property != &"id" and property not in object.CREATE_PARAMETERS:
					Changes.addChange(Changes.PropertyChange.new(object,property,properties[property]))
			return object
		return null

class DoorCopy extends ObjectCopy:
	var locks:Array[LockCopy]

	func _init(object:Door) -> void:
		super(object)
		for lock in object.locks:
			locks.append(LockCopy.new(lock))
		draw()
	
	func paste() -> Door:
		var object:GameObject = super()
		if object:
			for lock in locks:
				lock.paste(object)
		return object

	func draw() -> void: pass

class LockCopy extends Copy:
	var properties:Dictionary[StringName, Variant]

	func _init(lock:Lock) -> void:
		for property in Saving.FILE_VERSION.typeDefs[lock.get_script()].savedProperties:
			properties[property] = lock.get(property)

	func paste(door:Door) -> Lock:
		var lock:Lock = Changes.addChange(Changes.CreateComponentChange.new(Lock,
			{&"position":properties[&"position"], &"parentId":door.id}
		)).result
		for property in Saving.FILE_VERSION.typeDefs[lock.get_script()].savedProperties:
			if property != &"id" and property not in lock.CREATE_PARAMETERS:
				Changes.addChange(Changes.PropertyChange.new(lock,property,properties[property]))
		return lock

class KeyCounterCopy extends ObjectCopy:
	var elements:Array[KeyCounterElementCopy]

	func _init(object:KeyCounter) -> void:
		super(object)
		for element in object.elements:
			elements.append(KeyCounterElementCopy.new(element))

	func paste() -> Door:
		var object:GameObject = super()
		if object:
			for element in elements:
				element.paste(object)
		return object

class KeyCounterElementCopy extends Copy:
	var properties:Dictionary[StringName, Variant]

	func _init(element:KeyCounterElement) -> void:
		for property in Saving.FILE_VERSION.typeDefs[element.get_script()].savedProperties:
			properties[property] = element.get(property)

	func paste(keyCounter:KeyCounter) -> KeyCounterElement:
		var element:KeyCounterElement = Changes.addChange(Changes.CreateComponentChange.new(KeyCounterElement,
			{&"position":properties[&"position"], &"parentId":keyCounter.id}
		)).result
		for property in Saving.FILE_VERSION.typeDefs[element.get_script()].savedProperties:
			if property != &"id" and property not in element.CREATE_PARAMETERS:
				Changes.addChange(Changes.PropertyChange.new(element,property,properties[property]))
		return element
