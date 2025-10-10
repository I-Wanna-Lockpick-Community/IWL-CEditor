extends Control
class_name Editor

@onready var level:Level = %level
@onready var modes:Modes = %modes
@onready var levelViewportCont:SubViewportContainer = %levelViewportCont

enum Mode {SELECT, TILE, KEY, DOOR, PASTE}
var mode:Mode = Mode.SELECT

var mouseWorldPosition:Vector2
var mouseTilePosition:Vector2i

var targetCameraZoom:float = 1
var zoomPoint:Vector2 # the point where the latest zoom was targetted

func _process(_delta):
	queue_redraw()
	var scaleFactor:float = (targetCameraZoom/level.editorCamera.zoom.x)**0.2
	level.editorCamera.zoom *= scaleFactor
	level.editorCamera.position += (1-1/scaleFactor) * worldspaceToScreenspace(zoomPoint) / level.editorCamera.zoom

	mouseWorldPosition = screenspaceToWorldspace(get_global_mouse_position())
	mouseTilePosition = Vector2i(mouseWorldPosition) / Vector2i(32,32)
	levelViewportCont.material.set_shader_parameter("mousePosition",mouseWorldPosition)
	levelViewportCont.material.set_shader_parameter("screenPosition",level.editorCamera.position-levelViewportCont.position/level.editorCamera.zoom)
	levelViewportCont.material.set_shader_parameter("cameraZoom",level.editorCamera.zoom)

func _input(event:InputEvent) -> void:
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
						level.tiles.set_cell(mouseTilePosition,1,Vector2i(1,1))
					elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
						level.tiles.erase_cell(mouseTilePosition)
			Mode.KEY:
				if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
					level.add_child(oKey.new(mouseTilePosition*Vector2i(32,32)))
					if !Input.is_key_pressed(KEY_CTRL): modes.setMode(Mode.SELECT)
	elif event is InputEventKey:
		if event.pressed:
			hotkey(event)

func hotkey(event:InputEventKey) -> void:
	match event.keycode:
		KEY_ESCAPE: modes.setMode(Mode.SELECT)
		KEY_T: modes.setMode(Mode.TILE)
		KEY_K: modes.setMode(Mode.KEY)
		KEY_D: modes.setMode(Mode.DOOR)

func zoomCamera(factor:float) -> void:
	targetCameraZoom *= factor
	zoomPoint = mouseWorldPosition
	if abs(targetCameraZoom - 1) < 0.001: targetCameraZoom = 1

func worldspaceToScreenspace(vector:Vector2) -> Vector2:
	return (vector - level.editorCamera.position)*level.editorCamera.zoom + levelViewportCont.position

func screenspaceToWorldspace(vector:Vector2) -> Vector2:
	return (vector - levelViewportCont.position)/level.editorCamera.zoom + level.editorCamera.position
