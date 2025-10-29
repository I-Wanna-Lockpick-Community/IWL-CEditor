extends Control
class_name Editor

@onready var game:Game = %game
@onready var modes:Modes = %modes
@onready var gameViewportCont:SubViewportContainer = %gameViewportCont
@onready var focusDialog:FocusDialog = %focusDialog
@onready var quickSet:QuickSet = %quickSet
@onready var multiselect:Multiselect = %multiselect
@onready var paste:Button = %paste
@onready var otherObjects:OtherObjects = %otherObjects
@onready var topBar:TopBar = %topBar
var findProblems:FindProblems

enum MODE {SELECT, TILE, KEY, DOOR, OTHER, PASTE}
var mode:MODE = MODE.SELECT

var mouseWorldPosition:Vector2
var mouseTilePosition:Vector2i

var targetCameraZoom:float = 1
var zoomPoint:Vector2 # the point where the latest zoom was targetted

var objectHovered:GameObject
var componentHovered:GameComponent # you can hover both a door and a lock at the same time so

enum DRAG_MODE {POSITION, SIZE_FDIAG, SIZE_BDIAG, SIZE_VERT, SIZE_HORIZ}
enum SIZE_DRAG_PIVOT {TOP_LEFT, TOP, TOP_RIGHT, LEFT, RIGHT, BOTTOM_LEFT, BOTTOM, BOTTOM_RIGHT, NONE}
var componentDragged:GameComponent
var dragMode:DRAG_MODE
var dragOffset:Vector2 # the offset for position dragging
var dragPivotRect:Rect2 # the pivot for size dragging
var previousDragPosition:Vector2i # to check whether or not a drag would do anything

var tileSize:Vector2i = Vector2i(32,32)

var cameraZoom:float = 1

func _process(_delta) -> void:
	queue_redraw()
	var scaleFactor:float = (targetCameraZoom/game.editorCamera.zoom.x)**0.2
	if abs(scaleFactor - 1) < 0.0001:
		game.editorCamera.zoom = Vector2(targetCameraZoom,targetCameraZoom)
		if targetCameraZoom == 1: game.editorCamera.position = round(game.editorCamera.position)
	else:
		game.editorCamera.zoom *= scaleFactor
		game.editorCamera.position += (1-1/scaleFactor) * (worldspaceToScreenspace(zoomPoint)-gameViewportCont.position) / game.editorCamera.zoom
	
	if Input.is_key_pressed(KEY_ALT): tileSize = Vector2i(1,1)
	elif Input.is_key_pressed(KEY_CTRL): tileSize = Vector2i(16,16)
	else: tileSize = Vector2i(32,32)

	mouseWorldPosition = screenspaceToWorldspace(get_global_mouse_position())
	mouseTilePosition = Vector2i(mouseWorldPosition) / tileSize * tileSize
	if game.playState == Game.PLAY_STATE.PLAY: gameViewportCont.material.set_shader_parameter("mousePosition",Vector2(-1e7,-1e7)) # probably far away enough
	else: gameViewportCont.material.set_shader_parameter("mousePosition",mouseWorldPosition)
	gameViewportCont.material.set_shader_parameter("screenPosition",screenspaceToWorldspace(Vector2.ZERO))
	if game.playState == Game.PLAY_STATE.PLAY: cameraZoom = game.playCamera.zoom.x
	else: cameraZoom = game.editorCamera.zoom.x
	gameViewportCont.material.set_shader_parameter("rCameraZoom",1/cameraZoom)
	gameViewportCont.material.set_shader_parameter("tileSize",tileSize)
	componentHovered = null
	if !componentDragged:
		objectHovered = null
		for object in game.objectsParent.get_children():
			if mode == MODE.SELECT or (mode == MODE.KEY and object is KeyBulk) or (mode == MODE.DOOR and object is Door) or (mode == MODE.OTHER and object.get_script() == otherObjects.selected):
				if Rect2(object.position, object.size).has_point(mouseWorldPosition):
					objectHovered = object
		if focusDialog.focused is Door:
			for lock in focusDialog.focused.locks:
				if Rect2(lock.getDrawPosition(), lock.size).has_point(mouseWorldPosition):
					componentHovered = lock
		elif focusDialog.focused is KeyCounter:
			for element in focusDialog.focused.elements:
				if Rect2(element.getDrawPosition(), element.getHoverSize()).has_point(mouseWorldPosition):
					componentHovered = element

	game.tiles.z_index = 3 if mode == MODE.TILE and game.playState != Game.PLAY_STATE.PLAY else 0

