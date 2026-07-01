extends MarginContainer
class_name EditorSettingss

static var HotkeyTree:Array = [
	Hotkey.new("Half Tile Snap", &"heldTileSize16", [eventKey(KEY_CTRL)]).setHeld(),
	Hotkey.new("Eighth Tile Snap", &"heldTileSize4", [eventKey(KEY_ALT)]).setHeld(),
	Hotkey.new("Keep Mode After Placing Object", &"heldKeepMode", [eventKey(KEY_SHIFT)]).setHeld(),
	Hotkey.new("Start Playtest", &"editStartPlaytest", [eventKey(KEY_SPACE)]),
	Hotkey.new("Start Playtest From Latest Spawn", &"editStartPlaytestFromState", [eventKey(KEY_MASK_CTRL+KEY_SPACE)]),
	SubTree.new("Playtesting", [
		Hotkey.new("Pause Playtest", &"editPausePlaytest", [eventKey(KEY_P)]),
		Hotkey.new("Stop Playtest", &"editStopPlaytest", [eventKey(KEY_O)]),
		Hotkey.new("Leave Savestate", &"editSavestate", []),
	]).setClarification("Game controls also apply, though these hotkeys take priority."),
	Hotkey.new("Select Mode", &"editModeSelect", [eventKey(KEY_ESCAPE)]),
	Hotkey.new("Tile Mode", &"editModeTile", [eventKey(KEY_T)]),
	Hotkey.new("Key Mode", &"editModeKey", [eventKey(KEY_B)]),
	Hotkey.new("Door Mode", &"editModeDoor", [eventKey(KEY_D)]),
	Hotkey.new("Other Objects Mode", &"editModeOther", [eventKey(KEY_X)]),
	Hotkey.new("Search Other Objects", &"editObjectSearch", [eventKey(KEY_S)]),
	Hotkey.new("Pipette", &"editPipette", [eventKey(KEY_Q)]),
	Hotkey.new("Open Settings", &"editOpenSettings", [eventKey(KEY_MASK_SHIFT+KEY_ESCAPE)]),
	Hotkey.new("New Puzzle", &"editNew", []),
	Hotkey.new("Open Puzzle", &"editOpen", []),
	Hotkey.new("Save Puzzle", &"editSave", [eventKey(KEY_MASK_CTRL+KEY_S)]),
	Hotkey.new("Save Puzzle As", &"editSaveAs", [eventKey(KEY_MASK_CTRL+KEY_MASK_SHIFT+KEY_S)]),
	Hotkey.new("Export Puzzle", &"editExport", [eventKey(KEY_MASK_CTRL+KEY_E)]),
	Hotkey.new("Reset Camera", &"editHome", [eventKey(KEY_H)]),
	Hotkey.new("Copy Component(s)", &"editCopy", [eventKey(KEY_MASK_CTRL+KEY_C)]),
	Hotkey.new("Cut Component(s)", &"editCut", [eventKey(KEY_MASK_CTRL+KEY_X)]),
	Hotkey.new("Paste Component(s)", &"editPaste", [eventKey(KEY_MASK_CTRL+KEY_V)]),
	Hotkey.new("Undo", &"editUndo", [eventKey(KEY_MASK_CTRL+KEY_Z)]),
	Hotkey.new("Redo", &"editRedo", [eventKey(KEY_MASK_CTRL+KEY_Y)]),
	Hotkey.new("Move Camera Up", &"editCameraUp", [eventKey(KEY_UP)]),
	Hotkey.new("Move Camera Left", &"editCameraLeft", [eventKey(KEY_LEFT)]),
	Hotkey.new("Move Camera Down", &"editCameraDown", [eventKey(KEY_DOWN)]),
	Hotkey.new("Move Camera Right", &"editCameraRight", [eventKey(KEY_RIGHT)]),
	Hotkey.new("Drag Selected Component(s)", &"editDrag", [eventKey(KEY_M)]),
	Hotkey.new("Delete Selected Component(s)", &"editDelete", [eventKey(KEY_DELETE)]),
	SubTree.new("Component Focused", [
		QuicksetHotkey.new("Quickset Color", &"quicksetColor", [eventKey(KEY_C)], ColorQuicksetSetting),
		SubTree.new("Number Input Selected", [
			Hotkey.new("Multiply By -1", &"numberNegate", [eventKey(KEY_MINUS), eventKey(KEY_KP_SUBTRACT), eventKey(KEY_QUOTELEFT)]),
			Hotkey.new("Multiply By i", &"numberTimesI", [eventKey(KEY_I)]),
			Hotkey.new("Evaluate Expression", &"numberEvaluate", [eventKey(KEY_ENTER)]),
		]),
		SubTree.new("Key Focused", [
			Hotkey.new("Set Normal Type", &"focusKeyNormal", [eventKey(KEY_N)]),
			Hotkey.new("Set Exact Type", &"focusKeyExact", [eventKey(KEY_E)]),
			Hotkey.new("Toggle Star Type", &"focusKeyStar", [eventKey(KEY_S)]),
			Hotkey.new("Advance Rotor Type", &"focusKeyRotor", [eventKey(KEY_R)]),
			Hotkey.new("Toggle Curse Type", &"focusKeyCurse", [eventKey(KEY_U)], &"CurseKeys"),
			Hotkey.new("Set Operator Type", &"focusKeyOperator", [eventKey(KEY_O)], &"OperatorKeys"),
			Hotkey.new("Toggle Infinite", &"focusKeyInfinite", [eventKey(KEY_Y)]),
			Hotkey.new("Toggle Glistening", &"focusKeyGlistening", [eventKey(KEY_G)], &"Glistening"),
			SubTree.new("Operator Key Focused", [
				Hotkey.new("Set Set Operation", &"focusKeyOperationSet", [eventKey(KEY_MASK_SHIFT+KEY_S)], &"OperatorKeys"),
				Hotkey.new("Set Add Operation", &"focusKeyOperationAdd", [eventKey(KEY_MASK_SHIFT+KEY_A)], &"OperatorKeys"),
				Hotkey.new("Set Subtract Operation", &"focusKeyOperationSubtract", [eventKey(KEY_MASK_SHIFT+KEY_M)], &"OperatorKeys"),
				Hotkey.new("Set Multiply Operation", &"focusKeyOperationMultiply", [eventKey(KEY_MASK_SHIFT+KEY_X)], &"OperatorKeys"),
				Hotkey.new("Set Divide Operation", &"focusKeyOperationDivide", [eventKey(KEY_MASK_SHIFT+KEY_D)], &"OperatorKeys"),
				Hotkey.new("Set Modulo Operation", &"focusKeyOperationModulo", [eventKey(KEY_MASK_SHIFT+KEY_R)], &"OperatorKeys"),
			], &"OperatorKeys"),
		]),
		SubTree.new("Door Focused", [
			Hotkey.new("Add Lock", &"focusDoorAddLock", [eventKey(KEY_MASK_CTRL+KEY_E)]),
			Hotkey.new("Toggle Color Link", &"focusDoorColorLink", [eventKey(KEY_MASK_SHIFT+KEY_C)]),
			SubTree.new("Editing Door Properties", [
				Hotkey.new("Toggle Frozen", &"focusDoorFrozen", [eventKey(KEY_F)]),
				Hotkey.new("Toggle Crumbled", &"focusDoorCrumbled", [eventKey(KEY_R)]),
				Hotkey.new("Toggle Painted", &"focusDoorPainted", [eventKey(KEY_T)]),
				Hotkey.new("Toggle Spend Armament", &"focusDoorSpendArmament", [eventKey(KEY_MASK_SHIFT+KEY_A)], &"Armaments"),
				# oscillate
			]),
			SubTree.new("Editing Lock Properties", [
				Hotkey.new("Duplicate Lock", &"focusLockDuplicate", [eventKey(KEY_MASK_CTRL+KEY_D)]),
				Hotkey.new("Set Normal Type", &"focusLockNormal", [eventKey(KEY_N)]),
				Hotkey.new("Set Blank Type", &"focusLockBlank", [eventKey(KEY_B)]),
				Hotkey.new("Set Blast Type", &"focusLockBlast", [eventKey(KEY_X)]),
				Hotkey.new("Set All Type", &"focusLockAll", [eventKey(KEY_A)]),
				Hotkey.new("Set Exact Type", &"focusLockExact", [eventKey(KEY_E)], &"ExactLocks"),
				Hotkey.new("Set Glistening Type", &"focusLockGlistening", [eventKey(KEY_G)], &"Glistening"),
				Hotkey.new("Set Remainder Type", &"focusLockRemainder", [eventKey(KEY_R)], &"RemainderLocks"),
				Hotkey.new("Toggle Negated", &"focusLockNegated", [eventKey(KEY_MASK_SHIFT+KEY_N)], &"NegatedLocks"),
				Hotkey.new("Toggle Armament", &"focusLockArmament", [eventKey(KEY_MASK_SHIFT+KEY_A)], &"Armaments"),
				Hotkey.new("Convert To Remote Lock", &"focusLockConvertRemote", [eventKey(KEY_MASK_SHIFT+KEY_R)], &"RemoteLocks"),
				QuicksetHotkey.new("Quickset Lock Size", &"quicksetLockSize", [eventKey(KEY_S)], LockSizeQuicksetSetting),
			]),
		]),
		SubTree.new("Key Counter Focused", [
			Hotkey.new("Add Element", &"focusKeyCounterAddElement", [eventKey(KEY_MASK_CTRL+KEY_E)]),
		]).setClarification("Relevant hotkeys from \"Editing Door Properties\" and \"Editing Lock Properties\" also apply and take priority."),
		SubTree.new("Remote Lock Focused", [
			Hotkey.new("Add Connection", &"focusRemoteLockAddConnection", [eventKey(KEY_MASK_CTRL+KEY_E)], &"RemoteLocks"),
		], &"RemoteLocks"),
		SubTree.new("Player/Savestate Focused", [
			Hotkey.new("Start Playtest From Focused Spawn", &"focusPlayerStart", [eventKey(KEY_SPACE)]),
			Hotkey.new("Toggle Star", &"focusPlayerStar", [eventKey(KEY_S)]),
			Hotkey.new("Toggle Curse", &"focusPlayerCurse", [eventKey(KEY_U)], &"CurseKeys"),
			Hotkey.new("Leave Savestate", &"focusPlayerSavestate", [eventKey(KEY_MASK_SHIFT+KEY_S)]),
		]),
	]),
]
const HOTKEY_SETTING:PackedScene = preload("res://scenes/settings/hotkeySetting.tscn")
const HOTKEY_GROUP_LABEL_SETTINGS:LabelSettings = preload("res://resources/hotkeyGroupLabelSettings.tres")
static var prerequistedSubTrees:Array[SubTree]

