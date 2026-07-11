extends SubDialog
class_name DoorDialog

@onready var lockHandler:LockHandler = %lockHandler
@onready var doorsHandler:DoorsHandler = %doorsHandler

func _ready() -> void:
	%doorCopiesEdit.transformation = doorCopiesTransformation

func doorCopiesTransformation(value:PackedInt64Array) -> PackedInt64Array:
	if main.focused is Door: value = M.without(value, main.focused.infCopies)
	return value

func focus(focused:GameObject, new:bool, dontRedirect:bool, skipInput:Control) -> void: # Door or RemoteLock
	%spendArmament.visible = Mods.active(&"Armaments") and main.focused is Door
	%oscillate.visible = Mods.active(&"Fractions") and main.focused is Door
	%frozen.button_pressed = focused.frozen
	%crumbled.button_pressed = focused.crumbled
	%painted.button_pressed = focused.painted
	if focused is Door:
		%door.visible = true
		%remoteLock.visible = false
		%doorTypes.get_child(focused.type).button_pressed = true
		%colorLink.visible = focused.type == Door.TYPE.SIMPLE
		%spend.queue_redraw()
		%lockConfigurationSelector.visible = main.componentFocused and focused.type != Door.TYPE.SIMPLE
		%doorColorSelector.visible = main.componentFocused or focused.type != Door.TYPE.GATE # a mod will probably add something so i wont turn off the menu completely
		%spendArmament.button_pressed = focused.armament
		%oscillate.button_pressed = focused.oscillate
		%realInfinitePosCopy.button_pressed = M.positive(M.r(focused.infCopies))
		%realInfiniteNegCopy.button_pressed = M.negative(M.r(focused.infCopies))
		%imagInfinitePosCopy.button_pressed = M.positive(M.ir(focused.infCopies))
		%imagInfiniteNegCopy.button_pressed = M.negative(M.ir(focused.infCopies))
		%doorCopiesEdit.allowZero = Mods.active(&"ZeroCopyDoors") or M.ex(focused.infCopies)
		if !main.componentFocused:
			%lockSettings.visible = false
			%lockCountEdit.visible = false
			%doorBooleans.visible = focused.type != Door.TYPE.GATE
			if focused.type != Door.TYPE.GATE:
				%doorAuras.visible = focused.allowAuras()
			%doorCopySettings.visible = focused.type != Door.TYPE.GATE
			%doorColorSelector.setSelect(focused.colorSpend)
			%spend.button_pressed = true
			%blastLockSettings.visible = false
		if main.interacted and !main.interacted.is_visible_in_tree(): main.deinteract()
		if %doorCopySettings.visible:
			if !main.interacted: main.interact(%doorCopiesEdit)
		elif %lockCountEdit.visible:
			if !main.interacted: main.interact(%lockCountEdit)
		else: main.deinteract()
		if skipInput != %doorCopiesEdit: %doorCopiesEdit.setValue(M.without(focused.copies, focused.infCopies))
		if new:
			%lockHandler.setup(focused)
			if focused.type == Door.TYPE.SIMPLE and !dontRedirect: main.focusComponent(focused.locks[0], skipInput)
	elif focused is RemoteLock:
		%door.visible = false
		%remoteLock.visible = true
		%doorBooleans.visible = !focused.armament
		%lockConfigurationSelector.visible = false
		%doorsHandler.setup(focused)
		focusComponent(focused, new, skipInput)

