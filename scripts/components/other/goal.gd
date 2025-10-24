extends GameObject
class_name Goal
const SCENE:PackedScene = preload("res://scenes/objects/goal.tscn")

const SEARCH_ICON:Texture2D = NORMAL
const SEARCH_NAME:String = "Goal"
const SEARCH_KEYWORDS:Array[String] = ["oGoal", "end", "win"]

static func outlineTex() -> Texture2D: return preload("res://assets/game/goal/outlineMask.png")

const NORMAL:Texture2D = preload("res://assets/game/goal/normal.png")
const OMEGA:Texture2D = preload("res://assets/game/goal/omega.png")
func getSprite() -> Texture2D:
	match type:
		TYPE.OMEGA: return OMEGA
		_: return NORMAL

const CREATE_PARAMETERS:Array[StringName] = [
	&"position"
]
const EDITOR_PROPERTIES:Array[StringName] = [
	&"id", &"position", &"size",
	&"type"
]

const TYPES:int = 2
enum TYPE {NORMAL, OMEGA}

var type:TYPE = TYPE.NORMAL

var drawMain:RID

var floatAngle:float = 0
var particleSpawnTimer:float = 0

func _init() -> void : size = Vector2(32,32)

func _physics_process(delta:float):
	particleSpawnTimer += delta
	if particleSpawnTimer >= 0.1:
		particleSpawnTimer -= 0.1
		var particle:Particle = Particle.new()
		#if has_won: particle.hue = 60
		if type == TYPE.OMEGA: particle.hue = 275
		%particles.add_child(particle)
		%particles.move_child(particle, 0)
		return particle
		

func _process(delta:float):
	floatAngle += delta*2.6179938780 # 2.5 degrees per frame, 60fps
	floatAngle = fmod(floatAngle,TAU)
	queue_redraw()

func _ready() -> void:
	drawMain = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_z_index(drawMain,1)
	RenderingServer.canvas_item_set_parent(drawMain,get_canvas_item())

func _draw() -> void:
	RenderingServer.canvas_item_clear(drawMain)
	var rect:Rect2 = Rect2(Vector2(0,floor(3*sin(floatAngle))), size)
	RenderingServer.canvas_item_add_texture_rect(drawMain,rect,getSprite())

class Particle extends Sprite2D: # taken from lpe

	# this takes 58 frames to die
	var mode := 0
	var type := 0
	var _scale := 0.1
	var velocity := Vector2(0.1,0).rotated(deg_to_rad(randf() * 360.0))
	# originally 85 (out of 360)
	var hue := 120
	var sat := 30

	func _init():
		scale = Vector2(0.04, 0.04)
		texture = preload("res://assets/game/goal/particle.png")

	func _physics_process(_delta: float) -> void:
		# don't process if alone in editor (enable for tool mode)
		if get_parent() is SubViewport: return
		if type == 1:
			velocity *= 0.95
		if mode == 0:
			_scale += ((1 - _scale) * 0.2)
			if _scale >= 0.98:
				mode = 1
				if type == 0:
					velocity *= 4
		else:
			_scale = _scale - 0.025
			if _scale <= 0:
				queue_free()
		sat = min((sat + 3), 255)
		@warning_ignore("integer_division")
		modulate = Color.from_hsv((hue - (sat / 12)) / 360.0, sat / 255.0, 1)
		scale = Vector2.ONE * _scale / 2.5
		position += velocity

# ==== PLAY ==== #
func start() -> void:
	super()
	floatAngle = 0
