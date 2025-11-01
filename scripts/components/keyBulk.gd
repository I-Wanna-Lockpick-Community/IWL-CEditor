extends GameObject
class_name KeyBulk
const SCENE:PackedScene = preload("res://scenes/objects/keyBulk.tscn")

const TYPES:int = 9
enum TYPE {NORMAL, EXACT, STAR, UNSTAR, SIGNFLIP, POSROTOR, NEGROTOR, CURSE, UNCURSE}

const KEYTYPE_TEXTURE_OFFSETS:Array[int] = [0,1,2,3,0,0,0,0,0]

const FILL:Array[Texture2D] = [
	preload("res://assets/game/key/normal/fill.png"),
	preload("res://assets/game/key/exact/fill.png"),
	preload("res://assets/game/key/star/fill.png"),
	preload("res://assets/game/key/unstar/fill.png")
]

const FRAME:Array[Texture2D] = [
	preload("res://assets/game/key/normal/frame.png"),
	preload("res://assets/game/key/exact/frame.png"),
	preload("res://assets/game/key/star/frame.png"),
	preload("res://assets/game/key/unstar/frame.png")
]

const FILL_GLITCH:Array[Texture2D] = [
	preload("res://assets/game/key/normal/fillGlitch.png"),
	preload("res://assets/game/key/exact/fillGlitch.png"),
	preload("res://assets/game/key/star/fillGlitch.png"),
	preload("res://assets/game/key/unstar/fillGlitch.png")
]

const FILL_GLITCH_MASTER:Array[Texture2D] = [
	preload("res://assets/game/key/master/glitchNormal.png"),
	preload("res://assets/game/key/master/glitchExact.png"),
	preload("res://assets/game/key/master/glitchStar.png"),
	preload("res://assets/game/key/master/glitchUnstar.png")
]
const FILL_GLITCH_PURE:Array[Texture2D] = [
	preload("res://assets/game/key/pure/glitchNormal.png"),
	preload("res://assets/game/key/pure/glitchExact.png"),
	preload("res://assets/game/key/pure/glitchStar.png"),
	preload("res://assets/game/key/pure/glitchUnstar.png")
]
const FILL_GLITCH_STONE:Array[Texture2D] = [
	preload("res://assets/game/key/stone/glitchNormal.png"),
	preload("res://assets/game/key/stone/glitchExact.png"),
	preload("res://assets/game/key/stone/glitchStar.png"),
	preload("res://assets/game/key/stone/glitchUnstar.png")
]
const FILL_GLITCH_DYNAMITE:Array[Texture2D] = [
	preload("res://assets/game/key/dynamite/glitchNormal.png"),
	preload("res://assets/game/key/dynamite/glitchExact.png"),
	preload("res://assets/game/key/dynamite/glitchStar.png"),
	preload("res://assets/game/key/dynamite/glitchUnstar.png")
]
const FILL_GLITCH_QUICKSILVER:Array[Texture2D] = [
	preload("res://assets/game/key/quicksilver/glitchNormal.png"),
	preload("res://assets/game/key/quicksilver/glitchExact.png"),
	preload("res://assets/game/key/quicksilver/glitchStar.png"),
	preload("res://assets/game/key/quicksilver/glitchUnstar.png")
]
const FILL_GLITCH_ICE:Array[Texture2D] = [
	preload("res://assets/game/key/ice/glitchNormal.png"),
	preload("res://assets/game/key/ice/glitchExact.png"),
	preload("res://assets/game/key/ice/glitchStar.png"),
	preload("res://assets/game/key/ice/glitchUnstar.png")
]
const FILL_GLITCH_MUD:Array[Texture2D] = [
	preload("res://assets/game/key/mud/glitchNormal.png"),
	preload("res://assets/game/key/mud/glitchExact.png"),
	preload("res://assets/game/key/mud/glitchStar.png"),
	preload("res://assets/game/key/mud/glitchUnstar.png")
]
const FILL_GLITCH_GRAFFITI:Array[Texture2D] = [
	preload("res://assets/game/key/graffiti/glitchNormal.png"),
	preload("res://assets/game/key/graffiti/glitchExact.png"),
	preload("res://assets/game/key/graffiti/glitchStar.png"),
	preload("res://assets/game/key/graffiti/glitchUnstar.png")
]

