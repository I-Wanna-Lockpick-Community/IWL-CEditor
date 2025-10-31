extends GridContainer
class_name Selector # configurationSelector is not a selector

@onready var editor:Editor = get_node("/root/editor")

var defaultValue:Variant
var buttonType:Variant = SelectorButton

var options:Array[Variant] = []

var selected:Variant
var buttons:Array[SelectorButton] = []

var manuallySetting:bool = true # dont send signal (hacky)
var buttonGroup:ButtonGroup = ButtonGroup.new()

signal select(value)

func _ready() -> void:
	for value in options:
		var button = buttonType.new(value, self)
		add_child(button)
		buttons.append(button)
	buttonGroup.connect("pressed", _select)
	buttons[defaultValue].button_pressed = true
	selected = defaultValue
	manuallySetting = false

func setSelect(value:Variant) -> void:
	manuallySetting = true
	buttons[value].button_pressed = true
	manuallySetting = false
	selected = value

func _select(button:SelectorButton) -> void:
	if manuallySetting: return
	selected = button.value
	select.emit(button.value)

class SelectorButton extends Button:
	@onready var editor:Editor = get_node("/root/editor")

	var value:Variant
	var selector:Selector

	func _init(_value:Variant, _selector:Selector):
		value = _value
		selector = _selector
		button_group = selector.buttonGroup
		toggle_mode = true
		theme_type_variation = &"SelectorButton"