func focusComponent(component:GameComponent, _new:bool, skipInput:Control = null) -> void: # Lock or RemoteLock
	%doorColorSelector.visible = true
	%doorColorSelector.setSelect(component.color)
	if component is Lock: %lockHandler.setSelect(component.index)
	%lockTypeSelector.setSelect(component.type)
	if component is Lock:
		%lockConfigurationSelector.visible = main.focused.type != Door.TYPE.SIMPLE
		%lockConfigurationSelector.setup(component)
	%lockSettings.visible = true
	%lockSpendTypeSelector.visible = Mods.active(&"StarryWeakForceful")
	%lockSpendTypeSelector.setSelect(component.spendType)
	
	%remoteLockConvert.visible = Mods.active(&"RemoteLocks") and component is not RemoteLock

	%lockCountEdit.visible = component.type in [Lock.TYPE.NORMAL, Lock.TYPE.EXACT, Lock.TYPE.GLISTENING, Lock.TYPE.REMAINDER]
	%lockCountEdit.allowZero = Mods.active(&"ZeroCostLocks") \
		or (Mods.active(&"PartialBlastLocks") and component.type in [Lock.TYPE.BLAST, Lock.TYPE.ALL]) \
		or component.type == Lock.TYPE.EXACT
	%lockCountEdit.allowZeroI = component.type == Lock.TYPE.EXACT
	if skipInput != %lockCountEdit: %lockCountEdit.setValue(component.count)
	if component.zeroI: %lockCountEdit.setZeroI()

	%doorCopySettings.visible = false
	if component is Lock: %doorBooleans.visible = false

	%blastLockSettings.visible = component.type in [Lock.TYPE.BLAST, Lock.TYPE.ALL]
	%blastLockSign.button_pressed = M.negative(M.sign(component.denominator))
	%blastLockAxis.button_pressed = M.isNonzeroImag(component.denominator)
	
	%partialBlastSettings.visible = Mods.active(&"PartialBlastLocks")
	%isPartial.visible = Mods.active(&"PartialBlastLocks")
	%isPartial.button_pressed = component.isPartial
	%partialBlastDenominatorEdit.visible = component.isPartial
	%discreteBlastSettings.visible = !component.isPartial and component.type != Lock.TYPE.ALL
	%partialBlastConfiguration.visible = component.isPartial
	%partialBlastConfigurationV.button_pressed = !component.partialBlastHorizontal
	%partialBlastConfigurationH.button_pressed = component.partialBlastHorizontal
	if skipInput != %partialBlastNumeratorEdit: %partialBlastNumeratorEdit.setValue(component.count)
	if skipInput != %partialBlastDenominatorEdit: %partialBlastDenominatorEdit.setValue(component.denominator)

	if component is Lock: %lockHandler.redrawButton(component.index)
	%lockNegated.button_pressed = component.negated
	%lockArmament.button_pressed = component.armament
	if main.interacted and !main.interacted.is_visible_in_tree(): main.deinteract()
	if %lockCountEdit.visible:
		if !main.interacted: main.interact(%lockCountEdit)
	elif %partialBlastSettings.visible:
		if !main.interacted: main.interact(%partialBlastNumeratorEdit)
	else: main.deinteract()

