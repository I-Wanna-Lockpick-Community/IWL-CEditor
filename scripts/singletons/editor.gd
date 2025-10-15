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
enum SIZE_DRAG_PIVOT {TOP_LEFT, TOP, TOP_RIGHT, LEFT, RIGHT, BOTTOM_LEFT, BOTTOM, BOTTOM_RIGHT}
var objectDragged:GameObject
var dragMode:DRAG_MODE
var dragOffset:Vector2 # the offset for position dragging
var dragPivot:Vector2 # the pivot for size dragging
var previousDragPosition:Vector2i # to check whether or not a drag would do anything

func _process(_delta) -> void:
	queue_redraw()
	var scaleFactor:float = (targetCameraZoom/game.editorCamera.zoom.x)**0.2
	if abs(scaleFactor - 1) < 0.0001:
		game.editorCamera.zoom = Vector2(targetCameraZoom,targetCameraZoom)
		if targetCameraZoom == 1: game.editorCamera.position = round(game.editorCamera.position)
	else:
		game.editorCamera.zoom *= scaleFactor
		game.editorCamera.position += (1-1/scaleFactor) * (worldspaceToScreenspace(zoomPoint)-gameViewportCont.position) / game.editorCamera.zoom

	mouseWorldPosition = screenspaceToWorldspace(get_global_mouse_position())
	mouseTilePosition = Vector2i(mouseWorldPosition) / Vector2i(32,32)
	gameViewportCont.material.set_shader_parameter("mousePosition",mouseWorldPosition)
	gameViewportCont.material.set_shader_parameter("screenPosition",game.editorCamera.position-gameViewportCont.position/game.editorCamera.zoom)
	gameViewportCont.material.set_shader_parameter("rCameraZoom",1/game.editorCamera.zoom.x)

	componentHovered = null
	if !objectDragged:
		objectHovered = null
		for object in game.objects.get_children():
			if mode == MODE.SELECT or (mode == MODE.KEY and object is KeyBulk) or (mode == MODE.DOOR and object is Door):
				if Rect2(object.position, object.size).has_point(mouseWorldPosition):
					objectHovered = object
		if objectHovered is Door:
			for lock in objectHovered.locks:
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
			if objectDragged and dragMode in [DRAG_MODE.SIZE_FDIAG, DRAG_MODE.SIZE_BDIAG, DRAG_MODE.SIZE_VERT, DRAG_MODE.SIZE_HORIZ]:
				focusDialog.focus(objectDragged)
			changes.bufferSave()
			objectDragged = null
		# set mouse cursor
		if objectDragged:
			match dragMode:
				DRAG_MODE.POSITION: DisplayServer.cursor_set_shape(DisplayServer.CURSOR_DRAG)
				DRAG_MODE.SIZE_FDIAG, DRAG_MODE.SIZE_BDIAG:
					var diffSign:Vector2 = sign(Vector2(mouseTilePosition*32) - dragPivot)
					match diffSign:
						Vector2(-1,-1), Vector2(0,0), Vector2(1,1): DisplayServer.cursor_set_shape(DisplayServer.CURSOR_FDIAGSIZE)
						Vector2(-1,1), Vector2(1,-1): DisplayServer.cursor_set_shape(DisplayServer.CURSOR_BDIAGSIZE)
						Vector2(-1,0), Vector2(1,0): DisplayServer.cursor_set_shape(DisplayServer.CURSOR_HSIZE)
						Vector2(0,-1), Vector2(0,1): DisplayServer.cursor_set_shape(DisplayServer.CURSOR_VSIZE)
				DRAG_MODE.SIZE_VERT: DisplayServer.cursor_set_shape(DisplayServer.CURSOR_VSIZE)
				DRAG_MODE.SIZE_HORIZ: DisplayServer.cursor_set_shape(DisplayServer.CURSOR_HSIZE)
		else: DisplayServer.cursor_set_shape(DisplayServer.CURSOR_ARROW)
		# door size dragging
		if objectHovered and objectHovered.receiveMouseInput(event): return
		# other
		match mode:
			MODE.SELECT:
				if isLeftClick(event): # if youre hovering something and you leftclick, focus it
					if componentHovered:
						focusDialog.focusComponent(componentHovered,objectHovered)
					else: focusDialog.defocusComponent()
					if objectHovered is GameObject:
						startPositionDrag(objectHovered)
					else: focusDialog.defocus()
				if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
					dragObject()
			MODE.TILE:
				if game.levelBounds.has_point(mouseWorldPosition):
					if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
						changes.addChange(Changes.TileChange.new(game,mouseTilePosition,true))
						focusDialog.defocus()
					elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
						changes.addChange(Changes.TileChange.new(game,mouseTilePosition,false))
						focusDialog.defocus()
			MODE.KEY:
				if isLeftClick(event): # if youre hovering a key and you leftclick, focus it
					if objectHovered is KeyBulk:
						startPositionDrag(objectHovered)
					else: focusDialog.defocus()
				if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
					if !dragObject():
						if objectHovered is not KeyBulk and game.levelBounds.has_point(mouseWorldPosition):
							changes.addChange(Changes.CreateKeyChange.new(game,mouseTilePosition*Vector2i(32,32)))
							focusDialog.defocus()
							if !Input.is_key_pressed(KEY_CTRL):
								modes.setMode(MODE.SELECT)
				if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
					if objectHovered is KeyBulk:
						changes.addChange(Changes.DeleteKeyChange.new(game,objectHovered))
						changes.bufferSave()
			MODE.DOOR:
				if isLeftClick(event):
					if componentHovered:
						focusDialog.focusComponent(componentHovered,objectHovered)
					else: focusDialog.defocusComponent()
					if objectHovered is Door:
						startPositionDrag(objectHovered)
					else:
						if objectHovered is not Door and game.levelBounds.has_point(mouseWorldPosition):
							startSizeDrag(game.doors[changes.addChange(Changes.CreateDoorChange.new(game,mouseTilePosition*32)).id])
							if !Input.is_key_pressed(KEY_CTRL):
								modes.setMode(MODE.SELECT)
				if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
					dragObject()
				if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
					if objectHovered is Door:
						changes.addChange(Changes.DeleteDoorChange.new(game,objectHovered))
						changes.bufferSave()

