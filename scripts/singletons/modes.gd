extends HBoxContainer
class_name Modes

@onready var editor:Editor = get_node("/root/editor")

func _setMode(mode:int) -> void:
	editor.mode = mode as Editor.MODE

func setMode(mode:Editor.MODE) -> void:
	get_child(mode).button_pressed = true
	editor.mode = mode
