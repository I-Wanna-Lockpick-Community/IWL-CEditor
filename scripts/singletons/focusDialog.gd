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
		%keyInfiniteToggle.button_pressed = focused.infinite
		%keyDialog.visible = true
		%doorDialog.visible = false
		if new: interact(%keyNumberEdit.realEdit)
	elif object is Door:
		%doorColorSpendSelector.setSelect(focused.colorSpend)
		%keyDialog.visible = false
		%doorDialog.visible = true

func defocus() -> void:
	if !focused: return
	focused = null
	editor.quickSet.cancel()
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

func receiveKey(event:InputEvent) -> bool:
	if focused is KeyBulk:
		match event.keycode:
			KEY_N: _keyTypeSelected(Game.KEY.NORMAL)
			KEY_E: _keyTypeSelected(Game.KEY.EXACT if focused.type != Game.KEY.EXACT else Game.KEY.NORMAL)
			KEY_S: _keyTypeSelected(Game.KEY.STAR if focused.type != Game.KEY.STAR else Game.KEY.UNSTAR)
			KEY_R:
				if focused.type == Game.KEY.SIGNFLIP: _keyTypeSelected(Game.KEY.NEGROTOR)
				elif focused.type == Game.KEY.POSROTOR: _keyTypeSelected(Game.KEY.SIGNFLIP)
				else: _keyTypeSelected(Game.KEY.POSROTOR)
			KEY_C: editor.quickSet.startQuick(QuickSet.QUICK.COLOR, focused)
			KEY_U: _keyTypeSelected(Game.KEY.CURSE if focused.type != Game.KEY.CURSE else Game.KEY.UNCURSE)
			KEY_DELETE:
				editor.changes.addChange(Changes.DeleteKeyChange.new(editor.game,focused))
				editor.changes.bufferSave()
			KEY_Y: _keyInfiniteToggled(!focused.infinite)
			_: return false
	elif focused is Door:
		match event.keycode:
			KEY_C: editor.quickSet.startQuick(QuickSet.QUICK.COLOR, focused)
			KEY_DELETE:
				editor.changes.addChange(Changes.DeleteDoorChange.new(editor.game,focused))
				editor.changes.bufferSave()
			_: return false
	return true

func _process(_delta) -> void:
	if focused:
		visible = true
		position = editor.worldspaceToScreenspace(focused.position + Vector2(focused.size.x/2,focused.size.y)) + Vector2(0,8)
	else:
		visible = false

func _keyColorSelected(color:Game.COLOR) -> void:
	if focused is not KeyBulk: return
	editor.changes.addChange(Changes.PropertyChange.new(editor.game,focused,&"color",color))
	editor.changes.bufferSave()

func _keyTypeSelected(type:Game.KEY) -> void:
	if focused is not KeyBulk: return
	editor.changes.addChange(Changes.PropertyChange.new(editor.game,focused,&"type",type))
	editor.changes.bufferSave()

func _keyNumberSet(count:Complex):
	if focused is not KeyBulk: return
	editor.changes.addChange(Changes.PropertyChange.new(editor.game,focused,&"count",count))
	editor.changes.bufferSave()

func _keyInfiniteToggled(value:bool):
	if focused is not KeyBulk: return
	editor.changes.addChange(Changes.PropertyChange.new(editor.game,focused,&"infinite",value))
	editor.changes.bufferSave()

func _doorColorSpendSelected(colorSpend:Game.COLOR):
	if focused is not Door: return
	editor.changes.addChange(Changes.PropertyChange.new(editor.game,focused,&"colorSpend",colorSpend))
	editor.changes.bufferSave()
