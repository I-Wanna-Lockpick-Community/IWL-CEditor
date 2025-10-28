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

const TEXT_COLOR:Color = Color("#2c221c")

const STAR:Texture2D = preload("res://assets/game/keyCounter/star.png")
const STAR_COLOR:Color = Color("#ffffb4")

var parent:KeyCounter
var parentId:int
var color:Game.COLOR = Game.COLOR.WHITE
var index:int

var drawStar:RID
var drawGlitch:RID
var drawMain:RID

func _init(_parent:KeyCounter, _index:int) -> void:
	parent = _parent
	index = _index
	size = Vector2(32,32)

func _ready() -> void:
	drawStar = RenderingServer.canvas_item_create()
	drawGlitch = RenderingServer.canvas_item_create()
	drawMain = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_material(drawGlitch,Game.GLITCH_MATERIAL.get_rid())
	RenderingServer.canvas_item_set_parent(drawStar,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawGlitch,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawMain,get_canvas_item())
	editor.game.connect(&"goldIndexChanged",queue_redraw)

func _process(_delta:float) -> void: queue_redraw()

func _draw() -> void:
	RenderingServer.canvas_item_clear(drawStar)
	RenderingServer.canvas_item_clear(drawGlitch)
	RenderingServer.canvas_item_clear(drawMain)
	if editor.game.player and editor.game.player.star[color]:
		RenderingServer.canvas_item_set_transform(drawStar,Transform2D(parent.starAngle,Vector2(16,16)))
		RenderingServer.canvas_item_add_texture_rect(drawStar,Rect2(Vector2(-25.6,-25.6),Vector2(51.2,51.2)),STAR,false,STAR_COLOR)
	KeyBulk.drawKey(editor.game,drawMain,drawGlitch,Vector2.ZERO,color)
	Game.FKEYNUM.draw_string(drawMain,Vector2(38,14),"x",HORIZONTAL_ALIGNMENT_LEFT,-1,22,TEXT_COLOR)
	Game.FKEYNUM.draw_string(drawMain,Vector2(58,14),"0" if !editor.game.player else str(editor.game.player.key[color]),HORIZONTAL_ALIGNMENT_LEFT,-1,22,TEXT_COLOR)

func getDrawPosition() -> Vector2: return position + parent.position

func getHoverSize() -> Vector2: return Vector2(54, 32)
