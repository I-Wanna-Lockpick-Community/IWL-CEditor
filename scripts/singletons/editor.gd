extends Control
class_name Editor

@onready var game:Game = %game
@onready var modes:Modes = %modes
@onready var gameViewportCont:SubViewportContainer = %gameViewportCont
@onready var changes:Changes = %changes
@onready var focusDialog:FocusDialog = %focusDialog
@onready var quickSet:QuickSet = %quickSet

enum MODE {SELECT, TILE, KEY, DOOR, PASTE}
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

func _process(_delta) -> void:
	queue_redraw()
	var scaleFactor:float = (targetCameraZoom/game.editorCamera.zoom.x)**0.2
	if abs(scaleFactor - 1) < 0.0001:
		game.editorCamera.zoom = Vector2(targetCameraZoom,targetCameraZoom)
		if targetCameraZoom == 1: game.editorCamera.position = round(game.editorCamera.position)
	else:
		game.editorCamera.zoom *= scaleFactor
		game.editorCamera.position += (1-1/scaleFactor) * (worldspaceToScreenspace(zoomPoint)-gameViewportCont.position) / game.editorCamera.zoom
	
	if Input.is_key_pressed(KEY_CTRL): tileSize = Vector2i(16,16)
	else: tileSize = Vector2i(32,32)

	mouseWorldPosition = screenspaceToWorldspace(get_global_mouse_position())
	mouseTilePosition = Vector2i(mouseWorldPosition) / tileSize * tileSize
	gameViewportCont.material.set_shader_parameter("mousePosition",mouseWorldPosition)
	gameViewportCont.material.set_shader_parameter("screenPosition",game.editorCamera.position-gameViewportCont.position/game.editorCamera.zoom)
	gameViewportCont.material.set_shader_parameter("rCameraZoom",1/game.editorCamera.zoom.x)
	gameViewportCont.material.set_shader_parameter("tileSize",tileSize)

	componentHovered = null
	if !componentDragged:
		objectHovered = null
		for object in game.objects.get_children():
			if mode == MODE.SELECT or (mode == MODE.KEY and object is KeyBulk) or (mode == MODE.DOOR and object is Door):
				if Rect2(object.position, object.size).has_point(mouseWorldPosition):
					objectHovered = object
		if focusDialog.focused is Door:
			for lock in focusDialog.focused.locks:
				if Rect2(lock.getDrawPosition(), lock.size).has_point(mouseWorldPosition):
					componentHovered = lock

