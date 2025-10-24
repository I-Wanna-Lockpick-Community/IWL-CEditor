extends Selector
class_name GoalTypeSelector

const ICONS:Array[Texture2D] = [
	preload("res://assets/game/goal/normal.png"),
	preload("res://assets/game/goal/omega.png"),
]

func _ready() -> void:
	columns = Goal.TYPES
	options = range(Goal.TYPES)
	defaultValue = Goal.TYPE.NORMAL
	buttonType = GoalTypeSelectorButton
	super()

class GoalTypeSelectorButton extends SelectorButton:
	var drawMain:RID

	func _init(_value:KeyBulk.TYPE, _selector:GoalTypeSelector):
		custom_minimum_size = Vector2(16,16)
		z_index = 1
		super(_value, _selector)
		icon = ICONS[value]
