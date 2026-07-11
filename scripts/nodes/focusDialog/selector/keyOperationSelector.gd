extends Selector
class_name keyOperationSelector

const ICONS:Array[Texture2D] = [
	preload("res://assets/ui/focusDialog/key/type/operator/set.png"),
	preload("res://assets/ui/focusDialog/key/type/operator/add.png"),
	preload("res://assets/ui/focusDialog/key/type/operator/subtract.png"),
	preload("res://assets/ui/focusDialog/key/type/operator/multiply.png"),
	preload("res://assets/ui/focusDialog/key/type/operator/divide.png"),
	preload("res://assets/ui/focusDialog/key/type/operator/modulo.png"),
]

func _ready() -> void:
	columns = KeyBulk.OPERATIONS
	options = range(KeyBulk.OPERATIONS)
	defaultValue = KeyBulk.OPERATION.SET
	buttonType = keyOperationSelectorButton
	super()
	for button in buttons:
		var explanation:ControlExplanation
		match button.value:
			KeyBulk.OPERATION.SET: explanation = ControlExplanation.new("[%s]Set set operation", [&"focusKeyOperationSet"])
			KeyBulk.OPERATION.ADD: explanation = ControlExplanation.new("[%s]Set addition operation", [&"focusKeyOperationAdd"])
			KeyBulk.OPERATION.SUBTRACT: explanation = ControlExplanation.new("[%s]Set subtraction operation", [&"focusKeyOperationSubtract"])
			KeyBulk.OPERATION.MULTIPLY: explanation = ControlExplanation.new("[%s]Set multiplication operation", [&"focusKeyOperationMultiply"])
			KeyBulk.OPERATION.DIVIDE: explanation = ControlExplanation.new("[%s]Set division operation", [&"focusKeyOperationDivide"])
			KeyBulk.OPERATION.MODULO: explanation = ControlExplanation.new("[%s]Set modulo operation", [&"focusKeyOperationModulo"])
		Explainer.addControl(button,explanation)

func setSelect(value:Variant) -> void:
	manuallySetting = true
	buttons[value].button_pressed = true
	manuallySetting = false
	selected = value

class keyOperationSelectorButton extends SelectorButton:
	func _init(_value:KeyBulk.OPERATION, _selector:keyOperationSelector):
		custom_minimum_size = Vector2(16,16)
		z_index = 1
		super(_value, _selector)
		icon = ICONS[value]
