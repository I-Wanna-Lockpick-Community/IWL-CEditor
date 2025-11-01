extends GameObject
class_name Door
const SCENE:PackedScene = preload("res://scenes/objects/door.tscn")

enum TYPE {SIMPLE, COMBO, GATE}

const FRAME:Texture2D = preload("res://assets/game/door/frame.png")
const FRAME_NEGATIVE:Texture2D = preload("res://assets/game/door/frameNegative.png")
const FRAME_HIGH:Texture2D = preload("res://assets/game/door/frameHigh.png")
const FRAME_MAIN:Texture2D = preload("res://assets/game/door/frameMain.png")
const FRAME_DARK:Texture2D = preload("res://assets/game/door/frameDark.png")

const SPEND_HIGH:Texture2D = preload("res://assets/game/door/spendHigh.png")
const SPEND_MAIN:Texture2D = preload("res://assets/game/door/spendMain.png")
const SPEND_DARK:Texture2D = preload("res://assets/game/door/spendDark.png")
const GATE_FILL:Texture2D = preload("res://assets/game/door/gateFill.png")

const CRUMBLED_1X1:Texture2D = preload("res://assets/game/door/aura/crumbled1x1.png")
const CRUMBLED_1X2:Texture2D = preload("res://assets/game/door/aura/crumbled1x2.png")
const CRUMBLED_2X2:Texture2D = preload("res://assets/game/door/aura/crumbled2x2.png")
const CRUMBLED_BASE:Texture2D = preload("res://assets/game/door/aura/crumbledBase.png")

const PAINTED_1X1:Texture2D = preload("res://assets/game/door/aura/painted1x1.png")
const PAINTED_1X2:Texture2D = preload("res://assets/game/door/aura/painted1x2.png")
const PAINTED_2X2:Texture2D = preload("res://assets/game/door/aura/painted2x2.png")
const PAINTED_BASE:Texture2D = preload("res://assets/game/door/aura/paintedBase.png")
const PAINTED_MATERIAL:ShaderMaterial = preload("res://resources/materials/paintedDrawMaterial.tres")

const FROZEN_1X1:Texture2D = preload("res://assets/game/door/aura/frozen1x1.png")
const FROZEN_1X2:Texture2D = preload("res://assets/game/door/aura/frozen1x2.png")
const FROZEN_2X2:Texture2D = preload("res://assets/game/door/aura/frozen2x2.png")
const FROZEN_3X2:Texture2D = preload("res://assets/game/door/aura/frozen3x2.png")
const FROZEN_MATERIAL:ShaderMaterial = preload("res://resources/materials/frozenDrawMaterial.tres")

const GLITCH_HIGH:Texture2D = preload("res://assets/game/door/glitch/high.png")
const GLITCH_MAIN:Texture2D = preload("res://assets/game/door/glitch/main.png")
const GLITCH_DARK:Texture2D = preload("res://assets/game/door/glitch/dark.png")
const MASTER_GLITCH:Texture2D = preload("res://assets/game/door/glitch/master.png")
const PURE_GLITCH:Texture2D = preload("res://assets/game/door/glitch/pure.png")
const STONE_GLITCH:Texture2D = preload("res://assets/game/door/glitch/stone.png")
const DYNAMITE_GLITCH:Texture2D = preload("res://assets/game/door/glitch/dynamite.png")
const QUICKSILVER_GLITCH:Texture2D = preload("res://assets/game/door/glitch/quicksilver.png")


const TEXTURE_RECT:Rect2 = Rect2(Vector2.ZERO,Vector2(64,64)) # size of all the door textures
const CORNER_SIZE:Vector2 = Vector2(9,9) # size of door ninepatch corners
const GLITCH_CORNER_SIZE:Vector2 = Vector2(16,16) # except glitchdraw is a different size
const TILE:RenderingServer.NinePatchAxisMode = RenderingServer.NinePatchAxisMode.NINE_PATCH_TILE # just to save characters
const STRETCH:RenderingServer.NinePatchAxisMode = RenderingServer.NinePatchAxisMode.NINE_PATCH_STRETCH # just to save characters

const CREATE_PARAMETERS:Array[StringName] = [
	&"position"
]
const EDITOR_PROPERTIES:Array[StringName] = [
	&"id", &"position", &"size",
	&"colorSpend", &"copies", &"type",
	&"frozen", &"crumbled", &"painted"
]

var colorSpend:Game.COLOR = Game.COLOR.WHITE
var copies:C = C.ONE
var type:TYPE = TYPE.SIMPLE
var frozen:bool = false
var crumbled:bool = false
var painted:bool = false

var drawScaled:RID
var drawGlitch:RID
var drawMain:RID
var drawCrumbled:RID
var drawPainted:RID
var drawFrozen:RID
var drawCopies:RID
var drawNegative:RID

var locks:Array[Lock] = []

@onready var locksParent:Node2D = %locksParent

const COPIES_COLOR = Color("#edeae7")
const COPIES_OUTLINE_COLOR = Color("#3e2d1c")

func _init() -> void: size = Vector2(32,32)