func _gui_input(event:InputEvent) -> void:
	if event is InputEventMouse:
		if game.playState == Game.PLAY_STATE.PLAY:
			pass
		else:
			# move camera
			if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
				game.editorCamera.position -= event.relative / cameraZoom
			if event is InputEventMouseButton and event.is_pressed():
				match event.button_index:
					MOUSE_BUTTON_WHEEL_UP: zoomCamera(1.25)
					MOUSE_BUTTON_WHEEL_DOWN: zoomCamera(0.8)
			# modes
			if isLeftUnclick(event) or isRightUnclick(event):
				if componentDragged and sizeDragging():
					if !mods.active(&"NstdLockSize") and componentDragged is Lock and componentDragged.parent.type != Door.TYPE.SIMPLE:
						componentDragged._coerceSize()
					if componentDragged is GameObject: focusDialog.focus(componentDragged)
					else: focusDialog.focusComponent(componentDragged)
				changes.bufferSave()
				componentDragged = null
			# set mouse cursor
			if multiselect.state == Multiselect.STATE.DRAGGING: mouse_default_cursor_shape = CURSOR_DRAG
			elif componentDragged:
				match dragMode:
					DRAG_MODE.POSITION: mouse_default_cursor_shape = CURSOR_DRAG
					DRAG_MODE.SIZE_FDIAG, DRAG_MODE.SIZE_BDIAG:
						pass
						var diffSign:Vector2 = rectSign(dragPivotRect, Vector2(mouseTilePosition))
						match diffSign:
							Vector2(-1,-1), Vector2(0,0), Vector2(1,1): mouse_default_cursor_shape = CURSOR_FDIAGSIZE
							Vector2(-1,1), Vector2(1,-1): mouse_default_cursor_shape = CURSOR_BDIAGSIZE
							Vector2(-1,0), Vector2(1,0): mouse_default_cursor_shape = CURSOR_HSIZE
							Vector2(0,-1), Vector2(0,1): mouse_default_cursor_shape = CURSOR_VSIZE
					DRAG_MODE.SIZE_VERT: mouse_default_cursor_shape = CURSOR_VSIZE
					DRAG_MODE.SIZE_HORIZ: mouse_default_cursor_shape = CURSOR_HSIZE
			else: mouse_default_cursor_shape = CURSOR_ARROW
			# multiselect
			if multiselect.receiveMouseInput(event): return
			elif multiselect.state == Multiselect.STATE.HOLDING and isLeftClick(event): multiselect.deselect()
			# size drag handles
			if focusDialog.componentFocused is Lock and focusDialog.focused.type != Door.TYPE.SIMPLE:
				if focusDialog.componentFocused.receiveMouseInput(event): return
			elif objectHovered:
				if objectHovered.receiveMouseInput(event): return
			# dragging
			if componentDragged and dragComponent(): return
			# other
			match mode:
				MODE.SELECT:
					if isLeftClick(event): # if youre hovering something and you leftclick, focus it
						if componentHovered:
							focusDialog.focusComponent(componentHovered)
						else: focusDialog.defocusComponent()
						if componentHovered is Lock and componentHovered.parent.type != Door.TYPE.SIMPLE: startPositionDrag(componentHovered)
						elif componentHovered is KeyCounterElement: startPositionDrag(componentHovered)
						elif objectHovered: startPositionDrag(objectHovered)
						else:
							focusDialog.defocus()
							multiselect.startSelect()
				MODE.TILE:
					if game.levelBounds.has_point(mouseWorldPosition):
						if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
							changes.addChange(Changes.TileChange.new(game,mouseTilePosition/32,true))
							focusDialog.defocus()
						elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
							changes.addChange(Changes.TileChange.new(game,mouseTilePosition/32,false))
							focusDialog.defocus()
				MODE.KEY:
					if isLeftClick(event): # if youre hovering a key and you leftclick, focus it
						if objectHovered is KeyBulk:
							startPositionDrag(objectHovered)
						else: focusDialog.defocus()
					if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
						if objectHovered is not KeyBulk and game.levelBounds.has_point(mouseWorldPosition):
							var key:KeyBulk = changes.addChange(Changes.CreateComponentChange.new(game,KeyBulk,{&"position":mouseTilePosition})).result
							focusDialog.defocus()
							if !Input.is_key_pressed(KEY_SHIFT):
								modes.setMode(MODE.SELECT)
								startPositionDrag(key)
					if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
						if objectHovered is KeyBulk:
							changes.addChange(Changes.DeleteComponentChange.new(game,objectHovered))
							changes.bufferSave()
				MODE.DOOR:
					if isLeftClick(event):
						if componentHovered:
							focusDialog.focusComponent(componentHovered)
						else: focusDialog.defocusComponent()
						if componentHovered is Lock: startPositionDrag(componentHovered)
						elif objectHovered is Door: startPositionDrag(objectHovered)
						else:
							if objectHovered is not Door and game.levelBounds.has_point(mouseWorldPosition):
								var door:Door = changes.addChange(Changes.CreateComponentChange.new(game,Door,{&"position":mouseTilePosition})).result
								startSizeDrag(door)
								changes.addChange(Changes.CreateComponentChange.new(game,Lock,{&"position":Vector2.ZERO,&"parentId":door.id}))
								if !Input.is_key_pressed(KEY_SHIFT):
									modes.setMode(MODE.SELECT)
					if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
						if objectHovered is Door:
							changes.addChange(Changes.DeleteComponentChange.new(game,objectHovered))
							changes.bufferSave()
				MODE.OTHER:
					if isLeftClick(event):
						if componentHovered is KeyCounterElement and otherObjects.selected == KeyCounter: startPositionDrag(componentHovered)
						elif objectHovered and objectHovered.get_script() == otherObjects.selected:
							startPositionDrag(objectHovered)
						else: focusDialog.defocus()
					if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
						if (!objectHovered or objectHovered.get_script() != otherObjects.selected) and game.levelBounds.has_point(mouseWorldPosition):
							var object:GameObject = changes.addChange(Changes.CreateComponentChange.new(game,otherObjects.selected,{&"position":mouseTilePosition})).result
							focusDialog.defocus()
							if otherObjects.selected == KeyCounter:
								changes.addChange(Changes.CreateComponentChange.new(game,KeyCounterElement,{&"position":Vector2(12,12),&"parentId":object.id}))
							if !Input.is_key_pressed(KEY_SHIFT):
								modes.setMode(MODE.SELECT)
								startPositionDrag(object)
					if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
						if objectHovered and objectHovered.get_script() == otherObjects.selected:
							changes.addChange(Changes.DeleteComponentChange.new(game,objectHovered))
							changes.bufferSave()
				MODE.PASTE:
					if isLeftClick(event):
						multiselect.paste()
						if !Input.is_key_pressed(KEY_SHIFT):
							modes.setMode(MODE.SELECT)

