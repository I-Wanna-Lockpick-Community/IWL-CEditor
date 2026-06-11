extends GameObject
class_name KeyCounter
const SCENE:PackedScene = preload("res://scenes/objects/keyCounter.tscn")

const SEARCH_ICON:Texture2D = preload("res://assets/game/keyCounter/icon.png")
const SEARCH_NAME:String = "Key Counter"
const SEARCH_KEYWORDS:Array[String] = ["oKeyHandle", "key box"]

const TEXTURES = [
	preload("res://assets/game/keyCounter/short.png"),
	preload("res://assets/game/keyCounter/medium.png"),
	preload("res://assets/game/keyCounter/long.png"),
	preload("res://assets/game/keyCounter/vlong.png"),
	preload("res://assets/game/keyCounter/exlong.png")
]
const WIDTHS = 5
enum WIDTH {SHORT, MEDIUM, LONG, VLONG, EXLONG}
const WIDTH_AMOUNT:Array[float] = [107, 139, 203, 253, 353]
func getSprite() -> Texture2D:
	return TEXTURES[WIDTH_AMOUNT.find(size.x)]

# the ninepatch (or i guess 3 since we dont care about horizontally) tiling for this is weird
const TOP_LEFT:Vector2 = Vector2(16,16)
const BOTTOM_RIGHT:Vector2 = Vector2(7,7)
const TILE:RenderingServer.NinePatchAxisMode = RenderingServer.NinePatchAxisMode.NINE_PATCH_TILE # just to save characters

const CREATE_PARAMETERS:Array[StringName] = [
	&"position"
]
const PROPERTIES:Array[StringName] = [
	&"id", &"position", &"size",
]
static var ARRAYS:Dictionary[StringName,Variant] = {}

var drawMain:RID

var elements:Array[KeyCounterElement] = []

func _init() -> void :
	size = Vector2(WIDTH_AMOUNT[WIDTH.SHORT],63)

func _ready() -> void:
	drawMain = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(drawMain,get_canvas_item())

func _freed() -> void:
	RenderingServer.free_rid(drawMain)

func _draw() -> void:
	RenderingServer.canvas_item_clear(drawMain)
	var rect:Rect2 = Rect2(Vector2.ZERO, size)
	var textureRect:Rect2 = Rect2(Vector2.ZERO, Vector2(size.x, 63))
	RenderingServer.canvas_item_add_nine_patch(drawMain,Rect2(Vector2(2,2),size),textureRect,getSprite(),TOP_LEFT,BOTTOM_RIGHT,TILE,TILE,true,Color("#808080"))
	RenderingServer.canvas_item_add_nine_patch(drawMain,rect,textureRect,getSprite(),TOP_LEFT,BOTTOM_RIGHT,TILE,TILE,true)

func receiveMouseInput(event:InputEventMouse) -> bool:
	# resizing
	if !editor.edgeResizing or editor.componentDragged: return false
	var dragCornerSize:Vector2 = Vector2(8,8)/editor.cameraZoom
	var diffSign:Vector2 = Editor.rectSign(Rect2(position+dragCornerSize,size-dragCornerSize*2), editor.mouseWorldPosition)
	if !diffSign.x: return false
	editor.mouse_default_cursor_shape = Control.CURSOR_HSIZE
	if Editor.isLeftClick(event):
		editor.startSizeDrag(self, Vector2(diffSign.x,0))
		return true
	return false

func _elementsChanged() -> void:
	Changes.addChange(Changes.PropertyChange.new(self,&"size",Vector2(size.x,23+len(elements)*40)))
	var index:int = 0
	for element in elements:
		Changes.addChange(Changes.PropertyChange.new(element,&"position",Vector2(12,12+index*40)))
		index += 1

func _swapElements(first:int, second:int) -> void: # TODO:DEJANK
	var firstColor:C.olors = elements[first].color
	var secondColor:C.olors = elements[second].color
	editor.componentDragged = elements[second]
	editor.focusDialog.componentFocused = elements[second]
	Changes.addChange(Changes.PropertyChange.new(elements[first],&"color",secondColor))
	Changes.addChange(Changes.PropertyChange.new(elements[second],&"color",firstColor))

func addElement() -> void:
	var element:KeyCounterElement = Changes.addChange(Changes.CreateComponentChange.new(KeyCounterElement,{&"position":Vector2(12,12+len(elements)*40),&"parentId":id})).result
	Changes.addChange(Changes.PropertyChange.new(element,&"color",nextColor()))
	Changes.bufferSave()

func removeElement(index:int) -> void:
	Changes.addChange(Changes.DeleteComponentChange.new(elements[index]))
	Changes.bufferSave()

func nextColor() -> C.olors:
	# make sure to change this when implementing Mods
	if len(elements) < 2: return C.olors.WHITE
	return Mods.nextColor(elements[-2].color)

func reindexElements() -> void:
	var index:int = 0
	for element in elements:
		element.index = index
		index += 1

# ==== PLAY ==== #
var starAngle:float = 0

func _process(delta:float):
	starAngle += delta*2.3038346126 # 2.2 degrees per frame, 60fps
	starAngle = fmod(starAngle,TAU)

func start() -> void:
	super()
	starAngle = 0
