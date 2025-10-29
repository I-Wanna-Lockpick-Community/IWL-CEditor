extends CharacterBody2D
class_name Player

var game:Game

const HELD_SHINE:Texture2D = preload("res://assets/game/player/held/shine.png")
func getMasterShineColor() -> Color: return Color("#b4b432") if masterMode.reduce().gt(0) else Color("#3232b4")

const HELD_MASTER:Texture2D = preload("res://assets/game/player/held/master.png")
const HELD_QUICKSILVER:Texture2D = preload("res://assets/game/player/held/quicksilver.png")
const HELD_MASTER_NEGATIVE:Texture2D = preload("res://assets/game/player/held/masterNegative.png")
const HELD_QUICKSILVER_NEGATIVE:Texture2D = preload("res://assets/game/player/held/quicksilverNegative.png")
func getHeldKeySprite() -> Texture2D:
	if masterCycle == 1: return HELD_MASTER if masterMode.reduce().gt(0) else HELD_MASTER_NEGATIVE
	else: return HELD_QUICKSILVER if masterMode.reduce().gt(0) else HELD_QUICKSILVER_NEGATIVE

const AURA_RED:Texture2D = preload("res://assets/game/player/aura/red.png")
const AURA_GREEN:Texture2D = preload("res://assets/game/player/aura/green.png")
const AURA_BLUE:Texture2D = preload("res://assets/game/player/aura/blue.png")
const AURA_DRAW_OPACITY:Color = Color(Color.WHITE,0.5)

const FPS:float = 60 # godot velocity works in /s so we account for gamemaker's fps, which is 60

const JUMP_SPEED:float = 8.5
const DOUBLE_JUMP_SPEED:float = 7
const GRAVITY:float = 0.4
const Y_MAXSPEED:float = 9

var canDoubleJump:bool = true
var key:Array[C] = []
var star:Array[bool]

var nearDoor:bool = false # cant save if near a door

var masterMode:C = C.ZERO
var masterCycle:int = 0 # 0 = None, 1 = Master, 2 = Silver

var complexMode:C = C.new(1) # C(1,0) for real view, C(0,1) for i-view

var masterShineDraw:RID
var masterKeyDraw:RID
var masterShineAngle:float

var firstFrame:bool = true # jank prevention

var auraRed:bool = false
var auraGreen:bool = false
var auraBlue:bool = false
var auraDraw:RID

func _ready() -> void:
	auraDraw = RenderingServer.canvas_item_create()
	masterShineDraw = RenderingServer.canvas_item_create()
	masterKeyDraw = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_material(masterShineDraw, Game.ADDITIVE_MATERIAL)
	RenderingServer.canvas_item_set_z_index(auraDraw,11)
	RenderingServer.canvas_item_set_z_index(masterShineDraw,11)
	RenderingServer.canvas_item_set_z_index(masterKeyDraw,11)
	RenderingServer.canvas_item_set_parent(auraDraw, get_canvas_item())
	RenderingServer.canvas_item_set_parent(masterShineDraw, get_canvas_item())
	RenderingServer.canvas_item_set_parent(masterKeyDraw, get_canvas_item())

	for color in Game.COLORS:
		# if color == Game.COLOR.STONE:
		key.append(C.ZERO)
		star.append(false)

func _physics_process(_delta:float) -> void:
	if game.playState == Game.PLAY_STATE.PAUSED:
		%sprite.pause()
		return
	
	var xSpeed:float = 6
	if !is_on_floor() or Input.is_key_pressed(KEY_SHIFT): xSpeed = 3
	var moveDirection:float = Input.get_axis(&"left", &"right")
	velocity.x = xSpeed*FPS*moveDirection

	if is_on_floor(): canDoubleJump = true
	if Input.is_action_just_pressed(&"jump"):
		if is_on_floor():
			velocity.y = -JUMP_SPEED*FPS
			AudioManager.play(preload("res://resources/sounds/player/jump.wav"))
		elif canDoubleJump:
			velocity.y = -DOUBLE_JUMP_SPEED*FPS
			canDoubleJump = false
			AudioManager.play(preload("res://resources/sounds/player/doubleJump.wav"))
	if Input.is_action_just_released(&"jump") and velocity.y < 0: velocity.y *= 0.45
	velocity.y += GRAVITY*FPS
	velocity.y = clamp(velocity.y, -Y_MAXSPEED*FPS, Y_MAXSPEED*FPS)

	move_and_slide()

	if moveDirection: %sprite.flip_h = moveDirection < 0

	if velocity.y <= -0.05*FPS: %sprite.play("jump")
	elif velocity.y >= 0.05*FPS: %sprite.play("fall")
	elif moveDirection: %sprite.play("run")
	else: %sprite.play("idle")

	if firstFrame:
		firstFrame = false
	else:
		nearDoor = false
		for area in %near.get_overlapping_areas(): near(area)
		for area in %interact.get_overlapping_areas(): interacted(area)

