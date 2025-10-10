extends Control
class_name Editor

@onready var level:Level = %level
@onready var modes:Modes = %modes
@onready var levelViewportCont:SubViewportContainer = %levelViewportCont

enum Mode {SELECT, TILE, KEY, DOOR, PASTE}
var mode:Mode = Mode.SELECT

var mouseWorldPosition:Vector2
var mouseTilePosition:Vector2i

func _process(_delta):
	queue_redraw()

func _input(event:InputEvent) -> void:
	if event is InputEventMouse:
		mouseWorldPosition = (event.position - levelViewportCont.position)/level.editorCamera.zoom + level.editorCamera.position
		mouseTilePosition = Vector2i(mouseWorldPosition) / Vector2i(32,32)
		levelViewportCont.material.set_shader_parameter("mousePosition",mouseWorldPosition)
		levelViewportCont.material.set_shader_parameter("screenPosition",level.editorCamera.position-levelViewportCont.position/level.editorCamera.zoom)
		levelViewportCont.material.set_shader_parameter("cameraZoom",level.editorCamera.zoom)
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

func hotkey(event:InputEventKey):
	match event.keycode:
		KEY_ESCAPE: modes.setMode(Mode.SELECT)
		KEY_T: modes.setMode(Mode.TILE)
		KEY_K: modes.setMode(Mode.KEY)
		KEY_D: modes.setMode(Mode.DOOR)

func zoomCamera(factor:float):
	level.editorCamera.position += (1-1/factor) * levelViewportCont.get_local_mouse_position() / level.editorCamera.zoom
	level.editorCamera.zoom *= factor
	if abs(level.editorCamera.zoom.x - 1) < 0.001: level.editorCamera.zoom = Vector2(1,1)
