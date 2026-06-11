extends Node2D
class_name CurseParticle

const TEXTURE_BROWN_POSITIVE:Texture2D = preload("res://assets/game/player/curse/brownPositive.png") # gamemaker subtractive doesnt work right; this emulates it (stolen from lpe)
const TEXTURE_BROWN:Texture2D = preload("res://assets/game/player/curse/brown.png")
const TEXTURE_GENERIC:Texture2D = preload("res://assets/game/player/curse/generic.png")
const DRAW_RECT:Rect2 = Rect2(Vector2(-64,-64),Vector2(128,128))

var color:C.olors
var rotateSpeed:float # by default 2.5 degrees per frame, 60fps
@export var mode:int

var drawMain:RID

func _init(_color:C.olors,_mode:int,_position:Vector2=Vector2.ZERO,_rotateSpeed:float=2.6179938780,_scale:float=0.6) -> void:
	color = _color
	mode = _mode
	position = _position
	rotateSpeed = _rotateSpeed
	scale = Vector2(_scale,_scale)

func _ready() -> void:
	drawMain = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(drawMain,get_canvas_item())

func _process(delta:float) -> void:
	rotation += delta*rotateSpeed
	rotation = fmod(rotation,TAU)

func _draw() -> void:
	RenderingServer.canvas_item_clear(drawMain)
	if mode == 0: return
	if color == C.olors.BROWN:
		if mode > 0:
			RenderingServer.canvas_item_set_material(drawMain,Game.SUBTRACTIVE_MATERIAL)
			RenderingServer.canvas_item_add_texture_rect(drawMain,DRAW_RECT,TEXTURE_BROWN_POSITIVE)
		else:
			RenderingServer.canvas_item_set_material(drawMain,Game.ADDITIVE_MATERIAL)
			RenderingServer.canvas_item_add_texture_rect(drawMain,DRAW_RECT,TEXTURE_BROWN)
	else:
		RenderingServer.canvas_item_set_material(drawMain,Game.NO_MATERIAL)
		if mode > 0: RenderingServer.canvas_item_add_texture_rect(drawMain,DRAW_RECT,TEXTURE_GENERIC,false,getCurseColor())
		else: RenderingServer.canvas_item_add_texture_rect(drawMain,DRAW_RECT,TEXTURE_GENERIC,false,getCurseColor().inverted())

func getCurseColor() -> Color:
	match color:
		C.olors.MASTER: return Color("#eee8a0")
		C.olors.PURE: return Color("#dbf6f7")
		C.olors.GLITCH: return Color("#969696")
		C.olors.STONE: return Color("#7e8892")
		C.olors.QUICKSILVER: return Color("#cccccc")
		C.olors.DYNAMITE: return Color("#b97328")
		_: return Game.mainTone[color]

class Temporary extends CurseParticle:
	var speed:float
	var direction:float
	var alphaAngle:float
	var targetScale:Vector2

	func _init(_color:C.olors,_mode:int,_position:Vector2=Vector2.ZERO,_targetScale:float=randf_range(0.2,0.3)) -> void:
		super(_color, _mode, _position, 0, 0)
		position = _position
		direction = randf_range(0,TAU)
		rotation = direction
		rotateSpeed = -0.0698131701 if randi_range(0,1) else 0.0698131701 # 4 degrees per frame
		speed = 0.1
		targetScale = Vector2(_targetScale,_targetScale)
		alphaAngle = 0

	func _process(_delta:float) -> void: pass

	func _physics_process(_delta:float) -> void:
		scale += (targetScale - scale) * 0.1
		rotation += rotateSpeed
		rotation = fposmod(rotation,TAU)
		speed = min(speed+0.001,0.4)
		position += Vector2(speed,0).rotated(direction)
		alphaAngle += 0.0218166156 # 1.25 degrees per frame
		modulate.a = cos(alphaAngle)
		if alphaAngle >= 1.5707963268: queue_free()
