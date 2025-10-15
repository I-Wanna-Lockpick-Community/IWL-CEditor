extends GameComponent
class_name Lock

enum SIZE_TYPE {AnyS, AnyH, AnyV, AnyM, AnyL, AnyXL, ANY}
enum CONFIGURATION {spr1A, spr2H, spr2V, spr3H, spr3V, spr4A, spr4B, spr5A, spr5B, spr6A, spr6B, spr8A, spr12A, spr24A, NONE}

const ANY_RECT:Rect2 = Rect2(Vector2.ZERO,Vector2(64,64)) # size of ANY
const CORNER_SIZE:Vector2 = Vector2(9,9) # size of ANY's corners
const TILE:RenderingServer.NinePatchAxisMode = RenderingServer.NinePatchAxisMode.NINE_PATCH_TILE # just to save characters

const PREDEFINED_LOCK_SPRITE_NORMAL:Array[Texture2D] = [
	preload("res://assets/game/lock/predefined/1Anormal.png"), preload("res://assets/game/lock/predefined/1Aexact.png"),
	preload("res://assets/game/lock/predefined/2Hnormal.png"), preload("res://assets/game/lock/predefined/2Hexact.png"),
	preload("res://assets/game/lock/predefined/2Vnormal.png"), preload("res://assets/game/lock/predefined/2Vexact.png"),
	preload("res://assets/game/lock/predefined/3Hnormal.png"), preload("res://assets/game/lock/predefined/3Hexact.png"),
	preload("res://assets/game/lock/predefined/3Vnormal.png"), preload("res://assets/game/lock/predefined/3Vexact.png"),
	preload("res://assets/game/lock/predefined/4Anormal.png"), preload("res://assets/game/lock/predefined/4Aexact.png"),
	preload("res://assets/game/lock/predefined/4Bnormal.png"), preload("res://assets/game/lock/predefined/4Bexact.png"),
	preload("res://assets/game/lock/predefined/5Anormal.png"), preload("res://assets/game/lock/predefined/5Aexact.png"),
	preload("res://assets/game/lock/predefined/5Bnormal.png"), preload("res://assets/game/lock/predefined/5Bexact.png"),
	preload("res://assets/game/lock/predefined/6Anormal.png"), preload("res://assets/game/lock/predefined/6Aexact.png"),
	preload("res://assets/game/lock/predefined/6Bnormal.png"), preload("res://assets/game/lock/predefined/6Bexact.png"),
	preload("res://assets/game/lock/predefined/8Anormal.png"), preload("res://assets/game/lock/predefined/8Aexact.png"),
	preload("res://assets/game/lock/predefined/12Anormal.png"), preload("res://assets/game/lock/predefined/12Aexact.png"),
	preload("res://assets/game/lock/predefined/24Anormal.png"), preload("res://assets/game/lock/predefined/24Aexact.png")
]
const PREDEFINED_LOCK_SPRITE_IMAGINARY:Array[Texture2D] = [
	preload("res://assets/game/lock/predefined/1Aexact.png"), preload("res://assets/game/lock/predefined/1Aexacti.png"),
	preload("res://assets/game/lock/predefined/2Hexact.png"), preload("res://assets/game/lock/predefined/2Hexacti.png"),
	preload("res://assets/game/lock/predefined/2Vexact.png"), preload("res://assets/game/lock/predefined/2Vexacti.png"),
	preload("res://assets/game/lock/predefined/3Hexact.png"), preload("res://assets/game/lock/predefined/3Hexacti.png"),
	preload("res://assets/game/lock/predefined/3Vexact.png"), preload("res://assets/game/lock/predefined/3Vexacti.png"),
]
func getPredefinedLockSprite(imaginary:bool) -> Texture2D:
	if imaginary: return PREDEFINED_LOCK_SPRITE_IMAGINARY[configuration*2+int(type==Game.LOCK.EXACT)]
	else: return PREDEFINED_LOCK_SPRITE_NORMAL[configuration*2+int(type==Game.LOCK.EXACT)]

const LOCK_FRAME:Array[Texture2D] = [
	preload("res://assets/game/lock/frame/AnySnormal.png"),
	preload("res://assets/game/lock/frame/AnyHnormal.png"),
	preload("res://assets/game/lock/frame/AnyVnormal.png"),
	preload("res://assets/game/lock/frame/AnyMnormal.png"),
	preload("res://assets/game/lock/frame/AnyLnormal.png"),
	preload("res://assets/game/lock/frame/AnyXLnormal.png"),
	preload("res://assets/game/lock/frame/ANYnormal.png"),
]
func getLockFrameSprite() -> Texture2D: return LOCK_FRAME[sizeType]

const LOCK_FILL:Array[Texture2D] = [
	preload("res://assets/game/lock/fill/AnySnormal.png"),
	preload("res://assets/game/lock/fill/AnyHnormal.png"),
	preload("res://assets/game/lock/fill/AnyVnormal.png"),
	preload("res://assets/game/lock/fill/AnyMnormal.png"),
	preload("res://assets/game/lock/fill/AnyLnormal.png"),
	preload("res://assets/game/lock/fill/AnyXLnormal.png"),
	preload("res://assets/game/lock/fill/ANYnormal.png"),
]
func getLockFillSprite() -> Texture2D: return LOCK_FILL[sizeType]

const SYMBOL_NORMAL = preload("res://assets/game/lock/symbols/normal.png")

func getOffset() -> Vector2:
	match sizeType:
		SIZE_TYPE.AnyM: return Vector2(3, 3)
		SIZE_TYPE.ANY: return Vector2(0, 0)
		_: return Vector2(-7, -7)

