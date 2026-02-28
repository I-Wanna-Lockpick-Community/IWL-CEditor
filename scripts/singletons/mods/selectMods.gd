extends PanelContainer
class_name SelectMods

@onready var cancelButton:Button = %cancelButton
@onready var nextButton:Button = %nextButton
@onready var modsWindow = get_parent()

# the way the select tree is laid out
static var ModTree:Array = [
	&"PartialInfKeys", &"Glistening", &"OperatorKeys",
	SubTree.new(
		"Benign",
		"Mods that don't do much.",
		[&"MoreLockSizes",&"MoreLockConfigs",&"ZeroCostLocks",&"ZeroCopyDoors",&"MoreKeyCounterWidths"]
	),
	SubTree.new(
		"Systems",
		"Mods that change core systems of the game",
		[&"Fractions"]
	),
	SubTree.new(
		"Modpacks",
		"Mods that are based on community ideas.",
		[
			SubTree.new(
				"I Wanna Lockpick: Continued",
				"Mods that were made for the I Wanna Lockpick: Continued modpack.",
				[&"RemoteLocks",&"NegatedLocks", &"DynamiteColor",&"QuicksilverColor", &"PartialBlastLocks",&"ExactLocks", &"DarkAuraColors",&"AuraBreakerColors", &"CurseKeys",&"Armaments",&"RemainderLocks"]
			),
			SubTree.new(
				"Negative Worlds",
				"(by Something) Wow.. it's like these worlds are negative,,, (so far its just error)",
				[&"ErrorColor"]
			),
		]
	),
	SubTree.new(
		"Lockpick Editor Compatibility",
		"Mods to mimic unique behaviour from L4Vo5's Lockpick Editor",
		[&"InfCopyDoors",&"NoneColor"]
	),
	SubTree.new(
		"Possibly Misleading",
		"Surely this is a good idea",
		[&"DisconnectedLocks",&"OutOfBounds"]
	),
]

class SubTree extends RefCounted:
	var label:String
	var description:String
	var mods:Array

	func _init(_label:String, _description:String, _mods:Array) -> void:
		label = _label
		description = _description
		mods = _mods

var undoStack:Array[RefCounted] = [UndoSeparator.new()]
var saveBuffered:bool = false

var hoveredItem:Control # the hovered modtree item

func setup() -> void:
	updateModpacks()
	updateVersions()
	updateMods()
	setInfoModpack(modsWindow.tempActiveModpack, modsWindow.tempActiveVersion)

func updateModpacks() -> void:
	%modpacks.clear()
	var index:int = 0
	for modpack in Mods.modpacks.values():
		%modpacks.add_icon_item(modpack.iconSmall,modpack.name)
		if modpack == modsWindow.tempActiveModpack: %modpacks.select(index)
		index += 1
	if !modsWindow.tempActiveModpack:
		%modpacks.add_item("None")
		%modpacks.set_item_disabled(-1, true)
		%modpacks.select(-1)

func updateVersions() -> void:
	%versions.clear()
	if modsWindow.tempActiveModpack:
		%versionsLabel.visible = true
		%versions.visible = true
		var index:int = 0
		for version in modsWindow.tempActiveModpack.versions:
			%versions.add_item(version.name)
			if version == modsWindow.tempActiveVersion: %versions.select(index)
			index += 1
	else:
		%versionsLabel.visible = false
		%versions.visible = false

func updateMods() -> void:
	for child in %mods.get_children(): child.queue_free()
	addModTree(%mods, ModTree)

func addModTree(root:VBoxContainer, mods:Array) -> void:
	for element in mods:
		if element is StringName:
			addModTreeItem(root, element)
		elif element is SubTree:
			var subTreeNode:ModTreeSubTree = preload("res://scenes/mods/modTreeSubTree.tscn").instantiate()
			subTreeNode.selectMods = self
			subTreeNode.subTree = element
			root.add_child(subTreeNode)
			addModTree(subTreeNode.cont, element.mods)

func addModTreeItem(root:VBoxContainer, id:StringName) -> void:
	var item:ModTreeItem = preload("res://scenes/mods/modTreeItem.tscn").instantiate()
	item.selectMods = self
	item.modId = id
	item.mod = Mods.mods[id]
	Mods.mods[id].treeItem = item
	root.add_child(item)

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
		if modsWindow.tempActiveModpack == Mods.modpacks[Mods.modpacks.keys()[index]]: return
		modsWindow.tempActiveModpack = Mods.modpacks.values()[index]
		modsWindow.tempActiveVersion = modsWindow.tempActiveModpack.versions[modsWindow.tempActiveModpack.defaultVersion]
	updateModpacks()
	updateVersions()
	if index != -1 and !manual:
		for modId in Mods.mods.keys():
			if !Mods.mods[modId].disclosatory: addChange(ModChange.new(self, modId, modId in modsWindow.tempActiveVersion.mods))
	if !manual:
		setInfoModpack(modsWindow.tempActiveModpack, modsWindow.tempActiveVersion)
		bufferSave()

func _versionSelected(index:int, manual:bool=false) -> void:
	if modsWindow.tempActiveVersion == modsWindow.tempActiveModpack.versions[index]: return
	modsWindow.tempActiveVersion = modsWindow.tempActiveModpack.versions[index]
	if !manual:
		for modId in Mods.mods.keys():
			if !Mods.mods[modId].disclosatory: addChange(ModChange.new(self, modId, modId in modsWindow.tempActiveVersion.mods))
		setInfoModpack(modsWindow.tempActiveModpack, modsWindow.tempActiveVersion)
		bufferSave()

func _treeItemHovered(item:Control) -> void:
	hoveredItem = item
	if item is ModTreeItem:
		%info.visible = true
		%noModpackInfo.visible = false
		%infoName.text = item.mod.name

		%modpackInfo.visible = false
		%infoDescription.text = item.mod.description + "\n\n" + Mods.listDependencies(item.mod) + "\n\n" + Mods.listIncompatibilities(item.mod)
		%versionInfo.visible = false
	elif item is ModTreeSubTree:
		%info.visible = true
		%noModpackInfo.visible = false
		%infoName.text = item.subTree.label

		%modpackInfo.visible = false
		%infoDescription.text = item.subTree.description
		%versionInfo.visible = false

func _treeItemUnhovered(item:Control) -> void:
	if item != hoveredItem: return
	hoveredItem = null
	setInfoModpack(modsWindow.tempActiveModpack, modsWindow.tempActiveVersion)

func _modChanged(mod:StringName, toggled_on:bool) -> void:
	if addChange(ModChange.new(self, mod, toggled_on)):
		findModpack()
		bufferSave()

func findModpack() -> void:
	# get the current modpack (and version) (or none) from selected Mods
	# assumes modpack Mods are in the correct order
	var activeMods:Array[StringName] = Mods.getTempActiveMods(false)
	var modpackIndex:int = 0
	for modpackId in Mods.modpacks.keys():
		var modpack:Mods.Modpack = Mods.modpacks[modpackId]
		for version in modpack.versions:
			if activeMods == version.mods:
				_modpackSelected(modpackIndex, true)
				return
		modpackIndex += 1
	_modpackSelected(-1, true)

func setInfoModpack(modpack:Mods.Modpack,version:Mods.Version) -> void:
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
		%version.text = "Version: [color=#00a2ff][url=" + version.link + "]" + version.name + "[/url][/color]"
		%versionDescription.text = version.description

func _linkClicked(meta):
	OS.shell_open(str(meta))

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
			setInfoModpack(modsWindow.tempActiveModpack, modsWindow.tempActiveVersion)
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
		before = Mods.mods[mod].tempActive
		if before == after:
			cancelled = true
			return
		Mods.mods[mod].tempActive = after
		Mods.mods[mod].treeItem.button.button_pressed = after
		updateArrays(after)

	func undo() -> void:
		Mods.mods[mod].tempActive = before
		Mods.mods[mod].treeItem.button.button_pressed = before
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
