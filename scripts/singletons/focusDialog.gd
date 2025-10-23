extends Control
class_name FocusDialog

@onready var editor:Editor = get_node("/root/editor")
@onready var colorLink:Button = %colorLink

var focused:GameObject # the object that is currently focused
var componentFocused:GameComponent # you can focus both a door and a lock at the same time so
var interacted:PanelContainer # the number edit that is currently interacted

var above:bool = false # display above the object instead

func focus(object:GameObject) -> void:
	var new:bool = object != focused
	focused = object
	editor.game.objectsParent.move_child(focused, -1)
	showCorrectDialog()
	if focused is KeyBulk:
		%keyColorSelector.setSelect(focused.color)
		%keyTypeSelector.setSelect(focused.type)
		%keyCountEdit.visible = focused.type in [KeyBulk.TYPE.NORMAL,KeyBulk.TYPE.EXACT]
		%keyCountEdit.setValue(focused.count, true)
		%keyInfiniteToggle.button_pressed = focused.infinite
		if new: interact(%keyCountEdit.realEdit)
	elif focused is Door:
		%doorTypes.get_child(focused.type).button_pressed = true
		%lockHandler.colorLink.visible = focused.type == Door.TYPE.SIMPLE
		%spend.queue_redraw()
		if !componentFocused:
			%lockConfigurationSelector.visible = false
			%lockSettings.visible = false
			%doorAxialNumberEdit.visible = false
			%doorComplexNumberEdit.visible = focused.type != Door.TYPE.GATE
			%doorColorSelector.visible = focused.type != Door.TYPE.GATE # a mod will probably add something so i wont turn off the menu completely
			%doorColorSelector.setSelect(focused.colorSpend)
			%doorComplexNumberEdit.setValue(focused.copies, true)
			%spend.button_pressed = true
			%blastLockSettings.visible = false
		if new:
			interact(%doorComplexNumberEdit.realEdit)
			%lockHandler.setup(focused)
			if focused.type == Door.TYPE.SIMPLE: focusComponent(focused.locks[0])
	elif focused is PlayerSpawn:
		if editor.game.levelStart == focused: %levelStart.button_pressed = true
		else: %savestate.button_pressed = true
	elif focused is KeyCounter:
		%keyCounterWidthSelector.setSelect(KeyCounter.WIDTHS.find(focused.size.x))
		%keyCounterColorSelector.visible = false
		if new:
			%keyCounterHandler.setup(focused)
			focusComponent(focused.elements[-1])

func showCorrectDialog() -> void:
	%keyDialog.visible = focused is KeyBulk
	%doorDialog.visible = focused is Door
	%playerDialog.visible = focused is PlayerSpawn
	%keyCounterDialog.visible = focused is KeyCounter
	above = focused is KeyCounter
	%speechBubbler.rotation_degrees = 0 if above else 180

func defocus() -> void:
	if !focused: return
	focused = null
	editor.quickSet.cancel()
	deinteract()
	defocusComponent()

func focusComponent(component:GameComponent) -> void:
	var new:bool = component != componentFocused
	if focused != component.parent: focus(component.parent)
	componentFocused = component
	if component is Lock:
		%doorColorSelector.visible = true
		%doorColorSelector.setSelect(component.color)
		%doorAxialNumberEdit.setValue(component.count, true)
		%lockHandler.setSelect(component.index)
		%lockTypeSelector.setSelect(component.type)
		%lockConfigurationSelector.visible = focused.type != Door.TYPE.SIMPLE
		%lockConfigurationSelector.setup(component)
		%lockSettings.visible = true
		%doorAxialNumberEdit.visible = component.type == Lock.TYPE.NORMAL or component.type == Lock.TYPE.EXACT
		%doorComplexNumberEdit.visible = false
		%blastLockSettings.visible = component.type == Lock.TYPE.BLAST
		%blastLockSign.button_pressed = component.count.sign() < 0
		%blastLockAxis.button_pressed = component.count.isNonzeroImag()
		%lockHandler.redrawButton(component.index)
		if new:
			interact(%doorAxialNumberEdit)
	elif component is KeyCounterElement:
		%keyCounterHandler.setSelect(component.index)
		%keyCounterHandler.redrawButton(component.index)
		%keyCounterColorSelector.visible = true
		%keyCounterColorSelector.setSelect(component.color)

func defocusComponent() -> void:
	if !componentFocused: return
	componentFocused = null;

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
				if componentFocused.index == 0: _spendSelected(); interact(%doorComplexNumberEdit.imaginaryEdit)
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
				if componentFocused.index == len(focused.locks) - 1: _spendSelected(); interact(%doorComplexNumberEdit.realEdit)
				else:
					%lockHandler.buttons[componentFocused.index + 1].button_pressed = true