class Hotkey extends RefCounted:
	var label:String
	## The name of the action (in Project -> Project Settings -> Input Map)
	var action:StringName
	## A prerequisite mod, if this is a modded hotkey. Leave blank for no prerequisite
	var prerequisite:StringName
	## Whether or not this is a held modifier.
	var held:bool = false
	var defaultEvents:Array[InputEvent]
	var node:HotkeySetting

	func _init(_label:String, _action:StringName, _defaultEvents:Array[InputEvent], _prerequisite:StringName=&"") -> void:
		label = _label
		action = _action
		defaultEvents = _defaultEvents
		prerequisite = _prerequisite
	
	func setHeld() -> Hotkey:
		held = true
		return self

class QuicksetHotkey extends Hotkey:
	var quicksetSettingType:GDScript
	var quicksetSettingNode:QuicksetSetting

	func _init(_label:String, _action:StringName, _defaultEvents:Array[InputEvent], _quicksetSettingType:GDScript, _prerequisite:StringName=&"") -> void:
		quicksetSettingType = _quicksetSettingType
		super(_label, _action, _defaultEvents, _prerequisite)

class SubTree extends RefCounted:
	var label:String
	var contents:Array
	## A prerequisite mod, if this is a modded hotkey. Leave blank for no prerequisite
	var prerequisite:StringName
	var labelNode:Control
	var containerNode:MarginContainer
	var clarification:String

	func _init(_label:String, _contents:Array, _prerequisite:StringName=&"") -> void:
		label = _label
		contents = _contents
		prerequisite = _prerequisite
		if prerequisite: EditorSettingss.prerequistedSubTrees.append(self)
	
	func setClarification(_clarification:String) -> SubTree:
		clarification = _clarification
		return self

