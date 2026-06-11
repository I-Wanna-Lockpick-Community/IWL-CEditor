extends GameComponent
class_name KeyCounterElement

func outlineTex() -> Texture2D: return KeyBulk.getOutlineTexture(color)

const CREATE_PARAMETERS:Array[StringName] = [
	&"position", &"parentId"
]
const PROPERTIES:Array[StringName] = [
	&"id", &"position", &"size",
	&"parentId", &"color",
	&"index" # implciit
]
static var ARRAYS:Dictionary[StringName,Variant] = {}

const TEXT_COLOR:Color = Color("#2c221c")

const STAR:Texture2D = preload("res://assets/game/keyCounter/star.png")
const STAR_COLOR:Color = Color("#ffffb4")

var parent:KeyCounter
var parentId:int
var color:C.olors = C.olors.WHITE
var index:int

func getColors() -> Array[C.olors]: return [color]

var drawStar:RID
var drawGlitch:RID
var drawMain:RID
var drawCurse:CurseParticle

func _init() -> void: size = Vector2(32,32)

func _ready() -> void:
	drawCurse = CurseParticle.new(color,1,Vector2(16,16),-2.3038346126,0.4)
	drawStar = RenderingServer.canvas_item_create()
	drawGlitch = RenderingServer.canvas_item_create()
	drawMain = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_material(drawGlitch,Game.GLITCH_MATERIAL.get_rid())
	add_child(drawCurse)
	var drawParent:Node2D = Node2D.new()
	add_child(drawParent)
	RenderingServer.canvas_item_set_parent(drawStar,drawParent.get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawGlitch,drawParent.get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawMain,drawParent.get_canvas_item())
	Game.connect(&"goldIndexChanged",queue_redraw)

func _freed() -> void:
	RenderingServer.free_rid(drawStar)
	RenderingServer.free_rid(drawGlitch)
	RenderingServer.free_rid(drawMain)

func _draw() -> void:
	RenderingServer.canvas_item_clear(drawStar)
	RenderingServer.canvas_item_clear(drawGlitch)
	RenderingServer.canvas_item_clear(drawMain)
	if color == C.olors.NONE: return
	if Game.player and Game.player.star[color]:
		RenderingServer.canvas_item_set_transform(drawStar,Transform2D(parent.starAngle,Vector2(16,16)))
		RenderingServer.canvas_item_add_texture_rect(drawStar,Rect2(Vector2(-25.6,-25.6),Vector2(51.2,51.2)),STAR,false,STAR_COLOR)
	KeyBulk.drawKey(drawGlitch,drawMain,Vector2.ZERO,color)
	Game.FKEYNUM.draw_string(drawMain,Vector2(38,14),"x",HORIZONTAL_ALIGNMENT_LEFT,-1,22,TEXT_COLOR)
	# below code edited to add the glistening part if it is non-zero
	Game.FKEYNUM.draw_string(drawMain,Vector2(58,14),"0" if !Game.player else (M.str(Game.player.key[color]) + " (" + M.str(Game.player.glisten[color]) + ")" if Game.player.glisten[color] != M.ZERO else M.str(Game.player.key[color])),HORIZONTAL_ALIGNMENT_LEFT,-1,22,TEXT_COLOR)

func _process(_delta:float) -> void:
	queue_redraw()
	drawCurse.color = color
	drawCurse.scale = Vector2.ONE * (0.4 if color == C.olors.BROWN else 0.5)
	drawCurse.mode = 1 if Mods.active(&"CurseKeys") and Game.player and Game.player.curse[color] else 0
	drawCurse.queue_redraw()

func getDrawPosition() -> Vector2: return position + parent.position

func getHoverSize() -> Vector2: return Vector2(32, 32)
