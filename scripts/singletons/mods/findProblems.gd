extends PanelContainer
class_name FindProblems

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
	Game.editor.findProblems = self
	firstButton = true
	problems = 0
	for child in %modsAdded.get_children(): child.queue_free()
	for child in %modsRemoved.get_children(): child.queue_free()
	for mod in Mods.mods.values(): mod.clearProblems()
	
	problemDisplays = {}
	for mod in Mods.mods.keys():
		problemDisplays[mod] = {}
		for problemType in Mods.mods[mod].problems.keys():
			problemDisplays[mod][problemType] = preload("res://scenes/mods/problemDisplay.tscn").instantiate().setup(mod,problemType,self)
	
	for object in Game.objects.values():
		object.problems.clear()
		findProblems(object)
	for component in Game.components.values():
		component.problems.clear()
		findProblems(component)
	for note in Game.notes.values():
		note.problems.clear()
		findProblems(note)
	for mod in Mods.mods.keys():
		if mod in modsWindow.modsAdded: %modsAdded.add_child(ModSelectButton.new(self,mod))
		elif mod in modsWindow.modsRemoved: %modsRemoved.add_child(ModSelectButton.new(self,mod))
	isReady = true

func _modSelected(button:ModSelectButton) -> void:
	%modName.text = button.mod.name
	var anyProblems:bool = false
	for child in %problems.get_children(): %problems.remove_child(child)
	if shownDisplay: shownDisplay.stopShowing()

	for problemType in button.mod.problems.keys():
		%problems.add_child(problemDisplays[button.modId][problemType])
		problemDisplays[button.modId][problemType].setTexts()
		if len(button.mod.problems[problemType].components) != 0:
			anyProblems = true
	%problemsLabel.text = "Problems found:" if anyProblems else "No problems here"

func findProblems(component:GameComponent) -> void:
	for modName:StringName in modsWindow.modsRemoved:
		var mod:Mods.Mod = Mods.mods[modName]
		for problemName:StringName in mod.problems.keys():
			var problem:Mods.Problem = mod.problems[problemName]
			match problem.get_script():
				Mods.ComponentProblem:
					if component.get_script() in problem.types or (component is GameObject and GameObject in problem.types) or GameComponent in problem.types:
						noteProblem(modName, problemName, component, problem.checker.call(component))
				Mods.ColorProblem:
					for color in component.getColors():
						noteProblem(modName, problemName, component, color in problem.colors)

func noteProblem(mod:StringName, type:StringName, component:GameComponent, isProblem:bool) -> void:
	var problem:Array = [mod, type]
	if isProblem and problem not in component.problems:
		component.problems.append(problem)
		Mods.mods[mod].problems[type].components.append(component)
		problems += 1
		if isReady: problemDisplays[mod][type].newInstance()
	elif !isProblem and problem in component.problems:
		component.problems.erase(problem)
		var index = Mods.mods[mod].problems[type].components.find(component)
		Mods.mods[mod].problems[type].components.remove_at(index)
		problems -= 1
		if isReady: problemDisplays[mod][type].removeInstance(index)
	if isReady: Mods.mods[mod].selectButton.setIcon()

func componentRemoved(component:GameComponent) -> void:
	for problem in component.problems:
		noteProblem(problem[0], problem[1], component, false)

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
		mod = Mods.mods[modId]
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
