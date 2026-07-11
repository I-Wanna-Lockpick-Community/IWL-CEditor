extends Selector
class_name KeyBoolTypeSelector

const ICONS:Array[Texture2D] = [
	preload("res://assets/ui/focusDialog/key/type/star/star.png"),
	preload("res://assets/ui/focusDialog/key/type/star/unstar.png"),
	preload("res://assets/ui/focusDialog/key/type/rotor/signflip.png"),
]

func _ready() -> void:
	columns = KeyBulk.BOOL_TYPES
	options = range(KeyBulk.BOOL_TYPES)
	defaultValue = KeyBulk.BOOL_TYPE.ENABLE
	buttonType = KeyBoolTypeSelectorButton
	super()
	for button in buttons:
		var explanation:ControlExplanation
		match button.value:
			KeyBulk.BOOL_TYPE.ENABLE: explanation = ControlExplanation.new("[%s]Set enable mode", [&"focusKeyBoolEnable"])
			KeyBulk.BOOL_TYPE.DISABLE: explanation = ControlExplanation.new("[%s]Set disable mode", [&"focusKeyBoolDisable"])
			KeyBulk.BOOL_TYPE.TOGGLE: explanation = ControlExplanation.new("[%s]Set toggle mode", [&"focusKeyBoolToggle"])
		Explainer.addControl(button,explanation)

func setup() -> void:
	buttons[KeyBulk.BOOL_TYPE.TOGGLE].visible = Mods.active(&"Boolflip")

func setSelect(value:Variant) -> void:
	manuallySetting = true
	buttons[value].button_pressed = true
	manuallySetting = false
	selected = value

class KeyBoolTypeSelectorButton extends SelectorButton:
	func _init(_value:KeyBulk.BOOL_TYPE, _selector:KeyBoolTypeSelector):
		custom_minimum_size = Vector2(16,16)
		z_index = 1
		super(_value, _selector)
		icon = ICONS[value]
