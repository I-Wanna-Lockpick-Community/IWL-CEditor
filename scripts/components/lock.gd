extends GameComponent
class_name Lock

const TYPES:int = 7
enum TYPE {NORMAL, BLANK, BLAST, ALL, EXACT, GLISTENING, REMAINDER}
const TYPE_NAMES:Array[String] = ["Normal", "Blank", "Blast", "All", "Exact", "Glistening", "Remainder"]
const SIZE_TYPES:int = 7
enum SIZE_TYPE {AnyS, AnyH, AnyV, AnyM, AnyL, AnyXL, ANY}
const SIZE_TYPE_NAMES:Array[String] = ["AnyS", "AnyH", "AnyV", "AnyM", "AnyL", "AnyXL", "Any"]
const SIZES:Array[Vector2] = [Vector2(18,18), Vector2(50,18), Vector2(18,50), Vector2(38,38), Vector2(50,50), Vector2(82,82)]
enum CONFIGURATION {spr1A, spr2H, spr2V, spr3H, spr3V, spr4A, spr4B, spr5A, spr5B, spr6A, spr6B, spr8A, spr12A, spr24A, spr7A, spr9A, spr9B, spr10A, spr11A, spr13A, spr24B, NONE}
const CONFIGURATION_NAMES:Array[String] = ["1A", "2H", "2V", "3H", "3V", "4A", "4B", "5A", "5B", "6A", "6B", "8A", "12A", "24A", "7A", "9A", "9B", "10A", "11A", "13A", "24B"]
const PREDEFINED_REAL:Array[CONFIGURATION] = [CONFIGURATION.spr1A, CONFIGURATION.spr2H, CONFIGURATION.spr2V, CONFIGURATION.spr3H, CONFIGURATION.spr3V, CONFIGURATION.spr4A, CONFIGURATION.spr4B, CONFIGURATION.spr5A, CONFIGURATION.spr5B, CONFIGURATION.spr6A, CONFIGURATION.spr6B, CONFIGURATION.spr8A, CONFIGURATION.spr12A, CONFIGURATION.spr24A, CONFIGURATION.spr7A, CONFIGURATION.spr9A, CONFIGURATION.spr9B, CONFIGURATION.spr10A, CONFIGURATION.spr11A, CONFIGURATION.spr13A, CONFIGURATION.spr24B]
const PREDEFINED_IMAGINARY:Array[CONFIGURATION] = [CONFIGURATION.spr1A, CONFIGURATION.spr2H, CONFIGURATION.spr2V, CONFIGURATION.spr3H, CONFIGURATION.spr3V]

func getAvailableConfigurations() -> Array[Array]: return availableConfigurations(effectiveCount(), type)

static func availableConfigurations(lockCount:PackedInt64Array, lockType:TYPE) -> Array[Array]:
	# returns Array[Array[SIZE_TYPE, CONFIGURATION]]
	# SpecificA/H first, then SpecificB/V
	var available:Array[Array] = []
	if lockType != TYPE.NORMAL and lockType != TYPE.EXACT: return available
	var absCount:PackedInt64Array = M.cabs(lockCount)
	if M.isNonzeroReal(lockCount):
		if M.eq(absCount, M.ONE): available.append([SIZE_TYPE.AnyS, CONFIGURATION.spr1A])
		elif M.eq(absCount, M.N(2)): available.append([SIZE_TYPE.AnyH, CONFIGURATION.spr2H]); available.append([SIZE_TYPE.AnyV, CONFIGURATION.spr2V])
		elif M.eq(absCount, M.N(3)): available.append([SIZE_TYPE.AnyH, CONFIGURATION.spr3H]); available.append([SIZE_TYPE.AnyV, CONFIGURATION.spr3V])
		elif M.eq(absCount, M.N(4)): available.append([SIZE_TYPE.AnyM, CONFIGURATION.spr4A]); available.append([SIZE_TYPE.AnyL, CONFIGURATION.spr4B])
		elif M.eq(absCount, M.N(5)): available.append([SIZE_TYPE.AnyM, CONFIGURATION.spr5A]); available.append([SIZE_TYPE.AnyL, CONFIGURATION.spr5B])
		elif M.eq(absCount, M.N(6)): available.append([SIZE_TYPE.AnyM, CONFIGURATION.spr6A]); available.append([SIZE_TYPE.AnyL, CONFIGURATION.spr6B])
		elif M.eq(absCount, M.N(8)): available.append([SIZE_TYPE.AnyL, CONFIGURATION.spr8A])
		elif M.eq(absCount, M.N(12)): available.append([SIZE_TYPE.AnyL, CONFIGURATION.spr12A])
		elif M.eq(absCount, M.N(24)):
			available.append([SIZE_TYPE.AnyXL, CONFIGURATION.spr24A])
			if Mods.active("MoreLockConfigs"): available.append([SIZE_TYPE.AnyXL, CONFIGURATION.spr24B])
		elif Mods.active("MoreLockConfigs"):
			if M.eq(absCount, M.N(7)): available.append([SIZE_TYPE.AnyL, CONFIGURATION.spr7A])
			elif M.eq(absCount, M.N(9)): available.append([SIZE_TYPE.AnyL, CONFIGURATION.spr9A]); available.append([SIZE_TYPE.AnyL, CONFIGURATION.spr9B])
			elif M.eq(absCount, M.N(10)): available.append([SIZE_TYPE.AnyL, CONFIGURATION.spr10A])
			elif M.eq(absCount, M.N(11)): available.append([SIZE_TYPE.AnyL, CONFIGURATION.spr11A])
			elif M.eq(absCount, M.N(13)): available.append([SIZE_TYPE.AnyL, CONFIGURATION.spr13A])
	elif M.isNonzeroImag(lockCount):
		if M.eq(absCount, M.I): available.append([SIZE_TYPE.AnyS, CONFIGURATION.spr1A])
		elif M.eq(absCount, M.Ni(2)): available.append([SIZE_TYPE.AnyH, CONFIGURATION.spr2H]); available.append([SIZE_TYPE.AnyV, CONFIGURATION.spr2V])
		elif M.eq(absCount, M.Ni(3)): available.append([SIZE_TYPE.AnyH, CONFIGURATION.spr3H]); available.append([SIZE_TYPE.AnyV, CONFIGURATION.spr3V])
	return available

