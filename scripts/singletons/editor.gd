extends Control
class_name Editor

@onready var game:Game = %game
@onready var modes:Modes = %modes
@onready var gameViewportCont:SubViewportContainer = %gameViewportCont
@onready var changes:Changes = %changes
@onready var focusDialog:FocusDialog = %focusDialog
@onready var quickSet:QuickSet = %quickSet

enum Mode {SELECT, TILE, KEY, DOOR, PASTE}
var mode:Mode = Mode.SELECT

var mouseWorldPosition:Vector2
var mouseTilePosition:Vector2i

var targetCameraZoom:float = 1
var zoomPoint:Vector2 # the point where the latest zoom was targetted

var objectHovered:GameObject
var objectDragged:GameObject

func _process(_delta) -> void:
	queue_redraw()
	var scaleFactor:float = (targetCameraZoom/game.editorCamera.zoom.x)**0.2
	game.editorCamera.zoom *= scaleFactor
	game.editorCamera.position += (1-1/scaleFactor) * worldspaceToScreenspace(zoomPoint) / game.editorCamera.zoom

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
			changes.bufferSave()
			objectDragged = null
		match mode:
			Mode.SELECT:
				if isLeftClick(event): # if youre hovering something and you leftclick, focus it
					if objectHovered is KeyBulk:
						focusDialog.focus(objectHovered)
						objectDragged = objectHovered
					else: focusDialog.defocus()
				if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
					dragObject()
			Mode.TILE:
				if game.gameBounds.has_point(mouseWorldPosition):
					if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
						changes.addChange(Changes.TileChange.new(game,mouseTilePosition,true))
						focusDialog.defocus()
					elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
						changes.addChange(Changes.TileChange.new(game,mouseTilePosition,false))
						focusDialog.defocus()
			Mode.KEY:
				if isLeftClick(event): # if youre hovering a key and you leftclick, focus it
					if objectHovered is KeyBulk:
						focusDialog.focus(objectHovered)
						objectDragged = objectHovered
					else: focusDialog.defocus()
				if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
					if !dragObject():
						if objectHovered is not KeyBulk and game.gameBounds.has_point(mouseWorldPosition):
							changes.addChange(Changes.CreateKeyChange.new(game,mouseTilePosition*Vector2i(32,32)))
							focusDialog.defocus()
							if !Input.is_key_pressed(KEY_CTRL):
								modes.setMode(Mode.SELECT)
								changes.bufferSave()
				if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
					if objectHovered is KeyBulk:
						changes.addChange(Changes.DeleteKeyChange.new(game,objectHovered))
						objectHovered = null
						objectDragged = null

func dragObject() -> bool:
	if !objectDragged: return false
	if mouseTilePosition*32 == Vector2i(objectDragged.position): return false
	var dragPosition:Vector2 = mouseTilePosition*32
	if !game.gameBounds.has_point(mouseWorldPosition):
		dragPosition = dragPosition.clamp(game.gameBounds.position, game.gameBounds.end-Vector2i(32,32))
	if objectDragged is KeyBulk: changes.addChange(Changes.KeyPropertyChange.new(game,objectDragged,&"position",dragPosition))
	return true

func _input(event:InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		if quickSet.quick: quickSet.receiveKey(event); return
		if focusDialog.focused and focusDialog.receiveKey(event): return
		if focusDialog.interacted and focusDialog.interacted.receiveKey(event): return
		match event.keycode:
			KEY_ESCAPE:
				modes.setMode(Mode.SELECT)
				focusDialog.defocus()
				objectDragged = null
			KEY_T: modes.setMode(Mode.TILE)
			KEY_B: modes.setMode(Mode.KEY)
			KEY_D: modes.setMode(Mode.DOOR)
			KEY_Z: if Input.is_key_pressed(KEY_CTRL): changes.undo()
			KEY_Y: if Input.is_key_pressed(KEY_CTRL): changes.redo()

func zoomCamera(factor:float) -> void:
	targetCameraZoom *= factor
	zoomPoint = mouseWorldPosition
	if abs(targetCameraZoom - 1) < 0.001: targetCameraZoom = 1

func worldspaceToScreenspace(vector:Vector2) -> Vector2:
	return (vector - game.editorCamera.position)*game.editorCamera.zoom + gameViewportCont.position

func screenspaceToWorldspace(vector:Vector2) -> Vector2:
	return (vector - gameViewportCont.position)/game.editorCamera.zoom + game.editorCamera.position

static func isLeftClick(event:InputEvent) -> bool: return event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT
static func isRightClick(event:InputEvent) -> bool: return event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT
static func isLeftUnclick(event:InputEvent) -> bool: return event is InputEventMouseButton and !event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT
static func isRightUnclick(event:InputEvent) -> bool: return event is InputEventMouseButton and !event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT
