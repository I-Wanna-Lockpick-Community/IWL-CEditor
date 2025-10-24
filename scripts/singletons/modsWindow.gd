extends Window
class_name ModsWindow

# the way the picker is laid out
static var ModTree:Array = [
	&"VarLockSize", &"InfCopies", &"NoneColor",
	SubTree.new("IWL:C", [&"C1",&"C2",&"C3",&"C4",&"C5"])
]

func _ready() -> void:
	updateModpacks()
	updateversions()
	updateMods()
	setInfoModpack(mods.activeModpack)

func updateModpacks() -> void:
	%modpacks.clear()
	var index:int = 0
	for modpack in mods.modpacks.values():
		%modpacks.add_icon_item(modpack.iconSmall,modpack.name)
		if modpack == mods.activeModpack: %modpacks.select(index)
		index += 1
	if !mods.activeModpack:
		%modpacks.add_item("None")
		%modpacks.set_item_disabled(-1, true)
		%modpacks.select(-1)

func updateversions() -> void:
	%versions.clear()
	if mods.activeModpack:
		%versionsLabel.visible = true
		%versions.visible = true
		for version in mods.activeModpack.versions:
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
	item.set_checked(0, mod.active)
	mod.treeItem = item

func setMod(mod:Mods.Mod, active:bool) -> bool:
	if mod.active == active: return false
	mod.active = active
	mod.treeItem.set_checked(0, active)
	return true

func _close() -> void: queue_free()

func _modpackSelected(index:int, manual:bool=false) -> void:
	if index == -1:
		mods.activeModpack = null
		mods.activeVersion = null
	else:
		mods.activeModpack = mods.modpacks[mods.modpacks.keys()[index]]
		mods.activeVersion = mods.activeModpack.versions[0]
	updateModpacks()
	updateversions()
	if index != -1 and !manual:
		for modId in mods.mods.keys():
			setMod(mods.mods[modId], modId in mods.activeVersion.mods)
	setInfoModpack(mods.activeModpack)

func _modsDefocused() -> void:
	%mods.deselect_all()
	setInfoModpack(mods.activeModpack)

func _modsSelected() -> void:
	var item:TreeItem = %mods.get_selected()
	var mod:Mods.Mod = mods.mods[item.get_metadata(0)]
	if setMod(mod, item.is_checked(0)): findModpack()
	setInfoMod(mod)

func findModpack() -> void:
	# get the current modpack (or none) from selected mods
	# assumes modpack mods are in the correct order
	var activeMods:Array[StringName] = mods.getActiveMods()
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
		%version.text = "Version: [color=#00a2ff][url=" + mods.activeVersion.link + "]" + mods.activeVersion.name + "[/url][/color]"
		%versionDescription.text = mods.activeVersion.description

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
