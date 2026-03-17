extends Node
var editor:Editor

static var mods:Dictionary[StringName, Mod] = {
	&"MoreLockSizes": Mod.new(
		"More Lock Sizes",
		"Adds the option for locks on combo doors to be of arbitrary sizes",
		{&"NstdLockSize": ComponentProblem.new([Lock], func(component:GameComponent) -> bool: \
			return component.parent.type != Door.TYPE.SIMPLE and component.size not in Lock.SIZES
		, "Nonstandard Lock Size")}
	),
	&"ErrorColor": Mod.new(
		"Error Color",
		"Adds the Error Color from the Negative Worlds",
		{&"ErrorColorUsed": ColorProblem.new([Game.COLOR.ERROR], "Error Color Used")},
	),
	&"MoreLockConfigs": Mod.new(
		"More Lock Configurations",
		"Adds predefined lock configurations for 7, 9, 10, 11, and 13 locks, as well as an alternative configuration for 24 locks.\nDesigns by JustImagineIt and themetah",
		{&"NstdLockConfig": ComponentProblem.new([Lock], func(component:GameComponent) -> bool: \
			return component.parent.type != Door.TYPE.SIMPLE and component.configuration in [
				Lock.CONFIGURATION.spr7A, Lock.CONFIGURATION.spr9A, Lock.CONFIGURATION.spr9B, Lock.CONFIGURATION.spr10A, Lock.CONFIGURATION.spr11A, Lock.CONFIGURATION.spr13A,
				Lock.CONFIGURATION.spr24B
			]
		, "Nonstandard Lock Configuration")}
	),
	&"ZeroCopyDoors": Mod.new(
		"Zero Copy Doors",
		"Allows doors to have zero copies",
		{&"ZeroCopyDoor": ComponentProblem.new([Door], func(component:GameComponent) -> bool: \
			return M.nex(component.copies)
		, "Zero Copy Door")}, true
	),
	&"ZeroCostLocks": Mod.new(
		"Zero Cost Locks",
		"Allows locks to have a cost of zero",
		{&"ZeroCostLock": ComponentProblem.new([Lock, RemoteLock], func(component:GameComponent) -> bool: \
			return M.nex(component.count) and component.type not in [Lock.TYPE.BLAST, Lock.TYPE.ALL, Lock.TYPE.EXACT]
		, "Zero Cost Lock")}, true
	),
	&"InfCopyDoors": Mod.new(
		"Infinite Copy Doors",
		"Adds the option for doors to have infinite copies",
		{&"InfCopyDoor": ComponentProblem.new([Door], func(component:GameComponent) -> bool: \
			return M.ex(component.infCopies)
		, "Infinite Copy Door")}
	),
	&"NoneColor": Mod.new(
		"None Color",
		"Adds the None color from L4vo5's Lockpick Editor",
		{&"NoneColorUsed": ColorProblem.new([Game.COLOR.NONE], "None Color Used")}
	),
	&"RemoteLocks": Mod.new(
		"Remote Locks",
		"Adds Remote Locks from world 1 of IWL:C",
		{&"RemoteLock":  ComponentProblem.new([RemoteLock], func(_component:GameComponent) -> bool: \
			return true
		, "Remote Lock")}
	),
	&"NegatedLocks": Mod.new(
		"Negated Locks",
		"Adds the Negated property for Locks from world 1 of IWL:C",
		{&"NegatedLock": ComponentProblem.new([Lock, RemoteLock], func(component:GameComponent) -> bool: \
			return component.negated
		, "Negated Lock")}
	),
	&"DynamiteColor": Mod.new(
		"Dynamite Color",
		"Adds the Dynamite color from world 2 of IWL:C",
		{&"DynamiteColorUsed": ColorProblem.new([Game.COLOR.DYNAMITE], "Dynamite Color Used")}
	),
	&"QuicksilverColor": Mod.new(
		"Quicksilver Color",
		"Adds the Quicksilver color from world 2 of IWL:C",
		{&"QuicksilverColorUsed": ColorProblem.new([Game.COLOR.QUICKSILVER], "Quicksilver Color Used")}
	),
	&"PartialBlastLocks": Mod.new(
		"Partial Blast Locks",
		"Adds the Partial Blast type for Locks from world 3 of IWL:C",
		{&"PartialBlastLock": ComponentProblem.new([Lock, RemoteLock], func(component:GameComponent) -> bool: \
			return component.type == Lock.TYPE.BLAST and (component.isPartial or M.neq(component.count, component.denominator)) \
				or component.type == Lock.TYPE.ALL and (component.isPartial or M.neq(component.count, M.ONE) or M.neq(component.denominator, M.ONE))
		, "Partial Blast Lock")}
	),
	&"ExactLocks": Mod.new(
		"Exact Locks",
		"Adds the Exact type for Locks from world 3 of IWL:C",
		{&"ExactLock": ComponentProblem.new([Lock, RemoteLock], func(component:GameComponent) -> bool: \
			return component.type == Lock.TYPE.EXACT
		, "Exact Lock")}
	),
	&"DarkAuraColors": Mod.new(
		"Dark Aura Colors",
		"Adds the Dark Aura colors from world 4 of IWL:C",
		{&"DarkAuraColorUsed": ColorProblem.new([Game.COLOR.MAROON, Game.COLOR.FOREST, Game.COLOR.NAVY], "Dark Aura Color Used")}
	),
	&"AuraBreakerColors": Mod.new(
		"Aura Breaker Colors",
		"Adds the Aura Breaker colors from world 4 of IWL:C",
		{&"AuraBreakerColorUsed": ColorProblem.new([Game.COLOR.ICE, Game.COLOR.MUD, Game.COLOR.GRAFFITI], "Aura Breaker Color Used")}
	),
	&"CurseKeys": Mod.new(
		"Curse/Uncurse Keys",
		"Adds Curse and Uncurse Keys from world 5 of IWL:C",
		{&"CurseKey": ComponentProblem.new([KeyBulk], func(component:GameComponent) -> bool: \
			return component.type == KeyBulk.TYPE.CURSE
		, "Curse/Uncurse Key")}
	),
	&"Armaments": Mod.new(
		"Armaments",
		"Adds Armaments from world 5 of IWL:C",
		{&"LockArmament": ComponentProblem.new([Lock, RemoteLock], func(component:GameComponent) -> bool: \
			return component.armament
		, "Lock Armament")}
	),
	&"RemainderLocks": Mod.new(
		"Remainder Locks",
		"Adds Remainder Locks from world 6 of IWL:C. Added by Bored",
		{&"RemainderLock": ComponentProblem.new([Lock, RemoteLock], func(component:GameComponent) -> bool: \
			return component.type == Lock.TYPE.REMAINDER
		, "Remainder Lock")}
	),
	&"DisconnectedLocks": Mod.new(
		"Disconnected Locks",
		"Allows locks of a door to be visually disconnected from it",
		{&"DisconnectedLock": ComponentProblem.new([Lock], func(component:GameComponent) -> bool: \
			return !Rect2(component.getOffset(), component.parent.size).intersects(Rect2(component.position, component.size))
		, "Disconnected Lock")}, true
	),
	&"OutOfBounds": Mod.new(
		"Out of Bounds",
		"Allows objects to be placed out of level bounds",
		{&"OutOfBounds": ComponentProblem.new([GameObject], func(component:GameComponent) -> bool: \
			return !Game.levelBounds.intersects(Rect2(component.position, component.size))
		, "Object Out Of Bounds")}, true
	),
	&"PartialInfKeys": Mod.new(
		"Partial Infinite Keys",
		"Adds the option for infinite keys to only become re-available every N key collects",
		{&"PartialInfKey": ComponentProblem.new([KeyBulk], func(component:GameComponent) -> bool: \
			return component.infinite not in [0, 1]
		, "Partial Infinite Key")}
	),
	&"Fractions": Mod.new(
		"Fractions",
		"The fractional number type",
		{}
	),
	&"Glistening": Mod.new(
		"Glistening",
		"Adds Glistening keys and locks. Added by Bored",
		{&"GlisteningKey": ComponentProblem.new([KeyBulk], func(component:GameComponent) -> bool: \
			return component.glistening
		, "Glistening Key"),
		&"GlisteningLock": ComponentProblem.new([Lock, RemoteLock], func(component:GameComponent) -> bool: \
			return component.type == Lock.TYPE.GLISTENING
		, "Glistening Lock")}
	),
	&"MoreKeyCounterWidths": Mod.new(
		"More Key Counter Widths",
		"Adds larger sizes for key counters. Added by Bored",
		{&"NstdKeyCounterWidth": ComponentProblem.new([KeyCounter], func(component:GameComponent) -> bool: \
			return KeyCounter.WIDTH_AMOUNT.find(component.size.x) in [KeyCounter.WIDTH.VLONG, KeyCounter.WIDTH.EXLONG]
		, "Nonstandard Key COunter Width")}
	),
	&"OperatorKeys": Mod.new(
		"Operator Keys",
		"Adds Operator keys and Reciprocal keys. Added by Bored",
		{&"OperatorKey": ComponentProblem.new([KeyBulk], func(component:GameComponent) -> bool: \
			return component.type == KeyBulk.TYPE.OPERATOR
		, "Operator Key"),
		&"ReciprocalKey": ComponentProblem.new([KeyBulk], func(component:GameComponent) -> bool: \
			return component.reciprocal
		, "Reciprocal Key")}
	),
	&"CosmicColor": Mod.new(
		"Cosmic Color",
		"Adds the Cosmic color. Added by Bored",
		{&"CosmicColorUsed": ColorProblem.new([Game.COLOR.COSMIC], "Cosmic Color Used")}
	)
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
				"2025-12-26",
				"Includes mechanics from C1-C5. For backwards compatibility.",
				"https://github.com/I-Wanna-Lockpick-Community/IWannaLockpick-Continued/releases/tag/demo1",
				[&"RemoteLocks", &"NegatedLocks", &"DynamiteColor", &"QuicksilverColor", &"PartialBlastLocks", &"ExactLocks", &"DarkAuraColors", &"AuraBreakerColors", &"CurseKeys", &"Armaments"]
			),
			Version.new(
				"C1-C6 Mechanics",
				"202?-??-??",
				"Includes mechanics from C1-C6. If you want to submit levels for IWL:C, you should use this.",
				"https://github.com/I-Wanna-Lockpick-Community/IWannaLockpick-Continued",
				[&"RemoteLocks", &"NegatedLocks", &"DynamiteColor", &"QuicksilverColor", &"PartialBlastLocks", &"ExactLocks", &"DarkAuraColors", &"AuraBreakerColors", &"CurseKeys", &"Armaments", &"Fractions", &"OperatorKeys",&"RemainderLocks"]
			)
		], 1
	)
}

