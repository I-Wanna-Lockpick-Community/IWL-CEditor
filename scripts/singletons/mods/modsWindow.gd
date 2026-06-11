extends Window
class_name ModsWindow

enum STAGE {SELECT_MODS, FIND_PROBLEMS}
var stage:STAGE = STAGE.SELECT_MODS

var modsAdded:Array[StringName] # Mods that have been added
var modsRemoved:Array[StringName] # Mods that have been added

var tempActiveModpack:Mods.Modpack = Mods.activeModpack
var tempActiveVersion:Mods.Version = Mods.activeVersion

func _ready() -> void:
	%selectMods.visible = true
	%findProblems.visible = false
	for mod in Mods.mods.values():
		mod.tempActive = mod.active
	%selectMods.setup()
	Game.editor.modsWindow = self

func _input(event:InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		match event.keycode:
			KEY_Z: if Input.is_key_pressed(KEY_CTRL) and %selectMods.visible: %selectMods.undo()

func _close() -> void: queue_free()

func _next() -> void:
	%selectMods.visible = false
	%findProblems.visible = true
	title = "Find Problems"
	stage = STAGE.FIND_PROBLEMS
	%findProblems.setup()

func _back():
	%selectMods.visible = true
	%findProblems.visible = false
	title = "Select Mods"
	stage = STAGE.SELECT_MODS

func _saveChanges():
	if Game.playState != Game.PLAY_STATE.EDIT: Game.stopTest()
	Changes.addChange(Changes.GlobalPropertyChange.new(Mods,&"activeModpack",tempActiveModpack))
	Changes.addChange(Changes.GlobalPropertyChange.new(Mods,&"activeVersion",tempActiveVersion))
	for mod in Mods.mods.values():
		Changes.addChange(Changes.GlobalPropertyChange.new(mod,&"active",mod.tempActive))
	
	Mods.updateNumberSystem()

	for mod in modsAdded: addMod(mod)
	for mod in modsRemoved: removeMod(mod)

	if !Mods.objectAvailable(Game.editor.otherObjects.selected): Game.editor.otherObjects.objectSelected(PlayerSpawn, true)
	
	var availableColors:Array[C.olors] = Mods.colors()
	for playerSpawn in Game.objects.values().filter(func(object): return object is PlayerSpawn):
		if playerSpawn == Game.levelStart: continue
		if &"CurseKeys" in modsRemoved: Changes.addChange(Changes.ArrayElementChange.new(playerSpawn,&"curse",C.olors.BROWN,true))
		for color in Colors.COLORS:
			if color in availableColors: continue
			playerSpawn.resetColor(color)
	
	if Game.editor.focusDialog.interacted: Game.editor.focusDialog.interacted.evaluate()

	Changes.bufferSave()
	Game.editor.grab_focus()
	Mods.bufferModsChanged()
	queue_free()

func addMod(mod:StringName):
	match mod:
		&"MoreLockConfigs":
			for component in Game.components.values():
				if component is Lock and component.parent.type == Door.TYPE.SIMPLE: component._setAutoConfiguration()
			for object in Game.objects.values():
				if object is RemoteLock: object._setAutoConfiguration()

func removeMod(mod:StringName):
	match mod:
		&"MoreLockConfigs":
			for component in Game.components.values():
				if component is Lock and component.parent.type == Door.TYPE.SIMPLE: component._setAutoConfiguration()
			for object in Game.objects.values():
				if object is RemoteLock: object._setAutoConfiguration()
