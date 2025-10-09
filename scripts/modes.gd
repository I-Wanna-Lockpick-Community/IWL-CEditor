extends HBoxContainer

@onready var editor:Editor = get_node("/root/editor")

func _setMode(mode: int) -> void:
	editor.mode = mode as Editor.Mode
