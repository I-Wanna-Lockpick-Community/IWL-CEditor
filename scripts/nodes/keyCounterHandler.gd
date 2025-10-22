extends Handler
class_name KeyCounterHandler

var keyCounter:KeyCounter

func setup(_keyCounter:KeyCounter) -> void:
	keyCounter = _keyCounter
	deleteButtons()
	for element in keyCounter.elements:
		var button:KeyCounterHandlerButton = KeyCounterHandlerButton.new(len(buttons), self, element)
		buttons.append(button)
		add_child(button)
	remove_child(add)
	remove_child(remove)
	add_child(add)
	add_child(remove)

func _addElement() -> void:
	var keyCounterElement:KeyCounterElement = editor.changes.addChange(Changes.CreateComponentChange.new(editor.game,KeyCounterElement,{&"position":Vector2(12,12+len(buttons)*40),&"parentId":keyCounter.id})).result
	var button:KeyCounterHandlerButton = KeyCounterHandlerButton.new(len(buttons), self, keyCounterElement)
	addButton(button)
	if len(buttons) == 1: remove.visible = false
	editor.changes.bufferSave()

func _removeElement() -> void:
	editor.changes.addChange(Changes.DeleteComponentChange.new(editor.game,keyCounter.elements[selected]))
	super()
	if len(buttons) == 1: remove.visible = false

func _select(button:Button) -> void:
	super(button)
	if !manuallySetting: editor.focusDialog.focusComponent(keyCounter.elements[selected])

class KeyCounterHandlerButton extends HandlerButton:
	
	var element:KeyCounterElement

	var drawMain:RID
	var drawGlitch:RID

	func _init(_index:int,_selector:KeyCounterHandler, _element:KeyCounterElement) -> void:
		super(_index, _selector)
		element = _element

	func _ready() -> void:
		drawMain = RenderingServer.canvas_item_create()
		drawGlitch = RenderingServer.canvas_item_create()
		RenderingServer.canvas_item_set_material(drawGlitch,Game.UNSCALED_GLITCH_MATERIAL.get_rid())
		RenderingServer.canvas_item_set_parent(drawMain,selector.get_canvas_item())
		RenderingServer.canvas_item_set_parent(drawGlitch,selector.get_canvas_item())
		editor.game.connect(&"goldIndexChanged",queue_redraw)
		connect(&"item_rect_changed",queue_redraw) # control positioning jank
	
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
