extends Control
class_name FocusDialog

@onready var editor:Editor = get_node("/root/editor")

var focused:Control # the object that is currently focused

func focus(object:Control) -> void:
	if object is oKey:
		focused = object
		%keyColorSelector.setColor(focused.color)

func defocus() -> void:
	focused = null


func _process(_delta) -> void:
	if focused:
		visible = true
		position = editor.worldspaceToScreenspace(focused.position + Vector2(focused.size.x/2,-4))
	else:
		visible = false

func _keyColorSelected(color: Game.COLOR):
	if focused is not oKey: return
	focused.color = color
