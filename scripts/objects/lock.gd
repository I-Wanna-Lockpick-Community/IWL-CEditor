extends GameComponent
class_name Lock

enum SIZE_TYPE {AnyS, AnyH, AnyV, AnyM, AnyL, AnyXL, ANY}
enum CONFIGURATION {spr1A, spr2H, spr2V, spr3H, spr3V, spr4A, spr4B, spr5A, spr5B, spr6A, spr6B, spr8A, spr12A, spr24A, NONE}

func getAvailableConfigurations() -> Array[Array]:
	# returns Array[Array[SIZE_TYPE, CONFIGURATION]]
	# SpecificA/H first, then SpecificB/V
	var available:Array[Array] = []
	if type != Game.LOCK.NORMAL and type != Game.LOCK.EXACT: return available
	if count.isNonzeroReal():
		if count.r.eq(1): available.append([SIZE_TYPE.AnyS, CONFIGURATION.spr1A])
		elif count.r.eq(2): available.append([SIZE_TYPE.AnyH, CONFIGURATION.spr2H]); available.append([SIZE_TYPE.AnyV, CONFIGURATION.spr2V])
		elif count.r.eq(3): available.append([SIZE_TYPE.AnyH, CONFIGURATION.spr3H]); available.append([SIZE_TYPE.AnyV, CONFIGURATION.spr3V])
		elif count.r.eq(4): available.append([SIZE_TYPE.AnyM, CONFIGURATION.spr4A]); available.append([SIZE_TYPE.AnyL, CONFIGURATION.spr4B])
		elif count.r.eq(5): available.append([SIZE_TYPE.AnyM, CONFIGURATION.spr5A]); available.append([SIZE_TYPE.AnyL, CONFIGURATION.spr5B])
		elif count.r.eq(6): available.append([SIZE_TYPE.AnyM, CONFIGURATION.spr6A]); available.append([SIZE_TYPE.AnyL, CONFIGURATION.spr6B])
		elif count.r.eq(8): available.append([SIZE_TYPE.AnyL, CONFIGURATION.spr8A])
		elif count.r.eq(12): available.append([SIZE_TYPE.AnyL, CONFIGURATION.spr12A])
		elif count.r.eq(24): available.append([SIZE_TYPE.AnyXL, CONFIGURATION.spr24A])
	elif count.isNonzeroImag():
		if count.i.eq(1): available.append([SIZE_TYPE.AnyS, CONFIGURATION.spr1A])
		elif count.i.eq(2): available.append([SIZE_TYPE.AnyH, CONFIGURATION.spr2H]); available.append([SIZE_TYPE.AnyV, CONFIGURATION.spr2V])
		elif count.i.eq(3): available.append([SIZE_TYPE.AnyH, CONFIGURATION.spr3H]); available.append([SIZE_TYPE.AnyV, CONFIGURATION.spr3V])
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
	if count.isNonzeroImag(): return PREDEFINED_LOCK_SPRITE_IMAGINARY[configuration*2+int(type==Game.LOCK.EXACT)]
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

var id:int
var parent:Door
var doorId:int
var color:Game.COLOR = Game.COLOR.WHITE
var type:Game.LOCK = Game.LOCK.NORMAL
var configuration:CONFIGURATION = CONFIGURATION.spr1A
var sizeType:SIZE_TYPE = SIZE_TYPE.AnyS
var count:C = C.new(1)
var index:int

var drawGlitch:RID
var drawScaled:RID
var drawMain:RID

const COLOR:Color = Color("#2c2014")
const NEGATIVE_COLOR:Color = Color("#ebdfd3")

func _init(_parent:Door, _index:int) -> void:
	parent = _parent
	index = _index
	size = Vector2(18,18)

func _ready() -> void:
	drawGlitch = RenderingServer.canvas_item_create()
	drawScaled = RenderingServer.canvas_item_create()
	drawMain = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_material(drawGlitch,Game.GLITCH_MATERIAL.get_rid())
	RenderingServer.canvas_item_set_material(drawScaled,Game.PIXELATED_MATERIAL.get_rid())
	RenderingServer.canvas_item_set_parent(drawGlitch,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawScaled,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawMain,get_canvas_item())
	editor.game.connect(&"goldIndexChanged",queue_redraw)