static func eventKey(key:int) -> InputEventKey:
	var event:InputEventKey = InputEventKey.new()
	if key & KEY_MASK_ALT:
		event.alt_pressed = true
		key -= KEY_MASK_ALT
	if key & KEY_MASK_CTRL:
		event.ctrl_pressed = true
		key -= KEY_MASK_CTRL
	if key & KEY_MASK_META:
		event.meta_pressed = true
		key -= KEY_MASK_META
	if key & KEY_MASK_SHIFT:
		event.shift_pressed = true
		key -= KEY_MASK_SHIFT
	event.physical_keycode = key as Key
	return event

func _ready() -> void:
	addHotkeyTree(HotkeyTree, %hotkeys)

func addHotkeyTree(tree:Array, root:Control) -> void:
	for entry in tree:
		if entry is Hotkey:
			var setting:HotkeySetting = HOTKEY_SETTING.instantiate()
			entry.node = setting
			setting.definition = entry
			root.add_child(setting)
			if entry is QuicksetHotkey:
				var container:MarginContainer = MarginContainer.new()
				var subContainer:HBoxContainer = HBoxContainer.new()
				var quicksetSetting:QuicksetSetting = entry.quicksetSettingType.new()
				var buffer:Control = Control.new()
				entry.quicksetSettingNode = quicksetSetting
				buffer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				root.add_child(container)
				container.add_child(subContainer)
				subContainer.add_child(quicksetSetting)
				subContainer.add_child(buffer)
		elif entry is SubTree:
			var label:Label = Label.new()
			label.label_settings = HOTKEY_GROUP_LABEL_SETTINGS
			label.text = entry.label
			if entry.clarification:
				var clarificationContainer:HBoxContainer = HBoxContainer.new()
				root.add_child(clarificationContainer)
				clarificationContainer.add_child(label)
				clarificationContainer.add_child(Clarifier.new(entry.clarification))
				entry.labelNode = clarificationContainer
			else:
				root.add_child(label)
				entry.labelNode = label
			var container:MarginContainer = MarginContainer.new()
			var subContainer:VBoxContainer = VBoxContainer.new()
			entry.containerNode = container
			root.add_child(container)
			container.add_child(subContainer)
			addHotkeyTree(entry.contents, subContainer)

