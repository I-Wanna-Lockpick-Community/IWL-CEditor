extends Selector
class_name KeyBoolSelector

const ICONS:Array[Texture2D] = [
	preload("res://assets/ui/focusDialog/keySplitType/star.png"),
	preload("res://assets/ui/focusDialog/keySplitType/unstar.png"),
	preload("res://assets/ui/focusDialog/keySplitType/signflip.png"),
]

func _ready() -> void:
	columns = KeyBulk.BOOL_TYPES
	options = range(KeyBulk.BOOL_TYPES)
	defaultValue = KeyBulk.BOOL_TYPE.ENABLE
	buttonType = KeyBoolSelectorButton
	super()
	# not sure what that last part does
	#for button in buttons:
		#var explanation:ControlExplanation
		#match button.value:
			#KeyBulk.BOOL_TYPE.ENABLE: explanation = ControlExplanation.new("[%s]Set enable mode", [&"focusKeyOperationSet"])
			#KeyBulk.BOOL_TYPE.DISABLE: explanation = ControlExplanation.new("[%s]Set disable mode", [&"focusKeyOperationAdd"])
			#KeyBulk.BOOL_TYPE.TOGGLE: explanation = ControlExplanation.new("[%s]Set toggle mode", [&"focusKeyOperationSubtract"])
		#Explainer.addControl(button,explanation)

func setup() -> void:
	buttons[KeyBulk.BOOL_TYPE.TOGGLE].visible = Mods.active(&"Boolflip")

func setSelect(value:Variant) -> void:
	manuallySetting = true
	buttons[value].button_pressed = true
	manuallySetting = false
	selected = value

class KeyBoolSelectorButton extends SelectorButton:
	var drawMain:RID

	func _init(_value:KeyBulk.BOOL_TYPE, _selector:KeyBoolSelector):
		custom_minimum_size = Vector2(16,16)
		z_index = 1
		super(_value, _selector)
		icon = ICONS[value]
