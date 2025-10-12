extends Control
class_name FocusDialog

@onready var editor:Editor = get_node("/root/editor")
var focused:GameObject # the object that is currently focused
var interacted:NumberEdit # the number edit that is currently interacted

func focus(object:GameObject, new:bool=true) -> void:
	focused = object
	editor.game.objects.remove_child(focused)
	editor.game.objects.add_child(focused)
	if object is KeyBulk:
		%keyColorSelector.setSelect(focused.color)
		%keyTypeSelector.setSelect(focused.type)
		%keyNumberEdit.visible = focused.type in [Game.KEY.NORMAL,Game.KEY.EXACT]
		%keyNumberEdit.setValue(focused.count, true)
		if new: interact(%keyNumberEdit.realEdit)

func defocus() -> void:
	if !focused: return
	focused = null
	deinteract()

func interact(edit:NumberEdit) -> void:
	deinteract()
	edit.theme_type_variation = &"NumberEditPanelContainerSelected"
	interacted = edit
	edit.newlyInteracted = true

func deinteract() -> void:
	if !interacted: return
	interacted.theme_type_variation = &"NumberEditPanelContainer"
	interacted.bufferedNegative = false
	interacted.setValue(interacted.value,true)
	interacted = null

func _process(_delta) -> void:
	if focused:
		visible = true
		position = editor.worldspaceToScreenspace(focused.position + Vector2(focused.size.x/2,focused.size.y)) + Vector2(0,8)
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

func _keyNumberSet(count:Number):
	if focused is not KeyBulk: return
	editor.changes.addChange(Changes.KeyPropertyChange.new(editor.game,focused,&"count",count))
	editor.changes.bufferSave()
