extends Node2D
class_name CurseParticle

const TEXTURE_BROWN_POSITIVE:Texture2D = preload("res://assets/game/player/curse/brownPositive.png") # gamemaker subtractive doesnt work right; this emulates it (stolen from lpe)
const TEXTURE_BROWN:Texture2D = preload("res://assets/game/player/curse/brown.png")
const TEXTURE_GENERIC:Texture2D = preload("res://assets/game/player/curse/generic.png")
const DRAW_RECT:Rect2 = Rect2(Vector2(-64,-64),Vector2(128,128))

var color:Game.COLOR
var rotateSpeed:float # by default 2.5 degrees per frame, 60fps
@export var mode:int

func _init(_color:Game.COLOR,_mode:int,_position:Vector2=Vector2.ZERO,_rotateSpeed:float=2.6179938780,_scale:float=0.6) -> void:
	color = _color
	mode = _mode
	position = _position
	rotateSpeed = _rotateSpeed
	scale = Vector2(_scale,_scale)

func _process(delta:float) -> void:
	rotation += delta*rotateSpeed
	rotation = fmod(rotation,TAU)

func _draw() -> void:
	RenderingServer.canvas_item_clear(get_canvas_item())
	if mode == 0: return
	if color == Game.COLOR.BROWN:
		if mode > 0:
			material = Game.SUBTRACTIVE_MATERIAL
			RenderingServer.canvas_item_add_texture_rect(get_canvas_item(),DRAW_RECT,TEXTURE_BROWN_POSITIVE)
		else:
			material = Game.ADDITIVE_MATERIAL
			RenderingServer.canvas_item_add_texture_rect(get_canvas_item(),DRAW_RECT,TEXTURE_BROWN)
	else:
		material = null
		if mode > 0: RenderingServer.canvas_item_add_texture_rect(get_canvas_item(),DRAW_RECT,TEXTURE_GENERIC,false,getCurseColor())
		else: RenderingServer.canvas_item_add_texture_rect(get_canvas_item(),DRAW_RECT,TEXTURE_GENERIC,false,getCurseColor().inverted())

func getCurseColor() -> Color:
	match color:
		Game.COLOR.MASTER: return Color("#eee8a0")
		Game.COLOR.PURE: return Color("#dbf6f7")
		Game.COLOR.GLITCH: return Color("#969696")
		Game.COLOR.STONE: return Color("#7e8892")
		Game.COLOR.QUICKSILVER: return Color("#cccccc")
		Game.COLOR.DYNAMITE: return Color("#b97328")
		_: return Game.mainTone[color]

class Temporary extends CurseParticle:
	var speed:float
	var direction:float
	var alphaAngle:float
	var targetScale:Vector2

	func _init(_color:Game.COLOR,_mode:int,_position:Vector2=Vector2.ZERO,_targetScale:float=randf_range(0.2,0.3)) -> void:
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
