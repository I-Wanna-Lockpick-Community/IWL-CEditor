extends Button

const GATE_FILL:Texture2D = preload('res://assets/ui/focusDialog/lockHandler/spendGate.png')

var drawMain:RID

func _ready() -> void:
	drawMain = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(drawMain,get_parent().get_canvas_item())
	await get_tree().process_frame
	Game.connect(&"goldIndexChanged",queue_redraw)

func _draw() -> void:
	var door:GameObject = Game.editor.focusDialog.focused
	RenderingServer.canvas_item_clear(drawMain)
	if door is not Door: return
	var rect:Rect2 = Rect2(position+Vector2.ONE, size-Vector2(2,2))
	if door.colorSpend == C.olors.GLITCH: RenderingServer.canvas_item_set_material(drawMain, Game.GLITCH_MATERIAL)
	else: RenderingServer.canvas_item_set_material(drawMain, Game.NO_MATERIAL)
	if door.type == Door.TYPE.GATE:
		RenderingServer.canvas_item_add_texture_rect(drawMain,rect,GATE_FILL,true)
	else:
		if Colors.getDef(door.colorSpend).doorTexture: RenderingServer.canvas_item_add_texture_rect(drawMain,rect,Game.COLOR_TEXTURES.current([door.colorSpend]))
		else: RenderingServer.canvas_item_add_rect(drawMain,rect,Game.mainTone[door.colorSpend])