const FRAME_GLITCH:Array[Texture2D] = [
	preload("res://assets/game/key/normal/frameGlitch.png"),
	preload("res://assets/game/key/exact/frameGlitch.png"),
	preload("res://assets/game/key/star/frameGlitch.png"),
	preload("res://assets/game/key/unstar/frameGlitch.png")
]

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
var count:C = C.ONE
var infinite:bool = false

var drawGlitch:RID
var drawMain:RID
var drawSymbol:RID
func _init() -> void: size = Vector2(32,32)

func _ready() -> void:
	drawGlitch = RenderingServer.canvas_item_create()
	drawMain = RenderingServer.canvas_item_create()
	drawSymbol = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_material(drawGlitch,Game.GLITCH_MATERIAL.get_rid())
	RenderingServer.canvas_item_set_parent(drawGlitch,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawMain,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawSymbol,get_canvas_item())
	game.connect(&"goldIndexChanged",func():if Game.isAnimated(color): queue_redraw())

func outlineTex() -> Texture2D: return getOutlineTexture(color, type)

static func getOutlineTexture(keyColor:Game.COLOR, keyType:TYPE=TYPE.NORMAL) -> Texture2D:
	match keyType:
		KeyBulk.TYPE.EXACT:
			if keyColor == Game.COLOR.MASTER: return preload("res://assets/game/key/master/outlineMaskExact.png")
			else:  return preload("res://assets/game/key/exact/outlineMask.png")
		KeyBulk.TYPE.STAR: return preload("res://assets/game/key/star/outlineMask.png")
		KeyBulk.TYPE.UNSTAR: return preload("res://assets/game/key/unstar/outlineMask.png")
		_:
			match keyColor:
				Game.COLOR.MASTER:
					return preload("res://assets/game/key/master/outlineMask.png")
				Game.COLOR.DYNAMITE: return preload("res://assets/game/key/dynamite/outlineMask.png")
				Game.COLOR.QUICKSILVER: return preload("res://assets/game/key/quicksilver/outlineMask.png")
				_: return preload("res://assets/game/key/normal/outlineMask.png")

func _draw() -> void:
	RenderingServer.canvas_item_clear(drawGlitch)
	RenderingServer.canvas_item_clear(drawMain)
	RenderingServer.canvas_item_clear(drawSymbol)
	if !active and game.playState == Game.PLAY_STATE.PLAY: return
	var rect:Rect2 = Rect2(Vector2.ZERO, size)
	drawKey(game,drawGlitch,drawMain,Vector2.ZERO,color,type,glitchMimic)
	if animState == ANIM_STATE.FLASH: RenderingServer.canvas_item_add_texture_rect(drawSymbol,rect,outlineTex(),false,Color(Color.WHITE,animAlpha))
	match type:
		KeyBulk.TYPE.NORMAL, KeyBulk.TYPE.EXACT:
			if !count.eq(1): TextDraw.outlined2(FKEYBULK,drawSymbol,str(count),keycountColor(),keycountOutlineColor(),18,Vector2(2,31))
		KeyBulk.TYPE.SIGNFLIP: RenderingServer.canvas_item_add_texture_rect(drawSymbol,rect,SIGNFLIP_SYMBOL)
		KeyBulk.TYPE.POSROTOR, KeyBulk.TYPE.CURSE: RenderingServer.canvas_item_add_texture_rect(drawSymbol,rect,POSROTOR_SYMBOL)
		KeyBulk.TYPE.NEGROTOR, KeyBulk.TYPE.UNCURSE: RenderingServer.canvas_item_add_texture_rect(drawSymbol,rect,NEGROTOR_SYMBOL)
	if infinite: RenderingServer.canvas_item_add_texture_rect(drawSymbol,rect,INFINITE_SYMBOL)

