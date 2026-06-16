extends Selector
class_name LockSpendTypeSelector

const ICONS:Array[Texture2D] = [
	preload("res://assets/ui/focusDialog/lockBooleans/weak.png"),
	preload("res://assets/ui/focusDialog/lockBooleans/normal.png"),
	preload("res://assets/ui/focusDialog/lockBooleans/starry.png"),
	preload("res://assets/ui/focusDialog/lockBooleans/forceful.png"),
]

func _ready() -> void:
	columns = Lock.SPEND_TYPES
	options = range(Lock.SPEND_TYPES)
	defaultValue = Lock.SPEND_TYPE.NORMAL
	buttonType = LockSpendTypeSelectorButton
	super()
	# not sure what that last part does
	#for button in buttons:
		#var explanation:ControlExplanation
		#match button.value:
			#KeyBulk.COLLECT_TYPE.NONE: explanation = ControlExplanation.new("[%s]Disable spending", [&""])
			#KeyBulk.COLLECT_TYPE.NORMAL: explanation = ControlExplanation.new("[%s]Set normal spend mode", [&""])
			#KeyBulk.COLLECT_TYPE.STAR: explanation = ControlExplanation.new("[%s]Set star spend mode", [&""])
			#KeyBulk.COLLECT_TYPE.ALL: explanation = ControlExplanation.new("[%s]Force spending", [&""])
		#Explainer.addControl(button,explanation)

func setSelect(value:Variant) -> void:
	manuallySetting = true
	buttons[value].button_pressed = true
	manuallySetting = false
	selected = value

class LockSpendTypeSelectorButton extends SelectorButton:
	var drawMain:RID

	func _init(_value:Lock.SPEND_TYPE, _selector:LockSpendTypeSelector):
		custom_minimum_size = Vector2(16,16)
		z_index = 1
		super(_value, _selector)
		icon = ICONS[value]