func _process(delta:float) -> void:
	masterShineAngle += delta*4.1887902048 # 4 degrees per frame, 60fps
	masterShineAngle = fmod(masterShineAngle,TAU)
	queue_redraw()

func receiveKey(event:InputEventKey):
	if event.echo: return
	match event.keycode:
		KEY_P: game.pauseTest()
		KEY_O: game.stopTest()
		KEY_R: game.restart()
		KEY_Z: if gameChanges.undo(): AudioManager.play(preload("res://resources/sounds/player/undo.wav")).pitch_scale = 0.6
		KEY_X: cycleMaster()

func _newlyInteracted(area:Area2D) -> void:
	var object:GameObject = area.get_parent()
	if object is KeyBulk:
		object.collect(self)

func interacted(area:Area2D) -> void:
	var object:GameObject = area.get_parent()
	if object is Door:
		object.tryOpen(self)

func near(area:Area2D) -> void:
	var object:GameObject = area.get_parent()
	if object is Door:
		nearDoor = true
		object.auraCheck(self)

func overlapping(area:Area2D) -> bool: return %interact.overlaps_area(area)

func cycleMaster() -> void:
	if masterCycle < 1: # MASTER
		var relevantCount:C = key[Game.COLOR.MASTER].across(complexMode)
		if relevantCount.neq(0):
			masterCycle = 1
			masterMode = relevantCount.axis()
			if relevantCount.reduce().gt(0): AudioManager.play(preload("res://resources/sounds/player/masterEquip.wav"))
			else: AudioManager.play(preload("res://resources/sounds/player/masterNegativeEquip.wav"))
			return
	if masterCycle < 2: # SILVER
		var relevantCount:C = key[Game.COLOR.QUICKSILVER].across(complexMode)
		if relevantCount.neq(0):
			masterCycle = 2
			masterMode = relevantCount.axis()
			if relevantCount.reduce().gt(0): AudioManager.play(preload("res://resources/sounds/player/masterEquip.wav"))
			else: AudioManager.play(preload("res://resources/sounds/player/masterNegativeEquip.wav"))
			return
	if masterCycle != 0:
		AudioManager.play(preload("res://resources/sounds/player/masterUnequip.wav"))
	masterMode = C.ZERO
	masterCycle = 0

func dropMaster() -> void:
	masterMode = C.ZERO
	masterCycle = 0

func checkKeys() -> void:
	auraRed = !key[Game.COLOR.RED].lt(1)
	auraGreen = !key[Game.COLOR.GREEN].lt(5)
	auraBlue = !key[Game.COLOR.BLUE].lt(3)

	match masterCycle:
		1: if key[Game.COLOR.MASTER].across(masterMode).reduce().gt(0): return
		2: if key[Game.COLOR.QUICKSILVER].across(masterMode).reduce().gt(0): return
	masterMode = C.ZERO; masterCycle = 0

func _draw() -> void:
	RenderingServer.canvas_item_clear(auraDraw)
	RenderingServer.canvas_item_clear(masterShineDraw)
	RenderingServer.canvas_item_clear(masterKeyDraw)
	var auraRect:Rect2 = Rect2(Vector2(-32,-32),Vector2(64,64))
	if auraRed: RenderingServer.canvas_item_add_texture_rect(auraDraw,auraRect,AURA_RED,false,AURA_DRAW_OPACITY)
	if auraGreen: RenderingServer.canvas_item_add_texture_rect(auraDraw,auraRect,AURA_GREEN,false,AURA_DRAW_OPACITY)
	if auraBlue: RenderingServer.canvas_item_add_texture_rect(auraDraw,auraRect,AURA_BLUE,false,AURA_DRAW_OPACITY)
	if masterCycle != 0:
		var masterShineScale:float = 0.8 + 0.2*sin(masterShineAngle)
		var masterDrawOpacity:Color = Color(Color.WHITE,masterShineScale*0.6)
		RenderingServer.canvas_item_add_texture_rect(masterShineDraw,Rect2(Vector2(-32,-32)*masterShineScale,Vector2(64,64)*masterShineScale),HELD_SHINE,false,getMasterShineColor())
		RenderingServer.canvas_item_add_texture_rect(masterKeyDraw,Rect2(Vector2(-16,-16),Vector2(32,32)),getHeldKeySprite(),false,masterDrawOpacity)
