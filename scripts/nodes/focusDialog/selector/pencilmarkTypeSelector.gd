class_name PencilmarkTypeSelector
extends Selector

const ICONS:Array[Texture2D] = [
	preload("res://assets/game/pencilmark/symbol.png"),
	preload("res://assets/game/pencilmark/number.png"),
	preload("res://assets/game/pencilmark/text.png"),
]

func _ready() -> void:
	columns = Pencilmark.TYPES
	options = range(Pencilmark.TYPES)
	defaultValue = Pencilmark.TYPE.SYMBOL
	buttonType = PencilmarkTypeSelectorButton
	super()
	for button in buttons:
		var explanation:ControlExplanation
		match button.value:
			Pencilmark.TYPE.SYMBOL: explanation = ControlExplanation.new("[%s]Set symbol type", [&"focusPencilmarkSymbol"])
			Pencilmark.TYPE.NUMBER: explanation = ControlExplanation.new("[%s]Set number type", [&"focusPencilmarkNumber"])
			Pencilmark.TYPE.TEXT: explanation = ControlExplanation.new("[%s]Set text type", [&"focusPencilmarkText"])
		Explainer.addControl(button,explanation)

class PencilmarkTypeSelectorButton extends SelectorButton:
	func _init(_value:Pencilmark.TYPE, _selector:PencilmarkTypeSelector):
		custom_minimum_size = Vector2(24,24)
		z_index = 1
		super(_value, _selector)
		icon = ICONS[value]
