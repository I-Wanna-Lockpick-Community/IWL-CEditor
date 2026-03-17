extends Control
class_name KeyDialog

@onready var main:FocusDialog = get_parent()

const STAR_UN_ICONS:Array[Texture2D] = [ preload("res://assets/ui/focusDialog/keySplitType/star.png"), preload("res://assets/ui/focusDialog/keySplitType/unstar.png") ]
const CURSE_UN_ICONS:Array[Texture2D] = [ preload("res://assets/ui/focusDialog/keySplitType/curse.png"), preload("res://assets/ui/focusDialog/keySplitType/uncurse.png") ]

func focus(focused:KeyBulk, new:bool, _dontRedirect:bool) -> void:
	%keyColorSelector.setSelect(focused.color)
	%keyAltColorSelector.setSelect(focused.altColor)
	%keyAltColorSelector.visible = focused.type == KeyBulk.TYPE.OPERATOR
	%keyTypeSelector.setSelect(focused.type)
	%keyCountEdit.visible = focused.type in [KeyBulk.TYPE.NORMAL,KeyBulk.TYPE.EXACT]
	if new: %keyCountEdit.setValue(focused.count)
	%keyInfiniteToggle.button_pressed = focused.infinite
	%keyGlisteningToggle.button_pressed = focused.glistening
	%keyPartialInfinite.visible = Mods.active(&"PartialInfKeys") and focused.infinite
	if new: %keyPartialInfiniteEdit.setValue(M.N(focused.infinite))
	%keyOperationSelector.visible = focused.type == KeyBulk.TYPE.OPERATOR
	%keyOperationSelector.setSelect(focused.operation)
	%keyRotorSelector.visible = focused.type == KeyBulk.TYPE.ROTOR
	%keyUn.visible = focused.type in [KeyBulk.TYPE.STAR, KeyBulk.TYPE.CURSE]
	%keyUn.button_pressed = !focused.un
	%keyRotorSelector.setup(focused)
	%keyReciprocal.visible = focused.type == KeyBulk.TYPE.ROTOR && Mods.active(&"OperatorKeys")
	setKeyUnIcon()
	if focused.type == KeyBulk.TYPE.ROTOR: %keyRotorSelector.setValue(focused.count)
	if main.interacted and !main.interacted.is_visible_in_tree(): main.deinteract()
	if %keyCountEdit.visible:
		if !main.interacted: main.interact(%keyCountEdit)
	else: main.deinteract()

func receiveKey(event:InputEventKey) -> bool:
	if main.focused.type == KeyBulk.TYPE.OPERATOR:
		var matched:bool = true
		if Editor.eventIs(event, &"focusKeyOperationSet"): _keyOperationSelected(KeyBulk.OPERATION.SET)
		elif Editor.eventIs(event, &"focusKeyOperationAdd"): _keyOperationSelected(KeyBulk.OPERATION.ADD)
		elif Editor.eventIs(event, &"focusKeyOperationSubtract"): _keyOperationSelected(KeyBulk.OPERATION.SUBTRACT)
		elif Editor.eventIs(event, &"focusKeyOperationMultiply"): _keyOperationSelected(KeyBulk.OPERATION.MULTIPLY)
		elif Editor.eventIs(event, &"focusKeyOperationDivide"): _keyOperationSelected(KeyBulk.OPERATION.DIVIDE)
		elif Editor.eventIs(event, &"focusKeyOperationModulo"): _keyOperationSelected(KeyBulk.OPERATION.MODULO)
		else: matched = false
		if matched: return true
	if Editor.eventIs(event, &"focusKeyNormal"): _keyTypeSelected(KeyBulk.TYPE.NORMAL)
	elif Editor.eventIs(event, &"focusKeyExact"): _keyTypeSelected(KeyBulk.TYPE.EXACT if main.focused.type != KeyBulk.TYPE.EXACT else KeyBulk.TYPE.NORMAL)
	elif Editor.eventIs(event, &"focusKeyStar"):
		if main.focused.type == KeyBulk.TYPE.STAR: Changes.PropertyChange.new(main.focused,&"un",!main.focused.un)
		else: _keyTypeSelected(KeyBulk.TYPE.STAR)
	elif Editor.eventIs(event, &"focusKeyRotor"):
		if main.focused.type != KeyBulk.TYPE.ROTOR: _keyTypeSelected(KeyBulk.TYPE.ROTOR)
		elif M.eq(main.focused.count, M.nONE): _keyCountSet(M.I)
		elif M.eq(main.focused.count, M.I): _keyCountSet(M.nI)
		elif M.eq(main.focused.count, M.nI): _keyTypeSelected(KeyBulk.TYPE.NORMAL); _keyCountSet(M.ONE)
	elif Editor.eventIs(event, &"focusKeyCurse") and Mods.active(&"CurseKeys"):
			if main.focused.type == KeyBulk.TYPE.CURSE: Changes.PropertyChange.new(main.focused,&"un",!main.focused.un)
			else: _keyTypeSelected(KeyBulk.TYPE.CURSE)
	elif Editor.eventIs(event, &"focusKeyOperator"): _keyTypeSelected(KeyBulk.TYPE.OPERATOR if main.focused.type != KeyBulk.TYPE.OPERATOR else KeyBulk.TYPE.NORMAL)
	elif Editor.eventIs(event, &"focusKeyInfinite"): _keyInfiniteToggled(0 if main.focused.infinite else 1)
	elif Editor.eventIs(event, &"focusKeyGlistening"): _keyGlisteningToggled(!main.focused.glistening)
	elif Editor.eventIs(event, &"quicksetColor"): Game.editor.quickSet.startQuick(&"quicksetColor", main.focused)
	else: return false
	return true