func receiveKey(event:InputEvent) -> bool:
	if focused is KeyBulk:
		match event.keycode:
			KEY_N: _keyTypeSelected(KeyBulk.TYPE.NORMAL)
			KEY_E: _keyTypeSelected(KeyBulk.TYPE.EXACT if focused.type != KeyBulk.TYPE.EXACT else KeyBulk.TYPE.NORMAL)
			KEY_S: _keyTypeSelected(KeyBulk.TYPE.STAR if focused.type != KeyBulk.TYPE.STAR else KeyBulk.TYPE.UNSTAR)
			KEY_R:
				if focused.type == KeyBulk.TYPE.SIGNFLIP: _keyTypeSelected(KeyBulk.TYPE.NEGROTOR)
				elif focused.type == KeyBulk.TYPE.POSROTOR: _keyTypeSelected(KeyBulk.TYPE.SIGNFLIP)
				else: _keyTypeSelected(KeyBulk.TYPE.POSROTOR)
			KEY_C: editor.quickSet.startQuick(QuickSet.QUICK.COLOR, focused)
			KEY_U: _keyTypeSelected(KeyBulk.TYPE.CURSE if focused.type != KeyBulk.TYPE.CURSE else KeyBulk.TYPE.UNCURSE)
			KEY_DELETE:
				changes.addChange(Changes.DeleteComponentChange.new(editor.game,focused))
				changes.bufferSave()
			KEY_Y: _keyInfiniteToggled(!focused.infinite)
			_: return false
	elif focused is Door:
		match event.keycode:
			KEY_N: _lockTypeSelected(Lock.TYPE.NORMAL)
			KEY_B: _lockTypeSelected(Lock.TYPE.BLANK)
			KEY_X: _lockTypeSelected(Lock.TYPE.BLAST)
			KEY_A: _lockTypeSelected(Lock.TYPE.ALL)
			KEY_E: _lockTypeSelected(Lock.TYPE.EXACT)
			KEY_C:
				if componentFocused: editor.quickSet.startQuick(QuickSet.QUICK.COLOR, componentFocused)
				else: editor.quickSet.startQuick(QuickSet.QUICK.COLOR, focused)
			KEY_L: if Input.is_key_pressed(KEY_CTRL): %lockHandler._addElement()
			KEY_DELETE:
				if componentFocused:
					%lockHandler._removeElement()
					if len(focused.locks) != 0: focusComponent(focused.locks[len(focused.locks)-1])
					else: focus(focused)
				else: changes.addChange(Changes.DeleteComponentChange.new(editor.game,focused))
				changes.bufferSave()
			_: return false
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

func _keyColorSelected(color:Game.COLOR) -> void:
	if focused is not KeyBulk: return
	changes.addChange(Changes.PropertyChange.new(editor.game,focused,&"color",color))
	changes.bufferSave()

func _keyTypeSelected(type:KeyBulk.TYPE) -> void:
	if focused is not KeyBulk: return
	changes.addChange(Changes.PropertyChange.new(editor.game,focused,&"type",type))
	changes.bufferSave()

func _keyCountSet(count:C) -> void:
	if focused is not KeyBulk: return
	changes.addChange(Changes.PropertyChange.new(editor.game,focused,&"count",count))
	changes.bufferSave()

func _keyInfiniteToggled(value:bool) -> void:
	if focused is not KeyBulk: return
	changes.addChange(Changes.PropertyChange.new(editor.game,focused,&"infinite",value))
	changes.bufferSave()

func _doorColorSelected(color:Game.COLOR) -> void:
	if focused is not Door: return
	if componentFocused:
		changes.addChange(Changes.PropertyChange.new(editor.game,componentFocused,&"color",color))
	elif %lockHandler.colorLink.button_pressed and focused.type == Door.TYPE.SIMPLE:
		changes.addChange(Changes.PropertyChange.new(editor.game,focused.locks[0],&"color",color))
	if !componentFocused or (%lockHandler.colorLink.button_pressed and focused.type == Door.TYPE.SIMPLE):
		changes.addChange(Changes.PropertyChange.new(editor.game,focused,&"colorSpend",color))
	changes.bufferSave()

func _doorComplexNumberSet(value:C) -> void:
	if focused is not Door: return
	changes.addChange(Changes.PropertyChange.new(editor.game,focused,&"copies",value))
	changes.bufferSave()

