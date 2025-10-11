extends Control
class_name Editor

@onready var level:Level = %level
@onready var modes:Modes = %modes
@onready var levelViewportCont:SubViewportContainer = %levelViewportCont
@onready var changes:Changes = %changes
@onready var focusDialog:FocusDialog = %focusDialog

enum Mode {SELECT, TILE, KEY, DOOR, PASTE}
var mode:Mode = Mode.SELECT

var mouseWorldPosition:Vector2
var mouseTilePosition:Vector2i

var targetCameraZoom:float = 1
var zoomPoint:Vector2 # the point where the latest zoom was targetted

func _process(_delta) -> void:
	queue_redraw()
	var scaleFactor:float = (targetCameraZoom/level.editorCamera.zoom.x)**0.2
	level.editorCamera.zoom *= scaleFactor
	level.editorCamera.position += (1-1/scaleFactor) * worldspaceToScreenspace(zoomPoint) / level.editorCamera.zoom

	mouseWorldPosition = screenspaceToWorldspace(get_global_mouse_position())
	mouseTilePosition = Vector2i(mouseWorldPosition) / Vector2i(32,32)
	levelViewportCont.material.set_shader_parameter("mousePosition",mouseWorldPosition)
	levelViewportCont.material.set_shader_parameter("screenPosition",level.editorCamera.position-levelViewportCont.position/level.editorCamera.zoom)
	levelViewportCont.material.set_shader_parameter("rCameraZoom",1/level.editorCamera.zoom.x)

func _gui_input(event:InputEvent) -> void:
	if event is InputEventMouse:
		# move camera
		if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
			level.editorCamera.position -= event.relative / level.editorCamera.zoom
		if event is InputEventMouseButton and event.is_pressed():
			match event.button_index:
				MOUSE_BUTTON_WHEEL_UP: zoomCamera(1.25)
				MOUSE_BUTTON_WHEEL_DOWN: zoomCamera(0.8)
		# modes
		match mode:
			Mode.TILE:
				if level.levelBounds.has_point(mouseWorldPosition):
					if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
						changes.addChange(Changes.TileChange.new(level,mouseTilePosition,true))
					elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
						changes.addChange(Changes.TileChange.new(level,mouseTilePosition,false))
				if event is InputEventMouseButton and !event.is_pressed() and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
					changes.bufferSave()
			Mode.KEY:
				if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
					changes.addChange(Changes.CreateKeyChange.new(level,mouseTilePosition*Vector2i(32,32)))
					if !Input.is_key_pressed(KEY_CTRL):
						modes.setMode(Mode.SELECT)
						changes.bufferSave()
				if event is InputEventMouseButton and !event.is_pressed() and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
					changes.bufferSave()

func _shortcut_input(event:InputEvent) -> void:
	if event is InputEventKey:
		match event.keycode:
			KEY_ESCAPE: modes.setMode(Mode.SELECT)
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
	return (vector - level.editorCamera.position)*level.editorCamera.zoom + levelViewportCont.position

func screenspaceToWorldspace(vector:Vector2) -> Vector2:
	return (vector - levelViewportCont.position)/level.editorCamera.zoom + level.editorCamera.position

func focus(object:Control) -> void:
	if object is oKey:
		focusDialog.focused = object
