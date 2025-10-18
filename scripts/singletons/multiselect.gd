extends Panel
class_name Multiselect
# also handles copypasting

enum STATE {SELECTING, HOLDING, DRAGGING}

@onready var editor:Editor = get_node("/root/editor")

var state:STATE = STATE.HOLDING
var pivot:Vector2
var worldPivot:Vector2
var selected:Array[Select] = []
var dragPosition:Vector2

var drawTiles:RID
var drawOutline:RID # just a highlight for now but ill figure it out maybe

var clipboard:Array[Copy] = []

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
	worldPivot = editor.screenspaceToWorldspace(pivot)
	continueSelect()

func hold() -> void:
	state = STATE.HOLDING
	visible = false

func drag() -> void:
	state = STATE.DRAGGING
	dragPosition = editor.mouseTilePosition
	for select in selected: select.startDrag()
	draw()

func stopDrag() -> void:
	state = STATE.HOLDING
	for select in selected: select.endDrag()
	editor.changes.bufferSave()

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
	for object in editor.game.objects.get_children():
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
	clipboard = []
	for select in selected:
		if select is TileSelect: clipboard.append(TileCopy.new(select))
		elif select is ObjectSelect: clipboard.append(ObjectCopy.new(select))
	print(clipboard)

func paste() -> void:
	for copy in clipboard: copy.paste()

func delete() -> void:
	for select in selected:	select.delete()
	selected = []
	draw()
	editor.changes.bufferSave()

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
		super(_editor,_position)
		size = Vector2(32,32)
	
	func startDrag() -> void:
		editor.changes.addChange(Changes.TileChange.new(editor.game,position/32,false))
	func endDrag() -> void:
		if editor.game.levelBounds.has_point(position): editor.changes.addChange(Changes.TileChange.new(editor.game,position/32,true))

	func getDrawPosition() -> Vector2: return Vector2i(position/32)*32

	func delete() -> void: editor.changes.addChange(Changes.TileChange.new(editor.game,position/32,false))

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
		editor.changes.addChange(Changes.PropertyChange.new(editor.game,object,&"position",position))
	
	func delete() -> void: editor.changes.addChange(Changes.DeleteComponentChange.new(editor.game,object,object.Type))

class Copy extends RefCounted:
	# a copy of a single thing
	var editor:Editor

	func paste() -> void: pass

class TileCopy extends Copy: # definitely rethink this at some point
	var position:Vector2

	func _init(select:TileSelect) -> void:
		editor = select.editor
		position = select.position - editor.multiselect.worldPivot + Vector2(32,32)
	
	func paste() -> void:
		if editor.game.levelBounds.has_point(Vector2i(position)+editor.mouseTilePosition): editor.changes.addChange(Changes.TileChange.new(editor.game,(Vector2i(position)+editor.mouseTilePosition)/32,true))

class ObjectCopy extends Copy:
	var properties:Dictionary[StringName, Variant]

	func _init(select:ObjectSelect) -> void:
		editor = select.editor

		for property in select.object.EDITOR_PROPERTIES:
			properties[property] = select.object.get(property)
		
		properties[&"position"] -= editor.multiselect.worldPivot
