extends Button

@onready var editor:Editor = get_node("/root/editor")

var drawMain:RID

func _ready() -> void:
	drawMain = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(drawMain,get_parent().get_canvas_item())
	await get_tree().process_frame
	editor.game.connect(&"goldIndexChanged",queue_redraw)

func _draw() -> void:
	var door:GameObject = editor.focusDialog.focused
	if door is not Door: return
	RenderingServer.canvas_item_clear(drawMain)
	var rect:Rect2 = Rect2(position+Vector2.ONE, size-Vector2(2,2))
	var texture:Texture2D
	match door.colorSpend:
		Game.COLOR.MASTER: texture = editor.game.masterTex()
		Game.COLOR.PURE: texture = editor.game.pureTex()
		Game.COLOR.STONE: texture = editor.game.stoneTex()
		Game.COLOR.DYNAMITE: texture = editor.game.dynamiteTex()
		Game.COLOR.QUICKSILVER: texture = editor.game.quicksilverTex()
	if texture:
		RenderingServer.canvas_item_add_texture_rect(drawMain,rect,texture)
	else:
		RenderingServer.canvas_item_add_rect(drawMain,rect,editor.game.mainTone[door.colorSpend])
