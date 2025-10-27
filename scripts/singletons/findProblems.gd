extends PanelContainer
class_name FindProblems

@onready var editor:Editor = get_node("/root/editor")
@onready var modsWindow:ModsWindow = get_parent()
@onready var problemsLabel:Label = %problemsLabel
var buttonGroup:ButtonGroup = ButtonGroup.new()
var firstButton:bool = false

var problems:int = 0:
	set(value):
		problems = value
		%saveChanges.disabled = problems > 0
		if problems == 0: %saveChanges.text = "Save Changes"
		elif problems == 1: %saveChanges.text = "1 problem"
		else: %saveChanges.text = str(problems) + " problems"

var problemDisplays:Dictionary[StringName,Dictionary] = {} # Dictionary[mod, Dictionary[type, problemdisplay]]
var shownDisplay:ProblemDisplay
var isReady:bool = false

func _ready() -> void:
	buttonGroup.pressed.connect(_modSelected)

func setup() -> void:
	isReady = false
	editor.findProblems = self
	firstButton = true
	problems = 0
	for child in %modsAdded.get_children(): child.queue_free()
	for child in %modsRemoved.get_children(): child.queue_free()
	for mod in mods.mods.values(): mod.clearProblems()
	
	problemDisplays = {}
	for mod in mods.mods.keys():
		problemDisplays[mod] = {}
		for problemType in mods.mods[mod].problems.keys():
			problemDisplays[mod][problemType] = preload("res://scenes/problemDisplay.tscn").instantiate().setup(mod,problemType,self)
	
	for object in editor.game.objects.values():
		object.problems.clear()
		findProblems(object)
	for component in editor.game.components.values():
		component.problems.clear()
		findProblems(component)
	for mod in mods.mods.keys():
		if mod in modsWindow.modsAdded: %modsAdded.add_child(ModSelectButton.new(self,mod))
		elif mod in modsWindow.modsRemoved: %modsRemoved.add_child(ModSelectButton.new(self,mod))
	isReady = true

func _modSelected(button:ModSelectButton) -> void:
	%modName.text = button.mod.name
	var anyProblems:bool = false
	for child in %problems.get_children(): %problems.remove_child(child)
	if shownDisplay: shownDisplay.stopShowing()

	for problemType in button.mod.problems.keys():
		if len(button.mod.problems[problemType]) != 0:
			anyProblems = true
			%problems.add_child(problemDisplays[button.modId][problemType])
			problemDisplays[button.modId][problemType].setTexts()
	%problemsLabel.text = "Problems found:" if anyProblems else "No problems here"

func findProblems(component:GameComponent) -> void:
	match component.get_script():
		Lock:
			if &"NstdLockSize" in modsWindow.modsRemoved: noteProblem(&"NstdLockSize", &"NstdLockSize", component, component.parent.type != Door.TYPE.SIMPLE and component.size not in Lock.SIZES)

func noteProblem(mod:StringName, type:StringName, component:GameComponent, isProblem:bool) -> void:
	var problem:Array = [mod, type]
	print(isProblem, component.problems)
	if isProblem and problem not in component.problems:
		component.problems.append(problem)
		mods.mods[mod].problems[type].append(component)
		problems += 1
		if isReady: problemDisplays[mod][type].newInstance()
	elif !isProblem and problem in component.problems:
		component.problems.erase(problem)
		var index = mods.mods[mod].problems[type].find(component)
		mods.mods[mod].problems[type].remove_at(index)
		problems -= 1
		if isReady: problemDisplays[mod][type].removeInstance(index)
	if isReady: mods.mods[mod].selectButton.setIcon()

class ModSelectButton extends Button:
	const NO_PROBLEM:Texture2D = preload("res://assets/ui/mods/noProblem.png")
	const PROBLEM:Texture2D = preload("res://assets/ui/mods/problem.png")

	var findProblems:FindProblems
	var modId:StringName
	var mod:Mods.Mod

	func _init(_findProblems:FindProblems, _modId:StringName) -> void:
		toggle_mode = true
		findProblems = _findProblems
		button_group = findProblems.buttonGroup
		modId = _modId
		mod = mods.mods[modId]
		mod.selectButton = self
		text = mod.name
		setIcon()
		theme_type_variation = &"RadioButtonText"
		if findProblems.firstButton:
			button_pressed = true
			findProblems.firstButton = false

	func setIcon() -> void:
		if mod.hasProblems(): icon = PROBLEM
		else: icon = NO_PROBLEM