func _gui_input(event:InputEvent) -> void:
	if event is InputEventMouse:
		# move camera
		if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
			game.editorCamera.position -= event.relative / game.editorCamera.zoom
		if event is InputEventMouseButton and event.is_pressed():
			match event.button_index:
				MOUSE_BUTTON_WHEEL_UP: zoomCamera(1.25)
				MOUSE_BUTTON_WHEEL_DOWN: zoomCamera(0.8)
		# modes
		if isLeftUnclick(event) or isRightUnclick(event):
			if componentDragged and sizeDragging():
				if componentDragged is GameObject: focusDialog.focus(componentDragged)
				else:
					focusDialog.focusComponent(componentDragged)
					if componentDragged is Lock: focusDialog._doorTypeSelected(Door.DOOR_TYPE.COMBO) # if youre resizing the lock then the door is a combo
			changes.bufferSave()
			componentDragged = null
		# set mouse cursor
		if componentDragged:
			match dragMode:
				DRAG_MODE.POSITION: DisplayServer.cursor_set_shape(DisplayServer.CURSOR_DRAG)
				DRAG_MODE.SIZE_FDIAG, DRAG_MODE.SIZE_BDIAG:
					pass
					var diffSign:Vector2 = rectSign(dragPivotRect, Vector2(mouseTilePosition))
					match diffSign:
						Vector2(-1,-1), Vector2(0,0), Vector2(1,1): DisplayServer.cursor_set_shape(DisplayServer.CURSOR_FDIAGSIZE)
						Vector2(-1,1), Vector2(1,-1): DisplayServer.cursor_set_shape(DisplayServer.CURSOR_BDIAGSIZE)
						Vector2(-1,0), Vector2(1,0): DisplayServer.cursor_set_shape(DisplayServer.CURSOR_HSIZE)
						Vector2(0,-1), Vector2(0,1): DisplayServer.cursor_set_shape(DisplayServer.CURSOR_VSIZE)
				DRAG_MODE.SIZE_VERT: DisplayServer.cursor_set_shape(DisplayServer.CURSOR_VSIZE)
				DRAG_MODE.SIZE_HORIZ: DisplayServer.cursor_set_shape(DisplayServer.CURSOR_HSIZE)
		else: DisplayServer.cursor_set_shape(DisplayServer.CURSOR_ARROW)
		# size dragging
		if focusDialog.componentFocused:
			if componentHovered == focusDialog.componentFocused and focusDialog.componentFocused.receiveMouseInput(event): return
		elif objectHovered:
			if objectHovered.receiveMouseInput(event): return
		# other
		match mode:
			MODE.SELECT:
				if isLeftClick(event): # if youre hovering something and you leftclick, focus it
					if componentHovered:
						focusDialog.focusComponent(componentHovered)
					else: focusDialog.defocusComponent()
					if componentHovered: startPositionDrag(componentHovered)
					elif objectHovered: startPositionDrag(objectHovered)
					else: focusDialog.defocus()
				if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
					dragObject()
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
					if !dragObject():
						if objectHovered is not KeyBulk and game.levelBounds.has_point(mouseWorldPosition):
							changes.addChange(Changes.CreateKeyChange.new(game,mouseTilePosition))
							focusDialog.defocus()
							if !Input.is_key_pressed(KEY_SHIFT):
								modes.setMode(MODE.SELECT)
				if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
					if objectHovered is KeyBulk:
						changes.addChange(Changes.DeleteKeyChange.new(game,objectHovered))
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
							var door:Door = game.doors[changes.addChange(Changes.CreateDoorChange.new(game,mouseTilePosition)).id]
							startSizeDrag(door)
							changes.addChange(Changes.CreateLockChange.new(game,Vector2i.ZERO,door.id))
							if !Input.is_key_pressed(KEY_SHIFT):
								modes.setMode(MODE.SELECT)
				if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
					dragObject()
				if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
					if objectHovered is Door:
						changes.addChange(Changes.DeleteDoorChange.new(game,objectHovered))
						changes.bufferSave()

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
	var rectPos:Vector2
	var minSize:Vector2
	if component is Door: minSize = Vector2(32,32)
	elif component is Lock: minSize = Vector2(18,18)
	match pivot:
		SIZE_DRAG_PIVOT.BOTTOM_RIGHT: rectPos = componentDragged.position; dragMode = DRAG_MODE.SIZE_FDIAG
		SIZE_DRAG_PIVOT.TOP_LEFT: rectPos = componentDragged.position+componentDragged.size-minSize; dragMode = DRAG_MODE.SIZE_FDIAG
		SIZE_DRAG_PIVOT.TOP_RIGHT: rectPos = componentDragged.position+Vector2(0,componentDragged.size.y-minSize.y); dragMode = DRAG_MODE.SIZE_BDIAG
		SIZE_DRAG_PIVOT.BOTTOM_LEFT: rectPos = componentDragged.position+Vector2(componentDragged.size.x-minSize.x,0); dragMode = DRAG_MODE.SIZE_BDIAG
		SIZE_DRAG_PIVOT.BOTTOM: rectPos = componentDragged.position; dragMode = DRAG_MODE.SIZE_VERT
		SIZE_DRAG_PIVOT.TOP: rectPos = componentDragged.position+Vector2(0,componentDragged.size.y-minSize.y); dragMode = DRAG_MODE.SIZE_VERT
		SIZE_DRAG_PIVOT.RIGHT: rectPos = componentDragged.position; dragMode = DRAG_MODE.SIZE_HORIZ
		SIZE_DRAG_PIVOT.LEFT: rectPos = componentDragged.position+Vector2(componentDragged.size.x-minSize.x,0); dragMode = DRAG_MODE.SIZE_HORIZ
	if component is not GameObject: rectPos += component.parent.position
	dragPivotRect = Rect2(rectPos, minSize)
	previousDragPosition = mouseTilePosition


