extends GameComponent
class_name KeyCounterElement

func outlineTex() -> Texture2D: return KeyBulk.getOutlineTexture(color)

const CREATE_PARAMETERS:Array[StringName] = [
	&"position", &"parentId"
]
const EDITOR_PROPERTIES:Array[StringName] = [
	&"id", &"position", &"size",
	&"parentId", &"color",
	&"index" # implciit
]

var parent:KeyCounter
var parentId:int
var color:Game.COLOR = Game.COLOR.WHITE
var index:int

var drawGlitch:RID
var drawMain:RID

func _init(_parent:KeyCounter, _index:int) -> void:
	parent = _parent
	index = _index
	size = Vector2(32,32)

func _ready() -> void:
	drawGlitch = RenderingServer.canvas_item_create()
	drawMain = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_material(drawGlitch,Game.GLITCH_MATERIAL.get_rid())
	RenderingServer.canvas_item_set_parent(drawGlitch,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawMain,get_canvas_item())
	editor.game.connect(&"goldIndexChanged",queue_redraw)

func _draw() -> void:
	RenderingServer.canvas_item_clear(drawGlitch)
	RenderingServer.canvas_item_clear(drawMain)
	KeyBulk.drawKey(editor.game,drawMain,drawGlitch,Vector2.ZERO,color)

func getDrawPosition() -> Vector2: return position + parent.position
