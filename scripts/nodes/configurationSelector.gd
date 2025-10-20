extends HBoxContainer
class_name ConfigurationSelector
# selector for lock size and configuration; manages lock sizing

const SPECIFIC_A:Texture2D = preload("res://assets/ui/focusDialog/lockConfiguration/SpecificA.png")
const SPECIFIC_B:Texture2D = preload("res://assets/ui/focusDialog/lockConfiguration/SpecificB.png")
const SPECIFIC_H:Texture2D = preload("res://assets/ui/focusDialog/lockConfiguration/SpecificH.png")
const SPECIFIC_V:Texture2D = preload("res://assets/ui/focusDialog/lockConfiguration/SpecificV.png")

const ICONS:Array[Texture2D] = [
	SPECIFIC_A,
	SPECIFIC_B,
	preload("res://assets/ui/focusDialog/lockConfiguration/AnyS.png"),
	preload("res://assets/ui/focusDialog/lockConfiguration/AnyH.png"),
	preload("res://assets/ui/focusDialog/lockConfiguration/AnyV.png"),
	preload("res://assets/ui/focusDialog/lockConfiguration/AnyM.png"),
	preload("res://assets/ui/focusDialog/lockConfiguration/AnyL.png"),
	preload("res://assets/ui/focusDialog/lockConfiguration/AnyXL.png"),
	preload("res://assets/ui/focusDialog/lockConfiguration/ANY.png")
]

const OPTIONS:int = 9
enum OPTION {SpecificA, SpecificB, AnyS, AnyH, AnyV, AnyM, AnyL, AnyXL, ANY }

var manuallySetting:bool = false # dont send signal (hacky)
var buttonGroup:ButtonGroup = ButtonGroup.new()

var selected:int
var buttons:Array[ConfigurationSelectorButton] = []
var separator:VSeparator = VSeparator.new()

signal select(option:OPTION)

func _ready() -> void:
	separator.add_theme_constant_override(&"separation", 6)
	for option in OPTIONS:
		var button = ConfigurationSelectorButton.new(option, self)
		add_child(button)
		buttons.append(button)
		if option == OPTION.SpecificB:
			add_child(separator)
	buttonGroup.connect("pressed", _select)

func setSelect(option:OPTION) -> void:
	manuallySetting = true
	buttons[option].button_pressed = true
	manuallySetting = false
	selected = option

func _select(button:ConfigurationSelectorButton) -> void:
	buttons[OPTION.ANY].visible = button.option == OPTION.ANY
	selected = button.option
	if !manuallySetting: select.emit(button.option)

func setup(lock:Lock) -> void:
	var specificAAvailable:bool = false
	var specificBAvailable:bool = false
	for configuration in lock.getAvailableConfigurations():
		match configuration[1]:
			Lock.CONFIGURATION.spr1A, Lock.CONFIGURATION.spr4A, Lock.CONFIGURATION.spr5A, Lock.CONFIGURATION.spr6A, Lock.CONFIGURATION.spr8A, Lock.CONFIGURATION.spr12A, Lock.CONFIGURATION.spr24A:
				buttons[OPTION.SpecificA].icon = SPECIFIC_A
				specificAAvailable = true
				if configuration[1] == lock.configuration: setSelect(OPTION.SpecificA)
			Lock.CONFIGURATION.spr4B, Lock.CONFIGURATION.spr5B, Lock.CONFIGURATION.spr6B:
				buttons[OPTION.SpecificB].icon = SPECIFIC_B
				specificBAvailable = true
				if configuration[1] == lock.configuration: setSelect(OPTION.SpecificB)
			Lock.CONFIGURATION.spr2H, Lock.CONFIGURATION.spr3H:
				buttons[OPTION.SpecificA].icon = SPECIFIC_H
				specificAAvailable = true
				if configuration[1] == lock.configuration: setSelect(OPTION.SpecificA)
			Lock.CONFIGURATION.spr2V, Lock.CONFIGURATION.spr3V:
				buttons[OPTION.SpecificB].icon = SPECIFIC_V
				specificBAvailable = true
				if configuration[1] == lock.configuration: setSelect(OPTION.SpecificB)
	separator.visible = specificAAvailable or specificBAvailable
	buttons[OPTION.SpecificA].visible = specificAAvailable
	buttons[OPTION.SpecificB].visible = specificBAvailable
	if lock.configuration == Lock.CONFIGURATION.NONE:
		match lock.sizeType:
			Lock.SIZE_TYPE.AnyS: setSelect(OPTION.AnyS)
			Lock.SIZE_TYPE.AnyH: setSelect(OPTION.AnyH)
			Lock.SIZE_TYPE.AnyV: setSelect(OPTION.AnyV)
			Lock.SIZE_TYPE.AnyM: setSelect(OPTION.AnyM)
			Lock.SIZE_TYPE.AnyL: setSelect(OPTION.AnyL)
			Lock.SIZE_TYPE.AnyXL: setSelect(OPTION.AnyXL)
			Lock.SIZE_TYPE.ANY: setSelect(OPTION.ANY)

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
