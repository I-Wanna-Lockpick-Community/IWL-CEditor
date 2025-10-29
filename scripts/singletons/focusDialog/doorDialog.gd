extends Control
class_name DoorDialog

@onready var editor:Editor = get_node("/root/editor")
@onready var main = get_parent()

func focus(focused:Door, new:bool) -> void:
	%doorTypes.get_child(focused.type).button_pressed = true
	%lockHandler.colorLink.visible = focused.type == Door.TYPE.SIMPLE
	%spend.queue_redraw()
	%lockConfigurationSelector.visible = main.componentFocused and focused.type != Door.TYPE.SIMPLE
	%doorColorSelector.visible = main.componentFocused or focused.type != Door.TYPE.GATE # a mod will probably add something so i wont turn off the menu completely
	%frozen.button_pressed = focused.frozen
	%crumbled.button_pressed = focused.crumbled
	%painted.button_pressed = focused.painted
	if !main.componentFocused:
		%lockSettings.visible = false
		%doorAxialNumberEdit.visible = false
		%doorAuraSettings.visible = focused.type != Door.TYPE.GATE
		%doorComplexNumberEdit.visible = focused.type != Door.TYPE.GATE
		%doorColorSelector.setSelect(focused.colorSpend)
		%doorComplexNumberEdit.setValue(focused.copies, true)
		%spend.button_pressed = true
		%blastLockSettings.visible = false
	if new:
		main.interact(%doorComplexNumberEdit.realEdit)
		%lockHandler.setup(focused)
		if focused.type == Door.TYPE.SIMPLE: main.focusComponent(focused.locks[0])

func focusComponent(component:Lock, new:bool) -> void:
	%doorColorSelector.visible = true
	%doorColorSelector.setSelect(component.color)
	%doorAxialNumberEdit.setValue(component.count, true)
	%lockHandler.setSelect(component.index)
	%lockTypeSelector.setSelect(component.type)
	%lockConfigurationSelector.visible = main.focused.type != Door.TYPE.SIMPLE
	%lockConfigurationSelector.setup(component)
	%lockSettings.visible = true
	%doorAxialNumberEdit.visible = component.type == Lock.TYPE.NORMAL or component.type == Lock.TYPE.EXACT
	%doorAuraSettings.visible = false
	%doorComplexNumberEdit.visible = false
	%blastLockSettings.visible = component.type == Lock.TYPE.BLAST
	%blastLockSign.button_pressed = component.count.sign() < 0
	%blastLockAxis.button_pressed = component.count.isNonzeroImag()
	%lockHandler.redrawButton(component.index)
	if new:
		main.interact(%doorAxialNumberEdit)

func receiveKey(event:InputEvent) -> bool:
	match event.keycode:
		KEY_N: _lockTypeSelected(Lock.TYPE.NORMAL)
		KEY_B: _lockTypeSelected(Lock.TYPE.BLANK)
		KEY_X: _lockTypeSelected(Lock.TYPE.BLAST)
		KEY_A: _lockTypeSelected(Lock.TYPE.ALL)
		KEY_E: _lockTypeSelected(Lock.TYPE.EXACT)
		KEY_C:
			if main.componentFocused: editor.quickSet.startQuick(QuickSet.QUICK.COLOR, main.componentFocused)
			else: editor.quickSet.startQuick(QuickSet.QUICK.COLOR, main.focused)
		KEY_L: if Input.is_key_pressed(KEY_CTRL): main.focused.addLock()
		KEY_DELETE:
			if main.componentFocused:
				main.focused.removeLock(main.componentFocused.index)
				if len(main.focused.locks) != 0: main.focusComponent(main.focused.locks[-1])
				else: main.focus(main.focused)
			else: changes.addChange(Changes.DeleteComponentChange.new(editor.game,main.focused))
			changes.bufferSave()
		_: return false
	return true

