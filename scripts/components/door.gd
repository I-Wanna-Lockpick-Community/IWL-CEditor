extends GameObject
class_name Door
const SCENE:PackedScene = preload("res://scenes/objects/door.tscn")

enum TYPE {SIMPLE, COMBO, GATE}

const FRAME:Texture2D = preload("res://assets/game/door/frame.png")
const FRAME_NEGATIVE:Texture2D = preload("res://assets/game/door/frameNegative.png")
const SPEND_HIGH:Texture2D = preload("res://assets/game/door/spendHigh.png")
const SPEND_MAIN:Texture2D = preload("res://assets/game/door/spendMain.png")
const SPEND_DARK:Texture2D = preload("res://assets/game/door/spendDark.png")
const GATE_FILL:Texture2D = preload("res://assets/game/door/gateFill.png")

const TEXTURE_RECT:Rect2 = Rect2(Vector2.ZERO,Vector2(64,64)) # size of all the door textures
const CORNER_SIZE:Vector2 = Vector2(9,9) # size of door ninepatch corners
const TILE:RenderingServer.NinePatchAxisMode = RenderingServer.NinePatchAxisMode.NINE_PATCH_TILE # just to save characters

const CREATE_PARAMETERS:Array[StringName] = [
	&"position"
]
const EDITOR_PROPERTIES:Array[StringName] = [
	&"id", &"position", &"size",
	&"colorSpend", &"copies", &"type"
]

var colorSpend:Game.COLOR = Game.COLOR.WHITE
var copies:C = C.new(1)
var type:TYPE = TYPE.SIMPLE

var drawScaled:RID
var drawMain:RID
var drawGlitch:RID
var drawCopies:RID
var drawNegative:RID

var locks:Array[Lock] = []

const COPIES_COLOR = Color("#edeae7")
const COPIES_OUTLINE_COLOR = Color("#3e2d1c")

func _init() -> void: size = Vector2(32,32)

func _ready() -> void:
	drawScaled = RenderingServer.canvas_item_create()
	drawMain = RenderingServer.canvas_item_create()
	drawGlitch = RenderingServer.canvas_item_create()
	drawCopies = RenderingServer.canvas_item_create()
	drawNegative = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_material(drawGlitch,Game.GLITCH_MATERIAL.get_rid())
	RenderingServer.canvas_item_set_material(drawNegative,Game.NEGATIVE_MATERIAL.get_rid())
	RenderingServer.canvas_item_set_z_index(drawCopies,1)
	RenderingServer.canvas_item_set_z_index(drawNegative,1)
	RenderingServer.canvas_item_set_parent(drawScaled,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawMain,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawGlitch,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawCopies,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawNegative,get_canvas_item())
	editor.game.connect(&"goldIndexChanged",queue_redraw)