func _draw() -> void:
	RenderingServer.canvas_item_clear(drawGlitch)
	RenderingServer.canvas_item_clear(drawScaled)
	RenderingServer.canvas_item_clear(drawMain)
	RenderingServer.canvas_item_set_instance_shader_parameter(drawScaled, &"size", size)
	var rect:Rect2 = Rect2(-getOffset(), size)
	# fill
	var texture:Texture2D
	var tileTexture:bool = false
	match color:
		Game.COLOR.MASTER: texture = editor.game.masterTex()
		Game.COLOR.PURE: texture = editor.game.pureTex()
		Game.COLOR.STONE: texture = editor.game.stoneTex()
		Game.COLOR.DYNAMITE: texture = editor.game.dynamiteTex(); tileTexture = true
		Game.COLOR.QUICKSILVER: texture = editor.game.quicksilverTex()
	if texture:
		RenderingServer.canvas_item_add_texture_rect(drawScaled,rect,texture,tileTexture)
	elif color == Game.COLOR.GLITCH:
		if sizeType == SIZE_TYPE.ANY: RenderingServer.canvas_item_add_nine_patch(drawGlitch,rect,ANY_RECT,getLockFillSprite(),CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,Game.mainTone[color])
		else: RenderingServer.canvas_item_add_texture_rect(drawGlitch,rect,getLockFillSprite(),false,Game.mainTone[color])
	else:
		if sizeType == SIZE_TYPE.ANY: RenderingServer.canvas_item_add_nine_patch(drawMain,rect,ANY_RECT,getLockFillSprite(),CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,Game.mainTone[color])
		else: RenderingServer.canvas_item_add_texture_rect(drawMain,rect,getLockFillSprite(),false,Game.mainTone[color])
	# frame
	if sizeType == SIZE_TYPE.ANY: RenderingServer.canvas_item_add_nine_patch(drawMain,rect,ANY_RECT,getLockFrameSprite(),CORNER_SIZE,CORNER_SIZE)
	else: RenderingServer.canvas_item_add_texture_rect(drawMain,rect,getLockFrameSprite())
	# configuration
	if configuration == CONFIGURATION.NONE:
		var string:String = str(count)
		if string == "1": string = ""
		var lockOffsetX:float = 0
		var showLock:bool = size != Vector2(18,18) || string == ""
		var vertical:bool = size.x == 18 && size.y != 18 && string != ""
		if showLock and !vertical: lockOffsetX = 14
		var strWidth:float = Game.FTALK.get_string_size(string,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x + lockOffsetX
		var startX:int = round((size.x - strWidth)/2);
		var startY:int = round((size.y+14)/2);
		if showLock and vertical: startY -= 8;
		@warning_ignore("integer_division")
		if showLock:
			var lockRect:Rect2
			if vertical:
				var lockStartX:int = round((size.x - lockOffsetX)/2);
				lockRect = Rect2(Vector2(lockStartX+lockOffsetX/2,size.y/2+11)-SYMBOL_SIZE/2-getOffset(),Vector2(32,32))
			else: lockRect = Rect2(Vector2(startX+lockOffsetX/2,size.y/2)-SYMBOL_SIZE/2-getOffset(),Vector2(32,32))
			RenderingServer.canvas_item_add_texture_rect(drawMain,lockRect,SYMBOL_NORMAL,false,COLOR)
		Game.FTALK.draw_string(drawMain,Vector2(startX+lockOffsetX,startY)-getOffset(),string,HORIZONTAL_ALIGNMENT_LEFT,-1,12,COLOR)
	else: RenderingServer.canvas_item_add_texture_rect(drawMain,rect,getPredefinedLockSprite(),false,COLOR)

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
	editor.changes.addChange(Changes.PropertyChange.new(editor.game,self,&"position",Vector2.ZERO))
	editor.changes.addChange(Changes.PropertyChange.new(editor.game,self,&"sizeType",newSizeType))
	editor.changes.addChange(Changes.PropertyChange.new(editor.game,self,&"size",parent.size - Vector2(14,14)))
	_setAutoConfiguration()
	queue_redraw()

func _comboDoorConfigurationChanged(newSizeType:SIZE_TYPE,newConfiguration:CONFIGURATION=CONFIGURATION.NONE) -> void:
	editor.changes.addChange(Changes.PropertyChange.new(editor.game,self,&"sizeType",newSizeType))
	editor.changes.addChange(Changes.PropertyChange.new(editor.game,self,&"configuration",newConfiguration))
	var newSize:Vector2
	match sizeType:
		SIZE_TYPE.AnyS: newSize = Vector2(18,18)
		SIZE_TYPE.AnyH: newSize = Vector2(50,18)
		SIZE_TYPE.AnyV: newSize = Vector2(18,50)
		SIZE_TYPE.AnyM: newSize = Vector2(38,38)
		SIZE_TYPE.AnyL: newSize = Vector2(50,50)
		SIZE_TYPE.AnyXL: newSize = Vector2(82,82)
	if newSize: editor.changes.addChange(Changes.PropertyChange.new(editor.game,self,&"size",newSize))
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
	editor.focusDialog.lockConfigurationSelector.setSelect(newSizeType+ConfigurationSelector.OPTION.AnyS)
	editor.changes.addChange(Changes.PropertyChange.new(editor.game,self,&"sizeType",newSizeType))
	editor.changes.addChange(Changes.PropertyChange.new(editor.game,self,&"configuration",CONFIGURATION.NONE))
	_setAutoConfiguration()
	
func _setAutoConfiguration() -> void:
	var newConfiguration:CONFIGURATION = CONFIGURATION.NONE
	for option in getAvailableConfigurations():
		if sizeType == option[0]:
			newConfiguration = option[1]
			break
	editor.changes.addChange(Changes.PropertyChange.new(editor.game,self,&"configuration",newConfiguration))

func receiveMouseInput(event:InputEventMouse) -> bool:
	# resizing
	if editor.componentDragged: return false
	if !Rect2(position-getOffset(),size).has_point(editor.mouseWorldPosition - parent.position) : return false
	var dragCornerSize:Vector2 = Vector2(8,8)/editor.game.editorCamera.zoom
	var diffSign:Vector2 = Editor.rectSign(Rect2(position+dragCornerSize-getOffset(),size-dragCornerSize*2), editor.mouseWorldPosition-parent.position)
	var dragPivot:Editor.SIZE_DRAG_PIVOT = Editor.SIZE_DRAG_PIVOT.NONE
	match diffSign:
		Vector2(-1,-1): dragPivot = Editor.SIZE_DRAG_PIVOT.TOP_LEFT;	DisplayServer.cursor_set_shape(DisplayServer.CURSOR_FDIAGSIZE)
		Vector2(0,-1): dragPivot = Editor.SIZE_DRAG_PIVOT.TOP;			DisplayServer.cursor_set_shape(DisplayServer.CURSOR_VSIZE)
		Vector2(1,-1): dragPivot = Editor.SIZE_DRAG_PIVOT.TOP_RIGHT;	DisplayServer.cursor_set_shape(DisplayServer.CURSOR_BDIAGSIZE)
		Vector2(-1,0): dragPivot = Editor.SIZE_DRAG_PIVOT.LEFT;			DisplayServer.cursor_set_shape(DisplayServer.CURSOR_HSIZE)
		Vector2(1,0): dragPivot = Editor.SIZE_DRAG_PIVOT.RIGHT;			DisplayServer.cursor_set_shape(DisplayServer.CURSOR_HSIZE)
		Vector2(-1,1): dragPivot = Editor.SIZE_DRAG_PIVOT.BOTTOM_LEFT;	DisplayServer.cursor_set_shape(DisplayServer.CURSOR_BDIAGSIZE)
		Vector2(0,1): dragPivot = Editor.SIZE_DRAG_PIVOT.BOTTOM;		DisplayServer.cursor_set_shape(DisplayServer.CURSOR_VSIZE)
		Vector2(1,1): dragPivot = Editor.SIZE_DRAG_PIVOT.BOTTOM_RIGHT;	DisplayServer.cursor_set_shape(DisplayServer.CURSOR_FDIAGSIZE)
	if dragPivot != Editor.SIZE_DRAG_PIVOT.NONE and Editor.isLeftClick(event):
		editor.startSizeDrag(self, dragPivot)
		return true
	return false