func _doorColorSelected(color:Game.COLOR) -> void:
	if main.focused is not Door: return
	if main.componentFocused:
		changes.addChange(Changes.PropertyChange.new(editor.game,main.componentFocused,&"color",color))
	elif %lockHandler.colorLink.button_pressed and main.focused.type == Door.TYPE.SIMPLE:
		changes.addChange(Changes.PropertyChange.new(editor.game,main.focused.locks[0],&"color",color))
	if !main.componentFocused or (%lockHandler.colorLink.button_pressed and main.focused.type == Door.TYPE.SIMPLE):
		changes.addChange(Changes.PropertyChange.new(editor.game,main.focused,&"colorSpend",color))
	changes.bufferSave()

func _doorComplexNumberSet(value:C) -> void:
	if main.focused is not Door: return
	changes.addChange(Changes.PropertyChange.new(editor.game,main.focused,&"copies",value))
	changes.bufferSave()

func _doorAxialNumberSet(value:C) -> void:
	if main.componentFocused is not Lock: return
	changes.addChange(Changes.PropertyChange.new(editor.game,main.componentFocused,&"count",value))
	main.focused.queue_redraw()
	changes.bufferSave()

func _lockTypeSelected(type:Lock.TYPE) -> void:
	if main.componentFocused is not Lock: return
	main.componentFocused._setType(type)

func _doorTypeSelected(type:Door.TYPE) -> void:
	if main.focused is not Door: return
	changes.addChange(Changes.PropertyChange.new(editor.game,main.focused,&"type",type))
	changes.bufferSave()

func _spendSelected() -> void:
	main.defocusComponent()
	main.focus(main.focused)

func _lockConfigurationSelected(option:ConfigurationSelector.OPTION) -> void:
	if main.componentFocused is not Lock: return
	match option:
		ConfigurationSelector.OPTION.SpecificA:
			var configuration:Array = main.componentFocused.getAvailableConfigurations()[0]
			main.componentFocused._comboDoorConfigurationChanged(configuration[0], configuration[1])
		ConfigurationSelector.OPTION.SpecificB:
			var configuration:Array = main.componentFocused.getAvailableConfigurations()[1]
			main.componentFocused._comboDoorConfigurationChanged(configuration[0], configuration[1])
		ConfigurationSelector.OPTION.AnyS: main.componentFocused._comboDoorConfigurationChanged(Lock.SIZE_TYPE.AnyS)
		ConfigurationSelector.OPTION.AnyH: main.componentFocused._comboDoorConfigurationChanged(Lock.SIZE_TYPE.AnyH)
		ConfigurationSelector.OPTION.AnyV: main.componentFocused._comboDoorConfigurationChanged(Lock.SIZE_TYPE.AnyV)
		ConfigurationSelector.OPTION.AnyM: main.componentFocused._comboDoorConfigurationChanged(Lock.SIZE_TYPE.AnyM)
		ConfigurationSelector.OPTION.AnyL: main.componentFocused._comboDoorConfigurationChanged(Lock.SIZE_TYPE.AnyL)
		ConfigurationSelector.OPTION.AnyXL: main.componentFocused._comboDoorConfigurationChanged(Lock.SIZE_TYPE.AnyXL)
	changes.bufferSave()

func _blastLockSet() -> void:
	if main.componentFocused is not Lock: return
	changes.addChange(Changes.PropertyChange.new(editor.game,main.componentFocused,&"count",(C.I if %blastLockAxis.button_pressed else C.new(1)).times(-1 if %blastLockSign.button_pressed else 1)))
	main.focused.queue_redraw()
	changes.bufferSave()


func _frozenSet(value:bool):
	if main.focused is not Door: return
	changes.addChange(Changes.PropertyChange.new(editor.game,main.focused,&"frozen",value))
	changes.bufferSave()

func _crumbledSet(value:bool):
	if main.focused is not Door: return
	changes.addChange(Changes.PropertyChange.new(editor.game,main.focused,&"crumbled",value))
	changes.bufferSave()

func _paintedSet(value:bool):
	if main.focused is not Door: return
	changes.addChange(Changes.PropertyChange.new(editor.game,main.focused,&"painted",value))
	changes.bufferSave()
