extends GameObject
class_name Door

const FRAME:Texture2D = preload("res://assets/game/door/frame.png")
const SPEND_HIGH:Texture2D = preload("res://assets/game/door/spendHigh.png")
const SPEND_MAIN:Texture2D = preload("res://assets/game/door/spendMain.png")
const SPEND_DARK:Texture2D = preload("res://assets/game/door/spendDark.png")

const TEXTURE_RECT:Rect2 = Rect2(Vector2.ZERO,Vector2(64,64)) # size of all the door textures
const CORNER_SIZE:Vector2 = Vector2(9,9) # size of door ninepatch corners
const TILE:RenderingServer.NinePatchAxisMode = RenderingServer.NinePatchAxisMode.NINE_PATCH_TILE # just to save characters

var id:int
var colorSpend:Game.COLOR = Game.COLOR.WHITE

var drawMain:RID
var drawGlitch:RID

func _init() -> void : size = Vector2(32,32)

func _ready() -> void:
	drawMain = RenderingServer.canvas_item_create()
	drawGlitch = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_material(drawMain,Game.PIXELATED_MATERIAL.get_rid())
	RenderingServer.canvas_item_set_material(drawGlitch,Game.GLITCH_MATERIAL.get_rid())
	RenderingServer.canvas_item_set_parent(drawMain,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawGlitch,get_canvas_item())
	updateDraw()
	editor.game.connect(&"goldIndexChanged", updateDraw)

func updateDraw() -> void:
	RenderingServer.canvas_item_clear(drawMain)
	RenderingServer.canvas_item_clear(drawGlitch)
	var rect:Rect2 = Rect2(Vector2.ZERO, size)
	var texture:Texture2D
	match colorSpend:
		Game.COLOR.MASTER: texture = editor.game.masterTex()
		Game.COLOR.PURE: texture = editor.game.pureTex()
		Game.COLOR.STONE: texture = editor.game.stoneTex()
		Game.COLOR.DYNAMITE: texture = editor.game.dynamiteTex()
	if texture:
		RenderingServer.canvas_item_add_texture_rect(drawMain,rect,texture)
	elif colorSpend == Game.COLOR.GLITCH:
		pass
	else:
		RenderingServer.canvas_item_add_nine_patch(drawMain,rect,TEXTURE_RECT,SPEND_HIGH,CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,Game.highTone[colorSpend])
		RenderingServer.canvas_item_add_nine_patch(drawMain,rect,TEXTURE_RECT,SPEND_MAIN,CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,Game.mainTone[colorSpend])
		RenderingServer.canvas_item_add_nine_patch(drawMain,rect,TEXTURE_RECT,SPEND_DARK,CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,Game.darkTone[colorSpend])
	RenderingServer.canvas_item_add_nine_patch(drawMain,rect,TEXTURE_RECT,FRAME,CORNER_SIZE,CORNER_SIZE)
