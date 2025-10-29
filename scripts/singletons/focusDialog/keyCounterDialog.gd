extends Control
class_name KeyCounterDialog

@onready var editor:Editor = get_node("/root/editor")
@onready var main = get_parent()

func focus(focused:KeyCounter, new:bool, dontRedirect:bool) -> void:
	%keyCounterWidthSelector.setSelect(KeyCounter.WIDTHS.find(focused.size.x))
	if !main.componentFocused:
		%keyCounterColorSelector.visible = false
	if new:
		%keyCounterHandler.setup(focused)
		if !dontRedirect: main.focusComponent(focused.elements[-1])

func focusComponent(component:Lock, _new:bool) -> void:
	%keyCounterHandler.setSelect(component.index)
	%keyCounterHandler.redrawButton(component.index)
	%keyCounterColorSelector.visible = true
	%keyCounterColorSelector.setSelect(component.color)

func receiveKey(event:InputEvent) -> bool:
	match event.keycode:
		KEY_E: if Input.is_key_pressed(KEY_CTRL): main.focused.addElement()
		KEY_DELETE:
			if main.componentFocused:
				main.focused.removeElement(main.componentFocused.index)
				if len(main.focused.elements) != 0: main.focusComponent(main.focused.elements[-1])
				else: main.focus(main.focused)
			else: changes.addChange(Changes.DeleteComponentChange.new(editor.game,main.focused))
			changes.bufferSave()
		_: return false
	return true

func _keyCounterWidthSelected(width:int):
	if main.focused is not KeyCounter: return
	changes.addChange(Changes.PropertyChange.new(editor.game,main.focused,&"size",Vector2(KeyCounter.WIDTHS[width],main.focused.size.y)))
	changes.bufferSave()

func _keyCounterColorSelected(color:Game.COLOR) -> void:
	if main.focused is not KeyCounter: return
	changes.addChange(Changes.PropertyChange.new(editor.game,main.componentFocused,&"color",color))
	changes.bufferSave()
