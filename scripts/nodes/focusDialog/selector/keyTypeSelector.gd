extends Selector
class_name KeyTypeSelector

const ICONS:Array[Texture2D] = [
	preload("res://assets/ui/focusDialog/key/type/normal.png"),
	preload("res://assets/ui/focusDialog/key/type/exact.png"),
	preload("res://assets/ui/focusDialog/key/type/star.png"),
	preload("res://assets/ui/focusDialog/key/type/rotor.png"),
	preload("res://assets/ui/focusDialog/key/type/curse.png"),
	preload("res://assets/ui/focusDialog/key/type/operator.png"),
]

func _ready() -> void:
	columns = KeyBulk.TYPES
	options = range(KeyBulk.TYPES)
	defaultValue = KeyBulk.TYPE.NORMAL
	buttonType = KeyTypeSelectorButton
	super()
	for button in buttons:
		var explanation:ControlExplanation
		match button.value:
			KeyBulk.TYPE.NORMAL: explanation = ControlExplanation.new("[%s]Set normal key type", [&"focusKeyNormal"])
			KeyBulk.TYPE.EXACT: explanation = ControlExplanation.new("[%s]Set exact key type", [&"focusKeyExact"])
			KeyBulk.TYPE.STAR: explanation = ControlExplanation.new("[%s]Toggle star key type", [&"focusKeyStar"])
			KeyBulk.TYPE.ROTOR: explanation = ControlExplanation.new("[%s]Advance rotor key type", [&"focusKeyRotor"])
			KeyBulk.TYPE.CURSE: explanation = ControlExplanation.new("[%s]Toggle curse key type", [&"focusKeyCurse"])
			KeyBulk.TYPE.OPERATOR: explanation = ControlExplanation.new("[%s]Toggle operation key type", [&"focusKeyOperator"])
		Explainer.addControl(button,explanation)

func changedMods() -> void:
	var keyTypes:Array[KeyBulk.TYPE] = Mods.keyTypes()
	for button in buttons: button.visible = false
	for keyType in keyTypes: buttons[keyType].visible = true
	columns = len(keyTypes)

class KeyTypeSelectorButton extends SelectorButton:
	func _init(_value:KeyBulk.TYPE, _selector:KeyTypeSelector):
		custom_minimum_size = Vector2(16,16)
		z_index = 1
		super(_value, _selector)
		icon = ICONS[value]
