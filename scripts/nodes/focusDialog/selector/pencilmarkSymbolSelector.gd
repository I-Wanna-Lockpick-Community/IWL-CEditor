class_name PencilmarkSymbolSelector
extends Selector

const ICONS:Array[Texture2D] = [
	preload("res://assets/game/pencilmark/symbols/0.png"),
	preload("res://assets/game/pencilmark/symbols/1.png"),
	preload("res://assets/game/pencilmark/symbols/2.png"),
	preload("res://assets/game/pencilmark/symbols/3.png"),
	preload("res://assets/game/pencilmark/symbols/4.png"),
	preload("res://assets/game/pencilmark/symbols/5.png"),
]

func _ready() -> void:
	columns = Pencilmark.SYMBOLS
	options = range(Pencilmark.SYMBOLS)
	defaultValue = Pencilmark.SYMBOL.CHECK
	buttonType = PencilmarkSymbolSelectorButton
	super()
	for button in buttons:
		var explanation:ControlExplanation
		match button.value:
			Pencilmark.SYMBOL.CHECK: explanation = ControlExplanation.new("[%s]Set check symbol", [&"focusPencilmarkSymbolCheck"])
			Pencilmark.SYMBOL.CROSS: explanation = ControlExplanation.new("[%s]Set cross symbol", [&"focusPencilmarkSymbolCross"])
			Pencilmark.SYMBOL.CIRCLE: explanation = ControlExplanation.new("[%s]Set circle symbol", [&"focusPencilmarkSymbolCircle"])
			Pencilmark.SYMBOL.SQUARE: explanation = ControlExplanation.new("[%s]Set square symbol", [&"focusPencilmarkSymbolSquare"])
			Pencilmark.SYMBOL.BANG: explanation = ControlExplanation.new("[%s]Set bang symbol", [&"focusPencilmarkSymbolBang"])
			Pencilmark.SYMBOL.INTERRO: explanation = ControlExplanation.new("[%s]Set interro symbol", [&"focusPencilmarkSymbolInterro"])
		Explainer.addControl(button,explanation)

class PencilmarkSymbolSelectorButton extends SelectorButton:
	func _init(_value:Pencilmark.SYMBOL, _selector:PencilmarkSymbolSelector):
		custom_minimum_size = Vector2(24,24)
		z_index = 1
		super(_value, _selector)
		icon = ICONS[value]
