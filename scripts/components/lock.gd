extends GameComponent
class_name Lock

const TYPES:int = 5
enum TYPE {NORMAL, BLANK, BLAST, ALL, EXACT}
enum SIZE_TYPE {AnyS, AnyH, AnyV, AnyM, AnyL, AnyXL, ANY}
const SIZES:Array[Vector2] = [Vector2(18,18), Vector2(50,18), Vector2(18,50), Vector2(38,38), Vector2(50,50), Vector2(82,82)]
enum CONFIGURATION {spr1A, spr2H, spr2V, spr3H, spr3V, spr4A, spr4B, spr5A, spr5B, spr6A, spr6B, spr8A, spr12A, spr24A, NONE}

func getAvailableConfigurations() -> Array[Array]:
	# returns Array[Array[SIZE_TYPE, CONFIGURATION]]
	# SpecificA/H first, then SpecificB/V
	var available:Array[Array] = []
	if type != TYPE.NORMAL and type != TYPE.EXACT: return available
	if count.isNonzeroReal():
		if count.r.abs().eq(1): available.append([SIZE_TYPE.AnyS, CONFIGURATION.spr1A])
		elif count.r.abs().eq(2): available.append([SIZE_TYPE.AnyH, CONFIGURATION.spr2H]); available.append([SIZE_TYPE.AnyV, CONFIGURATION.spr2V])
		elif count.r.abs().eq(3): available.append([SIZE_TYPE.AnyH, CONFIGURATION.spr3H]); available.append([SIZE_TYPE.AnyV, CONFIGURATION.spr3V])
		elif count.r.abs().eq(4): available.append([SIZE_TYPE.AnyM, CONFIGURATION.spr4A]); available.append([SIZE_TYPE.AnyL, CONFIGURATION.spr4B])
		elif count.r.abs().eq(5): available.append([SIZE_TYPE.AnyM, CONFIGURATION.spr5A]); available.append([SIZE_TYPE.AnyL, CONFIGURATION.spr5B])
		elif count.r.abs().eq(6): available.append([SIZE_TYPE.AnyM, CONFIGURATION.spr6A]); available.append([SIZE_TYPE.AnyL, CONFIGURATION.spr6B])
		elif count.r.abs().eq(8): available.append([SIZE_TYPE.AnyL, CONFIGURATION.spr8A])
		elif count.r.abs().eq(12): available.append([SIZE_TYPE.AnyL, CONFIGURATION.spr12A])
		elif count.r.abs().eq(24): available.append([SIZE_TYPE.AnyXL, CONFIGURATION.spr24A])
	elif count.isNonzeroImag():
		if count.i.abs().eq(1): available.append([SIZE_TYPE.AnyS, CONFIGURATION.spr1A])
		elif count.i.abs().eq(2): available.append([SIZE_TYPE.AnyH, CONFIGURATION.spr2H]); available.append([SIZE_TYPE.AnyV, CONFIGURATION.spr2V])
		elif count.i.abs().eq(3): available.append([SIZE_TYPE.AnyH, CONFIGURATION.spr3H]); available.append([SIZE_TYPE.AnyV, CONFIGURATION.spr3V])
	return available

const ANY_RECT:Rect2 = Rect2(Vector2.ZERO,Vector2(50,50)) # rect of ANY
const CORNER_SIZE:Vector2 = Vector2(2,2) # size of ANY's corners
const TILE:RenderingServer.NinePatchAxisMode = RenderingServer.NinePatchAxisMode.NINE_PATCH_TILE # just to save characters
const STRETCH:RenderingServer.NinePatchAxisMode = RenderingServer.NinePatchAxisMode.NINE_PATCH_STRETCH # just to save characters

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
	preload("res://assets/game/lock/predefined/1Aimaginary.png"), preload("res://assets/game/lock/predefined/1Aexacti.png"),
	preload("res://assets/game/lock/predefined/2Himaginary.png"), preload("res://assets/game/lock/predefined/2Hexacti.png"),
	preload("res://assets/game/lock/predefined/2Vimaginary.png"), preload("res://assets/game/lock/predefined/2Vexacti.png"),
	preload("res://assets/game/lock/predefined/3Himaginary.png"), preload("res://assets/game/lock/predefined/3Hexacti.png"),
	preload("res://assets/game/lock/predefined/3Vimaginary.png"), preload("res://assets/game/lock/predefined/3Vexacti.png"),
]
func getPredefinedLockSprite() -> Texture2D:
	if count.isNonzeroImag(): return PREDEFINED_LOCK_SPRITE_IMAGINARY[configuration*2+int(type==TYPE.EXACT)]
	else: return PREDEFINED_LOCK_SPRITE_NORMAL[configuration*2+int(type==TYPE.EXACT)]