func opened(configFile:ConfigFile) -> void:
	%fileDialogWorkaround.button_pressed = configFile.get_value("editor", "fileDialogWorkaround", false)
	%fullscreen.button_pressed = configFile.get_value("editor", "fullscreen", false)
	%uiScale.value = configFile.get_value("editor", "logUiScale", log(DisplayServer.screen_get_dpi()/96.0)/0.6931471806) # log2
	%edgeResizing.button_pressed = configFile.get_value("editor", "edgeResizing", false)
	_uiScaleSet()
	openedHotkeyTree(configFile, HotkeyTree)
	update()

func openedHotkeyTree(configFile:ConfigFile, tree:Array) -> void:
	for entry in tree:
		if entry is Hotkey:
			InputMap.action_erase_events(entry.action)
			entry.node._reset(configFile.get_value("editor", "hotkey_"+entry.action, entry.defaultEvents))
			if entry is QuicksetHotkey:
				entry.quicksetSettingNode.setMatches(getMatches(configFile, entry.action+"Matches", entry.quicksetSettingType.DEFAULT_MATCHES))
			for button in entry.node.buttons: button.check()
		elif entry is SubTree:
			openedHotkeyTree(configFile, entry.contents)

func closed(configFile:ConfigFile) -> void:
	configFile.set_value("editor", "fileDialogWorkaround", %fileDialogWorkaround.button_pressed)
	configFile.set_value("editor", "fullscreen", %fullscreen.button_pressed)
	configFile.set_value("editor", "logUiScale", %uiScale.value)
	configFile.set_value("editor", "edgeResizing", %edgeResizing.button_pressed)
	closedHotkeyTree(configFile, HotkeyTree)
	update()

func closedHotkeyTree(configFile:ConfigFile, tree:Array) -> void:
	for entry in tree:
		if entry is Hotkey:
			configFile.set_value("editor", "hotkey_"+entry.action, InputMap.action_get_events(entry.action))
			if entry is QuicksetHotkey:
				configFile.set_value("editor", entry.action+"Matches", entry.quicksetSettingType.matches)
		elif entry is SubTree:
			closedHotkeyTree(configFile, entry.contents)

func update() -> void:
	updateFileMenuAction(2, &"editSave")
	if OS.has_feature('web'):
		updateFileMenuAction(3, &"editExport")
	else:
		updateFileMenuAction(3, &"editSaveAs")
		updateFileMenuAction(4, &"editExport")

func changedMods() -> void:
	for subTree in prerequistedSubTrees:
		subTree.labelNode.visible = Mods.active(subTree.prerequisite)
		subTree.containerNode.visible = Mods.active(subTree.prerequisite)

func updateFileMenuAction(index:int,action:StringName) -> void:
	if InputMap.action_get_events(action): Game.editor.fileMenu.menu.set_item_accelerator(index, InputMap.action_get_events(action)[0].get_physical_keycode_with_modifiers())
	else: Game.editor.fileMenu.menu.set_item_accelerator(index, KEY_NONE)

func getMatches(configFile:ConfigFile, matchName:String, default:Array[String]) -> Array[String]:
	var matches:Array[String] = configFile.get_value("editor", matchName, default.duplicate())
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