func changedMods() -> void:
	%keyGlisteningToggle.visible = Mods.active(&"Glistening")
	if main.focused is KeyBulk:
		%keyPartialInfinite.visible = Mods.active(&"PartialInfKeys") and main.focused.infinite
		%keyReciprocal.visible = main.focused.type == KeyBulk.TYPE.ROTOR && Mods.active(&"OperatorKeys")

func _keyColorSelected(color:Game.COLOR) -> void:
	if main.focused is not KeyBulk: return
	Changes.addChange(Changes.PropertyChange.new(main.focused,&"color",color))
	Changes.bufferSave()

func _keyAltColorSelected(color:Game.COLOR) -> void:
	if main.focused is not KeyBulk: return
	Changes.addChange(Changes.PropertyChange.new(main.focused,&"altColor",color))
	Changes.bufferSave()

func _keyTypeSelected(type:KeyBulk.TYPE) -> void:
	if main.focused is not KeyBulk: return
	var beforeType:KeyBulk.TYPE = main.focused.type
	Changes.addChange(Changes.PropertyChange.new(main.focused,&"type",type))
	if beforeType != type and type == KeyBulk.TYPE.ROTOR: Changes.PropertyChange.new(main.focused,&"count",M.nONE)
	Changes.bufferSave()

func _keyOperationSelected(operation:KeyBulk.OPERATION) -> void:
	if main.focused is not KeyBulk: return
	Changes.addChange(Changes.PropertyChange.new(main.focused,&"operation",operation))
	Changes.bufferSave()

func _keyCountSet(value:PackedInt64Array) -> void:
	if main.focused is not KeyBulk: return
	Changes.addChange(Changes.PropertyChange.new(main.focused,&"count",value))
	Changes.bufferSave()

func _keyInfiniteToggled(value:bool) -> void:
	if main.focused is not KeyBulk: return
	if value == !main.focused.infinite:
		Changes.addChange(Changes.PropertyChange.new(main.focused,&"infinite",int(value)))
		if value: %keyPartialInfiniteEdit.setValue(M.N(int(value)))
		Changes.bufferSave()

func _keyGlisteningToggled(value:bool) -> void:
	if main.focused is not KeyBulk: return
	if value == !main.focused.glistening:
		Changes.addChange(Changes.PropertyChange.new(main.focused,&"glistening",value))
		Changes.bufferSave()

func _keyRotorSelected(value:KeyRotorSelector.VALUE):
	if main.focused is not KeyBulk: return
	match value:
		KeyRotorSelector.VALUE.NOROTATE: Changes.addChange(Changes.PropertyChange.new(main.focused,&"count",M.ONE))
		KeyRotorSelector.VALUE.SIGNFLIP: Changes.addChange(Changes.PropertyChange.new(main.focused,&"count",M.nONE))
		KeyRotorSelector.VALUE.POSROTOR: Changes.addChange(Changes.PropertyChange.new(main.focused,&"count",M.I))
		KeyRotorSelector.VALUE.NEGROTOR: Changes.addChange(Changes.PropertyChange.new(main.focused,&"count",M.nI))
	Changes.bufferSave()

func _keyUnToggled(value:bool) -> void:
	if main.focused is not KeyBulk: return
	Changes.addChange(Changes.PropertyChange.new(main.focused,&"un",!value))
	Changes.bufferSave()
	setKeyUnIcon()

func setKeyUnIcon() -> void:
	match main.focused.type:
		KeyBulk.TYPE.STAR: %keyUn.icon = STAR_UN_ICONS[int(main.focused.un)]
		KeyBulk.TYPE.CURSE: %keyUn.icon = CURSE_UN_ICONS[int(main.focused.un)]

func _keyPartialInfiniteSet(value:PackedInt64Array) -> void:
	if main.focused is not KeyBulk: return
	Changes.addChange(Changes.PropertyChange.new(main.focused,&"infinite",M.toInt(value)))
	Changes.bufferSave()

func _keyReciprocalToggled(value:bool) -> void:
	if main.focused is not KeyBulk: return
	Changes.addChange(Changes.PropertyChange.new(main.focused,&"reciprocal",value))
	Changes.bufferSave()
