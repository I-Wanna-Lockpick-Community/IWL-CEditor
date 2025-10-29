extends Selector
class_name KeyCounterWidthSelector

const ICONS:Array[Texture2D] = [
	preload("res://assets/ui/focusDialog/lockConfiguration/AnyS.png"),
	preload("res://assets/ui/focusDialog/lockConfiguration/AnyM.png"),
	preload("res://assets/ui/focusDialog/lockConfiguration/AnyL.png"),
]

func _ready() -> void:
	columns = 3
	options = range(3)
	defaultValue = 0
	buttonType = KeyCounterWidthSelectorButton
	super()

class KeyCounterWidthSelectorButton extends SelectorButton:
	var drawMain:RID

	func _init(_value:KeyBulk.TYPE, _selector:KeyCounterWidthSelector):
		custom_minimum_size = Vector2(16,16)
		z_index = 1
		super(_value, _selector)
		icon = ICONS[value]