func _ready() -> void:
	drawScaled = RenderingServer.canvas_item_create()
	drawGlitch = RenderingServer.canvas_item_create()
	drawMain = RenderingServer.canvas_item_create()
	drawCrumbled = RenderingServer.canvas_item_create()
	drawPainted = RenderingServer.canvas_item_create()
	drawFrozen = RenderingServer.canvas_item_create()
	drawCopies = RenderingServer.canvas_item_create()
	drawNegative = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_material(drawGlitch,Game.GLITCH_MATERIAL.get_rid())
	RenderingServer.canvas_item_set_material(drawPainted,PAINTED_MATERIAL.get_rid())
	RenderingServer.canvas_item_set_material(drawFrozen,FROZEN_MATERIAL.get_rid())
	RenderingServer.canvas_item_set_material(drawNegative,Game.NEGATIVE_MATERIAL.get_rid())
	RenderingServer.canvas_item_set_z_index(drawCopies,1)
	RenderingServer.canvas_item_set_z_index(drawNegative,1)
	RenderingServer.canvas_item_set_parent(drawScaled,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawGlitch,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawMain,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawCrumbled, %auraParent.get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawPainted, %auraParent.get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawFrozen, %auraParent.get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawCopies,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawNegative,get_canvas_item())
	game.connect(&"goldIndexChanged",queue_redraw)