func keycountColor() -> Color: return Color("#363029") if count.sign() < 0 else Color("#ebe3dd")
func keycountOutlineColor() -> Color: return Color("#d6cfc9") if count.sign() < 0 else Color("#363029")

static func drawKey(_game:Game,keyDrawGlitch:RID,keyDrawMain:RID,keyOffset:Vector2,keyColor:Game.COLOR,keyType:TYPE=TYPE.NORMAL,keyGlitchMimic:Game.COLOR=Game.COLOR.GLITCH) -> void:
	var texture:Texture2D
	var rect:Rect2 = Rect2(keyOffset, Vector2(32,32))
	match keyColor:
		Game.COLOR.MASTER: texture = _game.masterKeyTex(keyType)
		Game.COLOR.PURE: texture = _game.pureKeyTex(keyType)
		Game.COLOR.STONE: texture = _game.stoneKeyTex(keyType)
		Game.COLOR.DYNAMITE: texture = _game.dynamiteKeyTex(keyType)
		Game.COLOR.QUICKSILVER: texture = _game.quicksilverKeyTex(keyType)
		Game.COLOR.ICE: texture = _game.iceKeyTex(keyType)
		Game.COLOR.MUD: texture = _game.mudKeyTex(keyType)
		Game.COLOR.GRAFFITI: texture = _game.graffitiKeyTex(keyType)
	if texture:
		RenderingServer.canvas_item_add_texture_rect(keyDrawMain,rect,texture)
	elif keyColor == Game.COLOR.GLITCH:
		RenderingServer.canvas_item_add_texture_rect(keyDrawGlitch,rect,FRAME_GLITCH[KEYTYPE_TEXTURE_OFFSETS[keyType]])
		RenderingServer.canvas_item_add_texture_rect(keyDrawGlitch,rect,FILL[KEYTYPE_TEXTURE_OFFSETS[keyType]],false,Game.mainTone[keyColor])
		if keyGlitchMimic != Game.COLOR.GLITCH:
			var glitchTextureSet:Array[Texture2D]
			match keyGlitchMimic:
				Game.COLOR.MASTER: glitchTextureSet = FILL_GLITCH_MASTER
				Game.COLOR.PURE: glitchTextureSet = FILL_GLITCH_PURE
				Game.COLOR.STONE: glitchTextureSet = FILL_GLITCH_STONE
				Game.COLOR.DYNAMITE: glitchTextureSet = FILL_GLITCH_DYNAMITE
				Game.COLOR.QUICKSILVER: glitchTextureSet = FILL_GLITCH_QUICKSILVER
				Game.COLOR.ICE: glitchTextureSet = FILL_GLITCH_ICE
				Game.COLOR.MUD: glitchTextureSet = FILL_GLITCH_MUD
				Game.COLOR.GRAFFITI: glitchTextureSet = FILL_GLITCH_GRAFFITI
			if glitchTextureSet: RenderingServer.canvas_item_add_texture_rect(keyDrawMain,rect,glitchTextureSet[KEYTYPE_TEXTURE_OFFSETS[keyType]])
			else: RenderingServer.canvas_item_add_texture_rect(keyDrawMain,rect,FILL_GLITCH[KEYTYPE_TEXTURE_OFFSETS[keyType]],false,Game.mainTone[keyGlitchMimic])
	else:
		RenderingServer.canvas_item_add_texture_rect(keyDrawMain,rect,FRAME[KEYTYPE_TEXTURE_OFFSETS[keyType]])
		RenderingServer.canvas_item_add_texture_rect(keyDrawMain,rect,FILL[KEYTYPE_TEXTURE_OFFSETS[keyType]],false,Game.mainTone[keyColor])