func receiveKey(event:InputEvent) -> bool:
	var blastSettings:bool = !main.interacted and main.componentFocused and main.componentFocused.type == Lock.TYPE.BLAST
	if Editor.eventIs(event, &"numberNegate") and blastSettings: _blastLockSignSet(!%blastLockSign.button_pressed)
	elif Editor.eventIs(event, &"numberTimesI") and blastSettings: _blastLockAxisSet(!%blastLockAxis.button_pressed)
	elif main.focused is RemoteLock or main.componentFocused is Lock:
		var lock:GameComponent = main.focused if main.focused is RemoteLock else main.componentFocused
		if Editor.eventIs(event, &"focusLockNormal"): _lockTypeSelected(Lock.TYPE.NORMAL)
		elif Editor.eventIs(event, &"focusLockBlank"): _lockTypeSelected(Lock.TYPE.BLANK if lock.type != Lock.TYPE.BLANK else Lock.TYPE.NORMAL)
		elif Editor.eventIs(event, &"focusLockBlast"): _lockTypeSelected(Lock.TYPE.BLAST if lock.type != Lock.TYPE.BLAST else Lock.TYPE.NORMAL)
		elif Editor.eventIs(event, &"focusLockAll"): _lockTypeSelected(Lock.TYPE.ALL if lock.type != Lock.TYPE.ALL else Lock.TYPE.NORMAL)
		elif Editor.eventIs(event, &"focusLockExact") and Mods.active(&"C3"): _lockTypeSelected(Lock.TYPE.EXACT if lock.type != Lock.TYPE.EXACT else Lock.TYPE.NORMAL)
		elif Editor.eventIs(event, &"focusLockGlistening") and Mods.active(&"Glistening"): _lockTypeSelected(Lock.TYPE.GLISTENING if lock.type != Lock.TYPE.GLISTENING else Lock.TYPE.NORMAL)
		elif Editor.eventIs(event, &"focusLockNegated") and Mods.active(&"NegatedLocks"): _lockNegatedSet(!%lockNegated.button_pressed)
		elif Editor.eventIs(event, &"focusLockRemainder") and Mods.active(&"RemainderLocks"): _lockTypeSelected(Lock.TYPE.REMAINDER if lock.type != Lock.TYPE.REMAINDER else Lock.TYPE.NORMAL)
		elif Editor.eventIs(event, &"focusLockArmament") and Mods.active(&"Armaments"): _lockArmamentSet(!%lockArmament.button_pressed)
		elif main.focused is RemoteLock:
			if Editor.eventIs(event, &"focusRemoteLockAddConnection"): %doorsHandler.addComponent()
			elif Editor.eventIs(event, &"focusDoorFrozen"): _frozenSet(!main.focused.frozen)
			elif Editor.eventIs(event, &"focusDoorCrumbled"): _crumbledSet(!main.focused.crumbled)
			elif Editor.eventIs(event, &"focusDoorPainted"): _paintedSet(!main.focused.painted)
			elif Editor.eventIs(event, &"quicksetColor"): Game.editor.quickSet.startQuick(&"quicksetColor", main.focused)
			else: return false
		else:
			if Editor.eventIs(event, &"focusLockDuplicate", true): main.focused.duplicateLock(main.componentFocused)
			elif Editor.eventIs(event, &"focusLockConvertRemote") and Mods.active(&"RemoteLocks"): _remoteLockConvert()
			elif Editor.eventIs(event, &"focusDoorFrozen"): _frozenSet(!main.focused.frozen)
			elif Editor.eventIs(event, &"focusDoorCrumbled"): _crumbledSet(!main.focused.crumbled)
			elif Editor.eventIs(event, &"focusDoorPainted"): _paintedSet(!main.focused.painted)
			elif Editor.eventIs(event, &"focusDoorSpendArmament") and Mods.active(&"Armaments"): _spendArmamentSet(!main.focused.armament)
			elif Editor.eventIs(event, &"focusDoorOscillate") and Mods.active(&"Fractions"): _oscillateSet(!main.focused.oscillate)
			elif Editor.eventIs(event, &"focusDoorAddLock", true): main.focused.addLock()
			elif Editor.eventIs(event, &"focusDoorColorLink"): %colorLink.button_pressed = !%colorLink.button_pressed
			elif Editor.eventIs(event, &"quicksetLockSize"): Game.editor.quickSet.startQuick(&"quicksetLockSize", main.componentFocused)
			elif Editor.eventIs(event, &"editDelete"):
				main.focused.removeLock(main.componentFocused.index)
				if len(main.focused.locks) != 0: main.focusComponent(main.focused.locks[-1])
				else: main.focus(main.focused)
			elif Editor.eventIs(event, &"quicksetColor"): Game.editor.quickSet.startQuick(&"quicksetColor", main.componentFocused)
			else: return false
	else:
		if Editor.eventIs(event, &"focusDoorFrozen"): _frozenSet(!main.focused.frozen)
		elif Editor.eventIs(event, &"focusDoorCrumbled"): _crumbledSet(!main.focused.crumbled)
		elif Editor.eventIs(event, &"focusDoorPainted"): _paintedSet(!main.focused.painted)
		elif Editor.eventIs(event, &"focusDoorSpendArmament") and Mods.active(&"Armaments"): _spendArmamentSet(!main.focused.armament)
		elif Editor.eventIs(event, &"focusDoorOscillate") and Mods.active(&"Fractions"): _oscillateSet(!main.focused.oscillate)
		elif Editor.eventIs(event, &"focusDoorAddLock", true): main.focused.addLock()
		elif Editor.eventIs(event, &"focusDoorColorLink"): %colorLink.button_pressed = !%colorLink.button_pressed
		elif Editor.eventIs(event, &"quicksetColor"): Game.editor.quickSet.startQuick(&"quicksetColor", main.focused)
		else: return false
	return true