func _draw() -> void:
	RenderingServer.canvas_item_clear(drawScaled)
	RenderingServer.canvas_item_clear(drawGlitch)
	RenderingServer.canvas_item_clear(drawMain)
	RenderingServer.canvas_item_clear(drawCrumbled)
	RenderingServer.canvas_item_clear(drawPainted)
	RenderingServer.canvas_item_clear(drawFrozen)
	RenderingServer.canvas_item_clear(drawCopies)
	RenderingServer.canvas_item_clear(drawNegative)
	if !active and game.playState == Game.PLAY_STATE.PLAY: return
	var rect:Rect2 = Rect2(Vector2.ZERO, size)
	# fill
	var texture:Texture2D
	var tileTexture:bool = false
	if type == TYPE.GATE:
		RenderingServer.canvas_item_add_texture_rect(drawMain,rect,GATE_FILL,true,Color(Color.WHITE,lerp(0.35,1.0,gateAlpha)))
	else:
		if animState != ANIM_STATE.RELOCK or animPart > 2:
			match colorAfterCurse():
				Game.COLOR.MASTER: texture = game.masterTex()
				Game.COLOR.PURE: texture = game.pureTex()
				Game.COLOR.STONE: texture = game.stoneTex()
				Game.COLOR.DYNAMITE: texture = game.dynamiteTex(); tileTexture = true
				Game.COLOR.QUICKSILVER: texture = game.quicksilverTex()
			if texture:
				if !tileTexture:
					RenderingServer.canvas_item_set_material(drawScaled,Game.PIXELATED_MATERIAL.get_rid())
					RenderingServer.canvas_item_set_instance_shader_parameter(drawScaled, &"size", size)
				RenderingServer.canvas_item_add_texture_rect(drawScaled,rect,texture,tileTexture)
			elif colorAfterCurse() == Game.COLOR.GLITCH:
				RenderingServer.canvas_item_add_nine_patch(drawGlitch,rect,TEXTURE_RECT,SPEND_HIGH,CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,Game.highTone[Game.COLOR.GLITCH])
				RenderingServer.canvas_item_add_nine_patch(drawGlitch,rect,TEXTURE_RECT,SPEND_MAIN,CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,Game.mainTone[Game.COLOR.GLITCH])
				RenderingServer.canvas_item_add_nine_patch(drawGlitch,rect,TEXTURE_RECT,SPEND_DARK,CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,Game.darkTone[Game.COLOR.GLITCH])
				if colorAfterGlitch() != Game.COLOR.GLITCH:
					var glitchTexture:Texture2D
					match colorAfterGlitch():
						Game.COLOR.MASTER: glitchTexture = MASTER_GLITCH
						Game.COLOR.PURE: glitchTexture = PURE_GLITCH
						Game.COLOR.STONE: glitchTexture = STONE_GLITCH
						Game.COLOR.DYNAMITE: glitchTexture = DYNAMITE_GLITCH
						Game.COLOR.QUICKSILVER: glitchTexture = QUICKSILVER_GLITCH
					if glitchTexture:
						RenderingServer.canvas_item_add_nine_patch(drawMain,rect,TEXTURE_RECT,glitchTexture,GLITCH_CORNER_SIZE,GLITCH_CORNER_SIZE,TILE,TILE)
					else:
						RenderingServer.canvas_item_add_nine_patch(drawMain,rect,TEXTURE_RECT,GLITCH_HIGH,GLITCH_CORNER_SIZE,GLITCH_CORNER_SIZE,TILE,TILE,true,Game.highTone[colorAfterGlitch()])
						RenderingServer.canvas_item_add_nine_patch(drawMain,rect,TEXTURE_RECT,GLITCH_MAIN,GLITCH_CORNER_SIZE,GLITCH_CORNER_SIZE,TILE,TILE,true,Game.mainTone[colorAfterGlitch()])
						RenderingServer.canvas_item_add_nine_patch(drawMain,rect,TEXTURE_RECT,GLITCH_DARK,GLITCH_CORNER_SIZE,GLITCH_CORNER_SIZE,TILE,TILE,true,Game.darkTone[colorAfterGlitch()])
			else:
				RenderingServer.canvas_item_add_nine_patch(drawMain,rect,TEXTURE_RECT,SPEND_HIGH,CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,Game.highTone[colorAfterCurse()])
				RenderingServer.canvas_item_add_nine_patch(drawMain,rect,TEXTURE_RECT,SPEND_MAIN,CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,Game.mainTone[colorAfterCurse()])
				RenderingServer.canvas_item_add_nine_patch(drawMain,rect,TEXTURE_RECT,SPEND_DARK,CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,Game.darkTone[colorAfterCurse()])
		# frame
		if drawComplex:
			RenderingServer.canvas_item_add_nine_patch(drawMain,rect,TEXTURE_RECT,FRAME_HIGH,CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,Color.from_hsv(game.complexViewHue,0.4901960784,1))
			RenderingServer.canvas_item_add_nine_patch(drawMain,rect,TEXTURE_RECT,FRAME_MAIN,CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,Color.from_hsv(game.complexViewHue,0.7058823529,0.9019607843))
			RenderingServer.canvas_item_add_nine_patch(drawMain,rect,TEXTURE_RECT,FRAME_DARK,CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,Color.from_hsv(game.complexViewHue,1,0.7450980392))
		elif (len(locks) > 0 and type == TYPE.SIMPLE and locks[0].count.sign() < 0) != (ipow().sign() < 0): RenderingServer.canvas_item_add_nine_patch(drawMain,rect,TEXTURE_RECT,FRAME_NEGATIVE,CORNER_SIZE,CORNER_SIZE)
		else: RenderingServer.canvas_item_add_nine_patch(drawMain,rect,TEXTURE_RECT,FRAME,CORNER_SIZE,CORNER_SIZE)
	# auras
	if crumbled if game.playState == Game.PLAY_STATE.EDIT else gameCrumbled:
		if size == Vector2(32,32): RenderingServer.canvas_item_add_texture_rect(drawCrumbled,Rect2(Vector2.ZERO, size),CRUMBLED_1X1)
		elif size == Vector2(32,64): RenderingServer.canvas_item_add_texture_rect(drawCrumbled,Rect2(Vector2.ZERO, size),CRUMBLED_1X2)
		elif size == Vector2(64,64): RenderingServer.canvas_item_add_texture_rect(drawCrumbled,Rect2(Vector2.ZERO, size),CRUMBLED_2X2)
		else:
			RenderingServer.canvas_item_add_nine_patch(drawCrumbled,rect,TEXTURE_RECT,CRUMBLED_BASE,Vector2(16,18),Vector2(16,14),TILE,TILE,true)
	if painted if game.playState == Game.PLAY_STATE.EDIT else gamePainted:
		RenderingServer.canvas_item_set_instance_shader_parameter(drawPainted, &"scale", Vector2(0,0))
		if size == Vector2(32,32): RenderingServer.canvas_item_add_texture_rect(drawPainted,Rect2(Vector2.ZERO, size),PAINTED_1X1)
		elif size == Vector2(32,64): RenderingServer.canvas_item_add_texture_rect(drawPainted,Rect2(Vector2.ZERO, size),PAINTED_1X2)
		elif size == Vector2(64,64): RenderingServer.canvas_item_add_texture_rect(drawPainted,Rect2(Vector2.ZERO, size),PAINTED_2X2)
		else:
			RenderingServer.canvas_item_set_instance_shader_parameter(drawPainted, &"scale", size/128)
			RenderingServer.canvas_item_add_texture_rect(drawPainted,rect,PAINTED_BASE,true)
	if frozen if game.playState == Game.PLAY_STATE.EDIT else gameFrozen:
		RenderingServer.canvas_item_set_instance_shader_parameter(drawFrozen, &"size", Vector2(0,0))
		if size == Vector2(32,32): RenderingServer.canvas_item_add_texture_rect(drawFrozen,Rect2(Vector2.ZERO, size),FROZEN_1X1)
		elif size == Vector2(32,64): RenderingServer.canvas_item_add_texture_rect(drawFrozen,Rect2(Vector2.ZERO, size),FROZEN_1X2)
		elif size == Vector2(64,64): RenderingServer.canvas_item_add_texture_rect(drawFrozen,Rect2(Vector2.ZERO, size),FROZEN_2X2)
		elif size == Vector2(96,64): RenderingServer.canvas_item_add_texture_rect(drawFrozen,Rect2(Vector2.ZERO, size),FROZEN_3X2)
		else:
			RenderingServer.canvas_item_set_instance_shader_parameter(drawFrozen, &"size", size)
			RenderingServer.canvas_item_add_rect(drawFrozen,rect,Color.WHITE)
	# anim overlays
	if animState == ANIM_STATE.ADD_COPY: RenderingServer.canvas_item_add_rect(drawNegative,rect,Color(Color.WHITE,animAlpha))
	elif animState == ANIM_STATE.RELOCK: RenderingServer.canvas_item_add_rect(drawCopies,rect,Color(Color.WHITE,animAlpha)) # just to be on top of everything else
	# copies
	if game.playState == Game.PLAY_STATE.EDIT:
		if !copies.eq(1): TextDraw.outlinedCentered(Game.FKEYX,drawCopies,"×"+str(copies),COPIES_COLOR,COPIES_OUTLINE_COLOR,20,Vector2(size.x/2,-8))
	else:
		if !gameCopies.eq(1): TextDraw.outlinedCentered(Game.FKEYX,drawCopies,"×"+str(gameCopies),COPIES_COLOR,COPIES_OUTLINE_COLOR,20,Vector2(size.x/2,-8))

