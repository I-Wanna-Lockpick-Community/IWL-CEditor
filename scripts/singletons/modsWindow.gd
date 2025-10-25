extends Window
class_name ModsWindow

var modsAdded:Array[StringName] # mods that have been added
var modsRemoved:Array[StringName] # mods that have been added

var tempActiveModpack:Mods.Modpack = mods.activeModpack
var tempActiveVersion:Mods.Version = mods.activeVersion

func _ready() -> void:
	%selectMods.visible = true
	%findProblems.visible = false
	for mod in mods.mods.values():
		mod.tempActive = mod.active
	%selectMods.setup()

func _input(event:InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		match event.keycode:
			KEY_Z: if Input.is_key_pressed(KEY_CTRL) and %selectMods.visible: %selectMods.undo()

func _close() -> void: queue_free()

func _next() -> void:
	%selectMods.visible = false
	%findProblems.visible = true
	title = "Find Problems"
	%findProblems.setup()

func _back():
	%selectMods.visible = true
	%findProblems.visible = false
	title = "Select Mods"

func _saveChanges():
	mods.activeModpack = tempActiveModpack
	mods.activeVersion = tempActiveVersion
	for mod in mods.mods.values():
		mod.active = mod.tempActive
	queue_free()
