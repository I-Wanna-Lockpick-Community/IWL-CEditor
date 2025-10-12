extends GameObject
class_name KeyBulk

const FILL = preload('res://assets/game/key/fill.png')
const FRAME = preload('res://assets/game/key/frame.png')
const FILL_GLITCH = preload('res://assets/game/key/fillGlitch.png')
const FRAME_GLITCH = preload('res://assets/game/key/frameGlitch.png')

@onready var editor:Editor = get_node("/root/editor")

var id:int
var color:Game.COLOR = Game.COLOR.WHITE

var drawMain:RID
var drawGlitch:RID

func _ready() -> void:
	size = Vector2(32,32)
	drawMain = RenderingServer.canvas_item_create()
	drawGlitch = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_material(drawGlitch,Game.GLITCH_MATERIAL.get_rid())
	RenderingServer.canvas_item_set_parent(drawMain,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawGlitch,get_canvas_item())
	updateDraw()
	editor.game.connect(&"goldIndexChanged",func():if Game.isAnimated(color): updateDraw())

func outlineTex() -> Texture2D:
	match color:
		Game.COLOR.MASTER: return preload('res://assets/game/key/master/outlineMask.png')
		Game.COLOR.DYNAMITE: return preload('res://assets/game/key/dynamite/outlineMask.png')
		Game.COLOR.SILVER: return preload('res://assets/game/key/silver/outlineMask.png')
		_: return preload('res://assets/game/key/outlineMask.png')

func updateDraw() -> void:
	RenderingServer.canvas_item_clear(drawMain)
	RenderingServer.canvas_item_clear(drawGlitch)
	var rect:Rect2 = Rect2(Vector2.ZERO, size)
	var texture:Texture2D
	match color:
		Game.COLOR.MASTER: texture = editor.game.masterKeyTex()
		Game.COLOR.PURE: texture = editor.game.pureKeyTex()
		Game.COLOR.STONE: texture = editor.game.stoneKeyTex()
		Game.COLOR.DYNAMITE: texture = editor.game.dynamiteKeyTex()
		Game.COLOR.SILVER: texture = editor.game.silverKeyTex()
		Game.COLOR.ICE: texture = editor.game.iceKeyTex()
		Game.COLOR.MUD: texture = editor.game.mudKeyTex()
		Game.COLOR.GRAFFITI: texture = editor.game.graffitiKeyTex()
	if texture:
		RenderingServer.canvas_item_add_texture_rect(drawMain,rect,texture)
	elif color == Game.COLOR.GLITCH:
		RenderingServer.canvas_item_add_texture_rect(drawMain,rect,FRAME_GLITCH)
		RenderingServer.canvas_item_add_texture_rect(drawGlitch,rect,FILL)
	else:
		RenderingServer.canvas_item_add_texture_rect(drawMain,rect,FRAME)
		RenderingServer.canvas_item_add_texture_rect(drawMain,rect,FILL,false,editor.game.mainTone[color])
