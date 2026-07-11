@tool
extends Node

var editor:Editor

enum ACTION {NEW, OPEN, SAVE_FOR_PLAY, NONE}

var savePath:String = ""
var confirmAction:ACTION

var jsCallback:JavaScriptObject

const FILE_FORMAT_VERSION:int = 3
const FILE_VERSIONS_PATH:String = "res://resources/fileVersions/"
var FILE_VERSIONS:Array[FileVersion] = []
var FILE_VERSION:FileVersion

# Okay.
# Here's how we'll do it
# HEADER:
# - file format header
# - file format version number
# - last opened editor version
# LEVEL METADATA:
# - level object
# - screenshot
# - active mods
# - modpack
# - modpack version
# - levelstart
# LEVEL DATA:
# - tiles
# - components
# - objects
# - notes

func _ready() -> void:
	if Engine.is_editor_hint(): return
	for i in FILE_FORMAT_VERSION:
		FILE_VERSIONS.append(load(FILE_VERSIONS_PATH + str(i+1) + ".tres"))
	FILE_VERSION = FILE_VERSIONS[-1]
	if OS.has_feature('web'):
		JavaScriptBridge.eval("window.callbacks = {loadJs: null};")

func editorReady() -> void:
	if !OS.has_feature('web'):
		DirAccess.make_dir_absolute("user://puzzles")
		DirAccess.make_dir_absolute("user://exports")
	editor.saveAsDialog.add_filter("*.cedit", "IWLCEditor Puzzle File")
	editor.openDialog.add_filter("*.cedit", "IWLCEditor Puzzle File")
	editor.unsavedChangesPopup.get_ok_button().theme_type_variation = &"RadioButtonText"
	editor.unsavedChangesPopup.get_cancel_button().theme_type_variation = &"RadioButtonText"
	editor.unsavedChangesPopup.get_ok_button().pressed.connect(confirmed)
	editor.loadErrorPopup.get_ok_button().theme_type_variation = &"RadioButtonText"
	editor.saveAsDialog.file_selected.connect(save)
	editor.openDialog.file_selected.connect(loadFile)

func open() -> void:
	confirmAction = ACTION.OPEN
	if Game.anyChanges:
		@warning_ignore("integer_division")
		editor.unsavedChangesPopup.position = get_window().position+(get_window().size-editor.unsavedChangesPopup.size)/2
		editor.unsavedChangesPopup.visible = true
		editor.unsavedChangesPopup.grab_focus()
	else: confirmed()

func saveAs() -> void:
	editor.saveAsDialog.current_dir = "puzzles"
	editor.saveAsDialog.current_file = Game.level.name+".cedit"
	editor.saveAsDialog.visible = true
	editor.saveAsDialog.grab_focus()

func new() -> void:
	confirmAction = ACTION.NEW
	if Game.anyChanges:
		@warning_ignore("integer_division")
		editor.unsavedChangesPopup.position = get_window().position+(get_window().size-editor.unsavedChangesPopup.size)/2
		editor.unsavedChangesPopup.visible = true
		editor.unsavedChangesPopup.grab_focus()
	else: confirmed()

