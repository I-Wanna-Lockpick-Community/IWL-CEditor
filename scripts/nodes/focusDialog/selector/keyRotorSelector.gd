extends Selector
class_name KeyRotorSelector

const VALUES:int = 4
enum VALUE {NOROTATE, SIGNFLIP, POSROTOR, NEGROTOR}

var isInRecMode:bool = false

const ICONS:Array[Texture2D] = [
	preload("res://assets/ui/focusDialog/key/type/rotor/norotate.png"),
	preload("res://assets/ui/focusDialog/key/type/rotor/signflip.png"),
	preload("res://assets/ui/focusDialog/key/type/rotor/positive.png"),
	preload("res://assets/ui/focusDialog/key/type/rotor/negative.png"),
]

func _ready() -> void:
	columns = VALUES
	options = range(VALUES)
	defaultValue = VALUE.SIGNFLIP
	buttonType = KeyRotorSelectorButton
	super()

func setup(key:KeyBulk) -> void:
	buttons[VALUE.NOROTATE].visible = key.reciprocal

func setValue(count:PackedInt64Array) -> void:
	if M.eq(count, M.ONE()): setSelect(VALUE.NOROTATE) # should be unreachable if not in reciprocate mode
	elif M.eq(count, M.nONE()): setSelect(VALUE.SIGNFLIP)
	elif M.eq(count, M.I()): setSelect(VALUE.POSROTOR)
	elif M.eq(count, M.nI()): setSelect(VALUE.NEGROTOR)

class KeyRotorSelectorButton extends SelectorButton:
	func _init(_value:VALUE, _selector:KeyRotorSelector):
		custom_minimum_size = Vector2(16,16)
		z_index = 1
		super(_value, _selector)
		icon = ICONS[value]
