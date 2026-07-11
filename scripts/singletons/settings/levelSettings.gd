extends MarginContainer
class_name LevelSettings

var textDraw:RID

func _ready() -> void:
	textDraw = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_z_index(textDraw,1)
	RenderingServer.canvas_item_set_parent(textDraw,%followWorld.get_canvas_item())
	if OS.has_feature("web"):
		%thumbnailClarifier.visible = false

func _draw() -> void:
	RenderingServer.canvas_item_clear(textDraw)
	TextDraw.outlinedCentered2(Game.FLEVELID,textDraw,%levelNumber.text,Color.WHITE,Color.BLACK,24,Vector2(400,218))
	TextDraw.outlinedCentered2(Game.FLEVELNAME,textDraw,%levelName.text,Color.WHITE,Color.BLACK,36,Vector2(400,282))
	TextDraw.outlinedCentered2(Game.FLEVELNAME,textDraw,%levelAuthor.text,Color.BLACK,Color.WHITE,36,Vector2(400,378))
	TextDraw.outlinedCentered(Game.FROOMNUM,textDraw,"PUZZLE",Color("#d6cfc9"),Color("#3e2d1c"),20,Vector2(732,524))
	TextDraw.outlinedCentered(Game.FROOMNUM,textDraw,%levelShortNumber.text,Color("#8c50c8"),Color("#140064"),20,Vector2(732,554))

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

func opened(configFile:ConfigFile) -> void:
	updatePosition()
	%levelNumber.text = Game.level.number
	%levelName.text = Game.level.name
	%levelAuthor.text = Game.level.author
	%levelDescription.text = Game.level.description
	%levelShortNumber.text = Game.level.shortNumber
	%levelRevision.value = Game.level.revision
	%thumbnailHideDescription.button_pressed = configFile.get_value("editor", "thumbnailHideDescription", false)
	%thumbnailEntireLevel.button_pressed = configFile.get_value("editor", "thumbnailEntireLevel", true)
	%thumbnailWithText.button_pressed = configFile.get_value("editor", "thumbnailWithText", true)

func closed(configFile:ConfigFile) -> void:
	configFile.set_value("editor", "thumbnailHideDescription", %thumbnailHideDescription.button_pressed)
	configFile.set_value("editor", "thumbnailEntireLevel", %thumbnailEntireLevel.button_pressed)
	configFile.set_value("editor", "thumbnailWithText", %thumbnailWithText.button_pressed)

func updatePosition() -> void:
	%followWorld.worldOffset = Game.editor.levelStartCameraCenter()

func _levelNumberSet(string:String) -> void:
	Game.level.number = string
	Game.anyChanges = true
	queue_redraw()

func _levelNameSet(string:String) -> void:
	Game.level.name = string if string else "Unnamed Level"
	Game.anyChanges = true
	queue_redraw()

func _levelAuthorSet(string:String) -> void:
	Game.level.author = string
	Game.anyChanges = true
	queue_redraw()

func _levelDescriptionSet():
	Game.level.description = %levelDescription.text
	Game.anyChanges = true

func _levelShortNumberSet(string:String) -> void:
	Game.level.shortNumber = string
	Game.anyChanges = true
	queue_redraw()

func _defocus() -> void:
	if !%levelName.text:
		%levelName.text = "Unnamed Level"
		_levelNameSet(%levelName.text)

func _levelRevisionSet(value:float) -> void:
	Game.level.revision = int(value)
	Game.anyChanges = true

func _generateThumbnail() -> void:
	Game.editor.outline.visible = false
	await Game.editor.takeThumbnailScreenshot(Game.editor.thumbnailWithText)
	Game.editor.outline.visible = true

func _thumbnailHideDescriptionSet(toggled_on:bool) -> void:
	Game.editor.thumbnailHideDescription = toggled_on

func _thumbnailEntireLevelSet(toggled_on:bool) -> void:
	Game.editor.thumbnailEntireLevel = toggled_on

func _thumbnailWithText(toggled_on: bool) -> void:
	Game.editor.thumbnailWithText = toggled_on
