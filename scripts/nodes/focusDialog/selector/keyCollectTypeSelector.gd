extends Selector
class_name KeyCollectTypeSelector

const ICONS:Array[Texture2D] = [
	preload("res://assets/ui/focusDialog/lockBooleans/weak.png"),
	preload("res://assets/ui/focusDialog/lockBooleans/normal.png"),
	preload("res://assets/ui/focusDialog/lockBooleans/starry.png"),
	preload("res://assets/ui/focusDialog/lockBooleans/forceful.png"),
]

func _ready() -> void:
	columns = KeyBulk.COLLECT_TYPES
	options = range(KeyBulk.COLLECT_TYPES)
	defaultValue = KeyBulk.COLLECT_TYPE.NORMAL
	buttonType = KeyCollectTypeSelectorButton
	super()
	# not sure what that last part does
	for button in buttons:
		var explanation:ControlExplanation
		match button.value:
			KeyBulk.COLLECT_TYPE.NONE: explanation = ControlExplanation.new("[%s]Disable spending", [&"focusKeyCollectTypeNone"])
			KeyBulk.COLLECT_TYPE.NORMAL: explanation = ControlExplanation.new("[%s]Set normal spend mode", [&"focusKeyCollectTypeNormal"])
			KeyBulk.COLLECT_TYPE.STAR: explanation = ControlExplanation.new("[%s]Set star spend mode", [&"focusKeyCollectTypeStar"])
			KeyBulk.COLLECT_TYPE.ALL: explanation = ControlExplanation.new("[%s]Force spending", [&"focusKeyCollectTypeAll"])
		Explainer.addControl(button,explanation)

func setSelect(value:Variant) -> void:
	manuallySetting = true
	buttons[value].button_pressed = true
	manuallySetting = false
	selected = value


class KeyCollectTypeSelectorButton extends SelectorButton:
	var drawMain:RID

	func _init(_value:KeyBulk.COLLECT_TYPE, _selector:KeyCollectTypeSelector):
		custom_minimum_size = Vector2(16,16)
		z_index = 1
		super(_value, _selector)
		icon = ICONS[value]
