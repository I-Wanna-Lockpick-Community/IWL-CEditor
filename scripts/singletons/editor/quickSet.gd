extends RichTextLabel
class_name QuickSet

var component:GameComponent
var quickType:StringName
var input:String = ""

func startQuick(type:StringName, _component:GameComponent) -> void:
	quickType = type
	component = _component
	visible = true
	%explainText.visible = false
	input = ""
	updateText()

func receiveInput(event:InputEvent) -> void:
	if event.is_action_released(quickType): applyOrCancel()
	elif event is InputEventKey and event.is_pressed() and !event.echo:
		if event.keycode >= 32 and event.keycode < 128:
			input += char(event.unicode).to_upper()
			updateText()

func updateText() -> void:
	text = "Quickset "
	match quickType:
		&"quicksetColor": text += "Color: "
		&"quicksetLockSize": text += "Lock Size: "
		&"quicksetPencilmarkColor": text += "Color: "
	text += input

func applyOrCancel() -> void:
	match quickType:
		&"quicksetColor":
			var found:int = findInputIn(ColorQuicksetSetting.matches)
			if found in Mods.colors():
				match component.get_script():
					KeyBulk: Game.editor.focusDialog.keyDialog._keyColorSelected(found)
					Door, Lock, RemoteLock: Game.editor.focusDialog.doorDialog._doorColorSelected(found)
					PlayerSpawn, PlayerPlaceholderObject: Game.editor.focusDialog.playerDialog.setSelectedColor(found)
					KeyCounterElement: Game.editor.focusDialog.keyCounterDialog._keyCounterColorSelected(found)
		&"quicksetLockSize":
			var found:int = findInputIn(LockSizeQuicksetSetting.matches)
			if found != -1: Game.editor.focusDialog.doorDialog._lockConfigurationSelected(found)
		&"quicksetPencilmarkColor":
			var found:int = findInputIn(PencilmarkColorQuicksetSetting.matches)
			if found != -1: Game.editor.focusDialog.pencilmarkDialog._pencilmarkColorSelected(found)
	visible = false
	%explainText.visible = true
	quickType = &""
	component = null

func findInputIn(matches:Array[String]) -> int:
	var sorted = input.split()
	sorted.sort()
	return matches.find("".join(sorted))
