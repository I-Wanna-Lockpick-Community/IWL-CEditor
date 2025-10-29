extends Control
class_name GoalDialog

@onready var editor:Editor = get_node("/root/editor")
@onready var main = get_parent()

func focus(focused:Goal, _new:bool) -> void:
	%goalTypeSelector.setSelect(focused.type)

func _goalTypeSelected(type:Goal.TYPE) -> void:
	if main.focused is not Goal: return
	changes.addChange(Changes.PropertyChange.new(editor.game,main.focused,&"type",type))
	changes.bufferSave()
