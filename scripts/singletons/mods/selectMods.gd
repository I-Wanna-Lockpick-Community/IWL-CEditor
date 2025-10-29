extends PanelContainer
class_name SelectMods

@onready var cancelButton:Button = %cancelButton
@onready var nextButton:Button = %nextButton
@onready var modsWindow = get_parent()

# the way the picker is laid out
static var ModTree:Array = [
	&"NstdLockSize", &"InfCopies", &"NoneColor",
	SubTree.new("I Wanna Lockpick: Continued", [&"C1",&"C2",&"C3",&"C4",&"C5"])
]

var undoStack:Array[RefCounted] = [UndoSeparator.new()]
var saveBuffered:bool = false

func setup() -> void:
	updateModpacks()
	updateversions()
	updateMods()
	setInfoModpack(modsWindow.tempActiveModpack)

func updateModpacks() -> void:
	%modpacks.clear()
	var index:int = 0
	for modpack in mods.modpacks.values():
		%modpacks.add_icon_item(modpack.iconSmall,modpack.name)
		if modpack == modsWindow.tempActiveModpack: %modpacks.select(index)
		index += 1
	if !modsWindow.tempActiveModpack:
		%modpacks.add_item("None")
		%modpacks.set_item_disabled(-1, true)
		%modpacks.select(-1)

func updateversions() -> void:
	%versions.clear()
	if modsWindow.tempActiveModpack:
		%versionsLabel.visible = true
		%versions.visible = true
		for version in modsWindow.tempActiveModpack.versions:
			%versions.add_item(version.name)
	else:
		%versionsLabel.visible = false
		%versions.visible = false

func updateMods() -> void:
	%mods.clear()
	var root = %mods.create_item()
	for element in ModTree:
		if element is StringName:
			addModTreeItem(root, element)
		elif element is SubTree:
			var subRoot:TreeItem = %mods.create_item(root)
			subRoot.set_text(0, element.label)
			subRoot.set_selectable(0, false)
			for subElement in element.mods:
				addModTreeItem(subRoot, subElement)

func addModTreeItem(root:TreeItem, id:StringName) -> void:
	var mod:Mods.Mod = mods.mods[id]
	var item:TreeItem = %mods.create_item(root)
	item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
	item.set_text(0, mod.name)
	item.set_editable(0, true)
	item.set_metadata(0, id)
	item.set_checked(0, mod.tempActive)
	mod.treeItem = item

func setMod(mod:Mods.Mod, active:bool) -> bool:
	if mod.tempActive == active: return false
	mod.tempActive = active
	mod.treeItem.set_checked(0, active)
	return true

func _modpackSelected(index:int, manual:bool=false) -> void:
	if index == -1:
		if modsWindow.tempActiveModpack == null: return
		modsWindow.tempActiveModpack = null
		modsWindow.tempActiveVersion = null
	else:
		if modsWindow.tempActiveModpack == mods.modpacks[mods.modpacks.keys()[index]]: return
		modsWindow.tempActiveModpack = mods.modpacks[mods.modpacks.keys()[index]]
		modsWindow.tempActiveVersion = modsWindow.tempActiveModpack.versions[0]
	updateModpacks()
	updateversions()
	if index != -1 and !manual:
		for modId in mods.mods.keys():
			addChange(ModChange.new(self, modId, modId in modsWindow.tempActiveVersion.mods))
	setInfoModpack(modsWindow.tempActiveModpack)
	if !manual: bufferSave()

func _modsDefocused() -> void:
	%mods.deselect_all()
	setInfoModpack(modsWindow.tempActiveModpack)
	bufferSave()

func _modsSelected() -> void:
	var item:TreeItem = %mods.get_selected()
	if !item: return
	var mod:Mods.Mod = mods.mods[item.get_metadata(0)]
	if addChange(ModChange.new(self, item.get_metadata(0), item.is_checked(0))): findModpack()
	setInfoMod(mod)