func _draw() -> void:
	RenderingServer.canvas_item_clear(drawScaled)
	RenderingServer.canvas_item_clear(drawMain)
	RenderingServer.canvas_item_clear(drawGlitch)
	RenderingServer.canvas_item_clear(drawCopies)
	RenderingServer.canvas_item_clear(drawNegative)
	if !active and editor.game.playState == Game.PLAY_STATE.PLAY: return
	var rect:Rect2 = Rect2(Vector2.ZERO, size)
	# fill
	var texture:Texture2D
	var tileTexture:bool = false
	if type == TYPE.GATE:
		RenderingServer.canvas_item_add_texture_rect(drawMain,rect,GATE_FILL,true)
	else:
		if animState != ANIM_STATE.RELOCK or animPart > 2:
			match colorSpend:
				Game.COLOR.MASTER: texture = editor.game.masterTex()
				Game.COLOR.PURE: texture = editor.game.pureTex()
				Game.COLOR.STONE: texture = editor.game.stoneTex()
				Game.COLOR.DYNAMITE: texture = editor.game.dynamiteTex(); tileTexture = true
				Game.COLOR.QUICKSILVER: texture = editor.game.quicksilverTex()
			if texture:
				if !tileTexture:
					RenderingServer.canvas_item_set_material(drawScaled,Game.PIXELATED_MATERIAL.get_rid())
					RenderingServer.canvas_item_set_instance_shader_parameter(drawScaled, &"size", size)
				RenderingServer.canvas_item_add_texture_rect(drawScaled,rect,texture,tileTexture)
			elif colorSpend == Game.COLOR.GLITCH:
				RenderingServer.canvas_item_add_nine_patch(drawGlitch,rect,TEXTURE_RECT,SPEND_HIGH,CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,Game.highTone[Game.COLOR.GLITCH])
				RenderingServer.canvas_item_add_nine_patch(drawGlitch,rect,TEXTURE_RECT,SPEND_MAIN,CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,Game.mainTone[Game.COLOR.GLITCH])
				RenderingServer.canvas_item_add_nine_patch(drawGlitch,rect,TEXTURE_RECT,SPEND_DARK,CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,Game.darkTone[Game.COLOR.GLITCH])
			else:
				RenderingServer.canvas_item_add_nine_patch(drawMain,rect,TEXTURE_RECT,SPEND_HIGH,CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,Game.highTone[colorSpend])
				RenderingServer.canvas_item_add_nine_patch(drawMain,rect,TEXTURE_RECT,SPEND_MAIN,CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,Game.mainTone[colorSpend])
				RenderingServer.canvas_item_add_nine_patch(drawMain,rect,TEXTURE_RECT,SPEND_DARK,CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,Game.darkTone[colorSpend])
		# frame
		if len(locks) > 0 and type == TYPE.SIMPLE and locks[0].count.sign() < 0: RenderingServer.canvas_item_add_nine_patch(drawMain,rect,TEXTURE_RECT,FRAME_NEGATIVE,CORNER_SIZE,CORNER_SIZE)
		else: RenderingServer.canvas_item_add_nine_patch(drawMain,rect,TEXTURE_RECT,FRAME,CORNER_SIZE,CORNER_SIZE)
	# anim overlays
	if animState == ANIM_STATE.ADD_COPY: RenderingServer.canvas_item_add_rect(drawNegative,rect,Color(Color.WHITE,animAlpha))
	elif animState == ANIM_STATE.RELOCK: RenderingServer.canvas_item_add_rect(drawCopies,rect,Color(Color.WHITE,animAlpha)) # just to be on top of everything else
	# copies
	if editor.game.playState == Game.PLAY_STATE.EDIT:
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
				changes.addChange(Changes.PropertyChange.new(editor.game,self,&"color",Game.COLOR.WHITE))
	if property == &"size" and type == TYPE.SIMPLE: locks[0]._simpleDoorUpdate()

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
	changes.addChange(Changes.CreateComponentChange.new(editor.game,Lock,{&"position":getFirstFreePosition(),&"parentId":id}))
	if len(locks) == 1: editor.focusDialog._doorTypeSelected(Door.TYPE.SIMPLE)
	elif type == Door.TYPE.SIMPLE: editor.focusDialog._doorTypeSelected(Door.TYPE.COMBO)
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
	changes.addChange(Changes.DeleteComponentChange.new(editor.game,locks[index]))
	if type == Door.TYPE.SIMPLE: changes.addChange(Changes.PropertyChange.new(editor.game,self,&"type",TYPE.COMBO))
	changes.bufferSave()

# ==== PLAY ==== #
var gameCopies:C = C.new(1)

enum ANIM_STATE {IDLE, ADD_COPY, RELOCK}
var animState:ANIM_STATE = ANIM_STATE.IDLE
var animTimer:float = 0
var animAlpha:float = 0
var addCopySound:AudioStreamPlayer
var animPart:int = 0

func _process(delta:float) -> void:
	match animState:
		ANIM_STATE.IDLE: animTimer = 0; animAlpha = 0
		ANIM_STATE.ADD_COPY:
			animTimer += delta*60
			if addCopySound: addCopySound.pitch_scale = 1 + 0.015*animTimer
			var animLength:float = lerp(50,10,editor.game.fastAnimSpeed)
			animAlpha = 1 - animTimer/animLength
			if animTimer >= animLength: animState = ANIM_STATE.IDLE
			queue_redraw()
		ANIM_STATE.RELOCK:
			animTimer += delta*60
			var animLength:float = lerp(60,12,editor.game.fastAnimSpeed)
			match animPart:
				0: if animTimer >= lerp(25,5,editor.game.fastAnimSpeed):
					AudioManager.play(preload("res://resources/sounds/door/relock.wav"))
					animPart += 1
				1: if animTimer >= lerp(40,8,editor.game.fastAnimSpeed):
					AudioManager.play(preload("res://resources/sounds/door/masterNegative.wav"))
					animAlpha = 1
					animPart += 1
				2: if animTimer >= lerp(50,10,editor.game.fastAnimSpeed):
					animPart += 1
					for lock in locks: lock.queue_redraw()
				3:
					animAlpha -= delta*6 # 0.1 per frame, 60fps
			if animTimer >= animLength:
				animState = ANIM_STATE.IDLE
			queue_redraw()

func start() -> void:
	gameCopies = copies
	animState = ANIM_STATE.IDLE
	animTimer = 0
	animAlpha = 0
	animPart = 0
	super()