func getSizeFromSizeType():
	match sizeType:
		SIZE_TYPE.AnyS: size = Vector2(18,18)
		SIZE_TYPE.AnyH: size = Vector2(50,18)
		SIZE_TYPE.AnyV: size = Vector2(18,50)
		SIZE_TYPE.AnyM: size = Vector2(38,38)
		SIZE_TYPE.AnyL: size = Vector2(50,50)
		SIZE_TYPE.AnyXL: size = Vector2(82,82)

var id:int
var parent:Door
var doorId:int
var color:Game.COLOR = Game.COLOR.WHITE
var type:Game.LOCK = Game.LOCK.NORMAL
var configuration:CONFIGURATION = CONFIGURATION.spr1A
var sizeType:SIZE_TYPE = SIZE_TYPE.AnyS
var count:C = C.new(1)

var drawMain:RID

const COLOR:Color = Color("#2c2014")
const NEGATIVE_COLOR:Color = Color("#ebdfd3")

func _init(_parent:Door) -> void:
	parent = _parent
	size = Vector2(18,18)

func _ready() -> void:
	drawMain = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(drawMain,get_canvas_item())

func _draw() -> void:
	RenderingServer.canvas_item_clear(drawMain)
	var rect:Rect2 = Rect2(-getOffset(), size)
	# fill
	if sizeType == SIZE_TYPE.ANY: RenderingServer.canvas_item_add_nine_patch(drawMain,rect,ANY_RECT,getLockFillSprite(),CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,Game.mainTone[color])
	else: RenderingServer.canvas_item_add_texture_rect(drawMain,rect,getLockFillSprite(),false,Game.mainTone[color])
	# frame
	if sizeType == SIZE_TYPE.ANY: RenderingServer.canvas_item_add_nine_patch(drawMain,rect,ANY_RECT,getLockFrameSprite(),CORNER_SIZE,CORNER_SIZE)
	else: RenderingServer.canvas_item_add_texture_rect(drawMain,rect,getLockFrameSprite())
	# configuration
	if configuration == CONFIGURATION.NONE:
		var lockOffsetX:int = 12;
		var string:String = str(count)
		var strWidth:int = int(Game.FTALK.get_string_size(string,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x)
		var startX:int = floor((size.x - strWidth - lockOffsetX)/2);
		var lockRect:Rect2 = Rect2(Vector2(startX-12,size.y/2-16)-getOffset(),Vector2(32,32))
		RenderingServer.canvas_item_add_texture_rect(drawMain,lockRect,SYMBOL_NORMAL,false,COLOR)
		Game.FTALK.draw_string(drawMain,Vector2(startX+lockOffsetX-1,size.y/2+7)-getOffset(),str(count),HORIZONTAL_ALIGNMENT_LEFT,size.x,12,COLOR)
	else: RenderingServer.canvas_item_add_texture_rect(drawMain,rect,getPredefinedLockSprite(false),false,COLOR)

func getDrawPosition() -> Vector2: return position + parent.position - getOffset()

func simpleDoorUpdate() -> void:
	# resize and set configuration
	configuration = CONFIGURATION.NONE
	match type:
		Game.LOCK.NORMAL, Game.LOCK.EXACT:
			if count.isNonzeroReal():
				match parent.size:
					Vector2(32,32):
						if count.r.eq(1): configuration = CONFIGURATION.spr1A
					Vector2(64,32):
						if count.r.eq(2): configuration = CONFIGURATION.spr2H
						elif count.r.eq(3): configuration = CONFIGURATION.spr3H
					Vector2(32,64):
						if count.r.eq(2): configuration = CONFIGURATION.spr2V
						elif count.r.eq(3): configuration = CONFIGURATION.spr3V
					Vector2(64,64):
						if count.r.eq(4): configuration = CONFIGURATION.spr4B
						elif count.r.eq(5): configuration = CONFIGURATION.spr5B
						elif count.r.eq(6): configuration = CONFIGURATION.spr6B
						elif count.r.eq(8): configuration = CONFIGURATION.spr8A
						elif count.r.eq(12): configuration = CONFIGURATION.spr12A
					Vector2(96,96):
						if count.r.eq(24): configuration = CONFIGURATION.spr24A
			elif count.isNonzeroImag():
				match parent.size:
					Vector2(32,32):
						if count.r.eq(1): configuration = CONFIGURATION.spr1A
					Vector2(64,32):
						if count.r.eq(2): configuration = CONFIGURATION.spr2H
						elif count.r.eq(3): configuration = CONFIGURATION.spr3H
					Vector2(32,64):
						if count.r.eq(2): configuration = CONFIGURATION.spr2V
						elif count.r.eq(3): configuration = CONFIGURATION.spr3V
	match parent.size:
		Vector2(32,32): sizeType = SIZE_TYPE.AnyS
		Vector2(64,32): sizeType = SIZE_TYPE.AnyH
		Vector2(32,64): sizeType = SIZE_TYPE.AnyV
		Vector2(64,64): sizeType = SIZE_TYPE.AnyL
		Vector2(96,96): sizeType = SIZE_TYPE.AnyXL
		_: sizeType = SIZE_TYPE.ANY; size = parent.size
	getSizeFromSizeType()
	queue_redraw()

func changedValue(property:StringName, _value:Variant) -> void:
	if property == &"count" and parent.type == Door.DOOR_TYPE.SIMPLE:
		simpleDoorUpdate()
