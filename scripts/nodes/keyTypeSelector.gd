extends Selector
class_name KeyTypeSelector

const ICONS:Array[Texture2D] = [
	preload("res://assets/ui/keyType/normal.png"),
	preload("res://assets/ui/keyType/exact.png"),
	preload("res://assets/ui/keyType/star.png"),
	preload("res://assets/ui/keyType/unstar.png"),
	preload("res://assets/ui/keyType/signflip.png"),
	preload("res://assets/ui/keyType/posrotor.png"),
	preload("res://assets/ui/keyType/negrotor.png"),
	preload("res://assets/ui/keyType/curse.png"),
	preload("res://assets/ui/keyType/uncurse.png"),
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
