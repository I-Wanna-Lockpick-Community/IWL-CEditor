extends Node
class_name Mods

static var mods:Dictionary[String, Mod] = {
	"VarLockSize": Mod.new(
		"Variable Lock Size",
		"Allows lock sizes on combo doors other than the ones supported by the basegame"
	),
	"InfCopies": Mod.new(
		"Infinite Copy Doors",
		"Allows doors to have infinite copies"
	),
	"NoneColor": Mod.new(
		"None Color",
		"Adds the None Color from L4vo5's Lockpick Editor"
	),
	"C1": Mod.new(
		"IWL: Continued - World 1",
		"Adds Remote Locks and Negated Locks from world 1 of IWL:C"
	),
	"C2": Mod.new(
		"IWL: Continued - World 2",
		"Adds Dynamite Keys and Quicksilver Keys from world 2 of IWL:C"
	),
	"C3": Mod.new(
		"IWL: Continued - World 3",
		"Adds Partial Blast Locks and Exact Locks from world 3 of IWL:C"
	),
	"C4": Mod.new(
		"IWL: Continued - World 4",
		"Adds Dark Aura Keys and Aura Breaker Keys from world 4 of IWL:C" # maybe we should figure out some official name for these
	),
	"C5": Mod.new(
		"IWL: Continued - World 5",
		"Adds Curse and Decurse Keys and Lock Armaments from world 5 of IWL:C"
	),
}

func active(id:String) -> bool: return mods[id].active

class Mod extends RefCounted:
	var active:bool = false
	var name:String
	var description:String
	var dependencies:Array[String]
	var incompatibilities:Array[String]

	func _init(_name:String="No name given",_description:String="",_dependencies:Array[String]=[],_incompatibilities:Array[String]=[]):
		name = _name
		description = _description
		dependencies = _dependencies
		incompatibilities = incompatibilities
