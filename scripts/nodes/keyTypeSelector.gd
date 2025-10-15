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
	columns = Game.KEYTYPES
	options = range(Game.KEYTYPES)
	defaultValue = Game.KEY.NORMAL
	buttonType = KeyTypeSelectorButton
	super()

class KeyTypeSelectorButton extends SelectorButton:
	var drawMain:RID

	func _init(_value:Game.KEY, _selector:KeyTypeSelector):
		custom_minimum_size = Vector2(16,16)
		z_index = 1
		super(_value, _selector)
		icon = ICONS[value]