const ANY_RECT:Rect2 = Rect2(Vector2.ZERO,Vector2(50,50)) # rect of ANY
const CORNER_SIZE:Vector2 = Vector2(2,2) # size of ANY's corners
const GLITCH_ANY_RECT:Rect2 = Rect2(Vector2.ZERO,Vector2(82,82))
const GLITCH_CORNER_SIZE:Vector2 = Vector2(9,9)
const TILE:RenderingServer.NinePatchAxisMode = RenderingServer.NinePatchAxisMode.NINE_PATCH_TILE # just to save characters
const STRETCH:RenderingServer.NinePatchAxisMode = RenderingServer.NinePatchAxisMode.NINE_PATCH_STRETCH # just to save characters

static var PREDEFINED_SPRITE_REAL:LockPredefinedTextureLoader = LockPredefinedTextureLoader.new("res://assets/game/lock/predefined/$p.png", PREDEFINED_REAL)
static var PREDEFINED_SPRITE_IMAGINARY:LockPredefinedTextureLoader = LockPredefinedTextureLoader.new("res://assets/game/lock/predefined/$pi.png", PREDEFINED_IMAGINARY)

static func getPredefinedLockSprite(lockCount:PackedInt64Array, lockType:TYPE, lockConfiguration:CONFIGURATION) -> Texture2D:
	if M.isNonzeroImag(lockCount): return PREDEFINED_SPRITE_IMAGINARY.current([lockType==TYPE.EXACT,lockConfiguration])
	else: return PREDEFINED_SPRITE_REAL.current([lockType==TYPE.EXACT,lockConfiguration])

const FRAME_HIGH:Texture2D = preload("res://assets/game/lock/frame/high.png")
const FRAME_MAIN:Texture2D = preload("res://assets/game/lock/frame/main.png")
const FRAME_DARK:Texture2D = preload("res://assets/game/lock/frame/dark.png")

static func getFrameHighColor(_isNegative:bool, _negated:bool) -> Color:
	if _isNegative: return Color("#14202c") if _negated else Color("#ebdfd3")
	else: return Color("#7b9fc3") if _negated else Color("#84603c")

static func getFrameMainColor(_isNegative:bool, _negated:bool) -> Color:
	if _isNegative: return Color("#274058") if _negated else Color("#d8bfa7")
	else: return Color("#a7bfd8") if _negated else Color("#584027")

static func getFrameDarkColor(_isNegative:bool, _negated:bool) -> Color:
	if _isNegative: return Color("#3b6084") if _negated else Color("#c49f7b")
	else: return Color("#d3dfeb") if _negated else Color("#42301d")

const SYMBOL_NORMAL = preload("res://assets/game/lock/symbols/normal.png")
const SYMBOL_BLAST = preload("res://assets/game/lock/symbols/blast.png")
const SYMBOL_BLASTI = preload("res://assets/game/lock/symbols/blasti.png")
const SYMBOL_EXACT = preload("res://assets/game/lock/symbols/exact.png")
const SYMBOL_EXACTI = preload("res://assets/game/lock/symbols/exacti.png")
const SYMBOL_ALL = preload("res://assets/game/lock/symbols/all.png")
const SYMBOL_GLISTENING = preload("res://assets/game/lock/symbols/glistening.png")
const SYMBOL_GLISTENINGI = preload("res://assets/game/lock/symbols/glisteningi.png")
const SYMBOL_REMAINDER = preload("res://assets/game/lock/symbols/remainder.png")
const SYMBOL_SIZE:Vector2 = Vector2(32,32)

static var GLITCH_FILL:LockTextureLoader = LockTextureLoader.new("res://assets/game/lock/fill/$tglitch.png")
static var GLITCH_FILL_TEXTURE:LockColorsTextureLoader = LockColorsTextureLoader.new("res://assets/game/lock/fill/$tglitch$c.png",Game.TEXTURED_COLORS,false,true)

