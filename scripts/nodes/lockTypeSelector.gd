extends Selector
class_name LockTypeSelector

const ICONS:Array[Texture2D] = [
	preload("res://assets/ui/lockType/normal.png"),
	preload("res://assets/ui/lockType/blank.png"),
	preload("res://assets/ui/lockType/blast.png"),
	preload("res://assets/ui/lockType/all.png"),
	preload("res://assets/ui/lockType/exact.png"),
]

func _ready() -> void:
	columns = Lock.TYPES
	options = range(Lock.TYPES)
	defaultValue = KeyBulk.TYPE.NORMAL
	buttonType = LockTypeSelectorButton
	super()

class LockTypeSelectorButton extends SelectorButton:
	var drawMain:RID

	func _init(_value:KeyBulk.TYPE, _selector:LockTypeSelector):
		custom_minimum_size = Vector2(16,16)
		z_index = 1
		super(_value, _selector)
		icon = ICONS[value]