func startPositionDrag(object:GameObject) -> void:
	focusDialog.focus(object)
	objectDragged = object
	dragOffset = object.position - Vector2(mouseTilePosition*32)
	dragMode = DRAG_MODE.POSITION
	previousDragPosition = mouseTilePosition*32

func startSizeDrag(object:GameObject, pivot:SIZE_DRAG_PIVOT=SIZE_DRAG_PIVOT.BOTTOM_RIGHT) -> void:
	focusDialog.defocus()
	objectDragged = object
	match pivot:
		SIZE_DRAG_PIVOT.BOTTOM_RIGHT: dragPivot = objectDragged.position; dragMode = DRAG_MODE.SIZE_FDIAG
		SIZE_DRAG_PIVOT.TOP_LEFT: dragPivot = objectDragged.position+objectDragged.size-Vector2(32,32); dragMode = DRAG_MODE.SIZE_FDIAG
		SIZE_DRAG_PIVOT.TOP_RIGHT: dragPivot = objectDragged.position+Vector2(0,objectDragged.size.y-32); dragMode = DRAG_MODE.SIZE_BDIAG
		SIZE_DRAG_PIVOT.BOTTOM_LEFT: dragPivot = objectDragged.position+Vector2(objectDragged.size.x-32,0); dragMode = DRAG_MODE.SIZE_BDIAG
		SIZE_DRAG_PIVOT.BOTTOM: dragPivot = objectDragged.position; dragMode = DRAG_MODE.SIZE_VERT
		SIZE_DRAG_PIVOT.TOP: dragPivot = objectDragged.position+Vector2(0,objectDragged.size.y-32); dragMode = DRAG_MODE.SIZE_VERT
		SIZE_DRAG_PIVOT.RIGHT: dragPivot = objectDragged.position; dragMode = DRAG_MODE.SIZE_HORIZ
		SIZE_DRAG_PIVOT.LEFT: dragPivot = objectDragged.position+Vector2(objectDragged.size.x-32,0); dragMode = DRAG_MODE.SIZE_HORIZ
	previousDragPosition = mouseTilePosition*32


func dragObject() -> bool: # returns whether or not an object is being dragged, for laziness
	if !objectDragged: return false
	if mouseTilePosition*32 == previousDragPosition: return true
	previousDragPosition = mouseTilePosition*32
	var dragPosition:Vector2 = mouseTilePosition*32
	match dragMode:
		DRAG_MODE.POSITION:
			if !game.levelBounds.encloses(Rect2i(mouseTilePosition*32+Vector2i(dragOffset),objectDragged.size)):
				dragPosition = dragPosition.clamp(game.levelBounds.position-Vector2i(dragOffset), game.levelBounds.end-Vector2i(objectDragged.size+dragOffset))
			changes.addChange(Changes.PropertyChange.new(game,objectDragged,&"position",dragPosition + dragOffset))
		DRAG_MODE.SIZE_FDIAG, DRAG_MODE.SIZE_BDIAG, DRAG_MODE.SIZE_VERT, DRAG_MODE.SIZE_HORIZ:
			if !game.levelBounds.encloses(Rect2i(mouseTilePosition*32,objectDragged.size)):
				dragPosition = dragPosition.clamp(game.levelBounds.position, game.levelBounds.end-Vector2i(32,32))
			var toPosition:Vector2 = dragPivot
			var toSize:Vector2 = objectDragged.size
			if dragMode != DRAG_MODE.SIZE_VERT:
				if dragPosition.x <= dragPivot.x:
					# dragging to the left
					toPosition.x = dragPosition.x
					toSize.x = dragPivot.x - dragPosition.x + 32
					# dragging to the right
				else: toSize.x = dragPosition.x - dragPivot.x + 32
			if dragMode != DRAG_MODE.SIZE_HORIZ:
				if dragPosition.y <= dragPivot.y:
					# dragging to the top
					toPosition.y = dragPosition.y
					toSize.y = dragPivot.y - dragPosition.y + 32
					# dragging to the bottom
				else: toSize.y = dragPosition.y - dragPivot.y + 32
			changes.addChange(Changes.PropertyChange.new(game,objectDragged,&"position",toPosition))
			changes.addChange(Changes.PropertyChange.new(game,objectDragged,&"size",toSize))
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
				objectDragged = null
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
