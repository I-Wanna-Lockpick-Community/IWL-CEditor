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

func updateLevelSettingsPosition() -> void:
	%followWorld.worldOffset = Game.editor.levelStartCameraCenter()

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

func _levelRevisionSet(value:float) -> void:
	Game.level.revision = int(value)
	Game.anyChanges = true

func _draw() -> void:
	RenderingServer.canvas_item_clear(textDraw)
	if %levelSettings.visible:
		TextDraw.outlinedCentered2(Game.FLEVELID,textDraw,%levelNumber.text,Color.WHITE,Color.BLACK,24,Vector2(400,218))
		TextDraw.outlinedCentered2(Game.FLEVELNAME,textDraw,%levelName.text,Color.WHITE,Color.BLACK,36,Vector2(400,282))
		TextDraw.outlinedCentered2(Game.FLEVELNAME,textDraw,%levelAuthor.text,Color.BLACK,Color.WHITE,36,Vector2(400,378))
		TextDraw.outlinedCentered(Game.FROOMNUM,textDraw,"PUZZLE",Color("#d6cfc9"),Color("#3e2d1c"),20,Vector2(732,524))
		TextDraw.outlinedCentered(Game.FROOMNUM,textDraw,%levelShortNumber.text,Color("#8c50c8"),Color("#140064"),20,Vector2(732,554))

func _defocus() -> void:
	if !%levelName.text:
		%levelName.text = "Unnamed Level"
		_levelNameSet(%levelName.text)

func opened() -> void:
	updateLevelSettingsPosition()
	%levelNumber.text = Game.level.number
	%levelName.text = Game.level.name
	%levelAuthor.text = Game.level.author
	%levelDescription.text = Game.level.description
	%levelShortNumber.text = Game.level.shortNumber
	%levelRevision.value = Game.level.revision
	configFile.load("user://config.ini")
	%thumbnailHideDescription.button_pressed = configFile.get_value("Game.editor", "thumbnailHideDescription", false)
	%thumbnailEntireLevel.button_pressed = configFile.get_value("Game.editor", "thumbnailEntireLevel", true)
	%thumbnailWithText.button_pressed = configFile.get_value("Game.editor", "thumbnailWithText", true)
	%fileDialogWorkaround.button_pressed = configFile.get_value("Game.editor", "fileDialogWorkaround", false)
	%fullscreen.button_pressed = configFile.get_value("Game.editor", "fullscreen", false)
	%uiScale.value = configFile.get_value("Game.editor", "logUiScale", log(DisplayServer.screen_get_dpi()/96.0)/0.6931471806) # log2
	%edgeResizing.button_pressed = configFile.get_value("Game.editor", "edgeResizing", false)
	_uiScaleSet()
	for setting in get_tree().get_nodes_in_group("hotkeySetting"):
		InputMap.action_erase_events(setting.action)
		setting._reset(configFile.get_value("Game.editor", "hotkey_"+setting.action, setting.default))
		for button in setting.buttons: button.check()
	%colorQuicksetSetting.setMatches(getMatches("quicksetColorMatches", ColorQuicksetSetting.DEFAULT_MATCHES))
	%lockSizeQuicksetSetting.setMatches(getMatches("quicksetLockSizeMatches", LockSizeQuicksetSetting.DEFAULT_MATCHES))
	%gameSettings.opened(configFile)
	update()

func getMatches(matchName:String, default:Array[String]) -> Array[String]:
	var matches:Array[String] = configFile.get_value("Game.editor", matchName, default.duplicate())
	for i in range(len(matches), len(default)): matches.append(default[i])
	return matches

func closed() -> void:
	configFile.set_value("Game.editor", "thumbnailHideDescription", %thumbnailHideDescription.button_pressed)
	configFile.set_value("Game.editor", "thumbnailEntireLevel", %thumbnailEntireLevel.button_pressed)
	configFile.set_value("Game.editor", "thumbnailWithText", %thumbnailWithText.button_pressed)
	configFile.set_value("Game.editor", "fileDialogWorkaround", %fileDialogWorkaround.button_pressed)
	configFile.set_value("Game.editor", "fullscreen", %fullscreen.button_pressed)
	configFile.set_value("Game.editor", "logUiScale", %uiScale.value)
	configFile.set_value("Game.editor", "edgeResizing", %edgeResizing.button_pressed)
	for setting in get_tree().get_nodes_in_group("hotkeySetting"):
		configFile.set_value("Game.editor", "hotkey_"+setting.action, InputMap.action_get_events(setting.action))
	configFile.set_value("Game.editor", "quicksetColorMatches", ColorQuicksetSetting.matches)
	configFile.set_value("Game.editor", "quicksetLockSizeMatches", LockSizeQuicksetSetting.matches)
	%gameSettings.closed(configFile)
	configFile.save("user://config.ini")
	update()

func update() -> void:
	updateFileMenuAction(2, &"editSave")
	if OS.has_feature('web'):
		updateFileMenuAction(3, &"editExport")
	else:
		updateFileMenuAction(3, &"editSaveAs")
		updateFileMenuAction(4, &"editExport")

func updateFileMenuAction(index:int,action:StringName) -> void:
	if InputMap.action_get_events(action): Game.editor.fileMenu.menu.set_item_accelerator(index, InputMap.action_get_events(action)[0].get_physical_keycode_with_modifiers())
	else: Game.editor.fileMenu.menu.set_item_accelerator(index, KEY_NONE)

func _fileDialogWorkaroundSet(toggled_on:bool) -> void:
	Game.editor.saveAsDialog.use_native_dialog = !toggled_on
	Game.editor.openDialog.use_native_dialog = !toggled_on

func _fullscreenSet(toggled_on:bool) -> void:
	get_window().mode = Window.MODE_FULLSCREEN if toggled_on else Window.MODE_WINDOWED

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

func _uiScaleChanged(value:float) -> void:
	Game.logUiScale = value
	%uiScaleLabel.text = " (%.2fx)" % (2**value)

func _uiScaleSet() -> void:
	Game.uiScale = 2**Game.logUiScale

func _edgeResizingSet(toggled_on:bool) -> void:
	Game.editor.edgeResizing = toggled_on
