extends Panel
class_name Multiselect
# also handles copypasting

enum STATE {SELECTING, HOLDING, DRAGGING}

@onready var editor:Editor = get_node("/root/editor")

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
	drawOutline = RenderingServer.canvas_item_create()
	await get_tree().process_frame
	RenderingServer.canvas_item_set_parent(drawTiles, editor.game.get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawOutline, drawTiles)
	RenderingServer.canvas_item_set_modulate(drawOutline, Color("#ffffff66"))
	RenderingServer.canvas_item_set_z_index(drawTiles, 3)

func startSelect() -> void:
	state = STATE.SELECTING
	visible = true
	selected = []
	pivot = get_global_mouse_position()
	continueSelect()

func hold() -> void:
	state = STATE.HOLDING
	visible = false
	if len(selected) > 0:
		selectRect = Rect2(selected[0].position,selected[0].size)
		for select in selected:
			selectRect = selectRect.expand(select.position).expand(select.position+select.size)
	else:
		selectRect = Rect2(Vector2.ZERO, Vector2.ZERO)

func drag() -> void:
	state = STATE.DRAGGING
	dragPosition = editor.mouseTilePosition
	for select in selected: select.startDrag()
	draw()

func stopDrag() -> void:
	state = STATE.HOLDING
	for select in selected: select.endDrag()
	changes.bufferSave()

func continueSelect() -> void:
	var rect:Rect2 = Rect2(pivot,Vector2.ZERO).expand(get_global_mouse_position())
	var worldRect:Rect2 = Rect2(editor.screenspaceToWorldspace(pivot),Vector2.ZERO).expand(editor.screenspaceToWorldspace(get_global_mouse_position()))
	position = rect.position - editor.gameViewportCont.position
	size = rect.size
	selected = []
	# tiles
	for x in range(floor(max(editor.game.levelBounds.position.x,worldRect.position.x)/32), ceil(min(worldRect.end.x,editor.game.levelBounds.end.x)/32)):
		for y in range(floor(max(editor.game.levelBounds.position.y,worldRect.position.y)/32), ceil(min(worldRect.end.y,editor.game.levelBounds.end.y)/32)):
			if editor.game.tiles.get_cell_source_id(Vector2i(x,y)) != -1: selected.append(TileSelect.new(editor,Vector2i(x,y)*32))
	# objects
	for object in editor.game.objectsParent.get_children():
		if Rect2(object.position,object.size).intersects(worldRect):
			selected.append(ObjectSelect.new(editor,object))
	draw()

func continueDrag() -> void:
	var difference:Vector2 = dragPosition - Vector2(editor.mouseTilePosition)
	if difference == Vector2.ZERO: return
	dragPosition = editor.mouseTilePosition
	for select in selected:
		select.position -= difference
		select.continueDrag()
	draw()

func receiveMouseInput(event:InputEventMouse) -> bool:
	if event is InputEventMouseMotion:
		if state == STATE.SELECTING: continueSelect(); return false
		if state == STATE.DRAGGING: continueDrag(); return false
	elif Editor.isLeftClick(event) and state == STATE.HOLDING:
		for select in selected:
			if Rect2i(select.position,select.size).has_point(editor.mouseWorldPosition):
				drag()
				return true
	elif Editor.isLeftUnclick(event):
		if state == STATE.SELECTING: hold(); return true
		if state == STATE.DRAGGING: stopDrag(); return true
	return false

func draw() -> void:
	RenderingServer.canvas_item_clear(drawTiles)
	RenderingServer.canvas_item_clear(drawOutline)
	for select in selected:
		if select is TileSelect:
			RenderingServer.canvas_item_add_texture_rect(drawTiles,Rect2(select.getDrawPosition(),select.size),TileSelect.TEXTURE)
		RenderingServer.canvas_item_add_rect(drawOutline,Rect2(select.getDrawPosition(),select.size),Color.WHITE)

func copySelection() -> void:
	if len(selected) == 0: return
	clipboard = []
	for select in selected:
		if select is TileSelect: clipboard.append(TileCopy.new(select))
		elif select is ObjectSelect:
			if select.object is Door: clipboard.append(DoorCopy.new(select))
			elif select.object is KeyCounter: clipboard.append(KeyCounterCopy.new(select))
			else: clipboard.append(ObjectCopy.new(select))
	# itll only be disabled at the start
	editor.paste.disabled = false

func paste() -> void:
	for copy in clipboard: copy.paste()

func delete() -> void:
	for select in selected:	select.delete()
	selected = []
	draw()
	changes.bufferSave()

func deselect() -> void:
	selected = []
	draw()
	hold()

class Select extends RefCounted:
	# a link to a single thing, selected
	var editor:Editor
	var position:Vector2
	var size:Vector2

	func _init(_editor:Editor, _position:Vector2) -> void:
		editor = _editor
		position = _position
	
	func startDrag() -> void: pass
	func continueDrag() -> void: pass
	func endDrag() -> void: pass

	func getDrawPosition() -> Vector2: return position

	func delete() -> void: pass # delete the thing selected

