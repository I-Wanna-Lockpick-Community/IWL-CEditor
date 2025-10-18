extends GameObject
class_name Door

enum TYPE {SIMPLE, COMBO, GATE}

const FRAME:Texture2D = preload("res://assets/game/door/frame.png")
const FRAME_NEGATIVE:Texture2D = preload("res://assets/game/door/frameNegative.png")
const SPEND_HIGH:Texture2D = preload("res://assets/game/door/spendHigh.png")
const SPEND_MAIN:Texture2D = preload("res://assets/game/door/spendMain.png")
const SPEND_DARK:Texture2D = preload("res://assets/game/door/spendDark.png")

const TEXTURE_RECT:Rect2 = Rect2(Vector2.ZERO,Vector2(64,64)) # size of all the door textures
const CORNER_SIZE:Vector2 = Vector2(9,9) # size of door ninepatch corners
const TILE:RenderingServer.NinePatchAxisMode = RenderingServer.NinePatchAxisMode.NINE_PATCH_TILE # just to save characters

const CREATE_PARAMETERS:Array[StringName] = [
	&"position"
]
const EDITOR_PROPERTIES:Array[StringName] = [
	&"id", &"position", &"size",
	&"colorSpend", &"copies", &"type"
]

var colorSpend:Game.COLOR = Game.COLOR.WHITE
var copies:C = C.new(1)
var type:TYPE = TYPE.SIMPLE

var drawScaled:RID
var drawMain:RID
var drawGlitch:RID
var drawCopies:RID

var locks:Array[Lock] = []

const COPIES_COLOR = Color("#edeae7")
const COPIES_OUTLINE_COLOR = Color("#3e2d1c")

func _init() -> void: size = Vector2(32,32)

func _ready() -> void:
	drawScaled = RenderingServer.canvas_item_create()
	drawMain = RenderingServer.canvas_item_create()
	drawGlitch = RenderingServer.canvas_item_create()
	drawCopies = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_material(drawScaled,Game.PIXELATED_MATERIAL.get_rid())
	RenderingServer.canvas_item_set_material(drawGlitch,Game.GLITCH_MATERIAL.get_rid())
	RenderingServer.canvas_item_set_parent(drawScaled,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawMain,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawGlitch,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawCopies,get_canvas_item())
	editor.game.connect(&"goldIndexChanged",queue_redraw)

func _draw() -> void:
	RenderingServer.canvas_item_clear(drawScaled)
	RenderingServer.canvas_item_clear(drawMain)
	RenderingServer.canvas_item_clear(drawGlitch)
	RenderingServer.canvas_item_clear(drawCopies)
	RenderingServer.canvas_item_set_instance_shader_parameter(drawScaled, &"size", size)
	var rect:Rect2 = Rect2(Vector2.ZERO, size)
	# fill
	var texture:Texture2D
	var tileTexture:bool = false
	match colorSpend:
		Game.COLOR.MASTER: texture = editor.game.masterTex()
		Game.COLOR.PURE: texture = editor.game.pureTex()
		Game.COLOR.STONE: texture = editor.game.stoneTex()
		Game.COLOR.DYNAMITE: texture = editor.game.dynamiteTex(); tileTexture = true
		Game.COLOR.QUICKSILVER: texture = editor.game.quicksilverTex()
	if texture:
		if tileTexture: RenderingServer.canvas_item_add_texture_rect(drawMain,rect,texture,true)
		else: RenderingServer.canvas_item_add_texture_rect(drawScaled,rect,texture)
	elif colorSpend == Game.COLOR.GLITCH:
		RenderingServer.canvas_item_add_nine_patch(drawGlitch,rect,TEXTURE_RECT,SPEND_HIGH,CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,Game.highTone[Game.COLOR.GLITCH])
		RenderingServer.canvas_item_add_nine_patch(drawGlitch,rect,TEXTURE_RECT,SPEND_MAIN,CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,Game.mainTone[Game.COLOR.GLITCH])
		RenderingServer.canvas_item_add_nine_patch(drawGlitch,rect,TEXTURE_RECT,SPEND_DARK,CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,Game.darkTone[Game.COLOR.GLITCH])
	else:
		RenderingServer.canvas_item_add_nine_patch(drawMain,rect,TEXTURE_RECT,SPEND_HIGH,CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,Game.highTone[colorSpend])
		RenderingServer.canvas_item_add_nine_patch(drawMain,rect,TEXTURE_RECT,SPEND_MAIN,CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,Game.mainTone[colorSpend])
		RenderingServer.canvas_item_add_nine_patch(drawMain,rect,TEXTURE_RECT,SPEND_DARK,CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,Game.darkTone[colorSpend])
	# frame
	if len(locks) > 0 and type == TYPE.SIMPLE and locks[0].count.sign() < 0: RenderingServer.canvas_item_add_nine_patch(drawMain,rect,TEXTURE_RECT,FRAME_NEGATIVE,CORNER_SIZE,CORNER_SIZE)
	else: RenderingServer.canvas_item_add_nine_patch(drawMain,rect,TEXTURE_RECT,FRAME,CORNER_SIZE,CORNER_SIZE)
	# copies
	if !copies.eq(1): TextDraw.outlinedCentered(Game.FKEYX,drawCopies,"×"+str(copies),COPIES_COLOR,COPIES_OUTLINE_COLOR,25,Vector2(size.x/2,1))
	# locks

func receiveMouseInput(event:InputEventMouse) -> bool:
	# resizing
	if editor.componentDragged: return false
	var dragCornerSize:Vector2 = Vector2(8,8)/editor.game.editorCamera.zoom
	var diffSign:Vector2 = Editor.rectSign(Rect2(position+dragCornerSize,size-dragCornerSize*2), editor.mouseWorldPosition)
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
