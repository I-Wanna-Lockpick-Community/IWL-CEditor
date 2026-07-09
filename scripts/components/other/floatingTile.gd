extends GameObject
class_name FloatingTile
const SCENE:PackedScene = preload("res://scenes/objects/floatingTile.tscn")

const SEARCH_ICON:Texture2D = TEXTURE
const SEARCH_NAME:String = "Floating Tile"
const SEARCH_KEYWORDS:Array[String] = []

const TEXTURE:Texture2D = preload("res://assets/ui/modes/tile.png")

const CREATE_PARAMETERS:Array[StringName] = [
	&"position"
]

var drawDropShadow:RID
var drawMain:RID

func _init() -> void: size = Vector2(32,32)

func _ready() -> void:
	drawDropShadow = RenderingServer.canvas_item_create()
	drawMain = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_z_index(drawDropShadow,-2)
	RenderingServer.canvas_item_set_parent(drawDropShadow,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawMain,get_canvas_item())

func _freed() -> void:
	RenderingServer.free_rid(drawDropShadow)
	RenderingServer.free_rid(drawMain)

func _draw() -> void:
	RenderingServer.canvas_item_clear(drawDropShadow)
	RenderingServer.canvas_item_clear(drawMain)
	RenderingServer.canvas_item_add_rect(drawDropShadow,Rect2(Vector2(3,3),size),Game.DROP_SHADOW_COLOR)
	RenderingServer.canvas_item_add_texture_rect(drawMain,Rect2(Vector2.ZERO,size),TEXTURE)

func receiveMouseInput(event:InputEventMouse) -> bool:
	# resizing
	if !editor.edgeResizing or editor.componentDragged: return false
	var dragCornerSize:Vector2 = Vector2(8,8)/editor.cameraZoom
	var diffSign:Vector2 = Editor.rectSign(Rect2(position+dragCornerSize,size-dragCornerSize*2), editor.mouseWorldPosition)
	if !diffSign: return false
	elif !diffSign.x: editor.mouse_default_cursor_shape = Control.CURSOR_VSIZE
	elif !diffSign.y: editor.mouse_default_cursor_shape = Control.CURSOR_HSIZE
	elif (diffSign.x > 0) == (diffSign.y > 0): editor.mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
	else: editor.mouse_default_cursor_shape = Control.CURSOR_BDIAGSIZE
	if Editor.isLeftClick(event):
		editor.startSizeDrag(self, diffSign)
		return true
	return false

func propertyChangedDo(property:StringName) -> void:
	super(property)
	if property == &"size":
		%shape.shape.size = size
		%shape.position = size/2
