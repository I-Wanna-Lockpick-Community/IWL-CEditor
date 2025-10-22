extends GameObject
class_name KeyCounter
const SCENE:PackedScene = preload("res://scenes/objects/keyCounter.tscn")

const SEARCH_ICON:Texture2D = preload("res://assets/game/keyCounter/icon.png")
const SEARCH_NAME:String = "Key Counter"
const SEARCH_KEYWORDS:Array[String] = ["oKeyHandle", "key box"]

const SHORT:Texture2D = preload("res://assets/game/keyCounter/short.png")
const MEDIUM:Texture2D = preload("res://assets/game/keyCounter/medium.png")
const LONG:Texture2D = preload("res://assets/game/keyCounter/long.png")
const WIDTHS:Array[float] = [107, 139, 203]
func getSprite() -> Texture2D:
	match size.x:
		WIDTHS[0]: return SHORT
		WIDTHS[1]: return MEDIUM
		WIDTHS[2]: return LONG
	return null

# the ninepatch (or i guess 3 since we dont care about horizontally) tiling for this is weird
const TOP_LEFT:Vector2 = Vector2(16,16)
const BOTTOM_RIGHT:Vector2 = Vector2(7,7)
const TILE:RenderingServer.NinePatchAxisMode = RenderingServer.NinePatchAxisMode.NINE_PATCH_TILE # just to save characters

const CREATE_PARAMETERS:Array[StringName] = [
	&"position"
]
const EDITOR_PROPERTIES:Array[StringName] = [
	&"id", &"position", &"size",
]

var drawMain:RID
var drawGlitch:RID

var elements:Array[KeyCounterElement] = []

func _init() -> void :
	size = Vector2(WIDTHS[0],63)
	z_index = 2

func _ready() -> void:
	drawMain = RenderingServer.canvas_item_create()
	drawGlitch = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_material(drawGlitch,Game.GLITCH_MATERIAL.get_rid())
	RenderingServer.canvas_item_set_parent(drawMain,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawGlitch,get_canvas_item())

func _process(_delta:float) -> void: queue_redraw()

func _draw() -> void:
	RenderingServer.canvas_item_clear(drawMain)
	RenderingServer.canvas_item_clear(drawGlitch)
	var rect:Rect2 = Rect2(Vector2.ZERO, size)
	var textureRect:Rect2 = Rect2(Vector2.ZERO, Vector2(size.x, 63))
	RenderingServer.canvas_item_add_nine_patch(drawMain,rect,textureRect,getSprite(),TOP_LEFT,BOTTOM_RIGHT,TILE,TILE,true)

func receiveMouseInput(event:InputEventMouse) -> bool:
	# resizing
	if editor.componentDragged: return false
	var dragCornerSize:Vector2 = Vector2(8,8)/editor.cameraZoom
	var diffSign:Vector2 = Editor.rectSign(Rect2(position+dragCornerSize,size-dragCornerSize*2), editor.mouseWorldPosition)
	var dragPivot:Editor.SIZE_DRAG_PIVOT = Editor.SIZE_DRAG_PIVOT.NONE
	match diffSign.x:
		-1.0: dragPivot = Editor.SIZE_DRAG_PIVOT.LEFT;			editor.mouse_default_cursor_shape = Control.CURSOR_HSIZE
		1.0: dragPivot = Editor.SIZE_DRAG_PIVOT.RIGHT;			editor.mouse_default_cursor_shape = Control.CURSOR_HSIZE
	if dragPivot != Editor.SIZE_DRAG_PIVOT.NONE and Editor.isLeftClick(event):
		editor.startSizeDrag(self, dragPivot)
		return true
	return false

func _elementsChanged() -> void:
	changes.addChange(Changes.PropertyChange.new(editor.game,self,&"size",Vector2(size.x,23+len(elements)*40)))
	var index:int = 0
	for element in elements:
		changes.addChange(Changes.PropertyChange.new(editor.game,element,&"position",Vector2(12,12+index*40)))
		index += 1

func _swapElements(first:int, second:int) -> void: # TODO:DEJANK
	var firstColor:Game.COLOR = elements[first].color
	var secondColor:Game.COLOR = elements[second].color
	editor.componentDragged = elements[second]
	editor.focusDialog.componentFocused = elements[second]
	changes.addChange(Changes.PropertyChange.new(editor.game,elements[first],&"color",secondColor))
	changes.addChange(Changes.PropertyChange.new(editor.game,elements[second],&"color",firstColor))
	elements[first].queue_redraw()
	elements[second].queue_redraw()