class TileSelect extends Select:
	const TEXTURE:Texture2D = preload("res://assets/ui/multiselect/tile.png")
	
	func _init(_editor:Editor, _position:Vector2) -> void:
		super(_editor,Vector2i(_position/32)*32)
		size = Vector2(32,32)
	
	func startDrag() -> void:
		changes.addChange(Changes.TileChange.new(editor.game,position/32,false))
	func endDrag() -> void:
		if editor.game.levelBounds.has_point(position): changes.addChange(Changes.TileChange.new(editor.game,position/32,true))

	func delete() -> void: changes.addChange(Changes.TileChange.new(editor.game,position/32,false))

class ObjectSelect extends Select:

	var startingPosition:Vector2
	var object:GameObject

	func _init(_editor:Editor, _object:GameObject) -> void:
		object = _object
		super(_editor, object.position)
		startingPosition = position
		size = object.size
	
	func continueDrag() -> void:
		object.position = position

	func endDrag() -> void:
		object.position = startingPosition
		changes.addChange(Changes.PropertyChange.new(editor.game,object,&"position",position))
	
	func delete() -> void: changes.addChange(Changes.DeleteComponentChange.new(editor.game,object))

class Copy extends RefCounted:
	# a copy of a single thing
	var editor:Editor

class TileCopy extends Copy: # definitely rethink this at some point
	var position:Vector2

	func _init(select:TileSelect) -> void:
		editor = select.editor
		position = select.position - editor.multiselect.selectRect.position
	
	func paste() -> void:
		if editor.game.levelBounds.has_point(Vector2i(position)+editor.mouseTilePosition): changes.addChange(Changes.TileChange.new(editor.game,(Vector2i(position)+editor.mouseTilePosition)/32,true))

class ObjectCopy extends Copy:
	var properties:Dictionary[StringName, Variant]
	var type:GDScript

	func _init(select:ObjectSelect) -> void:
		editor = select.editor
		type = select.object.get_script()

		for property in select.object.EDITOR_PROPERTIES:
			properties[property] = select.object.get(property)
		
		properties[&"position"] -= editor.multiselect.selectRect.position
	
	func paste() -> GameComponent:
		if editor.game.levelBounds.has_point(Vector2i(properties[&"position"])+editor.mouseTilePosition):
			var object:GameObject = changes.addChange(Changes.CreateComponentChange.new(editor.game,type,{&"position":properties[&"position"]+Vector2(editor.mouseTilePosition)})).result
			for property in object.EDITOR_PROPERTIES:
				if property != &"id" and property not in object.CREATE_PARAMETERS:
					changes.addChange(Changes.PropertyChange.new(editor.game,object,property,properties[property]))
			return object
		return null

class DoorCopy extends ObjectCopy:
	var locks:Array[LockCopy]

	func _init(select:ObjectSelect) -> void:
		super(select)
		for lock in select.object.locks:
			locks.append(LockCopy.new(editor,lock))
	
	func paste() -> Door:
		var object:GameObject = super()
		if object:
			for lock in locks:
				lock.paste(object)
		return object
			 
class LockCopy extends Copy:
	var properties:Dictionary[StringName, Variant]

	func _init(_editor,lock:Lock) -> void:
		editor = _editor
		for property in Lock.EDITOR_PROPERTIES:
			properties[property] = lock.get(property)

	func paste(door:Door) -> Lock:
		var lock:Lock = changes.addChange(Changes.CreateComponentChange.new(editor.game,Lock,
			{&"position":properties[&"position"], &"parentId":door.id}
		)).result
		for property in lock.EDITOR_PROPERTIES:
			if property != &"id" and property not in lock.CREATE_PARAMETERS:
				changes.addChange(Changes.PropertyChange.new(editor.game,lock,property,properties[property]))
		return lock

class KeyCounterCopy extends ObjectCopy:
	var elements:Array[KeyCounterElementCopy]

	func _init(select:ObjectSelect) -> void:
		super(select)
		for element in select.object.elements:
			elements.append(KeyCounterElementCopy.new(editor,element))
	
	func paste() -> Door:
		var object:GameObject = super()
		if object:
			for element in elements:
				element.paste(object)
		return object
			 
class KeyCounterElementCopy extends Copy:
	var properties:Dictionary[StringName, Variant]

	func _init(_editor,element:KeyCounterElement) -> void:
		editor = _editor
		for property in KeyCounterElement.EDITOR_PROPERTIES:
			properties[property] = element.get(property)

	func paste(keyCounter:KeyCounter) -> KeyCounterElement:
		var element:KeyCounterElement = changes.addChange(Changes.CreateComponentChange.new(editor.game,KeyCounterElement,
			{&"position":properties[&"position"], &"parentId":keyCounter.id}
		)).result
		for property in element.EDITOR_PROPERTIES:
			if property != &"id" and property not in element.CREATE_PARAMETERS:
				changes.addChange(Changes.PropertyChange.new(editor.game,element,property,properties[property]))
		return element
