extends SubDialog
class_name GoalDialog

func focus(focused:Goal, _new:bool, _dontRedirect:bool, _skipInput:Control) -> void:
	%goalTypeSelector.setSelect(focused.type)

func _goalTypeSelected(type:Goal.TYPE) -> void:
	if main.focused is not Goal: return
	Changes.addChange(Changes.PropertyChange.new(main.focused,&"type",type))
	Changes.bufferSave()

func receiveKey(_event:InputEventKey) -> bool:
	return false
