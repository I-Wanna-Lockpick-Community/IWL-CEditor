extends Control
class_name FocusDialog

@onready var editor:Editor = get_node("/root/editor")
@onready var keyColorSelector:ColorSelector = %keyColorSelector

var focused:GameObject # the object that is currently focused

func focus(object:GameObject) -> void:
	if object is KeyBulk:
		focused = object
		keyColorSelector.setColor(focused.color)

func defocus() -> void:
	focused = null


func _process(_delta) -> void:
	if focused:
		visible = true
		position = editor.worldspaceToScreenspace(focused.position + Vector2(focused.size.x/2,-4))
	else:
		visible = false

func _keyColorSelected(color: Game.COLOR) -> void:
	if focused is not KeyBulk: return
	editor.changes.addChange(Changes.KeyPropertyChange.new(editor.game,focused,&"color",color))
	editor.changes.bufferSave()
