extends Selector
class_name KeyTypeSelector

const ICONS:Array[Texture2D] = [
	preload("res://assets/ui/focusDialog/keyType/normal.png"),
	preload("res://assets/ui/focusDialog/keyType/exact.png"),
	preload("res://assets/ui/focusDialog/keyType/star.png"),
	preload("res://assets/ui/focusDialog/keyType/unstar.png"),
	preload("res://assets/ui/focusDialog/keyType/signflip.png"),
	preload("res://assets/ui/focusDialog/keyType/posrotor.png"),
	preload("res://assets/ui/focusDialog/keyType/negrotor.png"),
	preload("res://assets/ui/focusDialog/keyType/curse.png"),
	preload("res://assets/ui/focusDialog/keyType/uncurse.png"),
]

func _ready() -> void:
	columns = KeyBulk.TYPES
	options = range(KeyBulk.TYPES)
	defaultValue = KeyBulk.TYPE.NORMAL
	buttonType = KeyTypeSelectorButton
	super()

class KeyTypeSelectorButton extends SelectorButton:
	var drawMain:RID

	func _init(_value:KeyBulk.TYPE, _selector:KeyTypeSelector):
		custom_minimum_size = Vector2(16,16)
		z_index = 1
		super(_value, _selector)
		icon = ICONS[value]