func receiveMouseInput(event:InputEventMouse) -> bool:
	# resizing
	if editor.componentDragged: return false
	var dragCornerSize:Vector2 = Vector2(8,8)/editor.cameraZoom
	var diffSign:Vector2 = Editor.rectSign(Rect2(position+dragCornerSize,size-dragCornerSize*2), editor.mouseWorldPosition)
	var dragPivot:Editor.SIZE_DRAG_PIVOT = Editor.SIZE_DRAG_PIVOT.NONE
	match diffSign:
		Vector2(-1,-1): dragPivot = Editor.SIZE_DRAG_PIVOT.TOP_LEFT;	editor.mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
		Vector2(0,-1): dragPivot = Editor.SIZE_DRAG_PIVOT.TOP;			editor.mouse_default_cursor_shape = Control.CURSOR_VSIZE
		Vector2(1,-1): dragPivot = Editor.SIZE_DRAG_PIVOT.TOP_RIGHT;	editor.mouse_default_cursor_shape = Control.CURSOR_BDIAGSIZE
		Vector2(-1,0): dragPivot = Editor.SIZE_DRAG_PIVOT.LEFT;			editor.mouse_default_cursor_shape = Control.CURSOR_HSIZE
		Vector2(1,0): dragPivot = Editor.SIZE_DRAG_PIVOT.RIGHT;			editor.mouse_default_cursor_shape = Control.CURSOR_HSIZE
		Vector2(-1,1): dragPivot = Editor.SIZE_DRAG_PIVOT.BOTTOM_LEFT;	editor.mouse_default_cursor_shape = Control.CURSOR_BDIAGSIZE
		Vector2(0,1): dragPivot = Editor.SIZE_DRAG_PIVOT.BOTTOM;		editor.mouse_default_cursor_shape = Control.CURSOR_VSIZE
		Vector2(1,1): dragPivot = Editor.SIZE_DRAG_PIVOT.BOTTOM_RIGHT;	editor.mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
	if dragPivot != Editor.SIZE_DRAG_PIVOT.NONE and Editor.isLeftClick(event):
		editor.startSizeDrag(self, dragPivot)
		return true
	return false

func propertyChangedInit(property:StringName) -> void:
	if property == &"type":
		match type:
			TYPE.SIMPLE:
				if len(locks) == 0: addLock()
				elif len(locks) > 1:
					for lockIndex in range(1,len(locks)):
						removeLock(lockIndex)
				locks[0]._simpleDoorUpdate()
			TYPE.COMBO:
				if !mods.active(&"NstdLockSize"):
					for lock in locks: lock._coerceSize()
			TYPE.GATE:
				if !mods.active(&"NstdLockSize"):
					for lock in locks: lock._coerceSize()
				changes.addChange(Changes.PropertyChange.new(game,self,&"color",Game.COLOR.WHITE))
				changes.addChange(Changes.PropertyChange.new(game,self,&"copies",C.ONE))
				changes.addChange(Changes.PropertyChange.new(game,self,&"frozen",false))
				changes.addChange(Changes.PropertyChange.new(game,self,&"crumbled",false))
				changes.addChange(Changes.PropertyChange.new(game,self,&"painted",false))
	if property == &"size" and type == TYPE.SIMPLE and locks.get(0): locks[0]._simpleDoorUpdate() # ghhghghhh TODO: figure this out

func propertyChangedDo(property:StringName) -> void:
	super(property)
	if property == &"type" and editor.findProblems:
		for lock in locks: editor.findProblems.findProblems(lock)
	if property == &"size" or property == &"type":
		%shape.shape.size = size
		%shape.position = size/2
		%interactShape.shape.size = size
		%interactShape.position = size/2
		if type == TYPE.SIMPLE: %shape.shape.size -= Vector2(2,2)
		else: %interactShape.shape.size += Vector2(2,2)

func addLock() -> void:
	changes.addChange(Changes.CreateComponentChange.new(game,Lock,{&"position":getFirstFreePosition(),&"parentId":id}))
	if len(locks) == 1: changes.addChange(Changes.PropertyChange.new(game,self,&"type",TYPE.SIMPLE))
	elif type == Door.TYPE.SIMPLE: changes.addChange(Changes.PropertyChange.new(game,self,&"type",TYPE.COMBO))
	changes.bufferSave()

func getFirstFreePosition() -> Vector2:
	var x:float = 0
	while true:
		for y in floor(size.y/32):
			var rect:Rect2 = Rect2(Vector2(32*x+7,32*y+7), Vector2(32,32))
			var overlaps:bool = false
			for lock in locks:
				if Rect2(lock.position-lock.getOffset(), lock.size).intersects(rect):
					overlaps = true
					break
			if overlaps: continue
			return Vector2(32*x,32*y)
		x += 1
	return Vector2.ZERO # unreachable

func removeLock(index:int) -> void:
	changes.addChange(Changes.DeleteComponentChange.new(game,locks[index]))
	if type == Door.TYPE.SIMPLE: changes.addChange(Changes.PropertyChange.new(game,self,&"type",TYPE.COMBO))
	changes.bufferSave()

# ==== PLAY ==== #
var gameCopies:C = C.ONE
var gameFrozen:bool = false
var gameCrumbled:bool = false
var gamePainted:bool = false
var cursed:bool = false
var curseColor:Game.COLOR
var glitchMimic:Game.COLOR = Game.COLOR.GLITCH
var curseGlitchMimic:Game.COLOR = Game.COLOR.GLITCH