func propertyChangedInit(property:StringName) -> void:
	if property in [&"count", &"type"]:
		if type not in [TYPE.NORMAL, TYPE.EXACT] and count.neq(1): changes.addChange(Changes.PropertyChange.new(game,self,&"count",C.ONE))

# ==== PLAY ==== #
var glitchMimic:Game.COLOR = Game.COLOR.GLITCH

enum ANIM_STATE {IDLE, FLASH}
var animState:ANIM_STATE = ANIM_STATE.IDLE
var animAlpha:float = 0

func _process(delta:float) -> void:
	match animState:
		ANIM_STATE.IDLE: animAlpha = 0
		ANIM_STATE.FLASH:
			animAlpha -= delta*6
			if animAlpha <= 0: animState = ANIM_STATE.IDLE
			queue_redraw()

func stop() -> void:
	glitchMimic = Game.COLOR.GLITCH
	super()

func collect(player:Player) -> void:
	match type:
		TYPE.NORMAL: gameChanges.addChange(GameChanges.KeyChange.new(game, effectiveColor(), player.key[effectiveColor()].plus(count)))
		TYPE.EXACT: gameChanges.addChange(GameChanges.KeyChange.new(game, effectiveColor(), count))
		TYPE.SIGNFLIP: gameChanges.addChange(GameChanges.KeyChange.new(game, effectiveColor(), player.key[effectiveColor()].times(-1)))
		TYPE.POSROTOR: gameChanges.addChange(GameChanges.KeyChange.new(game, effectiveColor(), player.key[effectiveColor()].times(C.I)))
		TYPE.NEGROTOR: gameChanges.addChange(GameChanges.KeyChange.new(game, effectiveColor(), player.key[effectiveColor()].times(C.nI)))
		TYPE.STAR: gameChanges.addChange(GameChanges.StarChange.new(game, effectiveColor(), true))
		TYPE.UNSTAR: gameChanges.addChange(GameChanges.StarChange.new(game, effectiveColor(), false))
		TYPE.CURSE: gameChanges.addChange(GameChanges.CurseChange.new(game, effectiveColor(), true))
		TYPE.UNCURSE: gameChanges.addChange(GameChanges.CurseChange.new(game, effectiveColor(), false))
		
	if infinite: flashAnimation()
	else: gameChanges.addChange(GameChanges.PropertyChange.new(game, self, &"active", false))
	gameChanges.bufferSave()

	if color == Game.COLOR.MASTER: # not effectiveColor; doesnt trigger on glitch master
		AudioManager.play(preload("res://resources/sounds/key/master.wav"))
	else:
		match type:
			TYPE.SIGNFLIP, TYPE.POSROTOR, TYPE.NEGROTOR: AudioManager.play(preload("res://resources/sounds/key/signflip.wav"))
			TYPE.STAR: AudioManager.play(preload("res://resources/sounds/key/star.wav"))
			TYPE.UNSTAR: AudioManager.play(preload("res://resources/sounds/key/unstar.wav"))
			_:
				if count.sign() < 0: AudioManager.play(preload("res://resources/sounds/key/negative.wav"))
				else: AudioManager.play(preload("res://resources/sounds/key/normal.wav"))

func setGlitch(setColor:Game.COLOR) -> void:
	gameChanges.addChange(GameChanges.PropertyChange.new(game, self, &"glitchMimic", setColor))
	queue_redraw()

func flashAnimation() -> void:
	animState = ANIM_STATE.FLASH
	animAlpha = 1

func propertyGameChangedDo(property:StringName) -> void:
	if property == &"active":
		%interact.process_mode = PROCESS_MODE_INHERIT if active else PROCESS_MODE_DISABLED


func effectiveColor() -> Game.COLOR:
	if color == Game.COLOR.GLITCH: return glitchMimic
	return color
