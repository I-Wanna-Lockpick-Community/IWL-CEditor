extends Selector
class_name LockSpendTypeSelector

const ICONS:Array[Texture2D] = [
	preload("res://assets/ui/focusDialog/door/lockBooleans/weak.png"),
	preload("res://assets/ui/focusDialog/door/lockBooleans/normal.png"),
	preload("res://assets/ui/focusDialog/door/lockBooleans/starry.png"),
	preload("res://assets/ui/focusDialog/door/lockBooleans/forceful.png"),
]

func _ready() -> void:
	columns = Lock.SPEND_TYPES
	options = range(Lock.SPEND_TYPES)
	defaultValue = Lock.SPEND_TYPE.NORMAL
	buttonType = LockSpendTypeSelectorButton
	super()
	for button in buttons:
		var explanation:ControlExplanation
		match button.value:
			Lock.SPEND_TYPE.NONE: explanation = ControlExplanation.new("[%s]Disable spending", [&"focusLockSpendTypeNone"])
			Lock.SPEND_TYPE.NORMAL: explanation = ControlExplanation.new("[%s]Set normal spend mode", [&"focusLockSpendTypeNormal"])
			Lock.SPEND_TYPE.STAR: explanation = ControlExplanation.new("[%s]Set star spend mode", [&"focusLockSpendTypeStar"])
			Lock.SPEND_TYPE.ALL: explanation = ControlExplanation.new("[%s]Force spending", [&"focusLockSpendTypeAll"])
		Explainer.addControl(button,explanation)

func setSelect(value:Variant) -> void:
	manuallySetting = true
	buttons[value].button_pressed = true
	manuallySetting = false
	selected = value

class LockSpendTypeSelectorButton extends SelectorButton:
	func _init(_value:Lock.SPEND_TYPE, _selector:LockSpendTypeSelector):
		custom_minimum_size = Vector2(16,16)
		z_index = 1
		super(_value, _selector)
		icon = ICONS[value]
