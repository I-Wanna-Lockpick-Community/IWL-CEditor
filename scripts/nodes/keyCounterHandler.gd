extends Handler
class_name KeyCounterHandler

var keyCounter:KeyCounter

func setup(_keyCounter:KeyCounter) -> void:
	keyCounter = _keyCounter
	deleteButtons()
	for color in keyCounter.color:
		var button:KeyCounterHandlerButton = KeyCounterHandlerButton.new(len(buttons), self, color)
		buttons.append(button)
		add_child(button)
	remove_child(add)
	remove_child(remove)
	add_child(add)
	add_child(remove)

func _addElement() -> void:
	var button:KeyCounterHandlerButton = KeyCounterHandlerButton.new(len(buttons), self, Game.COLOR.WHITE)
	addButton(button)

func _removeElement() -> void:
	super()

class KeyCounterHandlerButton extends HandlerButton:
	
	var color:Game.COLOR

	var drawMain:RID

	func _init(_index:int,_selector:KeyCounterHandler, _color:Game.COLOR) -> void:
		super(_index, _selector)
		color = _color

	func _ready() -> void:
		drawMain = RenderingServer.canvas_item_create()
		RenderingServer.canvas_item_set_parent(drawMain,selector.get_canvas_item())
		editor.game.connect(&"goldIndexChanged",queue_redraw)
		connect(&"item_rect_changed",queue_redraw) # control positioning jank
	
	func _draw() -> void:
		RenderingServer.canvas_item_clear(drawMain)
		if deleted: return
		var rect:Rect2 = Rect2(position+Vector2.ONE, size-Vector2(2,2))
		var texture:Texture2D
		match color:
			Game.COLOR.MASTER: texture = editor.game.masterTex()
			Game.COLOR.PURE: texture = editor.game.pureTex()
			Game.COLOR.STONE: texture = editor.game.stoneTex()
			Game.COLOR.DYNAMITE: texture = editor.game.dynamiteTex()
			Game.COLOR.QUICKSILVER: texture = editor.game.quicksilverTex()
		if texture:
			RenderingServer.canvas_item_add_texture_rect(drawMain,rect,texture)
		else:
			RenderingServer.canvas_item_add_rect(drawMain,rect,editor.game.mainTone[color])
