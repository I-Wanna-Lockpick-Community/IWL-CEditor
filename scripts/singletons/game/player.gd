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
const AURA_RECT:Rect2 = Rect2(Vector2(-32,-32),Vector2(64,64))

const FPS:float = 60 # godot velocity works in /s so we account for gamemaker's fps, which is 60

const JUMP_SPEED:float = 8.5
const DOUBLE_JUMP_SPEED:float = 7
const GRAVITY:float = 0.4
const Y_MAXSPEED:float = 9

var canDoubleJump:bool = true
var key:Array[C] = []
var star:Array[bool]
var curse:Array[bool]

var nearDoor:bool = false # cant save if near a door

var masterMode:C = C.ZERO
var masterCycle:int = 0 # 0 = None, 1 = Master, 2 = Silver
const MASTER_CYCLE_COLORS:Array[Game.COLOR] = [Game.COLOR.WHITE, Game.COLOR.MASTER, Game.COLOR.QUICKSILVER]

var complexMode:C = C.ONE # C(1,0) for real view, C(0,1) for i-view

var masterShineDraw:RID
var masterKeyDraw:RID
var masterShineAngle:float = 0

var pauseFrame:bool = true # jank prevention

var auraRed:bool = false
var auraGreen:bool = false
var auraBlue:bool = false
var auraDraw:RID

var curseMode:int = 0 # 0 = none, 1 = curse, -1 = uncurse
var curseColor:Game.COLOR
var drawCurse:CurseParticle

var complexModeTextDraw:RID
var complexSwitchDraw:RID
var complexSwitchAnim:bool = false
var complexSwitchAngle:float = 0

func _ready() -> void:
	auraDraw = RenderingServer.canvas_item_create()
	masterShineDraw = RenderingServer.canvas_item_create()
	masterKeyDraw = RenderingServer.canvas_item_create()
	complexModeTextDraw = RenderingServer.canvas_item_create()
	complexSwitchDraw = RenderingServer.canvas_item_create()
	drawCurse = CurseParticle.new(curseColor,curseMode)
	RenderingServer.canvas_item_set_material(masterShineDraw, Game.ADDITIVE_MATERIAL)
	RenderingServer.canvas_item_set_material(complexSwitchDraw, Game.ADDITIVE_MATERIAL)
	drawCurse.z_index = 4
	RenderingServer.canvas_item_set_z_index(auraDraw,6)
	RenderingServer.canvas_item_set_z_index(masterShineDraw,6)
	RenderingServer.canvas_item_set_z_index(masterKeyDraw,6)
	RenderingServer.canvas_item_set_z_index(complexModeTextDraw,6)
	RenderingServer.canvas_item_set_z_index(complexSwitchDraw,6)
	RenderingServer.canvas_item_set_parent(auraDraw, get_canvas_item())
	RenderingServer.canvas_item_set_parent(masterShineDraw, get_canvas_item())
	RenderingServer.canvas_item_set_parent(masterKeyDraw, get_canvas_item())
	RenderingServer.canvas_item_set_parent(complexModeTextDraw, get_canvas_item())
	RenderingServer.canvas_item_set_parent(complexSwitchDraw, get_canvas_item())
	add_child(drawCurse)

	for color in Game.COLORS:
		# if color == Game.COLOR.STONE:
		key.append(C.ZERO)
		star.append(false)
		curse.append(color == Game.COLOR.BROWN)

func _physics_process(_delta:float) -> void:
	if game.playState != Game.PLAY_STATE.PLAY:
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

	if pauseFrame:
		pauseFrame = false
	else:
		nearDoor = false
		for area in %near.get_overlapping_areas(): near(area)
		for area in %interact.get_overlapping_areas(): interacted(area)

func _process(delta:float) -> void:
	masterShineAngle += delta*4.1887902048 # 4 degrees per frame, 60fps
	masterShineAngle = fmod(masterShineAngle,TAU)
	if complexSwitchAnim:
		complexSwitchAngle += delta*5.2359877560 # 5 degrees per frame, 60fps
		if complexSwitchAngle >= 1.5707963268: complexSwitchAnim = false
	queue_redraw()

	drawCurse.mode = curseMode
	drawCurse.color = curseColor
	drawCurse.queue_redraw()

func receiveKey(event:InputEventKey):
	if event.echo: return
	match event.keycode:
		KEY_P: game.pauseTest()
		KEY_O: game.stopTest()
		KEY_R: game.restart()
		KEY_Z: if gameChanges.undo(): AudioManager.play(preload("res://resources/sounds/player/undo.wav")).pitch_scale = 0.6
		KEY_X: cycleMaster()
		KEY_S: complexSwitch()

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
		if curseMode: object.curseCheck(self)

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
	dropMaster()

