extends PanelContainer
class_name SettingsMenu

@onready var levelSettings:MarginContainer = %levelSettings
@onready var editorSettings:MarginContainer = %editorSettings
@onready var gameSettings:GameSettings = %gameSettings

var configFile:ConfigFile = ConfigFile.new()

var textDraw:RID

func _ready() -> void:
	textDraw = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_z_index(textDraw,1)
	RenderingServer.canvas_item_set_parent(textDraw,%followWorld.get_canvas_item())
	if OS.has_feature("web"):
		%fileDialogWorkaroundCont.visible = false
		%thumbnailClarifier.visible = false
		%editSaveAs.visible = false

	_tabSelected(0)

func _modsChanged() -> void:
	%operatorKeyFocused.visible = Mods.active(&"OperatorKey")
	%remoteLockFocused.visible = Mods.active(&"RemoteLocks")
	%remainderLockFocused.visible = Mods.active(&"RemainderLock")

func _input(event:InputEvent) -> void:
	if !Game.editor.settingsOpen: return
	if event is InputEventKey and event.is_pressed():
		match event.keycode:
			KEY_ESCAPE:
				Game.editor._toggleSettingsMenu(false)
				get_viewport().set_input_as_handled()

func receiveMouseInput(event:InputEvent) -> void:
	# resizing
	if !Game.editor.edgeResizing: return
	var dragCornerSize:Vector2 = Vector2(8,8)/Game.editor.cameraZoom
	var diffSign:Vector2 = Editor.rectSign(Rect2(Vector2(Game.levelBounds.position)+dragCornerSize,Vector2(Game.levelBounds.size)-dragCornerSize*2), Game.editor.mouseWorldPosition)
	if !diffSign or !Game.levelBounds.has_point(Game.editor.mouseWorldPosition): return
	elif !diffSign.x: mouse_default_cursor_shape = Control.CURSOR_VSIZE
	elif !diffSign.y: mouse_default_cursor_shape = Control.CURSOR_HSIZE
	elif (diffSign.x > 0) == (diffSign.y > 0): mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
	else: mouse_default_cursor_shape = Control.CURSOR_BDIAGSIZE
	if Editor.isLeftClick(event):
		Game.editor.startSizeDrag(Game.editor.levelBoundsObject, diffSign)

func _tabSelected(tab:int) -> void:
	%levelSettings.visible = tab == 0
	%editorSettings.visible = tab == 1
	%gameSettings.visible = tab == 2
	mouse_filter = Control.MOUSE_FILTER_PASS if tab == 0 else Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = CURSOR_ARROW
	queue_redraw()

func _draw() -> void:
	RenderingServer.canvas_item_clear(textDraw)
	if %levelSettings.visible:
		TextDraw.outlinedCentered2(Game.FLEVELID,textDraw,%levelNumber.text,Color.WHITE,Color.BLACK,24,Vector2(400,218))
		TextDraw.outlinedCentered2(Game.FLEVELNAME,textDraw,%levelName.text,Color.WHITE,Color.BLACK,36,Vector2(400,282))
		TextDraw.outlinedCentered2(Game.FLEVELNAME,textDraw,%levelAuthor.text,Color.BLACK,Color.WHITE,36,Vector2(400,378))
		TextDraw.outlinedCentered(Game.FROOMNUM,textDraw,"PUZZLE",Color("#d6cfc9"),Color("#3e2d1c"),20,Vector2(732,524))
		TextDraw.outlinedCentered(Game.FROOMNUM,textDraw,%levelShortNumber.text,Color("#8c50c8"),Color("#140064"),20,Vector2(732,554))

func opened() -> void:
	configFile.load("user://config.ini")
	%levelSettings.opened(configFile)
	%editorSettings.opened(configFile)
	%gameSettings.opened(configFile)

func closed() -> void:
	%levelSettings.closed(configFile)
	%editorSettings.closed(configFile)
	%gameSettings.closed(configFile)
	configFile.save("user://config.ini")
