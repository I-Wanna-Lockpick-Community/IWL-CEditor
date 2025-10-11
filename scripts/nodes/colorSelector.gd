extends GridContainer
class_name ColorSelector

signal select(color:Game.COLOR)

@onready var editor:Editor = get_node("/root/editor")

var glitchDrawer:GlitchDrawer.DrawRect = GlitchDrawer.DrawRect.new()
var buttons:Array[ColorSelectorButton] = []
var colorSelected:Game.COLOR = Game.COLOR.WHITE

var manuallySetting:bool = false # dont send signal (hacky)

func _ready() -> void:
	columns = 8
	var buttonGroup:ButtonGroup = ButtonGroup.new()
	add_child(glitchDrawer)
	for color in Game.COLORS:
		var button = ColorSelectorButton.new()
		button.custom_minimum_size = Vector2(20,20)
		button.toggle_mode = true
		button.button_group = buttonGroup
		button.color = color
		button.theme_type_variation = &"ColorSelectorButton"
		add_child(button)
		buttons.append(button)
	buttonGroup.connect("pressed", _select)
	buttons[Game.COLOR.WHITE].button_pressed = true

func _process(_delta) -> void:
	queue_redraw()

func _select(button:ColorSelectorButton) -> void:
	if manuallySetting: return
	colorSelected = button.color as Game.COLOR
	select.emit(button.color as Game.COLOR)

func setColor(color:Game.COLOR) -> void:
	manuallySetting = true
	buttons[colorSelected].button_pressed = false
	buttons[color].button_pressed = true
	manuallySetting = false
	colorSelected = color

func _draw() -> void:
	for button:ColorSelectorButton in buttons:
		var rect:Rect2 = Rect2(button.position+Vector2(1,1),button.size-Vector2(2,2))
		match button.color:
			Game.COLOR.MASTER: draw_texture_rect(editor.game.masterTex(),rect,false)
			Game.COLOR.PURE: draw_texture_rect(editor.game.pureTex(),rect,false)
			Game.COLOR.STONE: draw_texture_rect(editor.game.stoneTex(),rect,false)
			Game.COLOR.DYNAMITE: draw_texture_rect(editor.game.dynamiteTex(),rect,false)
			Game.COLOR.SILVER: draw_texture_rect(editor.game.silverTex(),rect,false)
			Game.COLOR.GLITCH: glitchDrawer.draw(rect)
			_: draw_rect(rect, editor.game.mainTone[button.color])

class ColorSelectorButton extends Button:
	var color:Game.COLOR
