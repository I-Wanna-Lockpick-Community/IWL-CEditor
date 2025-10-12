extends GridContainer
class_name ColorSelector

signal select(color:Game.COLOR)

@onready var editor:Editor = get_node("/root/editor")

var buttons:Array[ColorSelectorButton] = []
var colorSelected:Game.COLOR = Game.COLOR.WHITE

var manuallySetting:bool = false # dont send signal (hacky)
var buttonGroup:ButtonGroup = ButtonGroup.new()

func _ready() -> void:
	columns = 8
	for color in Game.COLORS:
		var button = ColorSelectorButton.new(color, self)
		add_child(button)
		buttons.append(button)
	buttonGroup.connect("pressed", _select)
	buttons[Game.COLOR.WHITE].button_pressed = true

func _select(button:ColorSelectorButton) -> void:
	if manuallySetting: return
	colorSelected = button.color as Game.COLOR
	select.emit(button.color as Game.COLOR)

func setColor(color:Game.COLOR) -> void:
	manuallySetting = true
	buttons[colorSelected].button_pressed = false
	buttons[colorSelected].updateDraw()
	buttons[color].button_pressed = true
	buttons[color].updateDraw()
	manuallySetting = false
	colorSelected = color

class ColorSelectorButton extends Button:
	@onready var editor:Editor = get_node("/root/editor")

	var color:Game.COLOR
	var colorSelector:ColorSelector
	var drawMain:RID

	func _init(_color:Game.COLOR, _colorSelector:ColorSelector):
		color = _color
		colorSelector = _colorSelector
		button_group = colorSelector.buttonGroup
		custom_minimum_size = Vector2(20,20)
		toggle_mode = true
		theme_type_variation = &"ColorSelectorButton"
		z_index = 1

	func _ready() -> void:
		drawMain = RenderingServer.canvas_item_create()
		if color == Game.COLOR.GLITCH:
			RenderingServer.canvas_item_set_material(drawMain,Game.GLITCH_MATERIAL.get_rid())
			RenderingServer.canvas_item_set_instance_shader_parameter(drawMain,&"scaled",false)
		RenderingServer.canvas_item_set_parent(drawMain,colorSelector.get_canvas_item())
		await get_tree().process_frame
		connect(&"item_rect_changed",updateDraw)
		if Game.isAnimated(color):
			editor.game.connect(&"goldIndexChanged",updateDraw)
	
	func updateDraw():
		RenderingServer.canvas_item_clear(drawMain)
		var rect:Rect2 = Rect2(position+Vector2(1,1), size-Vector2(2,2))
		var texture:Texture2D
		match color:
			Game.COLOR.MASTER: texture = editor.game.masterTex()
			Game.COLOR.PURE: texture = editor.game.pureTex()
			Game.COLOR.STONE: texture = editor.game.stoneTex()
			Game.COLOR.DYNAMITE: texture = editor.game.dynamiteTex()
			Game.COLOR.SILVER: texture = editor.game.silverTex()
		if texture:
			RenderingServer.canvas_item_add_texture_rect(drawMain,rect,texture)
		else:
			RenderingServer.canvas_item_add_rect(drawMain,rect,editor.game.mainTone[color])