var activeModpack:Modpack = modpacks[&"Refactored"]
var activeVersion:Version = activeModpack.versions[0]

var bufferedModsChanged:bool = false

func bufferModsChanged() -> void: bufferedModsChanged = true

func updateNumberSystem() -> void:
	var previousNumberSystem:M.SYSTEM = M.system
	M.system = int(active(&"Fractions")) as M.SYSTEM
	if M.system != previousNumberSystem: get_tree().call_group("hasNumbers", "convertNumbers", previousNumberSystem)

func active(id:StringName) -> bool:
	return mods[id].active

func getActiveMods() -> Array[StringName]:
	var array:Array[StringName] = []
	for mod in mods.keys():
		if mods[mod].active: array.append(mod)
	return array

func getTempActiveMods(includeDisclosatory:bool=true) -> Array[StringName]:
	var array:Array[StringName] = []
	for mod in mods.keys():
		if mods[mod].tempActive and (includeDisclosatory or !mods[mod].disclosatory): array.append(mod)
	return array

func openModsWindow() -> void:
	if editor.modsWindow:
		editor.modsWindow.grab_focus()
	else:
		var window:Window = preload("res://scenes/mods/modsWindow.tscn").instantiate()
		editor.add_child(window)
		if !OS.has_feature("web"):
			@warning_ignore("integer_division") window.position = get_window().position+(get_window().size-window.size)/2

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
	if active(&"DynamiteColor"): array.append(Game.COLOR.DYNAMITE)
	if active(&"QuicksilverColor"): array.append(Game.COLOR.QUICKSILVER)
	if active(&"DarkAuraColors"): array.append_array([Game.COLOR.MAROON, Game.COLOR.FOREST, Game.COLOR.NAVY])
	if active( &"AuraBreakerColors"): array.append_array([Game.COLOR.ICE, Game.COLOR.MUD, Game.COLOR.GRAFFITI])
	if active(&"NoneColor"): array.append(Game.COLOR.NONE)
	if active(&"CosmicColor"): array.append(Game.COLOR.COSMIC)
	if active(&"ErrorColor"): array.append(Game.COLOR.ERROR)
	return array

