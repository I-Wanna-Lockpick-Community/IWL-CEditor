extends Selector
class_name ColorSelector

var spacers:Array[Control]

func _ready() -> void:
	columns = 8
	options = range(Game.COLORS)
	defaultValue = Game.COLOR.WHITE
	buttonType = ColorSelectorButton
	super()

func changedMods() -> void:
	var colors:Array[Game.COLOR] = mods.colors()
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

class ColorSelectorButton extends SelectorButton:
	var drawMain:RID

	func _init(_value:Game.COLOR, _selector:ColorSelector):
		custom_minimum_size = Vector2(20,20)
		z_index = 1
		super(_value, _selector)
	
	func _ready() -> void:
		drawMain = RenderingServer.canvas_item_create()
		if value == Game.COLOR.GLITCH:
			RenderingServer.canvas_item_set_material(drawMain,Game.UNSCALED_GLITCH_MATERIAL.get_rid())
		RenderingServer.canvas_item_set_z_index(drawMain,-1)
		RenderingServer.canvas_item_set_parent(drawMain,get_canvas_item())
		await get_tree().process_frame
		if Game.isAnimated(value): editor.game.connect(&"goldIndexChanged",queue_redraw)
		await get_tree().process_frame
		queue_redraw()
	
	func _draw() -> void:
		RenderingServer.canvas_item_clear(drawMain)
		var rect:Rect2 = Rect2(Vector2.ONE, size-Vector2(2,2))
		var texture:Texture2D
		match value:
			Game.COLOR.MASTER: texture = editor.game.masterTex()
			Game.COLOR.PURE: texture = editor.game.pureTex()
			Game.COLOR.STONE: texture = editor.game.stoneTex()
			Game.COLOR.DYNAMITE: texture = editor.game.dynamiteTex()
			Game.COLOR.QUICKSILVER: texture = editor.game.quicksilverTex()
		if texture:
			RenderingServer.canvas_item_add_texture_rect(drawMain,rect,texture)
		else:
			RenderingServer.canvas_item_add_rect(drawMain,rect,editor.game.mainTone[value])