func changedMods() -> void:
	%lockSettingsSep.visible = Mods.active(&"NegatedLocks") or Mods.active(&"Armaments")
	%remoteLockConvert.visible = Mods.active(&"RemoteLocks") and main.componentFocused is Lock
	%lockNegated.visible = Mods.active(&"NegatedLocks")
	%lockArmament.visible = Mods.active(&"Armaments")
	%doorInfCopiesSettings.visible = Mods.active(&"InfCopyDoors")
	%spendArmament.visible = Mods.active(&"Armaments") and main.focused is Door
	%oscillate.visible = Mods.active(&"Fractions") and main.focused is Door
	if main.componentFocused is Lock and main.componentFocused.type in [Lock.TYPE.BLAST, Lock.TYPE.ALL]:
		main.focusComponent(main.componentFocused)

func _doorColorSelected(color:C.olors) -> void:
	if main.focused is not Door and main.focused is not RemoteLock: return
	if main.focused is Door:
		if main.componentFocused:
			Changes.addChange(Changes.PropertyChange.new(main.componentFocused,&"color",color))
		elif %colorLink.button_pressed and main.focused.type == Door.TYPE.SIMPLE:
			Changes.addChange(Changes.PropertyChange.new(main.focused.locks[0],&"color",color))
		if !main.componentFocused or (%colorLink.button_pressed and main.focused.type == Door.TYPE.SIMPLE):
			Changes.addChange(Changes.PropertyChange.new(main.focused,&"colorSpend",color))
	elif main.focused is RemoteLock:
		Changes.addChange(Changes.PropertyChange.new(main.focused,&"color",color))
	Changes.bufferSave()

func _doorCopiesSet(value:PackedInt64Array) -> void:
	if main.focused is not Door: return
	Changes.addChange(Changes.PropertyChange.new(main.focused,&"copies",M.orelse(main.focused.infCopies, value),%doorCopiesEdit))
	Changes.bufferSave()

func _lockCountSet(value:PackedInt64Array) -> void:
	if main.componentFocused is not Lock and main.focused is not RemoteLock: return
	var lock:GameComponent = main.componentFocused if main.componentFocused is Lock else main.focused
	Changes.addChange(Changes.PropertyChange.new(lock,&"count",value,%lockCountEdit))
	Changes.addChange(Changes.PropertyChange.new(lock,&"zeroI",%lockCountEdit.isZeroI))
	Changes.bufferSave()

func _lockTypeSelected(type:Lock.TYPE) -> void:
	if main.componentFocused is not Lock and main.focused is not RemoteLock: return
	var lock:GameComponent = main.componentFocused if main.componentFocused is Lock else main.focused
	Changes.addChange(Changes.PropertyChange.new(lock,&"type",type))

func _doorTypeSelected(type:Door.TYPE) -> void:
	if main.focused is not Door: return
	Changes.addChange(Changes.PropertyChange.new(main.focused,&"type",type))
	Changes.bufferSave()

func _spendSelected() -> void:
	main.defocusComponent()
	main.focus(main.focused)

