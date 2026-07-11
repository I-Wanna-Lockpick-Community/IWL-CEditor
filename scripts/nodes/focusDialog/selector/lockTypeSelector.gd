extends Selector
class_name LockTypeSelector

const ICONS:Array[Texture2D] = [
	preload("res://assets/ui/focusDialog/door/lockType/normal.png"),
	preload("res://assets/ui/focusDialog/door/lockType/blank.png"),
	preload("res://assets/ui/focusDialog/door/lockType/blast.png"),
	preload("res://assets/ui/focusDialog/door/lockType/all.png"),
	preload("res://assets/ui/focusDialog/door/lockType/exact.png"),
	preload("res://assets/ui/focusDialog/door/lockType/glistening.png"),
	preload("res://assets/ui/focusDialog/door/lockType/remainder.png"),
]

func _ready() -> void:
	columns = Lock.TYPES
	options = range(Lock.TYPES)
	defaultValue = Lock.TYPE.NORMAL
	buttonType = LockTypeSelectorButton
	super()
	for button in buttons:
		var explanation:ControlExplanation
		match button.value:
			Lock.TYPE.NORMAL: explanation = ControlExplanation.new("[%s]Set normal lock type", [&"focusLockNormal"])
			Lock.TYPE.BLANK: explanation = ControlExplanation.new("[%s]Set blank lock type", [&"focusLockBlank"])
			Lock.TYPE.BLAST: explanation = ControlExplanation.new("[%s]Set blast lock type", [&"focusLockBlast"])
			Lock.TYPE.ALL: explanation = ControlExplanation.new("[%s]Set all lock type", [&"focusLockAll"])
			Lock.TYPE.EXACT: explanation = ControlExplanation.new("[%s]Set exact lock type", [&"focusLockExact"])
			Lock.TYPE.GLISTENING: explanation = ControlExplanation.new("[%s]Set glistening lock type", [&"focusLockGlistening"])
			Lock.TYPE.REMAINDER: explanation = ControlExplanation.new("[%s]Set remainder lock type", [&"focusLockRemainder"])
		Explainer.addControl(button,explanation)

func changedMods() -> void:
	var lockTypes:Array[Lock.TYPE] = Mods.lockTypes()
	for button in buttons: button.visible = false
	for lockType in lockTypes: buttons[lockType].visible = true
	columns = len(lockTypes)

class LockTypeSelectorButton extends SelectorButton:
	func _init(_value:Lock.TYPE, _selector:LockTypeSelector):
		custom_minimum_size = Vector2(16,16)
		z_index = 1
		super(_value, _selector)
		icon = ICONS[value]