func startPositionDrag(component:GameComponent) -> void:
	if component is GameObject: focusDialog.focus(component)
	else: focusDialog.focusComponent(component)
	componentDragged = component
	dragOffset = component.position - Vector2(mouseTilePosition)
	dragMode = DRAG_MODE.POSITION
	previousDragPosition = mouseTilePosition

func startSizeDrag(component:GameComponent, pivot:SIZE_DRAG_PIVOT=SIZE_DRAG_PIVOT.BOTTOM_RIGHT) -> void:
	focusDialog.defocus()
	componentDragged = component
	var rectPos:Vector2 = Vector2.ZERO
	var minSize:Vector2
	if component is Door: minSize = Vector2(32,32)
	elif component is Lock: minSize = Vector2(18,18)
	elif component is KeyCounter: minSize = Vector2(107,63)
	if component is not GameObject: rectPos += component.parent.position
	match pivot:
		SIZE_DRAG_PIVOT.BOTTOM_RIGHT: rectPos += componentDragged.position; dragMode = DRAG_MODE.SIZE_FDIAG
		SIZE_DRAG_PIVOT.TOP_LEFT: rectPos += componentDragged.position+componentDragged.size-minSize; dragMode = DRAG_MODE.SIZE_FDIAG
		SIZE_DRAG_PIVOT.TOP_RIGHT: rectPos += componentDragged.position+Vector2(0,componentDragged.size.y-minSize.y); dragMode = DRAG_MODE.SIZE_BDIAG
		SIZE_DRAG_PIVOT.BOTTOM_LEFT: rectPos += componentDragged.position+Vector2(componentDragged.size.x-minSize.x,0); dragMode = DRAG_MODE.SIZE_BDIAG
		SIZE_DRAG_PIVOT.BOTTOM: rectPos += componentDragged.position; dragMode = DRAG_MODE.SIZE_VERT
		SIZE_DRAG_PIVOT.TOP: rectPos += componentDragged.position+Vector2(0,componentDragged.size.y-minSize.y); dragMode = DRAG_MODE.SIZE_VERT
		SIZE_DRAG_PIVOT.RIGHT: rectPos += componentDragged.position; dragMode = DRAG_MODE.SIZE_HORIZ
		SIZE_DRAG_PIVOT.LEFT: rectPos += componentDragged.position+Vector2(componentDragged.size.x-minSize.x,0); dragMode = DRAG_MODE.SIZE_HORIZ
	if dragMode == DRAG_MODE.SIZE_VERT:  minSize.x = componentDragged.size.x
	if dragMode == DRAG_MODE.SIZE_HORIZ:  minSize.y = componentDragged.size.y
	dragPivotRect = Rect2(rectPos, minSize)
	previousDragPosition = mouseTilePosition