func findModpack() -> void:
	# get the current modpack (and version) (or none) from selected mods
	# assumes modpack mods are in the correct order
	var activeMods:Array[StringName] = mods.getTempActiveMods()
	var modpackIndex:int = 0
	for modpackId in mods.modpacks.keys():
		var modpack:Mods.Modpack = mods.modpacks[modpackId]
		for version in modpack.versions:
			if activeMods == version.mods:
				_modpackSelected(modpackIndex, true)
				return
		modpackIndex += 1
	_modpackSelected(-1, true)

func setInfoModpack(modpack:Mods.Modpack) -> void:
	if !modpack:
		%info.visible = false
		%noModpackInfo.visible = true
	else:
		%info.visible = true
		%noModpackInfo.visible = false
		%infoName.text = modpack.name

		%modpackInfo.visible = true
		%infoIcon.texture = modpack.icon
		%infoDescription.text = modpack.description

		%versionInfo.visible = true
		%version.text = "Version: [color=#00a2ff][url=" + modsWindow.tempActiveVersion.link + "]" + modsWindow.tempActiveVersion.name + "[/url][/color]"
		%versionDescription.text = modsWindow.tempActiveVersion.description

func _linkClicked(meta):
	OS.shell_open(str(meta))

func setInfoMod(mod:Mods.Mod) -> void:
	%info.visible = true
	%noModpackInfo.visible = false
	%infoName.text = mod.name

	%modpackInfo.visible = false
	%infoDescription.text = mod.description + "\n\n" + mods.listDependencies(mod) + "\n\n" + mods.listIncompatibilities(mod)
	%versionInfo.visible = false

class SubTree extends RefCounted:
	var label:String
	var mods:Array[StringName] # cant recurse yet; maybe at some point

	func _init(_label:String, _mods:Array[StringName]) -> void:
		label = _label
		mods = _mods

# because we want to be able to undo here
func bufferSave() -> void:
	saveBuffered = true

func addChange(change:Change) -> Change:
	if change.cancelled: return null
	undoStack.append(change)
	return change

func _process(_delta) -> void:
	if saveBuffered:
		saveBuffered = false
		if undoStack[-1] is UndoSeparator: return
		undoStack.append(UndoSeparator.new())

func undo() -> bool:
	if len(undoStack) == 1: return false
	if undoStack[-1] is UndoSeparator: undoStack.pop_back()
	saveBuffered = false
	while true:
		if undoStack[-1] is UndoSeparator:
			findModpack()
			setInfoModpack(modsWindow.tempActiveModpack)
			return true
		var change = undoStack.pop_back()
		change.undo()
	return true # unreachable

class Change extends RefCounted:
	var modsWindow:ModsWindow
	var selectMods:SelectMods
	var cancelled:bool = false
	# is a singular recorded change
	# do() subsumed to _init()
	func undo() -> void: pass

class UndoSeparator extends RefCounted:
	# indicates the start/end of an undo in the stack
	func _to_string() -> String:
		return "<UndoSeparator>"

class ModChange extends Change:
	var mod:StringName
	var before:bool

	func _init(_selectMods:SelectMods, _mod:StringName, after:bool) -> void:
		selectMods = _selectMods
		modsWindow = selectMods.modsWindow
		mod = _mod
		before = mods.mods[mod].tempActive
		if before == after:
			cancelled = true
			return
		mods.mods[mod].tempActive = after
		mods.mods[mod].treeItem.set_checked(0, after)
		updateArrays(after)

	func undo() -> void:
		mods.mods[mod].tempActive = before
		mods.mods[mod].treeItem.set_checked(0, before)
		updateArrays(before)
	
	func updateArrays(changedTo:bool) -> void:
		if changedTo:
			if mod in modsWindow.modsRemoved: modsWindow.modsRemoved.erase(mod)
			else: modsWindow.modsAdded.append(mod)
		else:
			if mod in modsWindow.modsAdded: modsWindow.modsAdded.erase(mod)
			else: modsWindow.modsRemoved.append(mod)
		var anythingChanged:bool = modsWindow.modsAdded != [] or modsWindow.modsRemoved != []
		selectMods.nextButton.visible = anythingChanged
		selectMods.cancelButton.text = "Cancel" if anythingChanged else "Close"
