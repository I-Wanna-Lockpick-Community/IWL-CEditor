extends GameObject
class_name KeyBulk
const SCENE:PackedScene = preload("res://scenes/objects/keyBulk.tscn")

const TYPES:int = 9
enum TYPE {NORMAL, EXACT, STAR, UNSTAR, SIGNFLIP, POSROTOR, NEGROTOR, CURSE, UNCURSE}

const FILL:Array[Texture2D] = [
	preload("res://assets/game/key/normal/fill.png"),
	preload("res://assets/game/key/exact/fill.png"),
	preload("res://assets/game/key/star/fill.png"),
	preload("res://assets/game/key/unstar/fill.png")
]
static func getFill(keyType:TYPE) -> Texture2D: return FILL[Game.KEYTYPE_TEXTURE_OFFSETS[keyType]]

const FRAME:Array[Texture2D] = [
	preload("res://assets/game/key/normal/frame.png"),
	preload("res://assets/game/key/exact/frame.png"),
	preload("res://assets/game/key/star/frame.png"),
	preload("res://assets/game/key/unstar/frame.png")
]
static func getFrame(keyType:TYPE) -> Texture2D: return FRAME[Game.KEYTYPE_TEXTURE_OFFSETS[keyType]]

const FILL_GLITCH:Array[Texture2D] = [
	preload("res://assets/game/key/normal/fillGlitch.png"),
	preload("res://assets/game/key/exact/fillGlitch.png"),
	preload("res://assets/game/key/star/fillGlitch.png"),
	preload("res://assets/game/key/unstar/fillGlitch.png")
]
static func getFillGlitch(keyType:TYPE) -> Texture2D: return FILL_GLITCH[Game.KEYTYPE_TEXTURE_OFFSETS[keyType]]

const FRAME_GLITCH:Array[Texture2D] = [
	preload("res://assets/game/key/normal/frameGlitch.png"),
	preload("res://assets/game/key/exact/frameGlitch.png"),
	preload("res://assets/game/key/star/frameGlitch.png"),
	preload("res://assets/game/key/unstar/frameGlitch.png")
]
static func getFrameGlitch(keyType:TYPE) -> Texture2D: return FRAME_GLITCH[Game.KEYTYPE_TEXTURE_OFFSETS[keyType]]

const SIGNFLIP_SYMBOL:Texture2D = preload("res://assets/game/key/symbols/signflip.png")
const POSROTOR_SYMBOL:Texture2D = preload("res://assets/game/key/symbols/posrotor.png")
const NEGROTOR_SYMBOL:Texture2D = preload("res://assets/game/key/symbols/negrotor.png")
const INFINITE_SYMBOL:Texture2D = preload("res://assets/game/key/symbols/infinite.png")

const FKEYBULK:Font = preload("res://resources/fonts/fKeyBulk.tres")

const CREATE_PARAMETERS:Array[StringName] = [
	&"position"
]
const EDITOR_PROPERTIES:Array[StringName] = [
	&"id", &"position", &"size",
	&"color", &"type", &"count", &"infinite"
]

var color:Game.COLOR = Game.COLOR.WHITE
var type:TYPE = TYPE.NORMAL
var count:C = C.new(1)
var infinite:bool = false

var drawMain:RID
var drawGlitch:RID
var drawSymbol:RID
func _init() -> void: size = Vector2(32,32)

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
		KeyBulk.TYPE.EXACT:
			if color == Game.COLOR.MASTER: return preload("res://assets/game/key/master/outlineMaskExact.png")
			else:  return preload("res://assets/game/key/exact/outlineMask.png")
		KeyBulk.TYPE.STAR: return preload("res://assets/game/key/star/outlineMask.png")
		KeyBulk.TYPE.UNSTAR: return preload("res://assets/game/key/unstar/outlineMask.png")
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
	drawKey(editor.game,drawMain,drawGlitch,Vector2.ZERO,color,type)
	match type:
		KeyBulk.TYPE.NORMAL, KeyBulk.TYPE.EXACT:
			if !count.eq(1): TextDraw.outlined(FKEYBULK,drawSymbol,str(count),keycountColor(),keycountOutlineColor(),18,Vector2(2,31),4)
		KeyBulk.TYPE.SIGNFLIP: RenderingServer.canvas_item_add_texture_rect(drawSymbol,rect,SIGNFLIP_SYMBOL)
		KeyBulk.TYPE.POSROTOR, KeyBulk.TYPE.CURSE: RenderingServer.canvas_item_add_texture_rect(drawSymbol,rect,POSROTOR_SYMBOL)
		KeyBulk.TYPE.NEGROTOR, KeyBulk.TYPE.UNCURSE: RenderingServer.canvas_item_add_texture_rect(drawSymbol,rect,NEGROTOR_SYMBOL)
	if infinite: RenderingServer.canvas_item_add_texture_rect(drawSymbol,rect,INFINITE_SYMBOL)

func keycountColor() -> Color: return Color("#363029") if count.sign() < 0 else Color("#ebe3dd")
func keycountOutlineColor() -> Color: return Color("#d6cfc9") if count.sign() < 0 else Color("#363029")

static func drawKey(game:Game,keyDrawMain:RID,keyDrawGlitch:RID,keyOffset:Vector2,keyColor:Game.COLOR,keyType:TYPE=TYPE.NORMAL) -> void:
	var texture:Texture2D
	var rect:Rect2 = Rect2(keyOffset, Vector2(32,32))
	match keyColor:
		Game.COLOR.MASTER: texture = game.masterKeyTex(keyType)
		Game.COLOR.PURE: texture = game.pureKeyTex(keyType)
		Game.COLOR.STONE: texture = game.stoneKeyTex(keyType)
		Game.COLOR.DYNAMITE: texture = game.dynamiteKeyTex(keyType)
		Game.COLOR.QUICKSILVER: texture = game.quicksilverKeyTex(keyType)
		Game.COLOR.ICE: texture = game.iceKeyTex(keyType)
		Game.COLOR.MUD: texture = game.mudKeyTex(keyType)
		Game.COLOR.GRAFFITI: texture = game.graffitiKeyTex(keyType)
	if texture:
		RenderingServer.canvas_item_add_texture_rect(keyDrawMain,rect,texture)
	elif keyColor == Game.COLOR.GLITCH:
		RenderingServer.canvas_item_add_texture_rect(keyDrawGlitch,rect,getFrameGlitch(keyType))
		RenderingServer.canvas_item_add_texture_rect(keyDrawGlitch,rect,getFill(keyType),false,Game.mainTone[keyColor])
	else:
		RenderingServer.canvas_item_add_texture_rect(keyDrawMain,rect,getFrame(keyType))
		RenderingServer.canvas_item_add_texture_rect(keyDrawMain,rect,getFill(keyType),false,Game.mainTone[keyColor])

