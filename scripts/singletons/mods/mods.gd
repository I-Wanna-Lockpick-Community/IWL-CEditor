extends Node
class_name Mods

@onready var editor:Editor = get_node("/root/editor")

static var mods:Dictionary[StringName, Mod] = {
	&"NstdLockSize": Mod.new(
		"Nonstandard Lock Sizes",
		"Allows lock sizes on combo doors other than the ones supported by the basegame",
		[&"NstdLockSize"]
	),
	&"InfCopies": Mod.new(
		"Infinite Copy Doors",
		"Allows doors to have infinite copies",
		[&"InfCopies"]
	),
	&"NoneColor": Mod.new(
		"None Color",
		"Adds the None Color from L4vo5's Lockpick Editor",
		[&"NoneColor"]
	),
	&"C1": Mod.new(
		"IWL:C World 1",
		"Adds Remote Locks and Negated Locks from world 1 of IWL:C",
		[&"RemoteLock", &"NegatedLock"]
	),
	&"C2": Mod.new(
		"IWL:C World 2",
		"Adds Dynamite Keys and Quicksilver Keys from world 2 of IWL:C",
		[&"DynamiteColor", &"QuicksilverColor"]
	),
	&"C3": Mod.new(
		"IWL:C World 3",
		"Adds Partial Blast Locks and Exact Locks from world 3 of IWL:C",
		[&"PartialBlastLock", &"ExactLock"]
	),
	&"C4": Mod.new(
		"IWL:C World 4",
		"Adds Dark Aura Keys and Aura Breaker Keys from world 4 of IWL:C", # maybe we should figure out some official name for these
		[&"DarkAuraColor", &"AuraBreakerColor"]
	),
	&"C5": Mod.new(
		"IWL:C World 5",
		"Adds Curse and Decurse Keys and Lock Armaments from world 5 of IWL:C",
		[&"CurseKeyType", &"LockArmament"]
	),
}

static var modpacks:Dictionary[StringName, Modpack] = {
	&"Refactored": Modpack.new(
		"Refactored",
		"Functionally almost identical to the basegame, but refactored to be easier for development.",
		preload("res://assets/ui/mods/icon/Refactored.png"), preload("res://assets/ui/mods/iconSmall/Refactored.png"),
		[
			Version.new(
				"Newest",
				"2025-10-14",
				"The most up to date version. This shouldn't change that often anyway",
				"https://github.com/apia46/IWannaLockpick/tree/refactored",
				[]
			)
		]
	),
	&"IWLC": Modpack.new(
		"IWL: Continued",
		"The first big modpack of I Wanna Lockpick.",
		preload("res://assets/ui/mods/icon/IWLC.png"), preload("res://assets/ui/mods/iconSmall/IWLC.png"),
		[
			Version.new(
				"C1-C5 Mechanics",
				"202?-??-??",
				"Includes mechanics from C1-C5. If you want to submit levels for IWL:C, you should use this.",
				"https://github.com/I-Wanna-Lockpick-Community/IWannaLockpick-Continued", # change this to the github releases thing
				[&"C1", &"C2", &"C3", &"C4", &"C5"]
			)
		]
	)
}

var activeModpack:Modpack = modpacks[&"Refactored"]
var activeVersion:Version = activeModpack.versions[0]

func active(id:StringName) -> bool:
	return mods[id].active

func getActiveMods() -> Array[StringName]:
	var array:Array[StringName] = []
	for mod in mods.keys():
		if mods[mod].active: array.append(mod)
	return array

func getTempActiveMods() -> Array[StringName]:
	var array:Array[StringName] = []
	for mod in mods.keys():
		if mods[mod].tempActive: array.append(mod)
	return array


func openModsWindow() -> void:
	var window:Window = preload("res://scenes/modsWindow.tscn").instantiate()
	editor.add_child(window)
	window.position = get_window().position+(get_window().size-window.size)/2