enum ANIM_STATE {IDLE, ADD_COPY, RELOCK}
var animState:ANIM_STATE = ANIM_STATE.IDLE
var animTimer:float = 0
var animAlpha:float = 0
var addCopySound:AudioStreamPlayer
var animPart:int = 0
var gateAlpha:float = 1
var gateOpen:bool = false
var gateBufferCheck:Player = null
var curseTimer:float = 0
var drawComplex:bool = false

func _process(delta:float) -> void:
	if cursed and active:
		curseTimer += delta
		if curseTimer >= 2:
			curseTimer -= 2
			makeCurseParticles(curseColor,1,0.2,0.3)
	match animState:
		ANIM_STATE.IDLE: animTimer = 0; animAlpha = 0
		ANIM_STATE.ADD_COPY:
			animTimer += delta*60
			if addCopySound: addCopySound.pitch_scale = 1 + 0.015*animTimer
			var animLength:float = lerp(50,10,game.fastAnimSpeed)
			animAlpha = 1 - animTimer/animLength
			if animTimer >= animLength: animState = ANIM_STATE.IDLE
			queue_redraw()
		ANIM_STATE.RELOCK:
			animTimer += delta*60
			var animLength:float = lerp(60,12,game.fastAnimSpeed)
			match animPart:
				0: if animTimer >= lerp(25,5,game.fastAnimSpeed):
					AudioManager.play(preload("res://resources/sounds/door/relock.wav"))
					animPart += 1
				1: if animTimer >= lerp(40,8,game.fastAnimSpeed):
					AudioManager.play(preload("res://resources/sounds/door/masterNegative.wav"))
					animAlpha = 1
					animPart += 1
				2: if animTimer >= lerp(50,10,game.fastAnimSpeed):
					animPart += 1
					for lock in locks: lock.queue_redraw()
				3:
					animAlpha -= delta*6 # 0.1 per frame, 60fps
			if animTimer >= animLength:
				animState = ANIM_STATE.IDLE
			queue_redraw()
	if type == TYPE.GATE:
		if gateBufferCheck and !gateBufferCheck.overlapping(%interact):
			gateBufferCheck = null
			gameChanges.addChange(GameChanges.PropertyChange.new(game,self,&"gateOpen",false))
		if !gateOpen and gateAlpha < 1:
			gateAlpha = min(gateAlpha+delta*6, 1)
			queue_redraw()
		elif gateOpen and gateAlpha > 0:
			gateAlpha = max(gateAlpha-delta*6, 0)
			queue_redraw()
	if drawComplex: queue_redraw()

func start() -> void:
	gameCopies = copies
	gameFrozen = frozen
	gameCrumbled = crumbled
	gamePainted = painted
	animState = ANIM_STATE.IDLE
	animTimer = 0
	animAlpha = 0
	animPart = 0
	propertyGameChangedDo(&"gateOpen")
	complexCheck()
	super()

func stop() -> void:
	cursed = false
	curseTimer = 0
	gateAlpha = 1
	gateOpen = false
	gateBufferCheck = null
	drawComplex = false
	glitchMimic = Game.COLOR.GLITCH
	curseGlitchMimic = Game.COLOR.GLITCH
	super()

func tryOpen(player:Player) -> void:
	if type == TYPE.GATE: return
	if animState != ANIM_STATE.IDLE: return
	if gameFrozen or gameCrumbled or gamePainted:
		if hasColor(Game.COLOR.PURE): return
		if int(gameFrozen) + int(gameCrumbled) + int(gamePainted) > 1: return
		if gameFrozen and player.key[Game.COLOR.ICE].eq(0): return
		if gameCrumbled and player.key[Game.COLOR.MUD].eq(0): return
		if gamePainted and player.key[Game.COLOR.GRAFFITI].eq(0): return
	else:
		if player.key[Game.COLOR.DYNAMITE].neq(0) and tryDynamiteOpen(player): return
		if player.masterCycle == 1 and tryMasterOpen(player): return
		if player.masterCycle == 2 and tryQuicksilverOpen(player): return

	for lock in locks:
		if !lock.canOpen(player): return
	
	var cost:C = C.ZERO
	for lock in locks:
		cost = cost.plus(lock.getCost(player))
	
	gameChanges.addChange(GameChanges.KeyChange.new(game, colorAfterAurabreaker(), player.key[colorAfterAurabreaker()].minus(cost)))
	gameChanges.addChange(GameChanges.PropertyChange.new(game, self, &"gameCopies", gameCopies.minus(ipow())))
	
	if gameFrozen or gameCrumbled or gamePainted: AudioManager.play(preload("res://resources/sounds/door/deaura.wav"))
	else:
		match type:
			TYPE.SIMPLE:
				if locks[0].type == Lock.TYPE.BLAST: AudioManager.play(preload("res://resources/sounds/door/blast.wav"))
				elif colorAfterAurabreaker() == Game.COLOR.MASTER and locks[0].colorAfterAurabreaker() == Game.COLOR.MASTER: AudioManager.play(preload("res://resources/sounds/door/master.wav"))
				else: AudioManager.play(preload("res://resources/sounds/door/simple.wav"))
			TYPE.COMBO: AudioManager.play(preload("res://resources/sounds/door/combo.wav"))
		game.setGlitch(colorAfterAurabreaker())

	if gameCopies.eq(0): destroy()
	else: relockAnimation()
	gameChanges.bufferSave()