func _lockConfigurationSelected(option:ConfigurationSelector.OPTION) -> void:
	if main.componentFocused is not Lock: return
	var lock:GameComponent = main.componentFocused
	var availableConfigurations:Array[Array] = lock.getAvailableConfigurations()
	match option:
		ConfigurationSelector.OPTION.SpecificA:
			if len(availableConfigurations) < 1: return
			var configuration:Array = availableConfigurations[0]
			lock._comboDoorConfigurationChanged(configuration[0], configuration[1])
		ConfigurationSelector.OPTION.SpecificB:
			if len(availableConfigurations) < 2: return
			var configuration:Array = availableConfigurations[1]
			lock._comboDoorConfigurationChanged(configuration[0], configuration[1])
		ConfigurationSelector.OPTION.AnyS: lock._comboDoorConfigurationChanged(Lock.SIZE_TYPE.AnyS)
		ConfigurationSelector.OPTION.AnyH: lock._comboDoorConfigurationChanged(Lock.SIZE_TYPE.AnyH)
		ConfigurationSelector.OPTION.AnyV: lock._comboDoorConfigurationChanged(Lock.SIZE_TYPE.AnyV)
		ConfigurationSelector.OPTION.AnyM: lock._comboDoorConfigurationChanged(Lock.SIZE_TYPE.AnyM)
		ConfigurationSelector.OPTION.AnyL: lock._comboDoorConfigurationChanged(Lock.SIZE_TYPE.AnyL)
		ConfigurationSelector.OPTION.AnyXL: lock._comboDoorConfigurationChanged(Lock.SIZE_TYPE.AnyXL)
	Changes.bufferSave()

func _frozenSet(value:bool) -> void:
	if main.focused is not Door and main.focused is not RemoteLock: return
	if main.focused is Door and main.focused.type == Door.TYPE.GATE: return
	Changes.addChange(Changes.PropertyChange.new(main.focused,&"frozen",value))
	Changes.bufferSave()

func _crumbledSet(value:bool) -> void:
	if main.focused is not Door and main.focused is not RemoteLock: return
	if main.focused is Door and main.focused.type == Door.TYPE.GATE: return
	Changes.addChange(Changes.PropertyChange.new(main.focused,&"crumbled",value))
	Changes.bufferSave()

func _paintedSet(value:bool) -> void:
	if main.focused is not Door and main.focused is not RemoteLock: return
	if main.focused is Door and main.focused.type == Door.TYPE.GATE: return
	Changes.addChange(Changes.PropertyChange.new(main.focused,&"painted",value))
	Changes.bufferSave()

func _oscillateSet(value:bool) -> void:
	if main.focused is not Door and main.focused is not RemoteLock: return
	if main.focused is Door and main.focused.type == Door.TYPE.GATE: return
	Changes.addChange(Changes.PropertyChange.new(main.focused,&"oscillate",value))
	Changes.bufferSave()

func _lockNegatedSet(value:bool) -> void:
	if main.componentFocused is not Lock and main.focused is not RemoteLock: return
	var lock:GameComponent = main.componentFocused if main.componentFocused is Lock else main.focused
	Changes.addChange(Changes.PropertyChange.new(lock,&"negated",value))
	Changes.bufferSave()
	
func _lockSpendTypeSet(value:Lock.SPEND_TYPE):
	if main.componentFocused is not Lock and main.focused is not RemoteLock: return
	var lock:GameComponent = main.componentFocused if main.componentFocused is Lock else main.focused
	Changes.addChange(Changes.PropertyChange.new(lock,&"spendType",value))
	Changes.bufferSave()
	
func _partialBlastNumeratorSet(value:PackedInt64Array) -> void:
	if main.componentFocused is not Lock and main.focused is not RemoteLock: return
	var lock:GameComponent = main.componentFocused if main.componentFocused is Lock else main.focused
	Changes.addChange(Changes.PropertyChange.new(lock,&"count",value,%partialBlastNumeratorEdit))
	Changes.bufferSave()