## wraps
func nextColor(color:Game.COLOR) -> Game.COLOR:
	var colorsArray:Array[Game.COLOR] = colors()
	return colorsArray[posmod(colorsArray.find(color) + 1, len(colorsArray))]

## wraps
func previousColor(color:Game.COLOR) -> Game.COLOR:
	var colorsArray:Array[Game.COLOR] = colors()
	return colorsArray[posmod(colorsArray.find(color) - 1, len(colorsArray))]

func keyTypes() -> Array[KeyBulk.TYPE]:
	var array:Array[KeyBulk.TYPE] = [
		KeyBulk.TYPE.NORMAL,
		KeyBulk.TYPE.EXACT,
		KeyBulk.TYPE.STAR,
		KeyBulk.TYPE.ROTOR
	]
	if active(&"CurseKeys"): array.append(KeyBulk.TYPE.CURSE)
	if active(&"OperatorKeys"): array.append(KeyBulk.TYPE.OPERATOR)
	return array

func lockTypes() -> Array[Lock.TYPE]:
	var array:Array[Lock.TYPE] = [
		Lock.TYPE.NORMAL,
		Lock.TYPE.BLANK,
		Lock.TYPE.BLAST, Lock.TYPE.ALL
	]
	if active(&"ExactLocks"): array.append(Lock.TYPE.EXACT)
	if active(&"Glistening"): array.append(Lock.TYPE.GLISTENING)
	if active(&"RemainderLocks"): array.append(Lock.TYPE.REMAINDER)
	return array