func tryMasterOpen(player:Player) -> bool:
	if hasColor(Game.COLOR.MASTER): return false
	if hasColor(Game.COLOR.PURE): return false

	var openedForwards:bool = gameCopies.across(player.masterMode).sign() > 0
	gameChanges.addChange(GameChanges.PropertyChange.new(game, self, &"gameCopies", gameCopies.minus(player.masterMode)))
	gameChanges.addChange(GameChanges.KeyChange.new(game, Game.COLOR.MASTER, player.key[Game.COLOR.MASTER].minus(player.masterMode)))
	
	if openedForwards:
		AudioManager.play(preload("res://resources/sounds/door/master.wav"))
		if gameCopies.eq(0): destroy()
		else: relockAnimation()
	else:
		AudioManager.play(preload("res://resources/sounds/door/masterNegative.wav"))
		addCopyAnimation()

	player.dropMaster()
	gameChanges.bufferSave()
	return true

func tryQuicksilverOpen(player:Player) -> bool:
	if hasColor(Game.COLOR.QUICKSILVER): return false
	if hasColor(Game.COLOR.PURE): return false

	var cost:C = C.ZERO
	for lock in locks:
		cost = cost.plus(lock.getCost(player, player.masterMode))
	
	gameChanges.addChange(GameChanges.KeyChange.new(game, Game.COLOR.QUICKSILVER, player.key[Game.COLOR.QUICKSILVER].minus(player.masterMode)))
	gameChanges.addChange(GameChanges.KeyChange.new(game, colorAfterGlitch(), player.key[colorAfterGlitch()].plus(cost)))

	AudioManager.play(preload("res://resources/sounds/door/master.wav"))
	relockAnimation()

	game.setGlitch(colorAfterGlitch())

	player.dropMaster()
	gameChanges.bufferSave()

	return true

func tryDynamiteOpen(player:Player) -> bool:
	if hasColor(Game.COLOR.DYNAMITE): return false
	if hasColor(Game.COLOR.PURE): return false

	var openedForwards:bool
	var openedBackwards:bool

	if player.key[Game.COLOR.DYNAMITE].across(gameCopies.axis()).minus(gameCopies.abs()).nonNegative():
		# if the door can open, open it
		gameChanges.addChange(GameChanges.KeyChange.new(game, Game.COLOR.DYNAMITE, player.key[Game.COLOR.DYNAMITE].minus(gameCopies)))
		gameChanges.addChange(GameChanges.PropertyChange.new(game, self, &"gameCopies", C.ZERO))
		
		openedForwards = true
	else:
		openedForwards = player.key[Game.COLOR.DYNAMITE].across(gameCopies.axis()).hasPositive()
		openedBackwards = player.key[Game.COLOR.DYNAMITE].across(gameCopies.axis()).hasNonPositive()
		print(player.key[Game.COLOR.DYNAMITE].across(gameCopies.axis()).hasNonPositive())

		gameChanges.addChange(GameChanges.PropertyChange.new(game, self, &"gameCopies", gameCopies.minus(player.key[Game.COLOR.DYNAMITE])))
		gameChanges.addChange(GameChanges.KeyChange.new(game, Game.COLOR.DYNAMITE, C.ZERO))

	if openedForwards:
		AudioManager.play(preload("res://resources/sounds/door/explode.wav"))
		if gameCopies.eq(0): destroy()
		else: relockAnimation()
		add_child(ExplosionParticle.new(size/2,1))
	if openedBackwards:
		AudioManager.play(preload("res://resources/sounds/door/explodeNegative.wav"))
		if !openedForwards:
			addCopyAnimation()
			add_child(ExplosionParticle.new(size/2,-1))

	gameChanges.bufferSave()
	return true

func hasColor(color:Game.COLOR) -> bool:
	if colorAfterGlitch() == color: return true
	for lock in locks: if lock.colorAfterGlitch() == color: return true
	return false

func destroy() -> void:
	gameChanges.addChange(GameChanges.PropertyChange.new(game, self, &"active", false))
	var color:Game.COLOR = colorAfterCurse()
	if type == TYPE.SIMPLE: color = locks[0].colorAfterCurse()
	makeDebris(Debris, color)

func addCopyAnimation() -> void:
	animState = ANIM_STATE.ADD_COPY
	animTimer = 0
	animAlpha = 0
	animPart = 0
	game.fasterAnims()
	addCopySound = AudioManager.play(preload("res://resources/sounds/door/addCopy.wav"))
	var color:Game.COLOR = colorAfterCurse()
	if type == TYPE.SIMPLE: color = locks[0].colorAfterCurse()
	makeDebris(AddCopyDebris, color)

func relockAnimation() -> void:
	animState = ANIM_STATE.RELOCK
	animTimer = 0
	animAlpha = 0
	animPart = 0
	game.fasterAnims()
	for lock in locks: lock.queue_redraw()
	var color:Game.COLOR = colorAfterCurse()
	if type == TYPE.SIMPLE: color = locks[0].colorAfterCurse()
	makeDebris(RelockDebris, color)

