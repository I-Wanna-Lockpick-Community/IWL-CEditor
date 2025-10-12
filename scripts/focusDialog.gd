extends Control
class_name FocusDialog

@onready var editor:Editor = get_node("/root/editor")
var focused:GameObject # the object that is currently focused

func focus(object:GameObject) -> void:
	focused = object
	editor.game.objects.remove_child(focused)
	editor.game.objects.add_child(focused)
	if object is KeyBulk:
		%keyColorSelector.setSelect(focused.color)
		%keyTypeSelector.setSelect(focused.type)

func defocus() -> void:
	focused = null


func _process(_delta) -> void:
	if focused:
		visible = true
		position = editor.worldspaceToScreenspace(focused.position + Vector2(focused.size.x/2,0)) + Vector2(0,-8)
	else:
		visible = false

func _keyColorSelected(color:Game.COLOR) -> void:
	if focused is not KeyBulk: return
	editor.changes.addChange(Changes.KeyPropertyChange.new(editor.game,focused,&"color",color))
	editor.changes.bufferSave()

func _keyTypeSelected(type:Game.KEY) -> void:
	if focused is not KeyBulk: return
	editor.changes.addChange(Changes.KeyPropertyChange.new(editor.game,focused,&"type",type))
	editor.changes.bufferSave()
