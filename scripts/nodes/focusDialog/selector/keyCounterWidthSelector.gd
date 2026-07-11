extends Selector
class_name KeyCounterWidthSelector

const ICONS:Array[Texture2D] = [
	preload("res://assets/ui/focusDialog/door/lockConfiguration/AnyS.png"),
	preload("res://assets/ui/focusDialog/door/lockConfiguration/AnyM.png"),
	preload("res://assets/ui/focusDialog/door/lockConfiguration/AnyL.png"),
	preload("res://assets/ui/focusDialog/door/lockConfiguration/AnyXL.png"),
	preload("res://assets/ui/focusDialog/door/lockConfiguration/AnyXXL.png"),
]

func _ready() -> void:
	columns = 5
	options = range(KeyCounter.WIDTHS)
	defaultValue = KeyCounter.WIDTH.SHORT
	buttonType = KeyCounterWidthSelectorButton
	super()

func changedMods() -> void:
	var widths:Array[KeyCounter.WIDTH] = Mods.keyCounterWidths()
	for button in buttons: button.visible = false
	for width in widths: buttons[width].visible = true
	columns = len(widths)

class KeyCounterWidthSelectorButton extends SelectorButton:
	func _init(_value:KeyCounter.WIDTH, _selector:KeyCounterWidthSelector):
		custom_minimum_size = Vector2(16,16)
		z_index = 1
		super(_value, _selector)
		icon = ICONS[value]
