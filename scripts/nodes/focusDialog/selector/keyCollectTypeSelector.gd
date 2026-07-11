extends Selector
class_name KeyCollectTypeSelector

const ICONS:Array[Texture2D] = [
	preload("res://assets/ui/focusDialog/door/lockBooleans/weak.png"),
	preload("res://assets/ui/focusDialog/door/lockBooleans/normal.png"),
	preload("res://assets/ui/focusDialog/door/lockBooleans/starry.png"),
	preload("res://assets/ui/focusDialog/door/lockBooleans/forceful.png"),
]

func _ready() -> void:
	columns = Player.KEYCHANGE_TYPES
	options = range(Player.KEYCHANGE_TYPES)
	defaultValue = Player.KEYCHANGE_TYPE.NORMAL
	buttonType = KeyCollectTypeSelectorButton
	super()
	# not sure what that last part does
	for button in buttons:
		var explanation:ControlExplanation
		match button.value:
			Player.KEYCHANGE_TYPE.NONE: explanation = ControlExplanation.new("[%s]Disable spending", [&"focusKeyCollectTypeNone"])
			Player.KEYCHANGE_TYPE.NORMAL: explanation = ControlExplanation.new("[%s]Set normal spend mode", [&"focusKeyCollectTypeNormal"])
			Player.KEYCHANGE_TYPE.STAR: explanation = ControlExplanation.new("[%s]Set star spend mode", [&"focusKeyCollectTypeStar"])
			Player.KEYCHANGE_TYPE.ALL: explanation = ControlExplanation.new("[%s]Force spending", [&"focusKeyCollectTypeAll"])
		Explainer.addControl(button,explanation)

func setSelect(value:Variant) -> void:
	manuallySetting = true
	buttons[value].button_pressed = true
	manuallySetting = false
	selected = value


class KeyCollectTypeSelectorButton extends SelectorButton:
	func _init(_value:Player.KEYCHANGE_TYPE, _selector:KeyCollectTypeSelector):
		custom_minimum_size = Vector2(16,16)
		z_index = 1
		super(_value, _selector)
		icon = ICONS[value]
