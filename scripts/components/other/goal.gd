extends GameObject
class_name Goal
const SCENE:PackedScene = preload("res://scenes/objects/goal.tscn")

const SEARCH_ICON:Texture2D = NORMAL
const SEARCH_NAME:String = "Goal"
const SEARCH_KEYWORDS:Array[String] = ["oGoal", "end", "win"]

static func outlineTex() -> Texture2D: return preload("res://assets/game/goal/outlineMask.png")

const NORMAL:Texture2D = preload("res://assets/game/goal/normal.png")
const STAR:Texture2D = preload("res://assets/game/goal/star.png")
const STAR_OUTLINE:Texture2D = preload("res://assets/game/goal/starOutline.png")
const STAR_COLOR:Color = Color("#787828")
const OMEGA:Texture2D = preload("res://assets/game/goal/omega.png")
const OMEGA_WON:Texture2D = preload("res://assets/game/goal/omegaWon.png")
func getSprite() -> Texture2D:
	match type:
		TYPE.STAR: return STAR
		TYPE.OMEGA: return OMEGA_WON if won else OMEGA
		_: return STAR if won else NORMAL

const KEY_PARTICLE_COLOR:Color = Color("#ffff00")
const KEY_PARTICLE_2_COLOR:Color = Color("#ffffb4")

const CREATE_PARAMETERS:Array[StringName] = [
	&"position"
]

const TYPES:int = 3
enum TYPE {NORMAL, STAR, OMEGA}

@export_group("SavedProperties")
@export var type:TYPE = TYPE.NORMAL

var drawMain:RID
var drawStar:RID

var floatAngle:float = 0
var particleSpawnTimer:float = 0
var starAngle:float = 0

var won:bool = false

func _init() -> void: size = Vector2(32,32)

func win() -> void:
	won = true
	if type != TYPE.OMEGA:
		for particle in %particles.get_children(): particle.hue = particleHue()
	for i in 80: Game.particlesParent.add_child(KeyParticle.new(Game.player.position+Vector2(randf_range(-8,8),randf_range(-8,8)), i, KEY_PARTICLE_COLOR, 1))
	for i in 60: Game.particlesParent.add_child(KeyParticle.new(Game.player.position+Vector2(randf_range(-8,8),randf_range(-8,8)), i, KEY_PARTICLE_2_COLOR, 0.6))

func _physics_process(delta:float):
	particleSpawnTimer += delta
	if particleSpawnTimer >= 0.1:
		particleSpawnTimer -= 0.1
		var particle:Particle = Particle.new(particleHue())
		%particles.add_child(particle)
		%particles.move_child(particle, 0)
		return particle
		

func _process(delta:float):
	floatAngle += delta*2.6179938780 # 2.5 degrees per frame, 60fps
	starAngle += delta*1.0471975512 # 1 degree per frame, 60fps
	floatAngle = fmod(floatAngle,TAU)
	starAngle = fmod(starAngle,TAU)
	queue_redraw()

func _ready() -> void:
	drawMain = RenderingServer.canvas_item_create()
	drawStar = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_z_index(drawMain,2)
	RenderingServer.canvas_item_set_z_index(drawStar,2)
	RenderingServer.canvas_item_set_material(drawStar,Game.ADDITIVE_MATERIAL.get_rid())
	RenderingServer.canvas_item_set_parent(drawMain,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawStar,get_canvas_item())

func _freed() -> void:
	RenderingServer.free_rid(drawMain)
	RenderingServer.free_rid(drawStar)

func _draw() -> void:
	RenderingServer.canvas_item_clear(drawMain)
	RenderingServer.canvas_item_clear(drawStar)
	var rect:Rect2 = Rect2(Vector2(0,floor(3*sin(floatAngle))), size)
	RenderingServer.canvas_item_add_texture_rect(drawMain,rect,getSprite())
	if type == TYPE.STAR:
		RenderingServer.canvas_item_set_transform(drawStar,Transform2D(starAngle,Vector2(16,16)))
		RenderingServer.canvas_item_add_texture_rect(drawStar,Rect2(Vector2(-40,-40),Vector2(80,80)),STAR_OUTLINE,false,STAR_COLOR)
		RenderingServer.canvas_item_add_texture_rect(drawStar,Rect2(Vector2(-24,-24),Vector2(48,48)),STAR_OUTLINE,false,Color(STAR_COLOR,0.5))

func particleHue() -> float:
	if won and type != TYPE.OMEGA: return 71
	match type:
		TYPE.STAR: return 71
		TYPE.OMEGA: return 275
	return 120

class Particle extends Sprite2D: # taken from lpe

	# this takes 58 frames to die
	var mode := 0
	var type := 0
	var _scale := 0.1
	var velocity := Vector2(0.1,0).rotated(deg_to_rad(randf() * 360.0))
	# originally 85 (out of 360)
	var hue:float
	var sat:float = 30

	func _init(_hue:float) -> void:
		hue = _hue
		scale = Vector2(0.04, 0.04)
		texture = preload("res://assets/game/goal/particle.png")
	
	func _physics_process(_delta:float) -> void:
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
		modulate = Color.from_hsv((hue - int(sat / 12)) / 360.0, sat / 255.0, 1)
		scale = Vector2.ONE * _scale / 2.5
		position += velocity

# ==== PLAY ==== #
func start() -> void:
	super()
	floatAngle = 0
	for particle in %particles.get_children(): particle.queue_free()

func stop() -> void:
	won = false
	super()