func dragComponent() -> bool: # returns whether or not an object is being dragged, for laziness
	if !componentDragged: return false
	if mouseTilePosition == previousDragPosition and componentDragged is not KeyCounterElement: return true
	previousDragPosition = mouseTilePosition
	var dragPosition:Vector2 = mouseTilePosition
	var parentPosition:Vector2 = Vector2.ZERO
	if componentDragged is not GameObject: parentPosition = componentDragged.parent.position
	match dragMode:
		DRAG_MODE.POSITION:
			if componentDragged is KeyCounterElement:
				dragPosition = mouseWorldPosition - Vector2(0,20)
				if componentDragged.index > 0 and (componentDragged.position+parentPosition).y - dragPosition.y >= 20:
					componentDragged.parent._swapElements(componentDragged.index, componentDragged.index-1)
				elif componentDragged.index < len(componentDragged.parent.elements) - 1 and (componentDragged.position+parentPosition).y - dragPosition.y <= -20:
					componentDragged.parent._swapElements(componentDragged.index, componentDragged.index+1)
			else:
				if componentDragged is not Lock and !game.levelBounds.has_point(dragPosition+dragOffset):
					dragPosition = dragPosition.clamp(game.levelBounds.position-Vector2i(dragOffset+parentPosition), game.levelBounds.end-Vector2i(dragOffset)-tileSize)
				changes.addChange(Changes.PropertyChange.new(game,componentDragged,&"position",dragPosition + dragOffset))
		DRAG_MODE.SIZE_FDIAG, DRAG_MODE.SIZE_BDIAG, DRAG_MODE.SIZE_VERT, DRAG_MODE.SIZE_HORIZ:
			# since mousetileposition rounds down, dragging down or right should go one tile farther
			if mouseWorldPosition.x > dragPivotRect.position.x:
				dragPosition.x += tileSize.x
				if componentDragged is Lock: dragPosition.x += componentDragged.getOffset().x*2
			if mouseWorldPosition.y > dragPivotRect.position.y:
				dragPosition.y += tileSize.y
				if componentDragged is Lock: dragPosition.y += componentDragged.getOffset().y*2
			# clamp to level bounds
			if componentDragged is not Lock and (mouseTilePosition.x < game.levelBounds.position.x or mouseTilePosition.y < game.levelBounds.position.y):
				dragPosition = dragPosition.clamp(game.levelBounds.position,dragPosition)
			# keycounter has only a few possible widths
			if componentDragged is KeyCounter:
				dragPosition -= dragPivotRect.position
				if dragPosition.x <= KeyCounter.WIDTHS[0] - KeyCounter.WIDTHS[2]: dragPosition.x = KeyCounter.WIDTHS[0] - KeyCounter.WIDTHS[2]
				elif dragPosition.x <= KeyCounter.WIDTHS[0] - KeyCounter.WIDTHS[1]: dragPosition.x = KeyCounter.WIDTHS[0] - KeyCounter.WIDTHS[1]
				elif dragPosition.x > KeyCounter.WIDTHS[2]: dragPosition.x = KeyCounter.WIDTHS[2]
				elif dragPosition.x > KeyCounter.WIDTHS[1]: dragPosition.x = KeyCounter.WIDTHS[1]
				else: dragPosition.x = 0
				dragPosition.y = 0
				dragPosition += dragPivotRect.position
			var toRect:Rect2 = dragPivotRect.expand(dragPosition)
			changes.addChange(Changes.PropertyChange.new(game,componentDragged,&"position",toRect.position-parentPosition))
			changes.addChange(Changes.PropertyChange.new(game,componentDragged,&"size",toRect.size))
	return true

