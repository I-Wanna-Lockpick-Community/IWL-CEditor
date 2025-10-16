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

const FRAME_NEGATIVE:Array[Texture2D] = [
	preload("res://assets/game/key/normal/frameNegative.png"),
	preload("res://assets/game/key/exact/frameNegative.png"),
	preload("res://assets/game/key/star/frame.png"),
	preload("res://assets/game/key/unstar/frame.png")
]
func getFrameNegative() -> Texture2D: return FRAME_NEGATIVE[Game.KEYTYPE_TEXTURE_OFFSETS[type]]

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

const SIGNFLIP_SYMBOL:Texture2D = preload("res://assets/game/key/symbols/signflip.png")
const POSROTOR_SYMBOL:Texture2D = preload("res://assets/game/key/symbols/posrotor.png")
const NEGROTOR_SYMBOL:Texture2D = preload("res://assets/game/key/symbols/negrotor.png")
const INFINITE_SYMBOL:Texture2D = preload("res://assets/game/key/symbols/infinite.png")

const FKEYBULK:Font = preload("res://resources/fonts/fKeyBulk.tres")

var id:int
var color:Game.COLOR = Game.COLOR.WHITE
var type:Game.KEY = Game.KEY.NORMAL
var count:C = C.new(1)
var infinite:bool = false

var drawMain:RID
var drawGlitch:RID
var drawSymbol:RID
func _init() -> void : size = Vector2(32,32)

func _ready() -> void:
	drawMain = RenderingServer.canvas_item_create()
	drawGlitch = RenderingServer.canvas_item_create()
	drawSymbol = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_material(drawGlitch,Game.GLITCH_MATERIAL.get_rid())
	RenderingServer.canvas_item_set_parent(drawMain,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawGlitch,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawSymbol,get_canvas_item())
	RenderingServer.canvas_item_set_z_index(drawSymbol,2)
	editor.game.connect(&"goldIndexChanged",func():if Game.isAnimated(color): queue_redraw())

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
				Game.COLOR.QUICKSILVER: return preload("res://assets/game/key/silver/outlineMask.png")
				_: return preload("res://assets/game/key/normal/outlineMask.png")

func _draw() -> void:
	RenderingServer.canvas_item_clear(drawMain)
	RenderingServer.canvas_item_clear(drawGlitch)
	RenderingServer.canvas_item_clear(drawSymbol)
	var rect:Rect2 = Rect2(Vector2.ZERO, size)
	var texture:Texture2D
	match color:
		Game.COLOR.MASTER: texture = editor.game.masterKeyTex(type)
		Game.COLOR.PURE: texture = editor.game.pureKeyTex(type)
		Game.COLOR.STONE: texture = editor.game.stoneKeyTex(type)
		Game.COLOR.DYNAMITE: texture = editor.game.dynamiteKeyTex(type)
		Game.COLOR.QUICKSILVER: texture = editor.game.quicksilverKeyTex(type)
		Game.COLOR.ICE: texture = editor.game.iceKeyTex(type)
		Game.COLOR.MUD: texture = editor.game.mudKeyTex(type)
		Game.COLOR.GRAFFITI: texture = editor.game.graffitiKeyTex(type)
	if texture:
		RenderingServer.canvas_item_add_texture_rect(drawMain,rect,texture)
	elif color == Game.COLOR.GLITCH:
		RenderingServer.canvas_item_add_texture_rect(drawGlitch,rect,getFrameGlitch())
		RenderingServer.canvas_item_add_texture_rect(drawGlitch,rect,getFill(),false,Game.mainTone[color])
	else:
		if count.sign() < 0: RenderingServer.canvas_item_add_texture_rect(drawMain,rect,getFrameNegative())
		else: RenderingServer.canvas_item_add_texture_rect(drawMain,rect,getFrame())
		RenderingServer.canvas_item_add_texture_rect(drawMain,rect,getFill(),false,Game.mainTone[color])
	match type:
		Game.KEY.NORMAL, Game.KEY.EXACT:
			if !count.eq(1): TextDraw.outlined(FKEYBULK,drawSymbol,str(count),keycountColor(),keycountOutlineColor(),18,Vector2(2,31),4)
		Game.KEY.SIGNFLIP: RenderingServer.canvas_item_add_texture_rect(drawSymbol,rect,SIGNFLIP_SYMBOL)
		Game.KEY.POSROTOR, Game.KEY.CURSE: RenderingServer.canvas_item_add_texture_rect(drawSymbol,rect,POSROTOR_SYMBOL)
		Game.KEY.NEGROTOR, Game.KEY.UNCURSE: RenderingServer.canvas_item_add_texture_rect(drawSymbol,rect,NEGROTOR_SYMBOL)
	if infinite: RenderingServer.canvas_item_add_texture_rect(drawSymbol,rect,INFINITE_SYMBOL)

func keycountColor() -> Color: return Color("#363029") if count.sign() < 0 else Color("#ebe3dd")
func keycountOutlineColor() -> Color: return Color("#d6cfc9") if count.sign() < 0 else Color("#363029")
