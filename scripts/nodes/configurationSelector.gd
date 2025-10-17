extends HBoxContainer
class_name ConfigurationSelector
# selector for lock size and configuration; manages lock sizing

const ICONS:Array[Texture2D] = [
	preload("res://assets/ui/lockConfiguration/SpecificA.png"),
	preload("res://assets/ui/lockConfiguration/SpecificB.png"),
	preload("res://assets/ui/lockConfiguration/AnyS.png"),
	preload("res://assets/ui/lockConfiguration/AnyH.png"),
	preload("res://assets/ui/lockConfiguration/AnyV.png"),
	preload("res://assets/ui/lockConfiguration/AnyM.png"),
	preload("res://assets/ui/lockConfiguration/AnyL.png"),
	preload("res://assets/ui/lockConfiguration/AnyXL.png"),
	preload("res://assets/ui/lockConfiguration/ANY.png")
]

const OPTIONS:int = 9
enum OPTION {SpecificA, SpecificB, AnyS, AnyH, AnyV, AnyM, AnyL, AnyXL, ANY }

var manuallySetting:bool = true # dont send signal (hacky)
var buttonGroup:ButtonGroup = ButtonGroup.new()

var selected:int
var buttons:Array[ConfigurationSelectorButton] = []

signal select(option:OPTION)

func _ready() -> void:
	for option in OPTIONS:
		var button = ConfigurationSelectorButton.new(option, self)
		add_child(button)
		buttons.append(button)
		if option == OPTION.SpecificB:
			var separator:VSeparator = VSeparator.new()
			separator.add_theme_constant_override(&"separation", 6)
			add_child(separator)
	buttonGroup.connect("pressed", _select)
	buttons[OPTION.AnyS].button_pressed = true
	selected = OPTION.AnyS
	manuallySetting = false
	buttons[OPTION.ANY].visible = false

func setSelect(option:OPTION) -> void:
	manuallySetting = true
	buttons[selected].button_pressed = false
	buttons[option].button_pressed = true
	manuallySetting = false
	selected = option

func _select(button:ConfigurationSelectorButton) -> void:
	buttons[OPTION.ANY].visible = button.option == OPTION.ANY
	if manuallySetting: return
	selected = button.option
	select.emit(button.option)

class ConfigurationSelectorButton extends Button:
	@onready var editor:Editor = get_node("/root/editor")

	var option:OPTION
	var selector:ConfigurationSelector

	func _init(_option:OPTION, _selector:ConfigurationSelector) -> void:
		option = _option
		selector = _selector
		button_group = selector.buttonGroup
		toggle_mode = true
		theme_type_variation = &"SelectorButton"
		icon = ICONS[option]