const LOCK_FRAME:Array[Texture2D] = [
	preload("res://assets/game/lock/frame/AnySnormal.png"), preload("res://assets/game/lock/frame/AnySnegative.png"),
	preload("res://assets/game/lock/frame/AnyHnormal.png"), preload("res://assets/game/lock/frame/AnyHnegative.png"),
	preload("res://assets/game/lock/frame/AnyVnormal.png"), preload("res://assets/game/lock/frame/AnyVnegative.png"),
	preload("res://assets/game/lock/frame/AnyMnormal.png"), preload("res://assets/game/lock/frame/AnyMnegative.png"),
	preload("res://assets/game/lock/frame/AnyLnormal.png"), preload("res://assets/game/lock/frame/AnyLnegative.png"),
	preload("res://assets/game/lock/frame/AnyXLnormal.png"), preload("res://assets/game/lock/frame/AnyXLnegative.png"),
	preload("res://assets/game/lock/frame/ANYnormal.png"), preload("res://assets/game/lock/frame/ANYnegative.png"),
]
func getLockFrameSprite() -> Texture2D: return LOCK_FRAME[sizeType*2+int(count.sign()<0)]

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
const SYMBOL_BLAST = preload("res://assets/game/lock/symbols/blast.png")
const SYMBOL_BLASTI = preload("res://assets/game/lock/symbols/blasti.png")
const SYMBOL_EXACT = preload("res://assets/game/lock/symbols/exact.png")
const SYMBOL_EXACTI = preload("res://assets/game/lock/symbols/exacti.png")
const SYMBOL_ALL = preload("res://assets/game/lock/symbols/all.png")
const SYMBOL_SIZE:Vector2 = Vector2(32,32)

func getOffset() -> Vector2:
	match sizeType:
		SIZE_TYPE.AnyM: return Vector2(3, 3)
		_: return Vector2(-7, -7)

const CREATE_PARAMETERS:Array[StringName] = [
	&"position", &"parentId"
]
const EDITOR_PROPERTIES:Array[StringName] = [
	&"id", &"position", &"size",
	&"parentId", &"color", &"type", &"configuration", &"sizeType", &"count",
	&"index" # implciit
]

var parent:Door
var parentId:int
var color:Game.COLOR = Game.COLOR.WHITE
var type:TYPE = TYPE.NORMAL
var configuration:CONFIGURATION = CONFIGURATION.spr1A
var sizeType:SIZE_TYPE = SIZE_TYPE.AnyS
var count:C = C.new(1)
var index:int

var drawGlitch:RID
var drawScaled:RID
var drawMain:RID

func getConfigurationColor() -> Color:
	if count.sign() < 0: return Color("#ebdfd3")
	else: return Color("#2c2014")

func _init(_parent:Door, _index:int) -> void:
	parent = _parent
	index = _index
	size = Vector2(18,18)

func _ready() -> void:
	drawGlitch = RenderingServer.canvas_item_create()
	drawScaled = RenderingServer.canvas_item_create()
	drawMain = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_material(drawGlitch,Game.GLITCH_MATERIAL.get_rid())
	RenderingServer.canvas_item_set_parent(drawGlitch,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawScaled,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawMain,get_canvas_item())
	game.connect(&"goldIndexChanged",queue_redraw)

