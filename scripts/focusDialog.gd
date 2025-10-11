extends Control
class_name FocusDialog

@onready var editor:Editor = get_node("/root/editor")

var focused:Control # the object that is currently focused

func _process(_delta) -> void:
	if focused:
		visible = true
		position = editor.worldspaceToScreenspace(focused.position + Vector2(focused.size.x/2,-4))
	else:
		visible = false