func keyCounterWidths() -> Array[KeyCounter.WIDTH]:
	var array:Array[KeyCounter.WIDTH] = [
		KeyCounter.WIDTH.SHORT,
		KeyCounter.WIDTH.MEDIUM,
		KeyCounter.WIDTH.LONG,
	]
	if active(&"MoreKeyCounterWidths"): array.append_array([KeyCounter.WIDTH.VLONG, KeyCounter.WIDTH.EXLONG])
	return array

func objectAvailable(object:GDScript) -> bool:
	match object:
		RemoteLock: return active(&"RemoteLocks")
		_: return true

class Mod extends RefCounted:
	var active:bool = false
	var tempActive:bool = false # used while in modsWindow
	var name:String
	var description:String
	var dependencies:Array[StringName]
	var incompatibilities:Array[StringName]
	var disclosatory:bool

	var treeItem:ModTreeItem # for the menu
	var problems:Dictionary[StringName, Problem] # dictionary[problemtype, [gamecomponent]]
	var selectButton:FindProblems.ModSelectButton # for findproblems

	func _init(_name:String,_description:String,_problems:Dictionary[StringName,Problem],_disclosatory:bool=false,_dependencies:Array[StringName]=[],_incompatibilities:Array[StringName]=[]) -> void:
		name = _name
		description = _description
		problems = _problems
		disclosatory = _disclosatory
		dependencies = _dependencies
		incompatibilities = _incompatibilities
	
	func clearProblems() -> void: for problem in problems.values(): problem.components.clear()
	func hasProblems() -> bool:
		for problem in problems.values(): if problem.components: return true
		return false

class Modpack extends RefCounted:
	var name:String
	var description:String
	var icon:Texture2D
	var iconSmall:Texture2D
	var versions:Array[Version]
	var defaultVersion:int

	func _init(_name:String,_description:String,_icon:Texture2D,_iconSmall:Texture2D,_versions:Array[Version], _defaultVersion:int=0) -> void:
		name = _name
		description = _description
		icon = _icon
		iconSmall = _iconSmall
		versions = _versions
		defaultVersion = _defaultVersion

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

class Problem extends RefCounted:
	var name:String
	var components:Array[GameComponent] # components with the problem

class ComponentProblem extends Problem:
	var types:Array[GDScript]
	var checker:Callable

	func _init(_types:Array[GDScript], _checker:Callable, _name:String) -> void:
		types = _types
		checker = _checker
		name = _name

class ColorProblem extends Problem:
	var colors:Array[Game.COLOR]

	func _init(_colors:Array[Game.COLOR], _name:String) -> void:
		colors = _colors
		name = _name
