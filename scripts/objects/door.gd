extends GameObject
class_name Door

enum DOOR_TYPE {SIMPLE, COMBO, GATE}

const FRAME:Texture2D = preload("res://assets/game/door/frame.png")
const SPEND_HIGH:Texture2D = preload("res://assets/game/door/spendHigh.png")
const SPEND_MAIN:Texture2D = preload("res://assets/game/door/spendMain.png")
const SPEND_DARK:Texture2D = preload("res://assets/game/door/spendDark.png")

const TEXTURE_RECT:Rect2 = Rect2(Vector2.ZERO,Vector2(64,64)) # size of all the door textures
const CORNER_SIZE:Vector2 = Vector2(9,9) # size of door ninepatch corners
const TILE:RenderingServer.NinePatchAxisMode = RenderingServer.NinePatchAxisMode.NINE_PATCH_TILE # just to save characters

var id:int
var colorSpend:Game.COLOR = Game.COLOR.WHITE
var copies:C = C.new(1)
var type:DOOR_TYPE = DOOR_TYPE.SIMPLE

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
	locks.append(editor.game.locks[editor.changes.addChange(Changes.CreateLockChange.new(editor.game,Vector2i.ZERO,id)).id])
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
	RenderingServer.canvas_item_add_nine_patch(drawMain,rect,TEXTURE_RECT,FRAME,CORNER_SIZE,CORNER_SIZE)
	# copies
	if !copies.eq(1): TextDraw.outlinedCentered(Game.FKEYX,drawCopies,"×"+str(copies),COPIES_COLOR,COPIES_OUTLINE_COLOR,25,Vector2(size.x/2,1))
	# locks

func receiveMouseInput(event:InputEventMouse) -> bool:
	# resizing
	if editor.objectDragged: return false
	var dragCornerSize:Vector2 = Vector2(8,8)/editor.game.editorCamera.zoom
	if Rect2(position+size-dragCornerSize,dragCornerSize).has_point(editor.mouseWorldPosition): # bottom right
		DisplayServer.cursor_set_shape(DisplayServer.CURSOR_FDIAGSIZE)
		if Editor.isLeftClick(event): editor.startSizeDrag(self,Editor.SIZE_DRAG_PIVOT.BOTTOM_RIGHT); return true
	elif Rect2(position,dragCornerSize).has_point(editor.mouseWorldPosition): # top left
		DisplayServer.cursor_set_shape(DisplayServer.CURSOR_FDIAGSIZE)
		if Editor.isLeftClick(event): editor.startSizeDrag(self,Editor.SIZE_DRAG_PIVOT.TOP_LEFT); return true
	elif Rect2(position+Vector2(size.x-dragCornerSize.x,0),dragCornerSize).has_point(editor.mouseWorldPosition): # top right
		DisplayServer.cursor_set_shape(DisplayServer.CURSOR_BDIAGSIZE)
		if Editor.isLeftClick(event): editor.startSizeDrag(self,Editor.SIZE_DRAG_PIVOT.TOP_RIGHT); return true
	elif Rect2(position+Vector2(0,size.y-dragCornerSize.y),dragCornerSize).has_point(editor.mouseWorldPosition): # bottom left
		DisplayServer.cursor_set_shape(DisplayServer.CURSOR_BDIAGSIZE)
		if Editor.isLeftClick(event): editor.startSizeDrag(self,Editor.SIZE_DRAG_PIVOT.BOTTOM_LEFT); return true
	elif Rect2(position,Vector2(size.x,dragCornerSize.y)).has_point(editor.mouseWorldPosition): # top
		DisplayServer.cursor_set_shape(DisplayServer.CURSOR_VSIZE)
		if Editor.isLeftClick(event): editor.startSizeDrag(self,Editor.SIZE_DRAG_PIVOT.TOP); return true
	elif Rect2(position+Vector2(0,size.y-dragCornerSize.y),size-Vector2(0,dragCornerSize.y)).has_point(editor.mouseWorldPosition): # bottom
		DisplayServer.cursor_set_shape(DisplayServer.CURSOR_VSIZE)
		if Editor.isLeftClick(event): editor.startSizeDrag(self,Editor.SIZE_DRAG_PIVOT.BOTTOM); return true
	elif Rect2(position,Vector2(dragCornerSize.x,size.y)).has_point(editor.mouseWorldPosition): # left
		DisplayServer.cursor_set_shape(DisplayServer.CURSOR_HSIZE)
		if Editor.isLeftClick(event): editor.startSizeDrag(self,Editor.SIZE_DRAG_PIVOT.LEFT); return true
	elif Rect2(position+Vector2(size.x-dragCornerSize.x,0),size-Vector2(dragCornerSize.x,0)).has_point(editor.mouseWorldPosition): # right
		DisplayServer.cursor_set_shape(DisplayServer.CURSOR_HSIZE)
		if Editor.isLeftClick(event): editor.startSizeDrag(self,Editor.SIZE_DRAG_PIVOT.RIGHT); return true
	return false

func changedValue(property:StringName, _value:Variant) -> void:
	if property == &"size" and type == DOOR_TYPE.SIMPLE:
		locks[0].simpleDoorUpdate()