static var ERROR_FX:IndexTextureLoader = IndexTextureLoader.new("res://assets/game/key/error/fx.png", 3)

const ARMAMENT:Array[Texture2D] = [
	preload("res://assets/game/lock/armament/0.png"),
	preload("res://assets/game/lock/armament/1.png"),
	preload("res://assets/game/lock/armament/2.png"),
	preload("res://assets/game/lock/armament/3.png")
]
const ARMAMENT_RECT:Rect2 = Rect2(Vector2.ZERO, Vector2(18,18))
const ARMAMENT_CORNER_SIZE:Vector2 = Vector2(5,5)

static func offsetFromType(getSizeType:SIZE_TYPE) -> Vector2:
	match getSizeType:
		SIZE_TYPE.AnyM: return Vector2(3, 3)
		_: return Vector2(-7, -7)

func getOffset() -> Vector2: return offsetFromType(sizeType)

const CREATE_PARAMETERS:Array[StringName] = [
	&"position", &"parentId"
]
const PROPERTIES:Array[StringName] = [
	&"id", &"position", &"size",
	&"parentId", &"color", &"type", &"sizeType", &"count", &"configuration", &"zeroI", &"isPartial", &"denominator", &"negated", &"armament",
	&"index", &"displayIndex" # implcit
]
static var ARRAYS:Dictionary[StringName,Variant] = {}

var parent:Door
var parentId:int
var color:Game.COLOR = Game.COLOR.WHITE
var type:TYPE = TYPE.NORMAL
var configuration:CONFIGURATION = CONFIGURATION.spr1A
var sizeType:SIZE_TYPE = SIZE_TYPE.AnyS
var count:PackedInt64Array = M.ONE
var zeroI:bool = false # if the count is zeroI, for exact locks
var isPartial:bool = false # for partial blast
var denominator:PackedInt64Array = M.ONE # for partial blast
var negated:bool = false
var armament:bool = false
var index:int
var displayIndex:int # split into armaments and nonarmaments

func getColors() -> Array[Game.COLOR]: return [color]

var drawScaled:RID
var drawAuraBreaker:RID
var drawGlitch:RID
var drawMain:RID
var drawError:RID
var drawConfiguration:RID

static func getConfigurationColor(_isNegative:bool) -> Color:
	if _isNegative: return Color("#ebdfd3")
	else: return Color("#2c2014")

func _init() -> void: size = Vector2(18,18)

func _ready() -> void:
	add_to_group(&"hasNumbers", true)
	drawScaled = RenderingServer.canvas_item_create()
	drawAuraBreaker = RenderingServer.canvas_item_create()
	drawGlitch = RenderingServer.canvas_item_create()
	drawError = RenderingServer.canvas_item_create()
	drawMain = RenderingServer.canvas_item_create()
	drawConfiguration = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(drawScaled,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawAuraBreaker,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawGlitch,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawMain,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawError,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawConfiguration,get_canvas_item())
	RenderingServer.canvas_item_set_self_modulate(drawError, "#ffffffaa")
	RenderingServer.canvas_item_set_material(drawError,Game.ADDITIVE_MATERIAL)
	Game.connect(&"goldIndexChanged",func(): if getColor(COLOR_STEP.DRAW_BASE) in Game.ANIMATED_COLORS: queue_redraw())

func _freed() -> void:
	RenderingServer.free_rid(drawScaled)
	RenderingServer.free_rid(drawAuraBreaker)
	RenderingServer.free_rid(drawGlitch)
	RenderingServer.free_rid(drawMain)
	RenderingServer.free_rid(drawError)
	RenderingServer.free_rid(drawConfiguration)

func convertNumbers(from:M.SYSTEM) -> void:
	Changes.addChange(Changes.ComponentConvertNumberChange.new(self, from, &"count"))
	Changes.addChange(Changes.ComponentConvertNumberChange.new(self, from, &"denominator"))

func _draw() -> void:
	RenderingServer.canvas_item_clear(drawScaled)
	RenderingServer.canvas_item_clear(drawAuraBreaker)
	RenderingServer.canvas_item_clear(drawGlitch)
	RenderingServer.canvas_item_clear(drawMain)
	RenderingServer.canvas_item_clear(drawError)
	RenderingServer.canvas_item_clear(drawConfiguration)
	if !parent.active and Game.playState == Game.PLAY_STATE.PLAY: return
	drawLock(drawScaled,drawAuraBreaker,drawGlitch,drawMain,drawConfiguration,
		size,getColor(COLOR_STEP.DRAW_BASE),getColor(COLOR_STEP.Glitch),type,effectiveConfiguration(),sizeType,effectiveCount(),effectiveZeroI(),isPartial,effectiveDenominator(),negated,armament,
		getFrameHighColor(isNegative(), negated),
		getFrameMainColor(isNegative(), negated),
		getFrameDarkColor(isNegative(), negated),
		isNegative(),
		parent.animState != Door.ANIM_STATE.RELOCK or parent.animPart > 2,
		Game.playState == Game.PLAY_STATE.PLAY and parent.drawComplex
	)
	if getColor(COLOR_STEP.BASE) == Game.COLOR.ERROR:
		RenderingServer.canvas_item_add_texture_rect(drawError,Rect2(-offsetFromType(sizeType), size),ERROR_FX.current([randi_range(0,2)]))