func tryOpen(player:Player) -> void:
	if animState != ANIM_STATE.IDLE: return
	if player.masterCycle == 1 and tryMasterOpen(player): return

	for lock in locks:
		if !lock.canOpen(player): return
	
	var cost:C = C.ZERO
	for lock in locks:
		cost = cost.plus(lock.getCost(player))
	
	gameChanges.addChange(GameChanges.KeyChange.new(editor.game, colorSpend, player.key[colorSpend].minus(cost)))
	gameChanges.addChange(GameChanges.PropertyChange.new(editor.game, self, &"gameCopies", gameCopies.minus(1)))
	
	match type:
		TYPE.SIMPLE:
			if locks[0].type == Lock.TYPE.BLAST: AudioManager.play(preload("res://resources/sounds/door/blast.wav"))
			elif colorSpend == Game.COLOR.MASTER and locks[0].color == Game.COLOR.MASTER: AudioManager.play(preload("res://resources/sounds/door/master.wav"))
			else: AudioManager.play(preload("res://resources/sounds/door/simple.wav"))
		TYPE.COMBO: AudioManager.play(preload("res://resources/sounds/door/combo.wav"))

	if gameCopies.eq(0): destroy()
	else: relockAnimation()
	gameChanges.bufferSave()

func tryMasterOpen(player:Player) -> bool:
	if hasColor(Game.COLOR.MASTER): return false
	if hasColor(Game.COLOR.PURE): return false

	var openedForwards:bool = gameCopies.across(player.masterMode).reduce().gt(0)
	gameChanges.addChange(GameChanges.PropertyChange.new(editor.game, self, &"gameCopies", gameCopies.minus(player.masterMode)))
	gameChanges.addChange(GameChanges.KeyChange.new(editor.game, Game.COLOR.MASTER, player.key[Game.COLOR.MASTER].minus(player.masterMode)))
	
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

func hasColor(color:Game.COLOR) -> bool:
	if colorSpend == color: return true
	for lock in locks: if lock.color == color: return true
	return false

func destroy() -> void:
	gameChanges.addChange(GameChanges.PropertyChange.new(editor.game, self, &"active", false))
	var color:Game.COLOR = colorSpend
	if type == TYPE.SIMPLE: color = locks[0].color
	for y in floor(size.y/16):
		for x in floor(size.x/16):
			add_child(Debris.new(color,Vector2(x*16,y*16)))

func addCopyAnimation() -> void:
	animState = ANIM_STATE.ADD_COPY
	animTimer = 0
	animAlpha = 0
	animPart = 0
	editor.game.fasterAnims()
	addCopySound = AudioManager.play(preload("res://resources/sounds/door/addCopy.wav"))
	var color:Game.COLOR = colorSpend
	if type == TYPE.SIMPLE: color = locks[0].color
	for y in floor(size.y/16):
		for x in floor(size.x/16):
			add_child(AddCopyDebris.new(color,Vector2(x*16,y*16)))

func relockAnimation() -> void:
	animState = ANIM_STATE.RELOCK
	animTimer = 0
	animAlpha = 0
	animPart = 0
	editor.game.fasterAnims()
	for lock in locks: lock.queue_redraw()
	var color:Game.COLOR = colorSpend
	if type == TYPE.SIMPLE: color = locks[0].color
	for y in floor(size.y/16):
		for x in floor(size.x/16):
			add_child(RelockDebris.new(editor.game,color,Vector2(x*16,y*16)))

func propertyGameChangedDo(property:StringName) -> void:
	if property == &"active":
		%collision.process_mode = PROCESS_MODE_INHERIT if active else PROCESS_MODE_DISABLED
		%interact.process_mode = PROCESS_MODE_INHERIT if active else PROCESS_MODE_DISABLED

class Debris extends Node2D:
	const FRAME:Texture2D = preload("res://assets/game/door/debris/frame.png")
	const HIGH:Texture2D = preload("res://assets/game/door/debris/high.png")
	const MAIN:Texture2D = preload("res://assets/game/door/debris/main.png")
	const DARK:Texture2D = preload("res://assets/game/door/debris/dark.png")

	var color:Game.COLOR
	var opacity:float = 1
	var velocity:Vector2 = Vector2.ZERO
	var acceleration:Vector2 = Vector2.ZERO
	var fadeSpeed:float

	const FPS:float = 60

	func _init(_color:Game.COLOR,_position) -> void:
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
	var game:Game
	var angle:float = randf_range(0,TAU)
	var speed:float = 1.5
	var startPosition:Vector2
	var part:int = 0
	var timer:int = 0
	var whiteAmt:float = 0

	func _init(_game:Game,_color:Game.COLOR,_position) -> void:
		game = _game
		super(_color, _position)

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
