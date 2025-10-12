extends HBoxContainer
class_name Modes

@onready var editor:Editor = get_node("/root/editor")

func _setMode(mode:int) -> void:
	editor.mode = mode as Editor.Mode

func setMode(mode:Editor.Mode) -> void:
	get_child(editor.mode).button_pressed = false
	get_child(mode).button_pressed = true
	editor.mode = mode
