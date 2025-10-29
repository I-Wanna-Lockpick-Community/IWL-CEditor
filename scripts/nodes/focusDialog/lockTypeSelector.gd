extends Selector
class_name LockTypeSelector

const ICONS:Array[Texture2D] = [
	preload("res://assets/ui/focusDialog/lockType/normal.png"),
	preload("res://assets/ui/focusDialog/lockType/blank.png"),
	preload("res://assets/ui/focusDialog/lockType/blast.png"),
	preload("res://assets/ui/focusDialog/lockType/all.png"),
	preload("res://assets/ui/focusDialog/lockType/exact.png"),
]

func _ready() -> void:
	columns = Lock.TYPES
	options = range(Lock.TYPES)
	defaultValue = KeyBulk.TYPE.NORMAL
	buttonType = LockTypeSelectorButton
	super()

func changedMods() -> void:
	var lockTypes:Array[Lock.TYPE] = mods.lockTypes()
	for button in buttons: button.visible = false
	for lockType in lockTypes: buttons[lockType].visible = true
	columns = len(lockTypes)

class LockTypeSelectorButton extends SelectorButton:
	var drawMain:RID

	func _init(_value:KeyBulk.TYPE, _selector:LockTypeSelector):
		custom_minimum_size = Vector2(16,16)
		z_index = 1
		super(_value, _selector)
		icon = ICONS[value]
