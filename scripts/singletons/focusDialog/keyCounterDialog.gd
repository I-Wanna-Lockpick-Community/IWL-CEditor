extends Control
class_name KeyCounterDialog

@onready var main:FocusDialog = get_parent()

func focus(focused:KeyCounter, new:bool, dontRedirect:bool) -> void:
	%keyCounterWidthSelector.setSelect(KeyCounter.WIDTH_AMOUNT.find(focused.size.x))
	if !main.componentFocused:
		%keyCounterColorSelector.visible = false
		%keyCounterHandler.deselect()
	if new:
		%keyCounterHandler.setup(focused)
		if !dontRedirect: main.focusComponent(focused.elements[-1])

func focusComponent(component:KeyCounterElement, _new:bool) -> void:
	%keyCounterHandler.setSelect(component.index)
	%keyCounterHandler.redrawButton(component.index)
	%keyCounterColorSelector.visible = true
	%keyCounterColorSelector.setSelect(component.color)

func receiveKey(event:InputEvent) -> bool:
	if Editor.eventIs(event, &"focusKeyCounterAddElement"): main.focused.addElement()
	elif Editor.eventIs(event, &"quicksetColor"): Game.editor.quickSet.startQuick(&"quicksetColor", main.componentFocused)
	elif Editor.eventIs(event, &"editDelete"):
		if main.componentFocused and len(main.focused.elements) > 1:
			main.focused.removeElement(main.componentFocused.index)
			if len(main.focused.elements) != 0: main.focusComponent(main.focused.elements[-1])
			else: main.focus(main.focused)
		else: Changes.addChange(Changes.DeleteComponentChange.new(main.focused))
		Changes.bufferSave()
	else: return false
	return true

func _keyCounterWidthSelected(width:KeyCounter.WIDTH):
	if main.focused is not KeyCounter: return
	Changes.addChange(Changes.PropertyChange.new(main.focused,&"size",Vector2(KeyCounter.WIDTH_AMOUNT[width],main.focused.size.y)))
	Changes.bufferSave()

func _keyCounterColorSelected(color:C.olors) -> void:
	if main.focused is not KeyCounter: return
	Changes.addChange(Changes.PropertyChange.new(main.componentFocused,&"color",color))
	Changes.bufferSave()