func _draw() -> void:
	RenderingServer.canvas_item_clear(drawGlitch)
	RenderingServer.canvas_item_clear(drawScaled)
	RenderingServer.canvas_item_clear(drawMain)
	if !parent.active and game.playState == Game.PLAY_STATE.PLAY: return
	var rect:Rect2 = Rect2(-getOffset(), size)
	# fill
	if parent.animState != Door.ANIM_STATE.RELOCK or parent.animPart > 2:
		var texture:Texture2D
		var tileTexture:bool = false
		match baseColor():
			Game.COLOR.MASTER: texture = game.masterTex()
			Game.COLOR.PURE: texture = game.pureTex()
			Game.COLOR.STONE: texture = game.stoneTex()
			Game.COLOR.DYNAMITE: texture = game.dynamiteTex(); tileTexture = true
			Game.COLOR.QUICKSILVER: texture = game.quicksilverTex()
		if texture:
			if !tileTexture:
				RenderingServer.canvas_item_set_material(drawScaled,Game.PIXELATED_MATERIAL.get_rid())
				RenderingServer.canvas_item_set_instance_shader_parameter(drawScaled, &"size", size)
			RenderingServer.canvas_item_add_texture_rect(drawScaled,rect,texture,tileTexture)
		elif baseColor() == Game.COLOR.GLITCH:
			if sizeType == SIZE_TYPE.ANY: RenderingServer.canvas_item_add_nine_patch(drawGlitch,rect,ANY_RECT,getLockFillSprite(),CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,Game.mainTone[color])
			else: RenderingServer.canvas_item_add_texture_rect(drawGlitch,rect,getLockFillSprite(),false,Game.mainTone[baseColor()])
		else:
			if sizeType == SIZE_TYPE.ANY: RenderingServer.canvas_item_add_nine_patch(drawMain,rect,ANY_RECT,getLockFillSprite(),CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,Game.mainTone[color])
			else: RenderingServer.canvas_item_add_texture_rect(drawMain,rect,getLockFillSprite(),false,Game.mainTone[baseColor()])
	# frame
	if sizeType == SIZE_TYPE.ANY: RenderingServer.canvas_item_add_nine_patch(drawMain,rect,ANY_RECT,getLockFrameSprite(),CORNER_SIZE,CORNER_SIZE)
	else: RenderingServer.canvas_item_add_texture_rect(drawMain,rect,getLockFrameSprite())
	# configuration
	if configuration == CONFIGURATION.NONE:
		match type:
			TYPE.NORMAL,TYPE.EXACT:
				var string:String = str(count.abs())
				if string == "1": string = ""
				if count.isNonzeroImag() && type == TYPE.NORMAL: string += "i"
				var lockOffsetX:float = 0
				var showLock:bool = type == TYPE.EXACT || (!count.isNonzeroImag() && (size != Vector2(18,18) || string == ""))
				if type == TYPE.EXACT and !showLock: string = "=" + string
				var vertical:bool = size.x == 18 && size.y != 18 && string != ""

				var symbolLast:bool = type == TYPE.EXACT and count.isNonzeroImag() and !vertical
				if showLock and !vertical:
					if type == TYPE.EXACT:
						if symbolLast: lockOffsetX = 6
						else: lockOffsetX = 12
					else: lockOffsetX = 14

				var strWidth:float = Game.FTALK.get_string_size(string,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x + lockOffsetX

				var startX:int = round((size.x - strWidth)/2)
				var startY:int = round((size.y+14)/2)
				if showLock and vertical: startY -= 8
				@warning_ignore("integer_division")
				if showLock:
					var lockRect:Rect2
					if vertical:
						var lockStartX:int = round((size.x - lockOffsetX)/2)
						lockRect = Rect2(Vector2(lockStartX+lockOffsetX/2,size.y/2+11)-SYMBOL_SIZE/2-getOffset(),Vector2(32,32))
					elif symbolLast: lockRect = Rect2(Vector2(startX+strWidth-lockOffsetX/2,size.y/2)-SYMBOL_SIZE/2-getOffset(),Vector2(32,32))
					else: lockRect = Rect2(Vector2(startX+lockOffsetX/2,size.y/2)-SYMBOL_SIZE/2-getOffset(),Vector2(32,32))
					var lockSymbol:Texture2D
					if type == TYPE.NORMAL: lockSymbol = SYMBOL_NORMAL
					elif count.isNonzeroImag(): lockSymbol = SYMBOL_EXACTI
					else: lockSymbol = SYMBOL_EXACT
					RenderingServer.canvas_item_add_texture_rect(drawMain,lockRect,lockSymbol,false,getConfigurationColor())
				if symbolLast: Game.FTALK.draw_string(drawMain,Vector2(startX,startY)-getOffset(),string,HORIZONTAL_ALIGNMENT_LEFT,-1,12,getConfigurationColor())
				else: Game.FTALK.draw_string(drawMain,Vector2(startX+lockOffsetX,startY)-getOffset(),string,HORIZONTAL_ALIGNMENT_LEFT,-1,12,getConfigurationColor())
			TYPE.BLANK: pass # nothing really
			TYPE.BLAST:
				var symbolRect:Rect2 = Rect2(Vector2((size-SYMBOL_SIZE)/2)-getOffset(),SYMBOL_SIZE)
				if count.isNonzeroReal(): RenderingServer.canvas_item_add_texture_rect(drawMain,symbolRect,SYMBOL_BLAST,false,getConfigurationColor())
				else: RenderingServer.canvas_item_add_texture_rect(drawMain,symbolRect,SYMBOL_BLASTI,false,getConfigurationColor())
			TYPE.ALL:
				var symbolRect:Rect2 = Rect2(Vector2((size-SYMBOL_SIZE)/2)-getOffset(),SYMBOL_SIZE)
				RenderingServer.canvas_item_add_texture_rect(drawMain,symbolRect,SYMBOL_ALL,false,getConfigurationColor())
	else: RenderingServer.canvas_item_add_texture_rect(drawMain,rect,getPredefinedLockSprite(),false,getConfigurationColor())

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
	changes.addChange(Changes.PropertyChange.new(game,self,&"position",Vector2.ZERO))
	changes.addChange(Changes.PropertyChange.new(game,self,&"sizeType",newSizeType))
	changes.addChange(Changes.PropertyChange.new(game,self,&"size",parent.size - Vector2(14,14)))
	queue_redraw()

func _comboDoorConfigurationChanged(newSizeType:SIZE_TYPE,newConfiguration:CONFIGURATION=CONFIGURATION.NONE) -> void:
	changes.addChange(Changes.PropertyChange.new(game,self,&"sizeType",newSizeType))
	changes.addChange(Changes.PropertyChange.new(game,self,&"configuration",newConfiguration))
	var newSize:Vector2
	match sizeType:
		SIZE_TYPE.AnyS: newSize = Vector2(18,18)
		SIZE_TYPE.AnyH: newSize = Vector2(50,18)
		SIZE_TYPE.AnyV: newSize = Vector2(18,50)
		SIZE_TYPE.AnyM: newSize = Vector2(38,38)
		SIZE_TYPE.AnyL: newSize = Vector2(50,50)
		SIZE_TYPE.AnyXL: newSize = Vector2(82,82)
	if newSize: changes.addChange(Changes.PropertyChange.new(game,self,&"size",newSize))
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
	changes.addChange(Changes.PropertyChange.new(game,self,&"sizeType",newSizeType))
	changes.addChange(Changes.PropertyChange.new(game,self,&"configuration",CONFIGURATION.NONE))
	
func _setAutoConfiguration() -> void:
	var newConfiguration:CONFIGURATION = CONFIGURATION.NONE
	for option in getAvailableConfigurations():
		if sizeType == option[0]:
			newConfiguration = option[1]
			break
	changes.addChange(Changes.PropertyChange.new(game,self,&"configuration",newConfiguration))

func _setType(newType:TYPE):
	changes.addChange(Changes.PropertyChange.new(game,self,&"type",newType))
	if type == TYPE.BLANK:
		changes.addChange(Changes.PropertyChange.new(game,self,&"count",C.new(1)))
		parent.queue_redraw()

func receiveMouseInput(event:InputEventMouse) -> bool:
	# resizing
	if editor.componentDragged: return false
	if !Rect2(position-getOffset(),size).has_point(editor.mouseWorldPosition - parent.position) : return false
	var dragCornerSize:Vector2 = Vector2(8,8)/editor.cameraZoom
	var diffSign:Vector2 = Editor.rectSign(Rect2(position+dragCornerSize-getOffset(),size-dragCornerSize*2), editor.mouseWorldPosition-parent.position)
	var dragPivot:Editor.SIZE_DRAG_PIVOT = Editor.SIZE_DRAG_PIVOT.NONE
	match diffSign:
		Vector2(-1,-1): dragPivot = Editor.SIZE_DRAG_PIVOT.TOP_LEFT;	editor.mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
		Vector2(0,-1): dragPivot = Editor.SIZE_DRAG_PIVOT.TOP;			editor.mouse_default_cursor_shape = Control.CURSOR_VSIZE
		Vector2(1,-1): dragPivot = Editor.SIZE_DRAG_PIVOT.TOP_RIGHT;	editor.mouse_default_cursor_shape = Control.CURSOR_BDIAGSIZE
		Vector2(-1,0): dragPivot = Editor.SIZE_DRAG_PIVOT.LEFT;			editor.mouse_default_cursor_shape = Control.CURSOR_HSIZE
		Vector2(1,0): dragPivot = Editor.SIZE_DRAG_PIVOT.RIGHT;			editor.mouse_default_cursor_shape = Control.CURSOR_HSIZE
		Vector2(-1,1): dragPivot = Editor.SIZE_DRAG_PIVOT.BOTTOM_LEFT;	editor.mouse_default_cursor_shape = Control.CURSOR_BDIAGSIZE
		Vector2(0,1): dragPivot = Editor.SIZE_DRAG_PIVOT.BOTTOM;		editor.mouse_default_cursor_shape = Control.CURSOR_VSIZE
		Vector2(1,1): dragPivot = Editor.SIZE_DRAG_PIVOT.BOTTOM_RIGHT;	editor.mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
	if dragPivot != Editor.SIZE_DRAG_PIVOT.NONE and Editor.isLeftClick(event):
		editor.startSizeDrag(self, dragPivot)
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
	changes.addChange(Changes.PropertyChange.new(game,self,&"size",newSize))

func propertyChangedInit(property:StringName) -> void:
	if parent.type != Door.TYPE.SIMPLE:
		if property == &"size": _comboDoorSizeChanged()
	if property == &"count" or property == &"sizeType" or property == &"type": _setAutoConfiguration()

func effectiveColor() -> Game.COLOR: # for calculations
	if parent.cursed and parent.curseColor != Game.COLOR.PURE: return parent.curseColor
	return color

func baseColor() -> Game.COLOR: # for drawing
	if parent.cursed and parent.curseColor != Game.COLOR.PURE: return parent.curseColor
	return color

# ==== PLAY ==== #
func canOpen(player:Player) -> bool:
	match type:
		TYPE.NORMAL: return !player.key[effectiveColor()].across(count.axis()).reduce().lt(count.abs())
		TYPE.BLANK: return player.key[effectiveColor()].eq(0)
		TYPE.BLAST:
			return player.key[effectiveColor()].axis().across(count.axis()).reduce().gt(0)
		TYPE.ALL: return player.key[effectiveColor()].neq(0)
		TYPE.EXACT: return player.key[effectiveColor()].across(count.axibs()).eq(count)
		_: return true

func getCost(player:Player) -> C:
	match type:
		TYPE.NORMAL, TYPE.EXACT: return count
		TYPE.BLAST: return player.key[effectiveColor()].across(count.axibs())
		TYPE.ALL: return player.key[effectiveColor()]
		_: return C.ZERO