func dropMaster() -> void:
	masterMode = C.ZERO
	masterCycle = 0

func checkKeys() -> void:
	match masterCycle:
		1: if !key[Game.COLOR.MASTER].across(masterMode).reduce().gt(0): masterMode = C.ZERO; masterCycle = 0
		2: if !key[Game.COLOR.QUICKSILVER].across(masterMode).reduce().gt(0): masterMode = C.ZERO; masterCycle = 0
	
	auraRed = !key[Game.COLOR.RED].lt(1)
	auraGreen = !key[Game.COLOR.GREEN].lt(5)
	auraBlue = !key[Game.COLOR.BLUE].lt(3)

	curseMode = 0
	var highestSeen:Q = Q.ZERO
	for color in Game.COLORS:
		if !curse[color] or key[color].r.eq(0): continue
		# tie
		if key[color].r.abs().eq(highestSeen): curseMode = 0
		elif key[color].r.abs().gt(highestSeen):
			highestSeen = key[color].r.abs()
			curseMode = key[color].r.sign()
			curseColor = color as Game.COLOR

func complexSwitch() -> void:
	if complexMode.eq(1): complexMode = C.I
	else: complexMode = C.ONE

	AudioManager.play(preload("res://resources/sounds/player/camera.wav"))
	AudioManager.play(preload("res://resources/sounds/key/signflip.wav"))
	complexSwitchAnim = true
	complexSwitchAngle = 0

	if complexMode.eq(C.I) and masterCycle and key[MASTER_CYCLE_COLORS[masterCycle]].across(C.I).neq(0):
		masterMode = key[MASTER_CYCLE_COLORS[masterCycle]].across(C.I).axis()
	elif complexMode.eq(1) and masterCycle and key[MASTER_CYCLE_COLORS[masterCycle]].across(1).neq(0):
		masterMode = key[MASTER_CYCLE_COLORS[masterCycle]].across(1).axis()
	elif masterCycle:
		AudioManager.play(preload("res://resources/sounds/player/masterUnequip.wav"))
		dropMaster()
	for object in game.objects.values(): if object is Door: object.complexCheck()
	for component in game.components.values(): if component is Lock: component.queue_redraw()

func _draw() -> void:
	RenderingServer.canvas_item_clear(auraDraw)
	RenderingServer.canvas_item_clear(masterShineDraw)
	RenderingServer.canvas_item_clear(masterKeyDraw)
	RenderingServer.canvas_item_clear(complexModeTextDraw)
	RenderingServer.canvas_item_clear(complexSwitchDraw)
	# auras
	if auraRed: RenderingServer.canvas_item_add_texture_rect(auraDraw,AURA_RECT,AURA_RED,false,AURA_DRAW_OPACITY)
	if auraGreen: RenderingServer.canvas_item_add_texture_rect(auraDraw,AURA_RECT,AURA_GREEN,false,AURA_DRAW_OPACITY)
	if auraBlue: RenderingServer.canvas_item_add_texture_rect(auraDraw,AURA_RECT,AURA_BLUE,false,AURA_DRAW_OPACITY)
	# held
	if masterCycle != 0:
		var masterShineScale:float = 0.8 + 0.2*sin(masterShineAngle)
		var masterDrawOpacity:Color = Color(Color.WHITE,masterShineScale*0.6)
		RenderingServer.canvas_item_add_texture_rect(masterShineDraw,Rect2(Vector2(-32,-32)*masterShineScale,Vector2(64,64)*masterShineScale),HELD_SHINE,false,getMasterShineColor())
		RenderingServer.canvas_item_add_texture_rect(masterKeyDraw,Rect2(Vector2(-16,-16),Vector2(32,32)),getHeldKeySprite(),false,masterDrawOpacity)
	if complexMode.eq(C.I):
		TextDraw.outlinedCentered(Game.FTALK,complexModeTextDraw,"I-View",Color.from_hsv(game.complexViewHue,0.4901960784,1),Color.BLACK,12,Vector2(0,-10))
	# complex switch
	if complexSwitchAnim:
		var switchScale:float = sin(complexSwitchAngle)
		RenderingServer.canvas_item_add_texture_rect(complexSwitchDraw,Rect2(Vector2(-64*switchScale,-64*switchScale),Vector2(128*switchScale,128*switchScale)),CurseParticle.TEXTURE_GENERIC,false,Color(Color.WHITE,cos(complexSwitchAngle)))