func makeDebris(debrisType:GDScript, debrisColor:Game.COLOR) -> void:
	for y in floor(size.y/16):
		for x in floor(size.x/16):
			add_child(debrisType.new(game,debrisColor,Vector2(x*16,y*16)))

func propertyGameChangedDo(property:StringName) -> void:
	if property == &"active":
		%collision.process_mode = PROCESS_MODE_INHERIT if active else PROCESS_MODE_DISABLED
		%interact.process_mode = PROCESS_MODE_INHERIT if active else PROCESS_MODE_DISABLED
	if property == &"gateOpen" and type == TYPE.GATE:
		%collision.process_mode = PROCESS_MODE_DISABLED if gateOpen else PROCESS_MODE_INHERIT

func gateCheck(player:Player) -> void:
	var shouldOpen:bool = true
	for lock in locks:
		if !lock.canOpen(player): shouldOpen = false
	if gateOpen and !shouldOpen:
		gateBufferCheck = player
	elif !gateOpen and shouldOpen:
		gateBufferCheck = null
		gameChanges.addChange(GameChanges.PropertyChange.new(game,self,&"gateOpen",true))

func auraCheck(player:Player) -> void:
	var deAuraed:bool = false
	if player.auraRed and gameFrozen:
		gameChanges.addChange(GameChanges.PropertyChange.new(game,self,&"gameFrozen",false))
		makeDebris(Debris, Game.COLOR.WHITE)
		deAuraed = true
	if player.auraGreen and gameCrumbled:
		gameChanges.addChange(GameChanges.PropertyChange.new(game,self,&"gameCrumbled",false))
		makeDebris(Debris, Game.COLOR.BROWN)
		deAuraed = true
	if player.auraBlue and gamePainted:
		gameChanges.addChange(GameChanges.PropertyChange.new(game,self,&"gamePainted",false))
		makeDebris(Debris, Game.COLOR.ORANGE)
		deAuraed = true
	var auraed:bool = false
	if player.auraMaroon and !gameFrozen:
		gameChanges.addChange(GameChanges.PropertyChange.new(game,self,&"gameFrozen",true))
		makeDebris(Debris, Game.COLOR.WHITE)
		auraed = true
	if player.auraForest and !gameCrumbled:
		gameChanges.addChange(GameChanges.PropertyChange.new(game,self,&"gameCrumbled",true))
		makeDebris(Debris, Game.COLOR.BROWN)
		auraed = true
	if player.auraNavy and !gamePainted:
		gameChanges.addChange(GameChanges.PropertyChange.new(game,self,&"gamePainted",true))
		makeDebris(Debris, Game.COLOR.ORANGE)
		auraed = true
	if deAuraed or auraed:
		AudioManager.play(preload("res://resources/sounds/door/deaura.wav"))
		changes.bufferSave()


func isAllColor(color:Game.COLOR) -> bool:
	if colorSpend != color: return false
	for lock in locks: if lock.color != color: return false
	return true

func curseCheck(player:Player) -> void:
	if hasColor(Game.COLOR.PURE): return
	if gameFrozen or gameCrumbled or gamePainted: return
	if player.curseMode > 0 and !isAllColor(player.curseColor) and (!cursed or curseColor != player.curseColor):
		gameChanges.addChange(GameChanges.PropertyChange.new(game,self,&"cursed",true))
		gameChanges.addChange(GameChanges.PropertyChange.new(game,self,&"curseColor",player.curseColor))
		makeCurseParticles(curseColor, 1, 0.2, 0.5)
		AudioManager.play(preload("res://resources/sounds/door/curse.wav"))
		changes.bufferSave()
	elif player.curseMode < 0 and cursed and curseColor == player.curseColor:
		gameChanges.addChange(GameChanges.PropertyChange.new(game,self,&"cursed",false))
		if curseColor == Game.COLOR.GLITCH:
			gameChanges.addChange(GameChanges.PropertyChange.new(game,self,&"curseGlitchMimic",Game.COLOR.GLITCH))
			for lock in locks:
				gameChanges.addChange(GameChanges.PropertyChange.new(game,lock,&"curseGlitchMimic",Game.COLOR.GLITCH))
		makeCurseParticles(Game.COLOR.BROWN, -1, 0.2, 0.5)
		AudioManager.play(preload("res://resources/sounds/door/decurse.wav"))
		changes.bufferSave()

func makeCurseParticles(color:Game.COLOR, mode:int, scaleMin:float=1,scaleMax:float=1) -> void:
	for y in floor(size.y/16):
		for x in floor(size.x/16):
			add_child(CurseParticle.Temporary.new(color, mode, Vector2(x,y)*16+Vector2.ONE*randf_range(4,12), randf_range(scaleMin,scaleMax)))

func colorAfterCurse() -> Game.COLOR:
	if cursed and curseColor != Game.COLOR.PURE: return curseColor
	return colorSpend

func colorAfterGlitch() -> Game.COLOR:
	var base:Game.COLOR = colorAfterCurse()
	if base == Game.COLOR.GLITCH: return curseGlitchMimic if cursed else glitchMimic
	return base

func colorAfterAurabreaker() -> Game.COLOR:
	if gameFrozen: return Game.COLOR.ICE
	if gameCrumbled: return Game.COLOR.MUD
	if gamePainted: return Game.COLOR.GRAFFITI
	return colorAfterGlitch()

