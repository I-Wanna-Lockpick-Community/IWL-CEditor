extends Control
class_name FocusDialog

@onready var editor:Editor = get_node("/root/editor")
@onready var colorLink:Button = %colorLink

@onready var keyDialog:KeyDialog = %keyDialog
@onready var doorDialog:DoorDialog = %doorDialog
@onready var playerDialog:PlayerDialog = %playerDialog
@onready var keyCounterDialog:KeyCounterDialog = %keyCounterDialog
@onready var goalDialog:GoalDialog = %goalDialog

var focused:GameObject # the object that is currently focused
var componentFocused:GameComponent # you can focus both a door and a lock at the same time so
var interacted:PanelContainer # the number edit that is currently interacted

var above:bool = false # display above the object instead

func _ready() -> void:
	get_tree().call_group("modUI", "changedMods")

func focus(object:GameObject, dontRedirect:bool=false) -> void:
	var new:bool = object != focused
	focused = object
	editor.game.objectsParent.move_child(focused, -1)
	showCorrectDialog()
	if focused is KeyBulk: keyDialog.focus(focused, new)
	elif focused is Door: doorDialog.focus(focused, new, dontRedirect)
	elif focused is PlayerSpawn: playerDialog.focus(focused, new)
	elif focused is KeyCounter: keyCounterDialog.focus(focused, new, dontRedirect)
	elif focused is Goal: goalDialog.focus(focused, new)

func showCorrectDialog() -> void:
	%keyDialog.visible = focused is KeyBulk
	%doorDialog.visible = focused is Door
	%playerDialog.visible = focused is PlayerSpawn
	%keyCounterDialog.visible = focused is KeyCounter
	%goalDialog.visible = focused is Goal
	above = focused is KeyCounter # maybe add more later
	%speechBubbler.rotation_degrees = 0 if above else 180

func defocus() -> void:
	if !focused: return
	focused = null
	editor.quickSet.cancel()
	deinteract()
	defocusComponent()

func focusComponent(component:GameComponent) -> void:
	var new:bool = component != componentFocused
	componentFocused = component
	if focused != component.parent: focus(component.parent)
	if component is Lock: doorDialog.focusComponent(component, new)
	elif component is KeyCounterElement: keyCounterDialog.focusComponent(component, new)

func defocusComponent() -> void:
	if !componentFocused: return
	componentFocused = null

func interact(edit:PanelContainer) -> void:
	deinteract()
	edit.theme_type_variation = &"NumberEditPanelContainerNewlyInteracted"
	interacted = edit
	edit.newlyInteracted = true

func deinteract() -> void:
	if !interacted: return
	interacted.theme_type_variation = &"NumberEditPanelContainer"
	if interacted is NumberEdit: interacted.bufferedNegative = false
	elif interacted is AxialNumberEdit: interacted.bufferedSign = C.new(1)
	interacted.setValue(interacted.value,true)
	interacted = null

func tabbed(numberEdit:PanelContainer) -> void:
	editor.grab_focus()
	if Input.is_key_pressed(KEY_SHIFT):
		match numberEdit.purpose:
			NumberEdit.PURPOSE.IMAGINARY: interact(numberEdit.get_parent().realEdit)
			NumberEdit.PURPOSE.REAL:
				assert(focused is Door)
				if len(focused.locks) > 0: %lockHandler.buttons[len(focused.locks)-1].button_pressed = true
				interact(%doorAxialNumberEdit)
			NumberEdit.PURPOSE.AXIAL:
				if !componentFocused: return
				if componentFocused.index == 0: doorDialog._spendSelected(); interact(%doorComplexNumberEdit.imaginaryEdit)
				else:
					%lockHandler.buttons[componentFocused.index - 1].button_pressed = true
	else:
		match numberEdit.purpose:
			NumberEdit.PURPOSE.REAL: interact(numberEdit.get_parent().imaginaryEdit)
			NumberEdit.PURPOSE.IMAGINARY:
				assert(focused is Door)
				if len(focused.locks) > 0: %lockHandler.buttons[0].button_pressed = true
				interact(%doorAxialNumberEdit)
			NumberEdit.PURPOSE.AXIAL:
				if !componentFocused: return
				if componentFocused.index == len(focused.locks) - 1: doorDialog._spendSelected(); interact(%doorComplexNumberEdit.realEdit)
				else:
					%lockHandler.buttons[componentFocused.index + 1].button_pressed = true

func receiveKey(event:InputEvent) -> bool:
	if focused is KeyBulk: return keyDialog.receiveKey(event)
	elif focused is Door: return doorDialog.receiveKey(event)
	elif focused is KeyCounter: return keyCounterDialog.receiveKey(event)
	else:
		match event.keycode:
			KEY_DELETE:
				changes.addChange(Changes.DeleteComponentChange.new(editor.game,focused))
				changes.bufferSave()
			_: return false
	return true

func _process(_delta) -> void:
	if focused:
		visible = true
		if above: position = editor.worldspaceToScreenspace(focused.position + Vector2(focused.size.x/2,0)) + Vector2(0,-8)
		else: position = editor.worldspaceToScreenspace(focused.position + Vector2(focused.size.x/2,focused.size.y)) + Vector2(0,8)
	else:
		visible = false

func focusComponentAdded(type:GDScript, index:int) -> void:
	if type == Lock:
		%lockHandler.addButton(index)
		focusComponent(focused.locks[index])
	elif type == KeyCounterElement:
		%keyCounterHandler.addButton(index)
		focusComponent(focused.elements[index])

func focusComponentRemoved(type:GDScript, index:int) -> void:
	if type == Lock:
		%lockHandler.removeButton(index)
		if index != 0: focusComponent(focused.locks[index-1])
	elif type == KeyCounterElement:
		%keyCounterHandler.removeButton(index)
		if index != 0: focusComponent(focused.elements[index-1])
