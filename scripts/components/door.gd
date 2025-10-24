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

var locks:Array[Lock] = []

const COPIES_COLOR = Color("#edeae7")
const COPIES_OUTLINE_COLOR = Color("#3e2d1c")

func _init() -> void: size = Vector2(32,32)

func _ready() -> void:
	drawScaled = RenderingServer.canvas_item_create()
	drawMain = RenderingServer.canvas_item_create()
	drawGlitch = RenderingServer.canvas_item_create()
	drawCopies = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_material(drawGlitch,Game.GLITCH_MATERIAL.get_rid())
	RenderingServer.canvas_item_set_parent(drawScaled,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawMain,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawGlitch,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawCopies,get_canvas_item())
	editor.game.connect(&"goldIndexChanged",queue_redraw)

func _draw() -> void:
	RenderingServer.canvas_item_clear(drawScaled)
	RenderingServer.canvas_item_clear(drawMain)
	RenderingServer.canvas_item_clear(drawGlitch)
	RenderingServer.canvas_item_clear(drawCopies)
	if !active and editor.game.playState == Game.PLAY_STATE.PLAY: return
	var rect:Rect2 = Rect2(Vector2.ZERO, size)
	# fill
	var texture:Texture2D
	var tileTexture:bool = false
	if type == TYPE.GATE:
		RenderingServer.canvas_item_add_texture_rect(drawMain,rect,GATE_FILL,true)
	else:
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
	# copies
	if !copies.eq(1): TextDraw.outlinedCentered(Game.FKEYX,drawCopies,"×"+str(copies),COPIES_COLOR,COPIES_OUTLINE_COLOR,25,Vector2(size.x/2,1))
	# locks

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
				if !mods.active(&"VarLockSize"):
					for lock in locks: lock._coerceSize()
			TYPE.GATE:
				changes.addChange(Changes.PropertyChange.new(editor.game,self,&"color",Game.COLOR.WHITE))
	if property == &"size" and type == TYPE.SIMPLE: locks[0]._simpleDoorUpdate()

func propertyChangedDo(property:StringName) -> void:
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
func tryOpen(player:Player) -> void:
	for lock in locks:
		if !lock.canOpen(player): return
	
	var cost:C = C.ZERO
	for lock in locks:
		cost = cost.plus(lock.getCost(player))
	
	gameChanges.addChange(GameChanges.KeyChange.new(editor.game, colorSpend, player.key[colorSpend].minus(cost)))
	gameChanges.addChange(GameChanges.PropertyChange.new(editor.game, self, &"active", false))
	gameChanges.bufferSave()

	match type:
		TYPE.SIMPLE:
			if locks[0].type == Lock.TYPE.BLAST: %audio.stream = preload("res://resources/sounds/door/blast.wav")
			else: %audio.stream = preload("res://resources/sounds/door/simple.wav")
		TYPE.COMBO: %audio.stream = preload("res://resources/sounds/door/combo.wav")
	%audio.play()

	for y in floor(size.y/16):
		for x in floor(size.x/16):
			add_child(Debris.new(colorSpend,Vector2(x*16,y*16)))

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
	
	const FPS:float = 60

	func _init(_color:Game.COLOR,_position):
		color = _color
		position = _position
		velocity.x = randf_range(-1.2,1.2)
		velocity.y = randf_range(-4,-3)
		acceleration.y = randf_range(0.4,0.5)
	
	func _physics_process(delta:float):
		opacity -= 2.4*delta # 0.04 per frame, 60fps
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
