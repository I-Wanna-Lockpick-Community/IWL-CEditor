extends Window
class_name ModsWindow

@onready var editor:Editor = get_node("/root/editor")

enum STAGE {SELECT_MODS, FIND_PROBLEMS}
var stage:STAGE = STAGE.SELECT_MODS

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
	stage = STAGE.FIND_PROBLEMS
	%findProblems.setup()

func _back():
	%selectMods.visible = true
	%findProblems.visible = false
	title = "Select Mods"
	stage = STAGE.SELECT_MODS

func _saveChanges():
	changes.addChange(Changes.GlobalPropertyChange.new(mods,&"activeModpack",tempActiveModpack))
	changes.addChange(Changes.GlobalPropertyChange.new(mods,&"activeVersion",tempActiveVersion))
	for mod in mods.mods.values():
		changes.addChange(Changes.GlobalPropertyChange.new(mod,&"active",mod.tempActive))
	changes.bufferSave()
	editor.focusDialog.changedMods()
	queue_free()
