extends PanelContainer
class_name FindProblems

@onready var modsWindow = get_parent()
var buttonGroup:ButtonGroup = ButtonGroup.new()
var firstButton:bool = false

func _ready() -> void:
	buttonGroup.pressed.connect(_modSelected)

func setup() -> void:
	firstButton = true
	for child in %modsAdded.get_children(): child.queue_free()
	for child in %modsRemoved.get_children(): child.queue_free()
	for mod in mods.mods.keys():
		if mod in modsWindow.modsAdded:
			%modsAdded.add_child(ModSelectButton.new(self,mod))
		elif mod in modsWindow.modsRemoved:
			%modsRemoved.add_child(ModSelectButton.new(self,mod))

func _modSelected(button:ModSelectButton) -> void:
	%modName.text = button.mod.name

class ModSelectButton extends Button:
	const NO_PROBLEM:Texture2D = preload("res://assets/ui/mods/noProblem.png")

	var findProblems:FindProblems
	var mod:Mods.Mod

	func _init(_findProblems:FindProblems, modId:StringName) -> void:
		toggle_mode = true
		findProblems = _findProblems
		button_group = findProblems.buttonGroup
		mod = mods.mods[modId]
		text = mod.name
		icon = NO_PROBLEM
		theme_type_variation = &"RadioButtonText"
		if findProblems.firstButton:
			button_pressed = true
			findProblems.firstButton = false
