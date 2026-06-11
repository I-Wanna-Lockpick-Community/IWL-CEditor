extends Handler
class_name DoorsHandler
# for remote lock

var remoteLock:RemoteLock

func setup(_remoteLock:RemoteLock) -> void:
	selected = -1
	remoteLock = _remoteLock
	deleteButtons()
	for index in len(remoteLock.doors):
		var button:DoorsHandlerButton = DoorsHandlerButton.new(index, self)
		buttons.append(button)
		add_child(button)
	move_child(add, -1)
	move_child(remove, -1)
	remove.visible = len(buttons) > 0

static func buttonType() -> GDScript: return DoorsHandlerButton

func addComponent() -> void:
	Game.editor.connectionSource = remoteLock
	Game.editor.focusDialog.defocus()

func removeComponent() -> void: remoteLock._disconnectTo(buttons[selected].door)

func _select(button:Button) -> void:
	if selected == button.index: Game.editor.focusDialog.focus(button.door)
	else: super(button)
	remoteLock.queue_redraw()

class DoorsHandlerButton extends HandlerButton:
	const ICON:Texture2D = preload("res://assets/ui/focusDialog/doorsHandler/door.png")

	var door:Door

	var drawMain:RID

	func _ready() -> void:
		drawMain = RenderingServer.canvas_item_create()
		RenderingServer.canvas_item_set_parent(drawMain,get_canvas_item())
		RenderingServer.canvas_item_set_z_index(drawMain,-1)
		Game.connect(&"goldIndexChanged",queue_redraw)
		icon = ICON
		queue_redraw()

	func _init(_index:int,_handler:DoorsHandler) -> void:
		super(_index, _handler)
		door = handler.remoteLock.doors[index]

	func _draw() -> void:
		RenderingServer.canvas_item_clear(drawMain)
		if deleted: return
		var rect:Rect2 = Rect2(Vector2.ONE, size-Vector2(2,2))
		if door.colorSpend == C.olors.GLITCH: RenderingServer.canvas_item_set_material(drawMain, Game.GLITCH_MATERIAL)
		else: RenderingServer.canvas_item_set_material(drawMain, Game.NO_MATERIAL)
		if Colors.getDef(door.colorSpend).doorTexture: RenderingServer.canvas_item_add_texture_rect(drawMain,rect,Game.COLOR_TEXTURES.current([door.colorSpend]))
		else: RenderingServer.canvas_item_add_rect(drawMain,rect,Game.mainTone[door.colorSpend])