func confirmed() -> void:
	match confirmAction:
		ACTION.NEW: clear()
		ACTION.OPEN:
			if OS.has_feature('web'):
				jsCallback = JavaScriptBridge.create_callback(loadJs)
				JavaScriptBridge.get_interface("callbacks").loadJs = jsCallback
				JavaScriptBridge.eval("
					const input = document.createElement('input');
					input.setAttribute('type', 'file');
					input.setAttribute('accept', '.cedit');
					input.addEventListener('change', event=>{
						const reader = new FileReader();
						reader.onload = ()=>{
							let array = new Uint8Array(reader.result);
							callbacks.loadJs(array.toBase64());
						}
						reader.readAsArrayBuffer(event.target.files[0]);
						input.remove();
					});
					input.click();
				")
			else:
				editor.openDialog.current_dir = "puzzles"
				editor.openDialog.visible = true
				editor.openDialog.grab_focus()

func clear() -> void:
	savePath = ""
	if editor:
		editor.focusDialog.defocus()
		editor.objectHovered = null
		editor.componentHovered = null
		editor.componentDragged = null
		editor.lockBufferConvert = false
		editor.connectionSource = null
		if editor.modsWindow: editor.modsWindow._close()
		editor.quickSet.applyOrCancel()
		editor.modes.setMode(Editor.MODE.SELECT)
		editor.modes.setView(Editor.VIEW.NORMAL)
		editor.modes.otherObjects.objectSelected(PlayerSpawn, true)
		editor.multiselect.deselect()
		editor.multiselect.clipboard.clear()
		editor.modes.paste.disabled = true
	if Game.playState != Game.PLAY_STATE.EDIT: await Game.stopTest()
	Game.latestSpawn = null
	Game.levelStart = null
	Game.fastAnimSpeed = 0
	Game.fastAnimTimer = 0
	Game.complexViewHue = 0
	Game.goldIndexFloat = 0
	Game.objectIdIter = 0
	Game.componentIdIter = 0
	Game.noteIdIter = 0
	for object in Game.objects.values(): object.queue_free()
	Game.objects.clear()
	for component in Game.components.values(): component.queue_free()
	Game.components.clear()
	for note in Game.notes.values(): note.queue_free()
	Game.notes.clear()
	Game.level = Level.new()
	Game.anyChanges = false
	Game.tiles.clear()
	Game.tilesDropShadow.clear()
	Changes.undoStack.clear()
	Changes.undoStack.append(Changes.UndoSeparator.new())
	Changes.stackPosition = 0
	Mods.activeModpack = Mods.modpacks[&"Refactored"]
	Mods.activeVersion = Mods.activeModpack.versions[0]
	for mod in Mods.mods.values(): mod.active = false
	Mods.updateNumberSystem()
	Mods.bufferModsChanged()
	Game.level.activate()
	if editor: editor.home()

func save(path:String="") -> void:
	if OS.has_feature('web'):
		savePath = "user://temp.cedit"
		path = savePath
	elif !path:
		if savePath:
			path = savePath
			if !Game.anyChanges:
				if confirmAction == ACTION.SAVE_FOR_PLAY: Game.playSaved()
				return
		else: return saveAs()
	else: savePath = path
	Game.anyChanges = false

	print("opening " + path)
	var file:FileAccess = FileAccess.open(path,FileAccess.ModeFlags.WRITE_READ)
	if !file:
		print("error opening, " + str(FileAccess.get_open_error()))
		if OS.has_feature('web'): return
		print("trying to save to some default")
		file = FileAccess.open("user://backup.cedit",FileAccess.ModeFlags.WRITE_READ)
		if !file:
			print("error opening again, " + str(FileAccess.get_open_error()))
			print("giving up")
			return

	# HEADER
	file.store_pascal_string("IWLCEditorLevel")
	file.store_32(FILE_FORMAT_VERSION)
	file.store_pascal_string(ProjectSettings.get_setting("application/config/version"))
	# LEVEL METADATA
	file.store_var(Game.level,true)
	await editor.takeScreenshot()
	file.store_var(editor.screenshot,true)
	file.store_var(Mods.getActiveMods())
	var modpackId = Mods.modpacks.find_key(Mods.activeModpack)
	file.store_var(modpackId if modpackId else &"")
	if Mods.activeModpack: file.store_32(Mods.activeModpack.versions.find(Mods.activeVersion))
	file.store_64(Game.levelStart.id if Game.levelStart else -1)
	# LEVEL DATA
	# tiles
	file.store_var(Game.tiles.tile_map_data)
	# components
	file.store_64(Game.componentIdIter)
	file.store_64(len(Game.components))
	for component in Game.components.values(): storeComponent(file, component)
	# objects
	file.store_64(Game.objectIdIter)
	file.store_64(len(Game.objects))
	for object in Game.objects.values(): storeComponent(file, object)
	# notes
	file.store_64(Game.noteIdIter)
	file.store_64(len(Game.notes))
	for note in Game.notes.values(): storeComponent(file, note)
	file.close()
	if OS.has_feature('web') and confirmAction != ACTION.SAVE_FOR_PLAY:
		JavaScriptBridge.download_buffer(FileAccess.get_file_as_bytes(path),Game.level.name+".cedit")
	
	if confirmAction == ACTION.SAVE_FOR_PLAY: Game.playSaved()

func storeComponent(file:FileAccess, component:GameComponent) -> void:
	if component is PlaceholderObject: return
	file.store_16(Game.COMPONENTS.find(component.get_script()))
	var typeDef:ComponentTypeDef = FILE_VERSION.typeDefs[component.get_script()]
	for property in typeDef.savedProperties: file.store_var(component.get(property), true)
	for array in typeDef.savedArrays: file.store_var(component.get(array))
	for array in typeDef.savedComponentArrays: file.store_var(componentArrayToIDs(component.get(array)))

func arrayTypeIsComponent(arrayType) -> bool: return arrayType is GDScript and arrayType in Game.COMPONENTS

func componentArrayToIDs(array:Array) -> Array: return array.map(func(component):return component.id)
func IDArraytoComponents(type:GDScript,array:Array) -> Array:
	if type in Game.NON_OBJECT_COMPONENTS: return array.map(func(id):return Game.components[id])
	else: return array.map(func(id):return Game.objects[id])

func loadFile(path:String, immediate:bool=false) -> OpenWindow:
	var openWindow:OpenWindow = preload("res://scenes/openWindow.tscn").instantiate()
	openWindow.path = path

	if path.get_extension() != "cedit": errorPopup("Unrecognised file format"); return null

	var file:FileAccess = FileAccess.open(path,FileAccess.ModeFlags.READ)

	var checkString:String = file.get_pascal_string()
	if checkString != "IWLCEditorLevel":
		if len(checkString) > 30: errorPopup("Unrecognised file format, check string was %s..." + checkString.substr(0, 30))
		else: errorPopup("Unrecognised file format, check string was " + checkString)
		return null
	var formatVersion:int = file.get_32()
	var editorVersion:String = file.get_pascal_string()
	openWindow.fileVersion = FILE_VERSIONS[formatVersion-1]
	if formatVersion == 0:
		openWindow.queue_free()
		if formatVersion == 0: errorPopup("File version 0 is unrecognised")
		return null
	elif formatVersion <= FILE_FORMAT_VERSION: openWindow.loader = LoadV1toCurrent
	else:
		openWindow.queue_free()
		errorPopup("File version %s is unrecognised. File last opened in IWLCEditor v%s" % [formatVersion, editorVersion])
		return null
	openWindow.level = file.get_var(true)
	openWindow.screenshot = file.get_var(true)
	openWindow.mods = migrateModNames(file.get_var(), formatVersion)
	var modpackId:StringName = file.get_var()
	if modpackId:
		openWindow.modpack = Mods.modpacks[modpackId]
		openWindow.version = Mods.modpacks[modpackId].versions[file.get_32()]
	openWindow.levelStart = file.get_64()
	openWindow.file = file
	if immediate: openWindow.resolve()
	else:
		@warning_ignore("integer_division") if !OS.has_feature("web"): openWindow.position = get_window().position+(get_window().size-openWindow.size)/2
		editor.add_child(openWindow)
	return openWindow

func migrateModNames(mods:Array[StringName], formatVersion:int) -> Array[StringName]:
	if formatVersion < 3:
		var toReturn:Array[StringName] = []
		for mod in mods:
			match mod:
				&"NstdLockSize": toReturn.append(&"MoreLockSizes")
				&"ZeroCopies": toReturn.append(&"ZeroCopyDoors")
				&"ZeroCostLock": toReturn.append(&"ZeroCostLocks")
				&"InfCopies": toReturn.append(&"InfCopyDoors")
				&"C1": toReturn.append_array([&"RemoteLocks", &"NegatedLocks"])
				&"C2": toReturn.append_array([&"DynamiteColor", &"QuicksilverColor"])
				&"C3": toReturn.append_array([&"PartialBlastLocks", &"ExactLocks"])
				&"C4": toReturn.append_array([&"DarkAuraColors", &"AuraBreakerColors"])
				&"C5": toReturn.append_array([&"CurseKeys", &"Armaments"])
				&"DisconnectedLock": toReturn.append(&"DisconnectedLocks")
				_: toReturn.append(mod)
		return toReturn
	return mods

func loadJs(result) -> void:
	var buffer:PackedByteArray = Marshalls.base64_to_raw(result[0])
	var file = FileAccess.open("user://temp.cedit",FileAccess.ModeFlags.WRITE)
	file.store_buffer(buffer)
	file.close()
	loadFile("user://temp.cedit")

func errorPopup(message:String,title:="Load Error") -> void:
	editor.loadErrorPopup.title = title
	editor.loadErrorPopup.dialog_text = message
	@warning_ignore("integer_division")
	editor.loadErrorPopup.position = get_window().position+(get_window().size-editor.loadErrorPopup.size)/2
	editor.loadErrorPopup.visible = true
	editor.loadErrorPopup.grab_focus()

func openExportWindow() -> void:
	if editor.exportWindow:
		editor.exportWindow.grab_focus()
	else:
		var window:Window = preload("res://scenes/exportWindow.tscn").instantiate()
		editor.add_child(window)
		@warning_ignore("integer_division")
		if !OS.has_feature("web"): window.position = get_window().position+(get_window().size-window.size)/2