func dragObject() -> bool: # returns whether or not an object is being dragged, for laziness
	if !componentDragged: return false
	if mouseTilePosition == previousDragPosition: return true
	previousDragPosition = mouseTilePosition
	var dragPosition:Vector2 = mouseTilePosition
	var parentPosition:Vector2 = Vector2.ZERO
	var componentSize:Vector2 = componentDragged.size
	if componentDragged is not GameObject: parentPosition = componentDragged.parent.position
	if componentDragged is Lock: componentSize -= componentDragged.getOffset()*2
	match dragMode:
		DRAG_MODE.POSITION:
			if !game.levelBounds.encloses(Rect2i(mouseTilePosition+Vector2i(dragOffset+parentPosition),componentSize)):
				dragPosition = dragPosition.clamp(game.levelBounds.position-Vector2i(dragOffset+parentPosition), game.levelBounds.end-Vector2i(componentSize+dragOffset+parentPosition))
			changes.addChange(Changes.PropertyChange.new(game,componentDragged,&"position",dragPosition + dragOffset))
		DRAG_MODE.SIZE_FDIAG, DRAG_MODE.SIZE_BDIAG, DRAG_MODE.SIZE_VERT, DRAG_MODE.SIZE_HORIZ:
			# since mousetileposition rounds down, dragging down or right should go one tile farther
			if mouseWorldPosition.x > dragPivotRect.position.x:
				dragPosition.x += tileSize.x
				if componentDragged is Lock: dragPosition.x += componentDragged.getOffset().x*2
			if mouseWorldPosition.y > dragPivotRect.position.y:
				dragPosition.y += tileSize.y
				if componentDragged is Lock: dragPosition.y += componentDragged.getOffset().y*2
			
			# to ignore the other axis
			if dragMode == DRAG_MODE.SIZE_VERT: dragPosition.x = componentDragged.position.x+componentSize.x
			elif dragMode == DRAG_MODE.SIZE_HORIZ: dragPosition.y = componentDragged.position.y+componentSize.y
			# clamp to level bounds
			if !game.levelBounds.encloses(Rect2i(mouseTilePosition,componentSize)):
				dragPosition = dragPosition.clamp(game.levelBounds.position, game.levelBounds.end)
			var toRect:Rect2 = dragPivotRect.expand(dragPosition)
			changes.addChange(Changes.PropertyChange.new(game,componentDragged,&"position",toRect.position-parentPosition))
			changes.addChange(Changes.PropertyChange.new(game,componentDragged,&"size",toRect.size))
	return true

func _input(event:InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		if quickSet.quick: quickSet.receiveKey(event); return
		if focusDialog.focused and focusDialog.receiveKey(event): return
		if focusDialog.interacted and focusDialog.interacted.receiveKey(event): return
		match event.keycode:
			KEY_ESCAPE:
				modes.setMode(MODE.SELECT)
				focusDialog.defocus()
				componentDragged = null
			KEY_T: modes.setMode(MODE.TILE)
			KEY_B: modes.setMode(MODE.KEY)
			KEY_D: modes.setMode(MODE.DOOR)
			KEY_Z: if Input.is_key_pressed(KEY_CTRL): changes.undo()
			KEY_Y: if Input.is_key_pressed(KEY_CTRL): changes.redo()
			KEY_SPACE:
				targetCameraZoom = 1
				zoomPoint = game.levelBounds.get_center()
				game.editorCamera.position = zoomPoint - gameViewportCont.size / (game.editorCamera.zoom*2)

func zoomCamera(factor:float) -> void:
	targetCameraZoom *= factor
	zoomPoint = mouseWorldPosition
	if abs(targetCameraZoom - 1) < 0.001: targetCameraZoom = 1
	if targetCameraZoom < 0.001: targetCameraZoom = 0.001
	if targetCameraZoom > 1000: targetCameraZoom = 1000

func worldspaceToScreenspace(vector:Vector2) -> Vector2:
	return (vector - game.editorCamera.position)*game.editorCamera.zoom + gameViewportCont.position

func screenspaceToWorldspace(vector:Vector2) -> Vector2:
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
