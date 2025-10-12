extends GameObject
class_name KeyBulk

const FILL:Array[Texture2D] = [
	preload("res://assets/game/key/normal/fill.png"),
	preload("res://assets/game/key/exact/fill.png"),
	preload("res://assets/game/key/star/fill.png"),
	preload("res://assets/game/key/unstar/fill.png")
]
func getFill() -> Texture2D: return FILL[Game.KEYTYPE_TEXTURE_OFFSETS[type]]

const FRAME:Array[Texture2D] = [
	preload("res://assets/game/key/normal/frame.png"),
	preload("res://assets/game/key/exact/frame.png"),
	preload("res://assets/game/key/star/frame.png"),
	preload("res://assets/game/key/unstar/frame.png")
]
func getFrame() -> Texture2D: return FRAME[Game.KEYTYPE_TEXTURE_OFFSETS[type]]

const FILL_GLITCH:Array[Texture2D] = [
	preload("res://assets/game/key/normal/fillGlitch.png"),
	preload("res://assets/game/key/exact/fillGlitch.png"),
	preload("res://assets/game/key/star/fillGlitch.png"),
	preload("res://assets/game/key/unstar/fillGlitch.png")
]
func getFillGlitch() -> Texture2D: return FILL_GLITCH[Game.KEYTYPE_TEXTURE_OFFSETS[type]]

const FRAME_GLITCH:Array[Texture2D] = [
	preload("res://assets/game/key/normal/frameGlitch.png"),
	preload("res://assets/game/key/exact/frameGlitch.png"),
	preload("res://assets/game/key/star/frameGlitch.png"),
	preload("res://assets/game/key/unstar/frameGlitch.png")
]
func getFrameGlitch() -> Texture2D: return FRAME_GLITCH[Game.KEYTYPE_TEXTURE_OFFSETS[type]]


@onready var editor:Editor = get_node("/root/editor")

var id:int
var color:Game.COLOR = Game.COLOR.WHITE
var type:Game.KEY = Game.KEY.NORMAL

var drawMain:RID
var drawGlitch:RID
var drawText:RID

func _ready() -> void:
	size = Vector2(32,32)
	drawMain = RenderingServer.canvas_item_create()
	drawGlitch = RenderingServer.canvas_item_create()
	drawText = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_material(drawGlitch,Game.GLITCH_MATERIAL.get_rid())
	RenderingServer.canvas_item_set_parent(drawMain,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawGlitch,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawText,get_canvas_item())
	RenderingServer.canvas_item_set_z_index(drawText,2)
	updateDraw()
	editor.game.connect(&"goldIndexChanged",func():if Game.isAnimated(color): updateDraw())

func outlineTex() -> Texture2D:
	match type:
		Game.KEY.EXACT:
			if color == Game.COLOR.MASTER: return preload("res://assets/game/key/master/outlineMaskExact.png")
			else:  return preload("res://assets/game/key/exact/outlineMask.png")
		Game.KEY.STAR: return preload("res://assets/game/key/star/outlineMask.png")
		Game.KEY.UNSTAR: return preload("res://assets/game/key/unstar/outlineMask.png")
		_:
			match color:
				Game.COLOR.MASTER:
					return preload("res://assets/game/key/master/outlineMask.png")
				Game.COLOR.DYNAMITE: return preload("res://assets/game/key/dynamite/outlineMask.png")
				Game.COLOR.SILVER: return preload("res://assets/game/key/silver/outlineMask.png")
				_: return preload("res://assets/game/key/normal/outlineMask.png")

func updateDraw() -> void:
	RenderingServer.canvas_item_clear(drawMain)
	RenderingServer.canvas_item_clear(drawGlitch)
	RenderingServer.canvas_item_clear(drawText)
	var rect:Rect2 = Rect2(Vector2.ZERO, size)
	var texture:Texture2D
	match color:
		Game.COLOR.MASTER: texture = editor.game.masterKeyTex(type)
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
		RenderingServer.canvas_item_add_texture_rect(drawMain,rect,getFrameGlitch())
		RenderingServer.canvas_item_add_texture_rect(drawGlitch,rect,getFill())
	else:
		RenderingServer.canvas_item_add_texture_rect(drawMain,rect,getFrame())
		RenderingServer.canvas_item_add_texture_rect(drawMain,rect,getFill(),false,editor.game.mainTone[color])
	match type:
		Game.KEY.SIGNFLIP: RenderingServer.canvas_item_add_texture_rect(drawText,rect,preload("res://assets/game/key/symbols/signflip.png").get_rid())
		Game.KEY.POSROTOR, Game.KEY.CURSE: RenderingServer.canvas_item_add_texture_rect(drawText,rect,preload("res://assets/game/key/symbols/posrotor.png").get_rid())
		Game.KEY.NEGROTOR, Game.KEY.UNCURSE: RenderingServer.canvas_item_add_texture_rect(drawText,rect,preload("res://assets/game/key/symbols/negrotor.png").get_rid())
