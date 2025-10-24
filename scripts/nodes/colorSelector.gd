extends Selector
class_name ColorSelector

func _ready() -> void:
	columns = 8
	options = range(Game.COLORS)
	defaultValue = Game.COLOR.WHITE
	buttonType = ColorSelectorButton
	add_child(Control.new())
	super()

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
		RenderingServer.canvas_item_set_parent(drawMain,selector.get_canvas_item())
		await get_tree().process_frame
		if Game.isAnimated(value): editor.game.connect(&"goldIndexChanged",queue_redraw)
		await get_tree().process_frame
		queue_redraw()
	
	func _draw() -> void:
		RenderingServer.canvas_item_clear(drawMain)
		var rect:Rect2 = Rect2(position+Vector2.ONE, size-Vector2(2,2))
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
