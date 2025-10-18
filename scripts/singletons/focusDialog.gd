extends Control
class_name FocusDialog

@onready var editor:Editor = get_node("/root/editor")
@onready var colorLink:Button = %colorLink

var focused:GameObject # the object that is currently focused
var componentFocused:GameComponent # you can focus both a door and a lock at the same time so
var interacted:PanelContainer # the number edit that is currently interacted

func focus(object:GameObject) -> void:
	var new:bool = object != focused
	focused = object
	editor.game.objects.remove_child(focused)
	editor.game.objects.add_child(focused)
	if focused is KeyBulk:
		%keyDialog.visible = true
		%doorDialog.visible = false
		%keyColorSelector.setSelect(focused.color)
		%keyTypeSelector.setSelect(focused.type)
		%keyCountEdit.visible = focused.type in [Game.KEY.NORMAL,Game.KEY.EXACT]
		%keyCountEdit.setValue(focused.count, true)
		%keyInfiniteToggle.button_pressed = focused.infinite
		if new: interact(%keyCountEdit.realEdit)
	elif focused is Door:
		%keyDialog.visible = false
		%doorDialog.visible = true
		%doorTypes.get_child(focused.type).button_pressed = true
		%lockSelector.colorLink.visible = focused.type == Door.TYPE.SIMPLE
		%spend.queue_redraw()
		if !componentFocused:
			%lockConfigurationSelector.visible = false
			%lockSettings.visible = false
			%doorAxialNumberEdit.visible = false
			%doorComplexNumberEdit.visible = true
			%doorColorSelector.setSelect(focused.colorSpend)
			%doorComplexNumberEdit.setValue(focused.copies, true)
			%spend.button_pressed = true
			%blastLockSettings.visible = false
		if new:
			interact(%doorComplexNumberEdit.realEdit)
			%lockSelector.setup(focused)
			if focused.type == Door.TYPE.SIMPLE: focusComponent(focused.locks[0])

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
		%doorColorSelector.setSelect(componentFocused.color)
		%doorAxialNumberEdit.setValue(componentFocused.count, true)
		%lockSelector.setSelect(componentFocused.index)
		%lockTypeSelector.setSelect(componentFocused.type)
		%lockConfigurationSelector.visible = focused.type != Door.TYPE.SIMPLE
		%lockConfigurationSelector.setup(componentFocused)
		%lockSettings.visible = true
		%doorAxialNumberEdit.visible = componentFocused.type == Lock.TYPE.NORMAL or componentFocused.type == Lock.TYPE.EXACT
		%doorComplexNumberEdit.visible = false
		%blastLockSettings.visible = componentFocused.type == Lock.TYPE.BLAST
		%blastLockSign.button_pressed = component.count.sign() < 0
		%blastLockAxis.button_pressed = component.count.isNonzeroImag()
		%lockSelector.redrawButton(component.index)
		if new:
			interact(%doorAxialNumberEdit)

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
	if Input.is_key_pressed(KEY_SHIFT):
		match numberEdit.purpose:
			NumberEdit.PURPOSE.IMAGINARY: interact(numberEdit.get_parent().realEdit)
			NumberEdit.PURPOSE.REAL:
				assert(focused is Door)
				if len(focused.locks) > 0: %lockSelector.buttons[len(focused.locks)-1].button_pressed = true
				interact(%doorAxialNumberEdit)
			NumberEdit.PURPOSE.AXIAL:
				if !componentFocused: return
				if componentFocused.index == 0: _spendSelected(); interact(%doorComplexNumberEdit.imaginaryEdit)
				else:
					%lockSelector.buttons[componentFocused.index - 1].button_pressed = true
	else:
		match numberEdit.purpose:
			NumberEdit.PURPOSE.REAL: interact(numberEdit.get_parent().imaginaryEdit)
			NumberEdit.PURPOSE.IMAGINARY:
				assert(focused is Door)
				if len(focused.locks) > 0: %lockSelector.buttons[0].button_pressed = true
				interact(%doorAxialNumberEdit)
			NumberEdit.PURPOSE.AXIAL:
				if !componentFocused: return
				if componentFocused.index == len(focused.locks) - 1: _spendSelected(); interact(%doorComplexNumberEdit.realEdit)
				else:
					%lockSelector.buttons[componentFocused.index + 1].button_pressed = true

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
				editor.changes.addChange(Changes.DeleteComponentChange.new(editor.game,focused,KeyBulk))
				editor.changes.bufferSave()
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
			KEY_L: if Input.is_key_pressed(KEY_CTRL): %lockSelector._addLock()
			KEY_DELETE:
				if componentFocused:
					%lockSelector._removeLock(componentFocused)
					if len(focused.locks) != 0: focusComponent(focused.locks[len(focused.locks)-1])
					else: focus(focused)
				else: editor.changes.addChange(Changes.DeleteComponentChange.new(editor.game,focused,Door))
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

