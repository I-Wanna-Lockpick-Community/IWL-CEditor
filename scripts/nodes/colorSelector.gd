extends GridContainer
class_name ColorSelector

signal select(color:Game.COLOR)

@onready var game:Game = get_node("/root/editor").game

var colorSelected:Game.COLOR = Game.COLOR.WHITE

func _ready():
	columns = 8
	var buttonGroup:ButtonGroup = ButtonGroup.new()
	var iter:int = 0
	for color in Game.COLOR:
		var button = ColorSelectorButton.new()
		button.text = color
		button.toggle_mode = true
		button.button_group = buttonGroup
		button.index = iter
		add_child(button)
		iter += 1
	buttonGroup.connect("pressed", _select)
	get_child(1).button_pressed = true

func _select(button:ColorSelectorButton):
	colorSelected = button.index as Game.COLOR
	select.emit(button.index as Game.COLOR)

func setColor(color:Game.COLOR):
	get_child(colorSelected).button_pressed = false
	get_child(color).button_pressed = true
	colorSelected = color

class ColorSelectorButton extends Button:
	var index:int
