extends Selector
class_name ColorSelector

const NONE_COLOR:Texture2D = preload("res://assets/ui/focusDialog/noneColor.png")

var spacers:Array[Control]

func _ready() -> void:
	columns = 8
	options = range(Colors.COLORS)
	defaultValue = C.olors.WHITE
	buttonType = ColorSelectorButton
	super()
	for button in buttons:
		Explainer.addControl(button,QuicksetExplanation.new("[%s+$q]Set "+Colors.getName(button.value).to_lower()+" color", [&"quicksetColor"], ColorQuicksetSetting.matches, button.value))

func onlyConfigurableColors() -> void:
	for color in Colors.DEFINITIONS:
		if !color.toneConfigurable: buttons[color.id].visible = false

func changedMods() -> void:
	var colors:Array[C.olors] = Mods.colors()
	for button in buttons: button.visible = false
	for color in colors: buttons[color].visible = true
	if len(colors) < 15: columns = 7
	else: columns = 8
	
	for spacer in spacers: spacer.queue_free()
	spacers.clear()
	@warning_ignore("integer_division")
	for i in (columns - 1 - (len(colors)-1) % columns)/2:
		var spacer:Control = Control.new()
		spacers.append(spacer)
		add_child(spacer)
		move_child(spacer,0)

	if selected not in colors: buttons[defaultValue].button_pressed = true

class ColorSelectorButton extends SelectorButton:
	var drawMain:RID

	func _init(_value:C.olors, _selector:Selector):
		custom_minimum_size = Vector2(20,20)
		z_index = 1
		super(_value, _selector)
	
	func _ready() -> void:
		drawMain = RenderingServer.canvas_item_create()
		if value == C.olors.GLITCH:
			RenderingServer.canvas_item_set_material(drawMain,Game.GLITCH_MATERIAL.get_rid())
		RenderingServer.canvas_item_set_z_index(drawMain,-1)
		RenderingServer.canvas_item_set_parent(drawMain,get_canvas_item())
		await get_tree().process_frame
		if Colors.getDef(value).doorTextureFrames > 1: Game.connect(&"goldIndexChanged",queue_redraw)
		await get_tree().process_frame
		queue_redraw()
	
	func _draw() -> void:
		RenderingServer.canvas_item_clear(drawMain)
		var rect:Rect2 = Rect2(Vector2.ONE, size-Vector2(2,2))
		if Colors.getDef(value).doorTexture: RenderingServer.canvas_item_add_texture_rect(drawMain,rect,Game.COLOR_TEXTURES.current([value]))
		elif value == C.olors.NONE: RenderingServer.canvas_item_add_texture_rect(drawMain,rect,NONE_COLOR)
		else: RenderingServer.canvas_item_add_rect(drawMain,rect,Game.mainTone[value])