func _partialBlastDenominatorSet(value:PackedInt64Array) -> void:
	if main.componentFocused is not Lock and main.focused is not RemoteLock: return
	var lock:GameComponent = main.componentFocused if main.componentFocused is Lock else main.focused
	Changes.addChange(Changes.PropertyChange.new(lock,&"denominator",value,%partialBlastDenominatorEdit))
	Changes.bufferSave()

func _isPartialSet(value:bool) -> void:
	if main.componentFocused is not Lock and main.focused is not RemoteLock: return
	var lock:GameComponent = main.componentFocused if main.componentFocused is Lock else main.focused
	Changes.addChange(Changes.PropertyChange.new(lock,&"isPartial",value))
	Changes.bufferSave()

func _blastLockSignSet(value:bool) -> void:
	if main.componentFocused is not Lock and main.focused is not RemoteLock: return
	var lock:GameComponent = main.componentFocused if main.componentFocused is Lock else main.focused
	if M.negative(M.sign(lock.denominator)) == value: return
	Changes.addChange(Changes.PropertyChange.new(lock,&"count",M.negate(lock.count)))
	Changes.addChange(Changes.PropertyChange.new(lock,&"denominator",M.negate(lock.denominator)))
	Changes.bufferSave()

func _blastLockAxisSet(value:bool) -> void:
	if main.componentFocused is not Lock and main.focused is not RemoteLock: return
	var lock:GameComponent = main.componentFocused if main.componentFocused is Lock else main.focused
	if M.isNonzeroImag(lock.denominator) == value: return
	Changes.addChange(Changes.PropertyChange.new(lock,&"count",M.times(lock.count, M.I() if value else M.nI())))
	Changes.addChange(Changes.PropertyChange.new(lock,&"denominator",M.times(lock.denominator, M.I() if value else M.nI())))
	Changes.bufferSave()

func _partialBlastHorizontalSet(value:bool) -> void:
	if main.componentFocused is not Lock and main.focused is not RemoteLock: return
	var lock:GameComponent = main.componentFocused if main.componentFocused is Lock else main.focused
	Changes.addChange(Changes.PropertyChange.new(lock,&"partialBlastHorizontal",value))
	Changes.bufferSave()

func _doorRealInfiniteSet(_toggled:bool) -> void:
	if main.focused is not Door: return
	var value:int = 0
	if %realInfinitePosCopy.button_pressed: value = 1
	elif %realInfiniteNegCopy.button_pressed: value = -1
	Changes.addChange(Changes.PropertyChange.new(main.focused,&"infCopies",M.Ncn(M.N(value), M.ir(main.focused.infCopies))))
	if !value: Changes.addChange(Changes.PropertyChange.new(main.focused,&"copies",M.ONE() if M.isReal(main.focused.copies) else M.i(main.focused.copies)))
	Changes.bufferSave()

func _doorImaginaryInfiniteSet(_toggled:bool) -> void:
	if main.focused is not Door: return
	var value:int = 0
	if %imagInfinitePosCopy.button_pressed: value = 1
	elif %imagInfiniteNegCopy.button_pressed: value = -1
	Changes.addChange(Changes.PropertyChange.new(main.focused,&"infCopies",M.Ncn(M.r(main.focused.infCopies), M.N(value))))
	if !value: Changes.addChange(Changes.PropertyChange.new(main.focused,&"copies",M.ONE() if M.isImag(main.focused.copies) else M.r(main.focused.copies)))
	Changes.bufferSave()

func _lockArmamentSet(value:bool) -> void:
	if main.componentFocused is not Lock and main.focused is not RemoteLock: return
	var lock:GameComponent = main.componentFocused if main.componentFocused is Lock else main.focused
	Changes.addChange(Changes.PropertyChange.new(lock,&"armament",value))
	Changes.bufferSave()

func _remoteLockConvert() -> void:
	main.focus(Editor.convertLock(main.componentFocused))

func _spendArmamentSet(value:bool) -> void:
	if main.focused is not Door: return
	Changes.addChange(Changes.PropertyChange.new(main.focused,&"armament",value))
	Changes.bufferSave()
