extends Handler
class_name KeyCounterHandler

var keyCounter:KeyCounter

func setup(_keyCounter:KeyCounter) -> void:
	keyCounter = _keyCounter
	deleteButtons()
	for index in len(keyCounter.elements):
		var button:KeyCounterHandlerButton = KeyCounterHandlerButton.new(index, self)
		buttons.append(button)
		add_child(button)
	move_child(add, -1)
	move_child(remove, -1)

func addComponent() -> void: keyCounter.addElement()
func removeComponent() -> void: keyCounter.removeElement(selected)

static func buttonType() -> GDScript: return KeyCounterHandlerButton

func addButton(index:int=len(buttons)) -> void:
	super(index)
	if len(buttons) == 1: remove.visible = false

func removeButton(index:int=selected) -> void:
	super(index)
	if len(buttons) == 1: remove.visible = false

func _select(button:Button) -> void:
	super(button)
	if !manuallySetting: editor.focusDialog.focusComponent(keyCounter.elements[selected])

class KeyCounterHandlerButton extends HandlerButton:
	
	var element:KeyCounterElement

	var drawMain:RID
	var drawGlitch:RID

	func _init(_index:int,_selector:KeyCounterHandler) -> void:
		super(_index, _selector)
		element = selector.keyCounter.elements[index]

	func _ready() -> void:
		drawMain = RenderingServer.canvas_item_create()
		drawGlitch = RenderingServer.canvas_item_create()
		RenderingServer.canvas_item_set_material(drawGlitch,Game.UNSCALED_GLITCH_MATERIAL.get_rid())
		RenderingServer.canvas_item_set_parent(drawMain,selector.get_canvas_item())
		RenderingServer.canvas_item_set_parent(drawGlitch,selector.get_canvas_item())
		editor.game.connect(&"goldIndexChanged",queue_redraw)
		await get_tree().process_frame
		await get_tree().process_frame # control positioning jank. figure out some way to fix this
		queue_redraw()
	
	func _draw() -> void:
		RenderingServer.canvas_item_clear(drawMain)
		RenderingServer.canvas_item_clear(drawGlitch)
		if deleted: return
		var rect:Rect2 = Rect2(position+Vector2.ONE, size-Vector2(2,2))
		var texture:Texture2D
		match element.color:
			Game.COLOR.MASTER: texture = editor.game.masterTex()
			Game.COLOR.PURE: texture = editor.game.pureTex()
			Game.COLOR.STONE: texture = editor.game.stoneTex()
			Game.COLOR.DYNAMITE: texture = editor.game.dynamiteTex()
			Game.COLOR.QUICKSILVER: texture = editor.game.quicksilverTex()
		if texture:
			RenderingServer.canvas_item_add_texture_rect(drawMain,rect,texture)
		elif element.color == Game.COLOR.GLITCH:
			RenderingServer.canvas_item_add_rect(drawGlitch,rect,editor.game.mainTone[element.color])
		else:
			RenderingServer.canvas_item_add_rect(drawMain,rect,editor.game.mainTone[element.color])
