extends Control
class_name KeyDialog

@onready var editor:Editor = get_node("/root/editor")
@onready var main = get_parent()

func focus(focused:KeyBulk,new:bool) -> void:
	%keyColorSelector.setSelect(focused.color)
	%keyTypeSelector.setSelect(focused.type)
	%keyCountEdit.visible = focused.type in [KeyBulk.TYPE.NORMAL,KeyBulk.TYPE.EXACT]
	%keyCountEdit.setValue(focused.count, true)
	%keyInfiniteToggle.button_pressed = focused.infinite
	if new: main.interact(%keyCountEdit.realEdit)

func receiveKey(event:InputEventKey) -> bool:
	match event.keycode:
		KEY_N: _keyTypeSelected(KeyBulk.TYPE.NORMAL)
		KEY_E: _keyTypeSelected(KeyBulk.TYPE.EXACT if main.focused.type != KeyBulk.TYPE.EXACT else KeyBulk.TYPE.NORMAL)
		KEY_S: _keyTypeSelected(KeyBulk.TYPE.STAR if main.focused.type != KeyBulk.TYPE.STAR else KeyBulk.TYPE.UNSTAR)
		KEY_R:
			if main.focused.type == KeyBulk.TYPE.SIGNFLIP: _keyTypeSelected(KeyBulk.TYPE.NEGROTOR)
			elif main.focused.type == KeyBulk.TYPE.POSROTOR: _keyTypeSelected(KeyBulk.TYPE.SIGNFLIP)
			else: _keyTypeSelected(KeyBulk.TYPE.POSROTOR)
		KEY_C: editor.quickSet.startQuick(QuickSet.QUICK.COLOR, main.focused)
		KEY_U: if mods.active(&"C5"): _keyTypeSelected(KeyBulk.TYPE.CURSE if main.focused.type != KeyBulk.TYPE.CURSE else KeyBulk.TYPE.UNCURSE)
		KEY_DELETE:
			changes.addChange(Changes.DeleteComponentChange.new(editor.game,main.focused))
			changes.bufferSave()
		KEY_Y: _keyInfiniteToggled(!main.focused.infinite)
		_: return false
	return true

func _keyColorSelected(color:Game.COLOR) -> void:
	if main.focused is not KeyBulk: return
	changes.addChange(Changes.PropertyChange.new(editor.game,main.focused,&"color",color))
	changes.bufferSave()

func _keyTypeSelected(type:KeyBulk.TYPE) -> void:
	if main.focused is not KeyBulk: return
	changes.addChange(Changes.PropertyChange.new(editor.game,main.focused,&"type",type))
	changes.bufferSave()

func _keyCountSet(count:C) -> void:
	if main.focused is not KeyBulk: return
	changes.addChange(Changes.PropertyChange.new(editor.game,main.focused,&"count",count))
	changes.bufferSave()

func _keyInfiniteToggled(value:bool) -> void:
	if main.focused is not KeyBulk: return
	changes.addChange(Changes.PropertyChange.new(editor.game,main.focused,&"infinite",value))
	changes.bufferSave()
