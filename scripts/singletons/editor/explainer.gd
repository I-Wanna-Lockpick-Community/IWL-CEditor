extends Node

const LMB:String = "[img]res://assets/ui/explainer/lmb.png[/img]"
const MMB:String = "[img]res://assets/ui/explainer/mmb.png[/img]"
const RMB:String = "[img]res://assets/ui/explainer/rmb.png[/img]"
const ARROWS_LR:String = "[img]res://assets/ui/explainer/arrowsLR.png[/img]"
const ARROWS_UD:String = "[img]res://assets/ui/explainer/arrowsUD.png[/img]"
const ARROWS:String = "[img]res://assets/ui/explainer/arrows.png[/img]"

var explainedControls:Array[Control]
var controlExplanations:Array[ControlExplanation]

var editor:Editor

func _ready() -> void:
	for control:Control in get_tree().get_nodes_in_group("explained"):
		control.mouse_entered.connect(_explain.bind(control))
		control.mouse_exited.connect(_deexplain.bind(control))

func _process(_delta:float) -> void: updateText()

func _explain(control:Control) -> void:
	explainedControls.append(control)
	controlExplanations.append(control.get_meta(&"explanation"))

func _deexplain(control:Control) -> void:
	var found:int = explainedControls.find(control)
	if found != -1:
		explainedControls.pop_at(found)
		controlExplanations.pop_at(found)

func addControl(control:Control, explanation:ControlExplanation) -> void:
	control.set_meta(&"explanation", explanation)
	control.mouse_entered.connect(_explain.bind(control))
	control.mouse_exited.connect(_deexplain.bind(control))

func updateText() -> void:
	var string:String = ""
	var control:String = str(controlExplanations[-1]) + " " if controlExplanations else ""
	if !editor: return
	if editor.exportWindow:
		string += "In Export Menu " + control
	elif editor.focusDialog.focused:
		if editor.focusDialog.componentFocused:
				match editor.focusDialog.componentFocused.get_script():
					Lock: string += "Lock / [%s]Duplicate " % hotkeyMap(&"focusLockDuplicate") + control
					KeyCounterElement: string += "Key Counter Element / " + control
		else:
			match editor.focusDialog.focused.get_script():
				KeyBulk: string += "Key / " + control
				Door: string += "Door / [%s]Add Lock " % hotkeyMap(&"focusDoorAddLock") + control
				PlayerSpawn: string += "Player Spawn / "+control
				Goal: string += "Goal / "+control
				KeyCounter: string += "Key Counter / [%s]Add Element " % hotkeyMap(&"focusKeyCounterAddElement") + control
				FloatingTile: string += "Floating Tile / " + control
				RemoteLock: string += "Remote Lock / [%s]Add Connection " % hotkeyMap(&"focusRemoteLockAddConnection") + control
				PlayerPlaceholderObject: string += "Player / " + control
		string += "[M]Move [Del]Delete"
	elif editor.otherObjects.objectSearch.has_focus():
		string += "Object Search / "+control+"[Enter][Tab]Select object [Esc]Cancel"
	elif Game.playState == Game.PLAY_STATE.PLAY:
		string += control# + ARROWS_LR+"Move [Space]Jump [Shift]Walk [X]Hold action [S]Switch axis [Z]Undo [R]Restart"
	else:
		string += control
		match editor.mode:
			Editor.MODE.SELECT:
				match editor.multiselect.state:
					Multiselect.STATE.HOLDING: string += LMB+"Select"
					Multiselect.STATE.SELECTING: string += LMB+"Multiselect"
					Multiselect.STATE.DRAGGING: string += LMB+"Move selection"
			Editor.MODE.TILE: string += LMB+"Place tile "+RMB+"Delete tile"
			Editor.MODE.KEY: string += LMB+"Place key"
			Editor.MODE.DOOR: string += LMB+"Place door"
			Editor.MODE.OTHER: string += LMB+"Place object"
			Editor.MODE.PASTE: string += LMB+"Paste"
		string += " "+MMB+ARROWS+"Move/zoom camera [%s]Home camera [%s]Pipette" % [hotkeyMap(&"editHome"), hotkeyMap(&"editPipette")]
	editor.explainText.text = string

func hotkeyMap(hotkey:StringName, default:String="Unset") -> String:
	var events:Array[InputEvent] = InputMap.action_get_events(hotkey)
	return events[0].as_text_physical_keycode().replace("Escape", "Esc") if events else default