func ipow() -> C: # for complex view
	if game.playState == Game.PLAY_STATE.EDIT: return C.ONE
	if gameCopies.across(game.player.complexMode).neq(0): return gameCopies.across(game.player.complexMode).axis()
	return gameCopies.across(game.player.complexMode.times(C.I).axibs()).axis()

func complexCheck() -> void:
	drawComplex = game.playState != Game.PLAY_STATE.EDIT and ipow().across(game.player.complexMode).eq(0)
	queue_redraw()

func setGlitch(setColor:Game.COLOR) -> void:
	if !cursed:
		gameChanges.addChange(GameChanges.PropertyChange.new(game, self, &"glitchMimic", setColor))
		for lock in locks:
			gameChanges.addChange(GameChanges.PropertyChange.new(game, lock, &"glitchMimic", setColor))
			lock.queue_redraw()
		queue_redraw()
	elif curseColor == Game.COLOR.GLITCH:
		gameChanges.addChange(GameChanges.PropertyChange.new(game, self, &"curseGlitchMimic", setColor))
		for lock in locks:
			gameChanges.addChange(GameChanges.PropertyChange.new(game, lock, &"curseGlitchMimic", setColor))
			lock.queue_redraw()
		queue_redraw()

class Debris extends Node2D:
	const FRAME:Texture2D = preload("res://assets/game/door/debris/frame.png")
	const HIGH:Texture2D = preload("res://assets/game/door/debris/high.png")
	const MAIN:Texture2D = preload("res://assets/game/door/debris/main.png")
	const DARK:Texture2D = preload("res://assets/game/door/debris/dark.png")

	var game:Game
	var color:Game.COLOR
	var opacity:float = 1
	var velocity:Vector2 = Vector2.ZERO
	var acceleration:Vector2 = Vector2.ZERO
	var fadeSpeed:float

	const FPS:float = 60

	func _init(_game:Game,_color:Game.COLOR,_position) -> void:
		game = _game
		color = _color
		position = _position
	
	func _ready() -> void:
		velocity.x = randf_range(-1.2,1.2)
		velocity.y = randf_range(-4,-3)
		acceleration.y = randf_range(0.4,0.5)
		fadeSpeed = 0.04
	
	func _physics_process(_delta:float) -> void:
		opacity -= fadeSpeed
		modulate.a = opacity
		if opacity <= 0: queue_free()

		position += velocity
		velocity += acceleration

	func _draw() -> void:
		var rect:Rect2 = Rect2(Vector2.ZERO,Vector2(16,16))
		RenderingServer.canvas_item_add_texture_rect(get_canvas_item(),rect,FRAME)
		RenderingServer.canvas_item_add_texture_rect(get_canvas_item(),rect,HIGH,false,Game.highTone[color])
		RenderingServer.canvas_item_add_texture_rect(get_canvas_item(),rect,MAIN,false,Game.mainTone[color])
		RenderingServer.canvas_item_add_texture_rect(get_canvas_item(),rect,DARK,false,Game.darkTone[color])

class AddCopyDebris extends Debris:
	
	func _ready() -> void:
		velocity = Vector2(0.8,0).rotated(randf_range(0,TAU))
		fadeSpeed = 0.03

	func _draw() -> void:
		var rect:Rect2 = Rect2(Vector2.ZERO,Vector2(16,16))
		RenderingServer.canvas_item_add_texture_rect(get_canvas_item(),rect,FRAME)
		RenderingServer.canvas_item_add_texture_rect(get_canvas_item(),rect,HIGH,false,Game.highTone[color].inverted())
		RenderingServer.canvas_item_add_texture_rect(get_canvas_item(),rect,MAIN,false,Game.mainTone[color].inverted())
		RenderingServer.canvas_item_add_texture_rect(get_canvas_item(),rect,DARK,false,Game.darkTone[color].inverted())

class RelockDebris extends Debris:
	var angle:float = randf_range(0,TAU)
	var speed:float = 1.5
	var startPosition:Vector2
	var part:int = 0
	var timer:int = 0
	var whiteAmt:float = 0

	func _ready() -> void:
		startPosition = position

	func _physics_process(_delta:float) -> void:
		match part:
			0:
				speed = max(speed - 0.06, 0.3)
				velocity = Vector2(speed,0).rotated(angle)
				position += Vector2(speed,0).rotated(angle)
				if timer >= lerp(25,5, game.fastAnimSpeed): part += 1; timer = 0
			1:
				position += (startPosition - position) * 0.3
				if position.distance_squared_to(startPosition) < 1: position = startPosition
				whiteAmt = min(whiteAmt+0.0666666667, 1)
				queue_redraw()
				if timer >= lerp(26,5, game.fastAnimSpeed): queue_free()
		timer += 1

	func _draw() -> void:
		var rect:Rect2 = Rect2(Vector2.ZERO,Vector2(16,16))
		RenderingServer.canvas_item_add_texture_rect(get_canvas_item(),rect,FRAME)
		RenderingServer.canvas_item_add_texture_rect(get_canvas_item(),rect,HIGH,false,Game.highTone[color])
		RenderingServer.canvas_item_add_texture_rect(get_canvas_item(),rect,MAIN,false,Game.mainTone[color])
		RenderingServer.canvas_item_add_texture_rect(get_canvas_item(),rect,DARK,false,Game.darkTone[color])
		RenderingServer.canvas_item_add_rect(get_canvas_item(),rect,Color(Color.WHITE,whiteAmt))
