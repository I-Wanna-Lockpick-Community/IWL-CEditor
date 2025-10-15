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
	columns = Game.LOCKTYPES
	options = range(Game.LOCKTYPES)
	defaultValue = Game.KEY.NORMAL
	buttonType = LockTypeSelectorButton
	super()

class LockTypeSelectorButton extends SelectorButton:
	var drawMain:RID

	func _init(_value:Game.KEY, _selector:LockTypeSelector):
		custom_minimum_size = Vector2(16,16)
		z_index = 1
		super(_value, _selector)
		icon = ICONS[value]