static func drawLock(lockDrawScaled:RID, lockDrawAuraBreaker:RID, lockDrawGlitch:RID, lockDrawMain:RID, lockDrawConfiguration:RID,
	lockSize:Vector2,
	lockBaseColor:Game.COLOR, lockGlitchColor:Game.COLOR,
	lockType:TYPE,
	lockConfiguration:CONFIGURATION,
	lockSizeType:SIZE_TYPE,
	lockCount:PackedInt64Array,
	lockZeroI:bool,
	lockIsPartial:bool,
	lockDenominator,
	lockNegated:bool,
	lockArmament:bool,
	frameHigh:Color,frameMain:Color,frameDark:Color,
	negative:bool, drawFill:bool=true, noCopies:bool=false
) -> void:
	var rect:Rect2 = Rect2(-offsetFromType(lockSizeType), lockSize)
	if lockNegated:
		RenderingServer.canvas_item_set_transform(lockDrawScaled,Transform2D(PI,lockSize-offsetFromType(lockSizeType)*2))
		RenderingServer.canvas_item_set_transform(lockDrawConfiguration,Transform2D(PI,lockSize-offsetFromType(lockSizeType)*2))
	else:
		RenderingServer.canvas_item_set_transform(lockDrawScaled,Transform2D.IDENTITY)
		RenderingServer.canvas_item_set_transform(lockDrawConfiguration,Transform2D.IDENTITY)
	# fill
	var tempColor = lockBaseColor
	if lockBaseColor == Game.COLOR.ERROR:
		tempColor = lockGlitchColor
	if drawFill:
		if tempColor in Game.TEXTURED_COLORS:
			var tileTexture:bool = tempColor in Game.TILED_TEXTURED_COLORS
			RenderingServer.canvas_item_add_texture_rect(lockDrawScaled,rect,Game.COLOR_TEXTURES.current([tempColor]),tileTexture)
		elif tempColor == Game.COLOR.GLITCH:
			RenderingServer.canvas_item_set_material(lockDrawGlitch,Game.GLITCH_MATERIAL.get_rid())
			RenderingServer.canvas_item_add_rect(lockDrawGlitch,Rect2(rect.position+Vector2.ONE,rect.size-Vector2(2,2)),Game.mainTone[tempColor])
			if lockGlitchColor != Game.COLOR.GLITCH:
				if lockSizeType == SIZE_TYPE.ANY:
					if lockGlitchColor in Game.TEXTURED_COLORS: RenderingServer.canvas_item_add_nine_patch(lockDrawMain,rect,GLITCH_ANY_RECT,GLITCH_FILL_TEXTURE.current([lockGlitchColor,lockSizeType]),GLITCH_CORNER_SIZE,GLITCH_CORNER_SIZE,TILE,TILE)
					else: RenderingServer.canvas_item_add_nine_patch(lockDrawMain,rect,GLITCH_ANY_RECT,GLITCH_FILL.current([lockSizeType]),GLITCH_CORNER_SIZE,GLITCH_CORNER_SIZE,TILE,TILE,true,Game.mainTone[lockGlitchColor])
				elif lockGlitchColor in Game.TEXTURED_COLORS: RenderingServer.canvas_item_add_texture_rect(lockDrawMain,rect,GLITCH_FILL_TEXTURE.current([lockGlitchColor,lockSizeType]))
				else: RenderingServer.canvas_item_add_texture_rect(lockDrawMain,rect,GLITCH_FILL.current([lockSizeType]),false,Game.mainTone[lockGlitchColor])
		elif tempColor in [Game.COLOR.ICE, Game.COLOR.MUD, Game.COLOR.GRAFFITI]:
			RenderingServer.canvas_item_set_material(lockDrawScaled,Game.NO_MATERIAL.get_rid())
			RenderingServer.canvas_item_add_rect(lockDrawScaled,Rect2(rect.position+Vector2.ONE,rect.size-Vector2(2,2)),Game.mainTone[tempColor])
			Door.drawAuras(lockDrawAuraBreaker,lockDrawAuraBreaker,lockDrawAuraBreaker,tempColor==Game.COLOR.ICE,tempColor==Game.COLOR.MUD,tempColor==Game.COLOR.GRAFFITI,rect)
		else:
			RenderingServer.canvas_item_add_rect(lockDrawMain,Rect2(rect.position+Vector2.ONE,rect.size-Vector2(2,2)),Game.mainTone[tempColor])
	if noCopies: return # no copies in this direction; go away
	# frame
	RenderingServer.canvas_item_add_nine_patch(lockDrawMain,rect,ANY_RECT,FRAME_HIGH,CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,frameHigh)
	RenderingServer.canvas_item_add_nine_patch(lockDrawMain,rect,ANY_RECT,FRAME_MAIN,CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,frameMain)
	RenderingServer.canvas_item_add_nine_patch(lockDrawMain,rect,ANY_RECT,FRAME_DARK,CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,frameDark)
	if lockArmament: RenderingServer.canvas_item_add_nine_patch(lockDrawMain,rect,ARMAMENT_RECT,ARMAMENT[Game.goldIndex%4],ARMAMENT_CORNER_SIZE,ARMAMENT_CORNER_SIZE,TILE,TILE,false)
	# configuration
	if lockConfiguration == CONFIGURATION.NONE:
		match lockType:
			TYPE.NORMAL,TYPE.EXACT,TYPE.GLISTENING,TYPE.REMAINDER:
				var string:String = M.str(M.abs(lockCount))
				if string == "1": string = ""
				if M.isNonzeroImag(lockCount) and lockType == TYPE.NORMAL: string += "i"
				var lockOffsetX:float = 0
				var showLock:bool = (lockType in [TYPE.EXACT, TYPE.GLISTENING, TYPE.REMAINDER]) || (!M.isNonzeroImag(lockCount) && (lockSize != Vector2(18,18) || string == ""))
				if lockType == TYPE.EXACT and !showLock: string = "=" + string
				var vertical:bool = lockSize.x == 18 && lockSize.y != 18 && string != ""

				var symbolLast:bool = (lockType == TYPE.EXACT or lockType == TYPE.GLISTENING) and (M.isNonzeroImag(lockCount) or lockZeroI) and !vertical
				if showLock and !vertical:
					if (lockType == TYPE.EXACT):
						if symbolLast: lockOffsetX = 6
						else: lockOffsetX = 12
					elif lockType == TYPE.GLISTENING:
						if symbolLast: lockOffsetX = 8
						else: lockOffsetX = 12
					else: lockOffsetX = 14

				var strWidth:float = Game.FTALK.get_string_size(string,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x + lockOffsetX

				var startX:int = round((lockSize.x - strWidth)/2)
				var startY:int = round((lockSize.y+14)/2)
				if showLock and vertical: startY -= 8
				@warning_ignore("integer_division")
				if showLock:
					var lockRect:Rect2
					if vertical:
						var lockStartX:int = round((lockSize.x - lockOffsetX)/2)
						lockRect = Rect2(Vector2(lockStartX+lockOffsetX/2,lockSize.y/2+11)-SYMBOL_SIZE/2-offsetFromType(lockSizeType),Vector2(32,32))
					elif symbolLast: lockRect = Rect2(Vector2(startX+strWidth-lockOffsetX/2,lockSize.y/2)-SYMBOL_SIZE/2-offsetFromType(lockSizeType),Vector2(32,32))
					else: lockRect = Rect2(Vector2(startX+lockOffsetX/2,lockSize.y/2)-SYMBOL_SIZE/2-offsetFromType(lockSizeType),Vector2(32,32))
					var lockSymbol:Texture2D
					match lockType:
						TYPE.NORMAL: lockSymbol = SYMBOL_NORMAL
						TYPE.GLISTENING: lockSymbol = SYMBOL_GLISTENINGI if M.isNonzeroImag(lockCount) else SYMBOL_GLISTENING
						TYPE.EXACT: lockSymbol = SYMBOL_EXACTI if M.isNonzeroImag(lockCount) or lockZeroI else SYMBOL_EXACT
						TYPE.REMAINDER: lockSymbol = SYMBOL_REMAINDER
					if lockNegated: lockRect = Rect2(lockSize-lockRect.position-lockRect.size-offsetFromType(lockSizeType)*2,lockRect.size)
					RenderingServer.canvas_item_add_texture_rect(lockDrawConfiguration,lockRect,lockSymbol,false,getConfigurationColor(negative))
				if symbolLast: Game.FTALK.draw_string(lockDrawMain,Vector2(startX,startY)-offsetFromType(lockSizeType),string,HORIZONTAL_ALIGNMENT_LEFT,-1,12,getConfigurationColor(negative))
				else: Game.FTALK.draw_string(lockDrawMain,Vector2(startX+lockOffsetX,startY)-offsetFromType(lockSizeType),string,HORIZONTAL_ALIGNMENT_LEFT,-1,12,getConfigurationColor(negative))
			TYPE.BLANK: pass # nothing really
			TYPE.BLAST, TYPE.ALL:
				var numerator:String
				var ipow:int = 0
				if M.isComplex(lockDenominator) or M.isComplex(lockCount) or M.nex(lockDenominator): numerator = M.str(lockCount)
				else:
					numerator = M.str(M.divide(lockCount, M.saxis(lockDenominator)))
					ipow = M.toIpow(M.axis(lockDenominator))
				if numerator == "1": numerator = ""
				
				const symbolOffsetX:float = 10
				var strWidth:float = Game.FTALK.get_string_size(numerator,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x + symbolOffsetX
				var startX:int = round((lockSize.x - strWidth)/2)
				var startY:int = round((lockSize.y+14)/2)
				
				if lockIsPartial:
					var denom:String
					if M.isComplex(lockDenominator) or M.isComplex(lockCount): denom = M.str(lockDenominator)
					else: denom = M.str(M.abs(lockDenominator))
					var denomWidth:float = Game.FTALK.get_string_size(denom,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
					var denomStartX = round((lockSize.x - denomWidth)/2)
					var denomStartY = startY + 10
					startY -= 10
					Game.FTALK.draw_string(lockDrawMain,Vector2(denomStartX, denomStartY)-offsetFromType(lockSizeType),denom,HORIZONTAL_ALIGNMENT_LEFT,-1,12,getConfigurationColor(negative))
					
					var lineWidth:float = max(strWidth,denomWidth)
					RenderingServer.canvas_item_add_rect(lockDrawMain,Rect2(Vector2(round((lockSize.x - lineWidth)/2),startY+2)-offsetFromType(lockSizeType),Vector2(lineWidth,2)),getConfigurationColor(negative))

				Game.FTALK.draw_string(lockDrawMain,Vector2(startX, startY)-offsetFromType(lockSizeType),numerator,HORIZONTAL_ALIGNMENT_LEFT,-1,12,getConfigurationColor(negative))

				var symbolRect:Rect2 = Rect2(Vector2(startX+strWidth-symbolOffsetX/2,startY-7)-SYMBOL_SIZE/2-offsetFromType(lockSizeType),Vector2(32,32))
				var symbol:Texture2D
				match ipow:
					0, 2: symbol = SYMBOL_BLAST
					1, 3: symbol = SYMBOL_BLASTI
				if lockType == TYPE.ALL: symbol = SYMBOL_ALL
				RenderingServer.canvas_item_add_texture_rect(lockDrawMain,symbolRect,symbol,false,getConfigurationColor(negative))
	else: RenderingServer.canvas_item_add_texture_rect(lockDrawConfiguration,rect,getPredefinedLockSprite(lockCount,lockType,lockConfiguration),false,getConfigurationColor(negative))

func getDrawPosition() -> Vector2: return position + parent.position - getOffset()

func _simpleDoorUpdate() -> void:
	# resize and set configuration	
	var newSizeType:SIZE_TYPE
	match parent.size:
		Vector2(32,32): newSizeType = SIZE_TYPE.AnyS
		Vector2(64,32): newSizeType = SIZE_TYPE.AnyH
		Vector2(32,64): newSizeType = SIZE_TYPE.AnyV
		Vector2(64,64): newSizeType = SIZE_TYPE.AnyL
		Vector2(96,96): newSizeType = SIZE_TYPE.AnyXL
		_: newSizeType = SIZE_TYPE.ANY
	Changes.addChange(Changes.PropertyChange.new(self,&"position",Vector2.ZERO))
	Changes.addChange(Changes.PropertyChange.new(self,&"sizeType",newSizeType))
	Changes.addChange(Changes.PropertyChange.new(self,&"size",parent.size - Vector2(14,14)))
	queue_redraw()

func _comboDoorConfigurationChanged(newSizeType:SIZE_TYPE,newConfiguration:CONFIGURATION=CONFIGURATION.NONE) -> void:
	Changes.addChange(Changes.PropertyChange.new(self,&"sizeType",newSizeType))
	Changes.addChange(Changes.PropertyChange.new(self,&"configuration",newConfiguration))
	var newSize:Vector2
	match sizeType:
		SIZE_TYPE.AnyS: newSize = Vector2(18,18)
		SIZE_TYPE.AnyH: newSize = Vector2(50,18)
		SIZE_TYPE.AnyV: newSize = Vector2(18,50)
		SIZE_TYPE.AnyM: newSize = Vector2(38,38)
		SIZE_TYPE.AnyL: newSize = Vector2(50,50)
		SIZE_TYPE.AnyXL: newSize = Vector2(82,82)
	if newSize: Changes.addChange(Changes.PropertyChange.new(self,&"size",newSize))
	queue_redraw()

func _comboDoorSizeChanged() -> void:
	var newSizeType:SIZE_TYPE = SIZE_TYPE.ANY
	match size:
		Vector2(18,18): newSizeType = SIZE_TYPE.AnyS
		Vector2(50,18): newSizeType = SIZE_TYPE.AnyH
		Vector2(18,50): newSizeType = SIZE_TYPE.AnyV
		Vector2(38,38): newSizeType = SIZE_TYPE.AnyM
		Vector2(50,50): newSizeType = SIZE_TYPE.AnyL
		Vector2(82,82): newSizeType = SIZE_TYPE.AnyXL
	Changes.addChange(Changes.PropertyChange.new(self,&"sizeType",newSizeType))
	if [sizeType, configuration] not in getAvailableConfigurations():
		Changes.addChange(Changes.PropertyChange.new(self,&"configuration",CONFIGURATION.NONE))

static func getAutoConfiguration(lock:GameComponent) -> CONFIGURATION:
	var newConfiguration:CONFIGURATION = CONFIGURATION.NONE
	for option in lock.getAvailableConfigurations():
		if lock.sizeType == option[0]:
			newConfiguration = option[1]
			break
	return newConfiguration

func _setAutoConfiguration() -> void:
	Changes.addChange(Changes.PropertyChange.new(self,&"configuration",getAutoConfiguration(self)))

func receiveMouseInput(event:InputEventMouse) -> bool:
	# resizing
	if !editor.edgeResizing or editor.componentDragged: return false
	if !Rect2(position-getOffset(),size).has_point(editor.mouseWorldPosition - parent.position) : return false
	var dragCornerSize:Vector2 = Vector2(8,8)/editor.cameraZoom
	var diffSign:Vector2 = Editor.rectSign(Rect2(position+dragCornerSize-getOffset(),size-dragCornerSize*2), editor.mouseWorldPosition-parent.position)
	if !diffSign: return false
	elif !diffSign.x: editor.mouse_default_cursor_shape = Control.CURSOR_VSIZE
	elif !diffSign.y: editor.mouse_default_cursor_shape = Control.CURSOR_HSIZE
	elif (diffSign.x > 0) == (diffSign.y > 0): editor.mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
	else: editor.mouse_default_cursor_shape = Control.CURSOR_BDIAGSIZE
	if Editor.isLeftClick(event):
		editor.startSizeDrag(self, diffSign)
		return true
	return false

func _coerceSize() -> void:
	var newSize = (size+Vector2(14,14)).snapped(Vector2(16,16))
	if newSize == Vector2(48,48):
		newSize = Vector2(38,38)
	else:
		newSize = (size+Vector2(14,14)).snapped(Vector2(32,32)) - Vector2(14,14)
		if newSize in SIZES: return
		newSize = newSize.min(Vector2(82,82))
		# 1x3, 2x3 -> 3x3
		if newSize.x < newSize.y: newSize = Vector2(newSize.y, newSize.y)
		elif newSize.y < newSize.x: newSize = Vector2(newSize.x, newSize.x)
	Changes.addChange(Changes.PropertyChange.new(self,&"size",newSize))

func propertyChangedInit(property:StringName) -> void:
	if parent.type != Door.TYPE.SIMPLE:
		if property == &"size": _comboDoorSizeChanged()
	if property in [&"count", &"sizeType", &"type"]: _setAutoConfiguration()
	lockPropertyChangedInit(self, property)
	if property in [&"color", &"type"] and editor.focusDialog.focused == parent: editor.focusDialog.doorDialog.lockHandler.redrawButton(index)

static func lockPropertyChangedInit(lock:GameComponent, property:StringName) -> void:
	if property == &"type":
		if (lock.type == TYPE.BLANK or (lock.type == TYPE.ALL and !Mods.active(&"PartialBlastLocks"))) and M.neq(lock.count, M.ONE):
			Changes.addChange(Changes.PropertyChange.new(lock,&"count",M.ONE))
		if lock.type != TYPE.EXACT and lock.zeroI:
			Changes.addChange(Changes.PropertyChange.new(lock,&"zeroI",false))
		if lock.type == TYPE.BLAST:
			if !Mods.active(&"PartialBlastLocks"):
				if M.neq(M.abs(lock.count), M.ONE): Changes.addChange(Changes.PropertyChange.new(lock,&"count",M.saxis(lock.count)))
				if M.neq(M.axis(lock.denominator), M.axis(lock.count)): Changes.addChange(Changes.PropertyChange.new(lock,&"denominator", M.axis(lock.count)))
		elif lock.type == TYPE.ALL:
			if !lock.isPartial and M.neq(lock.denominator, M.ONE): Changes.addChange(Changes.PropertyChange.new(lock,&"denominator",M.ONE))
		else:
			if M.neq(lock.denominator, M.ONE): Changes.addChange(Changes.PropertyChange.new(lock,&"denominator",M.ONE))
			if lock.isPartial: Changes.addChange(Changes.PropertyChange.new(lock,&"isPartial",false))
			if M.isComplex(lock.count):
				Changes.addChange(Changes.PropertyChange.new(lock,&"count",M.r(lock.count)))

	if property == &"isPartial" and !lock.isPartial:
		Changes.addChange(Changes.PropertyChange.new(lock,&"denominator", M.ONE if M.isComplex(lock.count) or M.nex(lock.count) or lock.type == TYPE.ALL else M.axis(lock.count)))

func propertyChangedDo(property:StringName) -> void:
	if property in [&"count", &"denominator"] and parent: parent.queue_redraw()
	if property == &"armament" and parent: parent.reindexLocks()

# ==== PLAY ==== #
var glitchMimic:Game.COLOR = Game.COLOR.GLITCH
var errorMimic:Game.COLOR = Game.COLOR.ERROR
func stop() -> void:
	glitchMimic = Game.COLOR.GLITCH
	errorMimic = Game.COLOR.ERROR

enum COLOR_STEP {INITIAL, Curse, BASE, Error, DRAW_BASE, Glitch, EFFECTIVE, AuraBreaker, FINAL}

func getColor(step:COLOR_STEP) -> Game.COLOR:
	var resultColor:Game.COLOR = color

	if step < COLOR_STEP.Curse: return resultColor
	var curseAffected:bool = parent.cursed and parent.curseColor != Game.COLOR.PURE and !armament
	if curseAffected: resultColor = parent.curseColor
	
	# BASE
	# redundancy checks go here, like cant freeze if all ice

	if step < COLOR_STEP.Error: return resultColor
	var checkColor:Game.COLOR = resultColor # error and glitch act independently
	if checkColor == Game.COLOR.ERROR: resultColor = parent.curseMimic if curseAffected else errorMimic

	# DRAW_BASE
	# the step used for drawing

	if step < COLOR_STEP.Glitch: return resultColor
	if checkColor == Game.COLOR.GLITCH: resultColor = parent.curseMimic if curseAffected else glitchMimic

	# EFFECTIVE
	# the step used for normal immunities

	if step < COLOR_STEP.AuraBreaker: return resultColor
	if !armament:
		if parent.gameFrozen: resultColor = Game.COLOR.ICE
		if parent.gameCrumbled: resultColor = Game.COLOR.MUD
		if parent.gamePainted: resultColor = Game.COLOR.GRAFFITI

	# FINAL
	# the step used for check and cost
	return resultColor

func effectiveConfiguration() -> CONFIGURATION:
	if Game.simpleLocks: return CONFIGURATION.NONE
	if M.neq(parent.ipow(), M.ONE):
		if parent.type == Door.TYPE.SIMPLE: return getAutoConfiguration(self)
		else: return CONFIGURATION.NONE
	else: return configuration

func canOpen(player:Player) -> bool: return getLockCanOpen(self, player)

static func getLockCanOpen(lock:GameComponent,player:Player) -> bool:
	var can:bool = true
	var keyCount:PackedInt64Array = player.key[lock.getColor(COLOR_STEP.FINAL)]
	var glistCount:PackedInt64Array = player.glisten[lock.getColor(COLOR_STEP.FINAL)]
	var lockCount:PackedInt64Array = lock.effectiveCount()
	var lockDenominator:PackedInt64Array = lock.effectiveDenominator()
	if M.isError(keyCount): return lock.negated
	match lock.type:
		TYPE.NORMAL: can = M.cgte(M.along(keyCount, lockCount), M.cabs(lockCount))
		TYPE.BLANK: can = M.nex(keyCount)
		TYPE.BLAST:
			if M.nex(lockDenominator): can = false
			elif !M.simplies(lockDenominator, keyCount): can = false
			elif lock.isPartial:
				if !M.divisibleBy(M.alongbs(keyCount, lockDenominator), lockDenominator): can = false
				elif M.neq(M.sign(M.divide(M.alongbs(keyCount, lockDenominator), lockDenominator)), M.ONE): can = false
		TYPE.ALL:
			if M.nex(lockDenominator): can = false
			elif M.nex(keyCount): can = false
			elif lock.isPartial:
				if !M.divisibleBy(keyCount, lockDenominator): can = false
		TYPE.EXACT:
			if M.nex(lockCount):
				if lock.effectiveZeroI(): can = M.nex(M.i(keyCount))
				else: can = M.nex(M.r(keyCount))
			else: can = M.eq(M.along(keyCount, lockCount), M.cabs(lockCount))
		TYPE.GLISTENING: can = M.cgte(M.along(glistCount, lockCount), M.cabs(lockCount))
		TYPE.REMAINDER:
			can = M.neq(M.partialRemainder(keyCount, lockCount),M.ZERO)
	return can != lock.negated

func getCost(player:Player, ipow:PackedInt64Array=parent.ipow()) -> PackedInt64Array: return getLockCost(self, player, ipow)

static func getLockCost(lock:GameComponent, player:Player, ipow:PackedInt64Array) -> PackedInt64Array:
	var cost:PackedInt64Array = M.ZERO
	var keyCount:PackedInt64Array = player.key[lock.getColor(COLOR_STEP.FINAL)]
	var lockCount:PackedInt64Array = lock.effectiveCount(ipow)
	var lockDenominator:PackedInt64Array = lock.effectiveDenominator(ipow)
	match lock.type:
		TYPE.NORMAL, TYPE.EXACT, TYPE.GLISTENING: cost = lockCount
		TYPE.BLAST: if M.ex(lockDenominator): cost = M.divide(M.times(M.alongbs(keyCount, lockDenominator), lockCount), lockDenominator)
		TYPE.REMAINDER: cost = M.partialRemainder(keyCount, lockCount)
		TYPE.ALL: if M.ex(lockDenominator): cost = M.divide(M.times(keyCount, lockCount), lockDenominator)
	if lock.negated: return M.negate(cost)
	return cost

func effectiveCount(ipow:PackedInt64Array=parent.ipow()) -> PackedInt64Array:
	return M.times(count, ipow)

func effectiveDenominator(ipow:PackedInt64Array=parent.ipow()) -> PackedInt64Array:
	return M.times(denominator, ipow)

func effectiveZeroI() -> bool: return (zeroI != M.isNonzeroImag(parent.ipow())) and M.nex(count)

func isNegative() -> bool:
	if type in [TYPE.BLAST, TYPE.ALL]:
		if M.isComplex(count) or M.isComplex(denominator): return false
		return M.negative(M.sign(effectiveDenominator()))
	return M.negative(M.sign(effectiveCount()))