func _keyCountSet(count:C):
	if focused is not KeyBulk: return
	editor.changes.addChange(Changes.PropertyChange.new(editor.game,focused,&"count",count))
	editor.changes.bufferSave()

func _keyInfiniteToggled(value:bool):
	if focused is not KeyBulk: return
	editor.changes.addChange(Changes.PropertyChange.new(editor.game,focused,&"infinite",value))
	editor.changes.bufferSave()

func _doorColorSelected(color:Game.COLOR):
	if focused is not Door: return
	if componentFocused:
		editor.changes.addChange(Changes.PropertyChange.new(editor.game,componentFocused,&"color",color))
	elif %lockSelector.colorLink.button_pressed and focused.type == Door.TYPE.SIMPLE:
		editor.changes.addChange(Changes.PropertyChange.new(editor.game,focused.locks[0],&"color",color))
	if !componentFocused or (%lockSelector.colorLink.button_pressed and focused.type == Door.TYPE.SIMPLE):
		editor.changes.addChange(Changes.PropertyChange.new(editor.game,focused,&"colorSpend",color))
	editor.changes.bufferSave()

func _doorComplexNumberSet(value:C):
	if focused is not Door: return
	editor.changes.addChange(Changes.PropertyChange.new(editor.game,focused,&"copies",value))
	editor.changes.bufferSave()

func _doorAxialNumberSet(value:C):
	if componentFocused is not Lock: return
	editor.changes.addChange(Changes.PropertyChange.new(editor.game,componentFocused,&"count",value))
	focused.queue_redraw()
	if focused.type == Door.TYPE.SIMPLE:
		componentFocused._simpleDoorUpdate()
	else: componentFocused._setAutoConfiguration()
	editor.changes.bufferSave()

func _lockTypeSelected(type:Lock.TYPE):
	if componentFocused is not Lock: return
	componentFocused._setType(type)

func _doorTypeSelected(type:Door.TYPE):
	if focused is not Door: return
	editor.changes.addChange(Changes.PropertyChange.new(editor.game,focused,&"type",type))
	%lockSelector.colorLink.visible = focused.type == Door.TYPE.SIMPLE
	if type == Door.TYPE.SIMPLE:
		focused.locks[0]._simpleDoorUpdate()
		%lockConfigurationSelector.visible = false
	else:
		%lockConfigurationSelector.visible = componentFocused is Lock
	editor.changes.bufferSave()

func _spendSelected():
	defocusComponent()
	focus(focused)

func _lockConfigurationSelected(option:ConfigurationSelector.OPTION):
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
	editor.changes.bufferSave()

func _blastLockSet():
	if componentFocused is not Lock: return
	editor.changes.addChange(Changes.PropertyChange.new(editor.game,componentFocused,&"count",(C.new(0,1) if %blastLockAxis.button_pressed else C.new(1)).times(-1 if %blastLockSign.button_pressed else 1)))
	focused.queue_redraw()
	editor.changes.bufferSave()