func _input(event:InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		if game.playState == Game.PLAY_STATE.PLAY:
			# IN PLAY
			game.player.receiveKey(event)
		else:
			# IN EDIT
			if %objectSearch.has_focus(): return
			if quickSet.quick: quickSet.receiveKey(event); return
			if focusDialog.focused and focusDialog.receiveKey(event): return
			if focusDialog.interacted and focusDialog.interacted.receiveKey(event): return
			match event.keycode:
				KEY_ESCAPE:
					modes.setMode(MODE.SELECT)
					focusDialog.defocus()
					componentDragged = null
					multiselect.deselect()
				KEY_T: modes.setMode(MODE.TILE)
				KEY_B: modes.setMode(MODE.KEY)
				KEY_D: modes.setMode(MODE.DOOR)
				KEY_S: otherObjects.objectSearch.grab_focus()
				KEY_Z: if Input.is_key_pressed(KEY_CTRL): changes.undo()
				KEY_Y: if Input.is_key_pressed(KEY_CTRL): changes.redo()
				KEY_C: if Input.is_key_pressed(KEY_CTRL): multiselect.copySelection()
				KEY_V: if Input.is_key_pressed(KEY_CTRL) and multiselect.clipboard != []: modes.setMode(MODE.PASTE)
				KEY_X:
					if Input.is_key_pressed(KEY_CTRL): multiselect.copySelection(); multiselect.delete()
					else: modes.setMode(MODE.OTHER)
				KEY_O: if game.playState != Game.PLAY_STATE.EDIT: game.stopTest()
				KEY_M:
					if focusDialog.componentFocused: startPositionDrag(focusDialog.componentFocused)
					elif focusDialog.focused: startPositionDrag(focusDialog.focused)
				KEY_H:
					targetCameraZoom = 1
					zoomPoint = game.levelBounds.get_center()
					game.editorCamera.position = zoomPoint - gameViewportCont.size / (cameraZoom*2)
				KEY_SPACE:
					if !topBar.play.disabled:
						var ctrlHeld:bool = Input.is_key_pressed(KEY_CTRL)
						await get_tree().process_frame
						await get_tree().process_frame # bullshit to make sure you dont jump at the start
						if ctrlHeld: game.playTest(game.latestSpawn)
						else: game.playTest(game.levelStart)
				KEY_DELETE: multiselect.delete()
				KEY_TAB: grab_focus()

func zoomCamera(factor:float) -> void:
	targetCameraZoom *= factor
	zoomPoint = mouseWorldPosition
	if abs(targetCameraZoom - 1) < 0.001: targetCameraZoom = 1
	if targetCameraZoom < 0.001: targetCameraZoom = 0.001
	if targetCameraZoom > 1000: targetCameraZoom = 1000

func worldspaceToScreenspace(vector:Vector2) -> Vector2:
	if game.playState == Game.PLAY_STATE.PLAY: return (vector - game.playCamera.get_screen_center_position())*game.playCamera.zoom + gameViewportCont.position + gameViewportCont.size/2
	else: return (vector - game.editorCamera.position)*game.editorCamera.zoom + gameViewportCont.position

func screenspaceToWorldspace(vector:Vector2) -> Vector2:
	if game.playState == Game.PLAY_STATE.PLAY: return (vector - gameViewportCont.position - gameViewportCont.size/2)/game.playCamera.zoom + game.playCamera.get_screen_center_position()
	return (vector - gameViewportCont.position)/game.editorCamera.zoom + game.editorCamera.position

static func isLeftClick(event:InputEvent) -> bool: return event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT
static func isRightClick(event:InputEvent) -> bool: return event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT
static func isLeftUnclick(event:InputEvent) -> bool: return event is InputEventMouseButton and !event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT
static func isRightUnclick(event:InputEvent) -> bool: return event is InputEventMouseButton and !event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT

func sizeDragging() -> bool: return dragMode in [DRAG_MODE.SIZE_FDIAG, DRAG_MODE.SIZE_BDIAG, DRAG_MODE.SIZE_VERT, DRAG_MODE.SIZE_HORIZ]

static func rectSign(rect:Rect2, point:Vector2) -> Vector2: # the "sign" of a point minus a rectangle, ie. where it is in relation
	var signX:float = 0
	var signY:float = 0
	if point.x < rect.position.x: signX = -1
	if point.x >= rect.end.x: signX = 1
	if point.y < rect.position.y: signY = -1
	if point.y >= rect.end.y: signY = 1
	return Vector2(signX, signY)

func scrollIntoView(component:GameComponent) -> void:
	var rect:Rect2 = Rect2(component.getDrawPosition()-Vector2(16,16), component.size+Vector2(32,32))
	var screenRect:Rect2 = Rect2(screenspaceToWorldspace(gameViewportCont.position), gameViewportCont.size/game.editorCamera.zoom)
	if rect.size.x > screenRect.size.x: zoomCamera(0.8**ceil(log(screenRect.size.x/rect.size.x)/-0.2231435513))
	if rect.size.y > screenRect.size.y: zoomCamera(0.8**ceil(log(screenRect.size.y/rect.size.y)/-0.2231435513))
	game.editorCamera.zoom = Vector2(targetCameraZoom,targetCameraZoom)
	screenRect = Rect2(screenspaceToWorldspace(gameViewportCont.position), gameViewportCont.size/game.editorCamera.zoom)
	game.editorCamera.position = game.editorCamera.position.clamp(rect.end-screenRect.size, rect.position)
