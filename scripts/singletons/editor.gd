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

enum DRAG_MODE {POSITION, SIZE}
var objectDragged:GameObject
var dragMode:DRAG_MODE
var dragOffset: Vector2 # the offset for position dragging
var dragPivot:Vector2 # the pivot for size dragging

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

	objectHovered = null
	for object in game.objects.get_children():
		if Rect2(object.position, object.size).has_point(mouseWorldPosition):
			objectHovered = object

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
			if objectDragged and dragMode == DRAG_MODE.SIZE:
				focusDialog.focus(objectDragged)

			changes.bufferSave()
			objectDragged = null
		match mode:
			MODE.SELECT:
				if isLeftClick(event): # if youre hovering something and you leftclick, focus it
					if objectHovered is KeyBulk or objectHovered is Door:
						focusDialog.focus(objectHovered)
						objectDragged = objectHovered
						dragOffset = objectDragged.position - Vector2(mouseTilePosition*Vector2i(32,32))
						dragMode = DRAG_MODE.POSITION
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
						focusDialog.focus(objectHovered)
						objectDragged = objectHovered
						dragOffset = objectDragged.position - Vector2(mouseTilePosition*Vector2i(32,32))
						dragMode = DRAG_MODE.POSITION
					else: focusDialog.defocus()
				if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
					if !dragObject():
						if objectHovered is not KeyBulk and game.levelBounds.has_point(mouseWorldPosition):
							changes.addChange(Changes.CreateKeyChange.new(game,mouseTilePosition*Vector2i(32,32)))
							focusDialog.defocus()
							if !Input.is_key_pressed(KEY_CTRL):
								modes.setMode(MODE.SELECT)
								changes.bufferSave()
				if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
					if objectHovered is KeyBulk:
						changes.addChange(Changes.DeleteKeyChange.new(game,objectHovered))
						objectHovered = null
						objectDragged = null
			MODE.DOOR:
				if isLeftClick(event):
					if objectHovered is Door:
						focusDialog.focus(objectHovered)
						objectDragged = objectHovered
						dragOffset = objectDragged.position - Vector2(mouseTilePosition*Vector2i(32,32))
						dragMode = DRAG_MODE.POSITION
					else:
						if objectHovered is not Door and game.levelBounds.has_point(mouseWorldPosition):
							focusDialog.defocus()
							objectDragged = game.doors[changes.addChange(Changes.CreateDoorChange.new(game,mouseTilePosition*Vector2i(32,32))).id]
							dragMode = DRAG_MODE.SIZE
							dragPivot = objectDragged.position
							if !Input.is_key_pressed(KEY_CTRL):
								modes.setMode(MODE.SELECT)
				if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
					dragObject()
				if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
					if objectHovered is Door:
						changes.addChange(Changes.DeleteDoorChange.new(game,objectHovered))
						objectHovered = null
						objectDragged = null

func dragObject() -> bool: # returns whether or not an object is being dragged, for laziness
	if !objectDragged: return false
	if mouseTilePosition*32 == Vector2i(objectDragged.position): return true
	var dragPosition:Vector2 = mouseTilePosition*32
	if !game.levelBounds.has_point(mouseWorldPosition):
		dragPosition = dragPosition.clamp(game.levelBounds.position, game.levelBounds.end-Vector2i(32,32))
	match dragMode:
		DRAG_MODE.POSITION:
			changes.addChange(Changes.PropertyChange.new(game,objectDragged,&"position",dragPosition + dragOffset))
		DRAG_MODE.SIZE:
			var toPosition:Vector2 = dragPivot
			var toSize:Vector2
			if dragPosition.x < dragPivot.x:
				# dragging to the left
				toPosition.x = dragPosition.x
				toSize.x = dragPivot.x - dragPosition.x + 32
				# dragging to the right
			else: toSize.x = dragPosition.x - dragPivot.x + 32
			if dragPosition.y < dragPivot.y:
				# dragging to the top
				toPosition.y = dragPosition.y
				toSize.y = dragPivot.y - dragPosition.y + 32
				# dragging to the bottom
			else: toSize.y = dragPosition.y - dragPivot.y + 32
			toSize.x = max(toSize.x, 32)
			toSize.y = max(toSize.y, 32)
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
