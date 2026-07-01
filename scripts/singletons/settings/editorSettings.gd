extends MarginContainer

func opened(configFile:ConfigFile) -> void:
	%fileDialogWorkaround.button_pressed = configFile.get_value("Game.editor", "fileDialogWorkaround", false)
	%fullscreen.button_pressed = configFile.get_value("Game.editor", "fullscreen", false)
	%uiScale.value = configFile.get_value("Game.editor", "logUiScale", log(DisplayServer.screen_get_dpi()/96.0)/0.6931471806) # log2
	%edgeResizing.button_pressed = configFile.get_value("Game.editor", "edgeResizing", false)
	_uiScaleSet()
	for setting in get_tree().get_nodes_in_group("hotkeySetting"):
		InputMap.action_erase_events(setting.action)
		setting._reset(configFile.get_value("Game.editor", "hotkey_"+setting.action, setting.default))
		for button in setting.buttons: button.check()
	%colorQuicksetSetting.setMatches(getMatches(configFile, "quicksetColorMatches", ColorQuicksetSetting.DEFAULT_MATCHES))
	%lockSizeQuicksetSetting.setMatches(getMatches(configFile, "quicksetLockSizeMatches", LockSizeQuicksetSetting.DEFAULT_MATCHES))
	update()

func closed(configFile:ConfigFile) -> void:
	configFile.set_value("Game.editor", "fileDialogWorkaround", %fileDialogWorkaround.button_pressed)
	configFile.set_value("Game.editor", "fullscreen", %fullscreen.button_pressed)
	configFile.set_value("Game.editor", "logUiScale", %uiScale.value)
	configFile.set_value("Game.editor", "edgeResizing", %edgeResizing.button_pressed)
	for setting in get_tree().get_nodes_in_group("hotkeySetting"):
		configFile.set_value("Game.editor", "hotkey_"+setting.action, InputMap.action_get_events(setting.action))
	configFile.set_value("Game.editor", "quicksetColorMatches", ColorQuicksetSetting.matches)
	configFile.set_value("Game.editor", "quicksetLockSizeMatches", LockSizeQuicksetSetting.matches)
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

func getMatches(configFile:ConfigFile, matchName:String, default:Array[String]) -> Array[String]:
	var matches:Array[String] = configFile.get_value("Game.editor", matchName, default.duplicate())
	for i in range(len(matches), len(default)): matches.append(default[i])
	return matches

func _fileDialogWorkaroundSet(toggled_on:bool) -> void:
	Game.editor.saveAsDialog.use_native_dialog = !toggled_on
	Game.editor.openDialog.use_native_dialog = !toggled_on

func _fullscreenSet(toggled_on:bool) -> void:
	get_window().mode = Window.MODE_FULLSCREEN if toggled_on else Window.MODE_WINDOWED

func _uiScaleChanged(value:float) -> void:
	Game.logUiScale = value
	%uiScaleLabel.text = " (%.2fx)" % (2**value)

func _uiScaleSet() -> void:
	Game.uiScale = 2**Game.logUiScale

func _edgeResizingSet(toggled_on:bool) -> void:
	Game.editor.edgeResizing = toggled_on