func listDependencies(mod:Mod) -> String:
	if mod.dependencies == []: return "No dependencies"
	var string:String = "Dependencies:"
	for id in mod.dependencies:
		string += "\n - " + mods[id].name
	return string

func listIncompatibilities(mod:Mod) -> String:
	if mod.incompatibilities == []: return "No incompatibilities"
	var string:String = "Incompatibilities:"
	for id in mod.incompatibilities:
		string += "\n - " + mods[id].name
	return string

func colors() -> Array[Game.COLOR]:
	var array:Array[Game.COLOR] = [
		Game.COLOR.MASTER,
		Game.COLOR.WHITE, Game.COLOR.ORANGE, Game.COLOR.PURPLE,
		Game.COLOR.RED, Game.COLOR.GREEN, Game.COLOR.BLUE,
		Game.COLOR.PINK, Game.COLOR.CYAN, Game.COLOR.BLACK,
		Game.COLOR.BROWN,
		Game.COLOR.PURE,
		Game.COLOR.GLITCH,
		Game.COLOR.STONE,
	]
	if active(&"C2"): array.append_array([Game.COLOR.DYNAMITE, Game.COLOR.QUICKSILVER])
	if active(&"C4"): array.append_array([Game.COLOR.MAROON, Game.COLOR.FOREST, Game.COLOR.NAVY, Game.COLOR.ICE, Game.COLOR.MUD, Game.COLOR.GRAFFITI])
	return array

func keyTypes() -> Array[KeyBulk.TYPE]:
	var array:Array[KeyBulk.TYPE] = [
		KeyBulk.TYPE.NORMAL,
		KeyBulk.TYPE.EXACT,
		KeyBulk.TYPE.STAR, KeyBulk.TYPE.UNSTAR,
		KeyBulk.TYPE.SIGNFLIP, KeyBulk.TYPE.POSROTOR, KeyBulk.TYPE.NEGROTOR
	]
	if active(&"C5"): array.append_array([KeyBulk.TYPE.CURSE, KeyBulk.TYPE.UNCURSE])
	return array

func lockTypes() -> Array[Lock.TYPE]:
	var array:Array[Lock.TYPE] = [
		Lock.TYPE.NORMAL,
		Lock.TYPE.BLANK,
		Lock.TYPE.BLAST, Lock.TYPE.ALL
	]
	if active(&"C3"): array.append(Lock.TYPE.EXACT)
	return array

class Mod extends RefCounted:
	var active:bool = false
	var tempActive:bool = false # used while in modsWindow
	var name:String
	var description:String
	var dependencies:Array[StringName]
	var incompatibilities:Array[StringName]

	var treeItem:TreeItem # for the menu
	var problems:Dictionary[StringName, Array] # dictionary[problemtype, [gamecomponent]]
	var selectButton:FindProblems.ModSelectButton # for findproblems

	func _init(_name:String,_description:String,_problems:Array[StringName],_dependencies:Array[StringName]=[],_incompatibilities:Array[StringName]=[]) -> void:
		name = _name
		description = _description
		for problem in _problems: problems[problem] = []
		dependencies = _dependencies
		incompatibilities = _incompatibilities
	
	func clearProblems() -> void: for array in problems.values(): array.clear()
	func hasProblems() -> bool:
		for array in problems.values(): if array: return true
		return false

class Modpack extends RefCounted:
	var name:String
	var description:String
	var icon:Texture2D
	var iconSmall:Texture2D
	var versions:Array[Version]

	func _init(_name:String,_description:String,_icon:Texture2D,_iconSmall:Texture2D,_versions:Array[Version]) -> void:
		name = _name
		description = _description
		icon = _icon
		iconSmall = _iconSmall
		versions = _versions

class Version extends RefCounted:
	var name:String
	var date:String
	var description:String
	var mods:Array[StringName]
	var link:String

	func _init(_name:String,_date:String,_description:String,_link:String,_mods:Array[StringName]) -> void:
		name = _name
		date = _date
		description = _description
		link = _link
		mods = _mods
