extends VBoxContainer
class_name ProblemDisplay

@onready var editor:Editor = get_node("/root/editor")
var modId:StringName
var mod:Mods.Mod
var type:StringName
var findProblems:FindProblems
var showIndex:int = 0
var count:int:
	get(): return len(mod.problems[type])

func setup(_mod:StringName,_type:StringName, _findProblems:FindProblems) -> ProblemDisplay:
	modId = _mod
	mod = mods.mods[modId]
	type = _type
	findProblems = _findProblems
	%nameLabel.text = getProblemName()
	return self

func setTexts() -> void:
	if count == 1: %countLabel.text = "1 instance"
	else: %countLabel.text = str(count) + " instances"
	%showIndex.text = str(showIndex+1) + "/" + str(count)
	visible = count > 0

func getProblemName() -> String:
	match [modId, type]:
		[&"NstdLockSize", &"NstdLockSize"]: return "Nonstandard Lock Size"

		[&"C3", &"ExactLock"]: return "Exact Lock"
		[&"C5", &"CurseKeyType"]: return "Curse/Decurse Key"
	return "huh?? what??"

func showInstance(index:int) -> void:
	showIndex = index
	setTexts()
	var component:GameComponent = mod.problems[type][index]
	if component is GameObject:
		editor.focusDialog.defocusComponent()
		editor.focusDialog.focus(component)
	else: editor.focusDialog.focusComponent(component)
	editor.scrollIntoView(component)

func _showPressed():
	%shower.visible = true
	%show.visible = false
	if findProblems.shownDisplay: findProblems.shownDisplay.stopShowing()
	findProblems.shownDisplay = self
	showInstance(0)

func stopShowing() -> void:
	if findProblems.shownDisplay != self: return
	findProblems.shownDisplay = null
	%show.visible = true
	%shower.visible = false

func _showLeft(): showInstance(posmod(showIndex-1,count))
func _showRight(): showInstance(posmod(showIndex+1,count))

func newInstance() -> void: setTexts()

func removeInstance(index:int) -> void:
	if count == 0:
		visible = false
		findProblems.problemsLabel.text = "Problems found:" if mod.hasProblems() else "No problems here"
		return
	if showIndex > index: showIndex -= 1
	elif showIndex == count: showInstance(index-1)
	elif showIndex == index: showInstance(index)
	setTexts()