func _doorAxialNumberSet(value:C) -> void:
	if componentFocused is not Lock: return
	changes.addChange(Changes.PropertyChange.new(editor.game,componentFocused,&"count",value))
	focused.queue_redraw()
	if focused.type == Door.TYPE.SIMPLE:
		componentFocused._simpleDoorUpdate()
	else: componentFocused._setAutoConfiguration()
	changes.bufferSave()

func _lockTypeSelected(type:Lock.TYPE) -> void:
	if componentFocused is not Lock: return
	componentFocused._setType(type)

func _doorTypeSelected(type:Door.TYPE) -> void:
	if focused is not Door: return
	changes.addChange(Changes.PropertyChange.new(editor.game,focused,&"type",type))
	%lockHandler.colorLink.visible = focused.type == Door.TYPE.SIMPLE
	if type == Door.TYPE.SIMPLE:
		if len(focused.locks) == 0: %lockHandler._addElement()
		elif len(focused.locks) > 1:
			for lock in focused.locks.slice(1):
				%lockHandler._removeElement(lock.index)
		focused.locks[0]._simpleDoorUpdate()
		%lockConfigurationSelector.visible = false
	else:
		if type == Door.TYPE.GATE:
			changes.addChange(Changes.PropertyChange.new(editor.game,focused,&"color",Game.COLOR.WHITE))
		%lockConfigurationSelector.visible = componentFocused is Lock
	changes.bufferSave()
	%spend.queue_redraw()

func _spendSelected() -> void:
	defocusComponent()
	focus(focused)

func _lockConfigurationSelected(option:ConfigurationSelector.OPTION) -> void:
	if componentFocused is not Lock: return
	match option:
		ConfigurationSelector.OPTION.SpecificA:
			var configuration:Array = componentFocused.getAvailableConfigurations()[0]
			componentFocused._comboDoorConfigurationChanged(configuration[0], configuration[1])
		ConfigurationSelector.OPTION.SpecificB:
			var configuration:Array = componentFocused.getAvailableConfigurations()[1]
			componentFocused._comboDoorConfigurationChanged(configuration[0], configuration[1])
		ConfigurationSelector.OPTION.AnyS: componentFocused._comboDoorConfigurationChanged(Lock.SIZE_TYPE.AnyS)
		ConfigurationSelector.OPTION.AnyH: componentFocused._comboDoorConfigurationChanged(Lock.SIZE_TYPE.AnyH)
		ConfigurationSelector.OPTION.AnyV: componentFocused._comboDoorConfigurationChanged(Lock.SIZE_TYPE.AnyV)
		ConfigurationSelector.OPTION.AnyM: componentFocused._comboDoorConfigurationChanged(Lock.SIZE_TYPE.AnyM)
		ConfigurationSelector.OPTION.AnyL: componentFocused._comboDoorConfigurationChanged(Lock.SIZE_TYPE.AnyL)
		ConfigurationSelector.OPTION.AnyXL: componentFocused._comboDoorConfigurationChanged(Lock.SIZE_TYPE.AnyXL)
	changes.bufferSave()

func _blastLockSet() -> void:
	if componentFocused is not Lock: return
	changes.addChange(Changes.PropertyChange.new(editor.game,componentFocused,&"count",(C.I if %blastLockAxis.button_pressed else C.new(1)).times(-1 if %blastLockSign.button_pressed else 1)))
	focused.queue_redraw()
	changes.bufferSave()

func _setLevelStart() -> void:
	if focused is not PlayerSpawn: return
	if editor.game.levelStart:
		editor.game.levelStart.queue_redraw()
	changes.addChange(Changes.GlobalObjectChange.new(editor.game,editor.game,&"levelStart",focused))
	focused.queue_redraw()

func _setSavestate() -> void:
	if focused is not PlayerSpawn: return
	if editor.game.levelStart == focused:
		changes.addChange(Changes.GlobalObjectChange.new(editor.game,editor.game,&"levelStart",null))
		focused.queue_redraw()

func _playTest() -> void:
	editor.game.playTest(focused)

func _keyCounterWidthSelected(width:int):
	if focused is not KeyCounter: return
	changes.addChange(Changes.PropertyChange.new(editor.game,focused,&"size",Vector2(KeyCounter.WIDTHS[width],focused.size.y)))
	changes.bufferSave()

func _keyCounterColorSelected(color:Game.COLOR) -> void:
	if focused is not KeyCounter: return
	changes.addChange(Changes.PropertyChange.new(editor.game,componentFocused,&"color",color))
	changes.bufferSave()
