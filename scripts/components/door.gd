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
const CRUMBLED_MATERIAL:ShaderMaterial = preload("res://resources/materials/crumbledDrawMaterial.tres")

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

const STARRED_SYMBOL_ON:Texture2D = preload("res://assets/game/door/symbols/starOn.png")
const STARRED_SYMBOL_OFF:Texture2D = preload("res://assets/game/door/symbols/starOff.png")

static var GLITCH:ColorsTextureLoader = ColorsTextureLoader.new("res://assets/game/door/glitch/$c.png", false, false, {capitalised=false})

static var ERROR_FX:IndexTextureLoader = IndexTextureLoader.new("res://assets/game/key/error/fx.png", 3)

const TEXTURE_RECT:Rect2 = Rect2(Vector2.ZERO,Vector2(64,64)) # size of all the door textures
const CORNER_SIZE:Vector2 = Vector2(9,9) # size of door ninepatch corners
const GLITCH_CORNER_SIZE:Vector2 = Vector2(16,16) # except glitchdraw is a different size
const TILE:RenderingServer.NinePatchAxisMode = RenderingServer.NinePatchAxisMode.NINE_PATCH_TILE # just to save characters
const STRETCH:RenderingServer.NinePatchAxisMode = RenderingServer.NinePatchAxisMode.NINE_PATCH_STRETCH # just to save characters

const SYMBOL_RECT:Rect2 = Rect2(Vector2.ZERO,Vector2(25,25)) # size of symbol textures
const CREATE_PARAMETERS:Array[StringName] = [
	&"position"
]
const PROPERTIES:Array[StringName] = [
	&"id", &"position", &"size",
	&"colorSpend", &"copies", &"infCopies", &"type",
	&"frozen", &"crumbled", &"painted", &"oscillate"
]
static var ARRAYS:Dictionary[StringName,Variant] = {
	&"remoteLocks":RemoteLock
}

var colorSpend:C.olors = C.olors.WHITE
var copies:PackedInt64Array = M.ONE
var infCopies:PackedInt64Array = M.ZERO # axes with infinite copies
var type:TYPE = TYPE.SIMPLE
var frozen:bool = false
var crumbled:bool = false
var painted:bool = false
var oscillate:bool = false

func getColors() -> Array[C.olors]: return [colorSpend]

var drawDropShadow:RID
var drawScaled:RID # also draws aura breaker fills
var drawAuraBreaker:RID
var drawGlitch:RID
var drawMain:RID
var drawError:RID
var drawCrumbled:RID
var drawPainted:RID
var drawFrozen:RID
var drawSymbols:RID
var drawNegative:RID

var locks:Array[Lock] = []
var remoteLocks:Array[RemoteLock] = []

@onready var locksParent:Node2D = %locksParent

const COPIES_COLOR = Color("#edeae7")
const COPIES_OUTLINE_COLOR = Color("#3e2d1c")

func _init() -> void: size = Vector2(32,32)

func _ready() -> void:
	drawDropShadow = RenderingServer.canvas_item_create()
	drawScaled = RenderingServer.canvas_item_create()
	drawAuraBreaker = RenderingServer.canvas_item_create()
	drawGlitch = RenderingServer.canvas_item_create()
	drawMain = RenderingServer.canvas_item_create()
	drawError = RenderingServer.canvas_item_create()
	drawCrumbled = RenderingServer.canvas_item_create()
	drawPainted = RenderingServer.canvas_item_create()
	drawFrozen = RenderingServer.canvas_item_create()
	drawSymbols = RenderingServer.canvas_item_create()
	drawNegative = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_material(drawGlitch,Game.GLITCH_MATERIAL.get_rid())
	RenderingServer.canvas_item_set_material(drawNegative,Game.NEGATIVE_MATERIAL.get_rid())
	RenderingServer.canvas_item_set_z_index(drawDropShadow,-3)
	RenderingServer.canvas_item_set_z_index(drawSymbols,2)
	RenderingServer.canvas_item_set_z_index(drawNegative,2)
	RenderingServer.canvas_item_set_parent(drawDropShadow,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawScaled,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawAuraBreaker,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawGlitch,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawMain,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawError,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawCrumbled, %auraParent.get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawPainted, %auraParent.get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawFrozen, %auraParent.get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawSymbols,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawNegative,get_canvas_item())
	RenderingServer.canvas_item_set_self_modulate(drawError, "#ffffffaa")
	RenderingServer.canvas_item_set_material(drawError,Game.ADDITIVE_MATERIAL)
	Game.connect(&"goldIndexChanged",func(): if Colors.getDef(getColor(COLOR_STEP.DRAW_BASE)).doorTextureFrames > 1: queue_redraw())

func _freed() -> void:
	RenderingServer.free_rid(drawDropShadow)
	RenderingServer.free_rid(drawScaled)
	RenderingServer.free_rid(drawAuraBreaker)
	RenderingServer.free_rid(drawGlitch)
	RenderingServer.free_rid(drawMain)
	RenderingServer.free_rid(drawError)
	RenderingServer.free_rid(drawCrumbled)
	RenderingServer.free_rid(drawPainted)
	RenderingServer.free_rid(drawFrozen)
	RenderingServer.free_rid(drawSymbols)
	RenderingServer.free_rid(drawNegative)

func convertNumbers(from:M.SYSTEM) -> void:
	Changes.addChange(Changes.ComponentConvertNumberChange.new(self, from, &"copies"))
	Changes.addChange(Changes.ComponentConvertNumberChange.new(self, from, &"infCopies"))
	Changes.addChange(Changes.ComponentConvertNumberChange.new(self, from, &"gameCopies"))

func _draw() -> void:
	RenderingServer.canvas_item_clear(drawDropShadow)
	RenderingServer.canvas_item_clear(drawScaled)
	RenderingServer.canvas_item_clear(drawAuraBreaker)
	RenderingServer.canvas_item_clear(drawGlitch)
	RenderingServer.canvas_item_clear(drawMain)
	RenderingServer.canvas_item_clear(drawError)
	RenderingServer.canvas_item_clear(drawCrumbled)
	RenderingServer.canvas_item_clear(drawPainted)
	RenderingServer.canvas_item_clear(drawFrozen)
	RenderingServer.canvas_item_clear(drawSymbols)
	RenderingServer.canvas_item_clear(drawNegative)
	if !active and Game.playState == Game.PLAY_STATE.PLAY: return
	if type != TYPE.GATE: RenderingServer.canvas_item_add_rect(drawDropShadow,Rect2(Vector2(3,3),size),Game.DROP_SHADOW_COLOR)
	drawDoor(drawScaled,drawAuraBreaker,drawGlitch,drawMain,
		size,getColor(COLOR_STEP.DRAW_BASE),getColor(COLOR_STEP.Glitch),type,
		gateAlpha,
		len(locks) > 0 and (locks[0].isNegative() if type == TYPE.SIMPLE else M.negative(M.sign(ipow()))),
		(Game.playState == Game.PLAY_STATE.PLAY and drawComplex) or (Game.playState == Game.PLAY_STATE.EDIT and M.nex(copies)),
		animState != ANIM_STATE.RELOCK or animPart > 2
	)
	var rect:Rect2 = Rect2(Vector2.ZERO, size)
	# error effect
	if getColor(COLOR_STEP.BASE) == C.olors.ERROR:
		for i in range(size.x / 32):
			for j in range(size.y / 32):
				var errorrect:Rect2 = Rect2(i*32+randi_range(-5,5),j*32+randi_range(-5,5),32.0,32.0)
				RenderingServer.canvas_item_add_texture_rect(drawError,errorrect,ERROR_FX.current([randi_range(0,2)]))
	# auras
	drawAuras(drawCrumbled,drawPainted,drawFrozen,
		frozen if Game.playState == Game.PLAY_STATE.EDIT else gameFrozen,
		crumbled if Game.playState == Game.PLAY_STATE.EDIT else gameCrumbled,
		painted if Game.playState == Game.PLAY_STATE.EDIT else gamePainted,
		rect)
	# anim overlays
	if animState == ANIM_STATE.ADD_COPY: RenderingServer.canvas_item_add_rect(drawNegative,rect,Color(Color.WHITE,animAlpha))
	elif animState == ANIM_STATE.RELOCK: RenderingServer.canvas_item_add_rect(drawSymbols,rect,Color(Color.WHITE,animAlpha)) # just to be on top of everything else
	# copies
	if Game.playState == Game.PLAY_STATE.PLAY:
		if M.neq(gameCopies, M.ONE) or M.ex(infCopies): TextDraw.outlinedCentered(Game.FKEYX,drawSymbols,"×"+M.strWithInf(gameCopies,infCopies),COPIES_COLOR,COPIES_OUTLINE_COLOR,20,Vector2(size.x/2,-8))
	else:
		if M.neq(copies, M.ONE) or M.ex(infCopies): TextDraw.outlinedCentered(Game.FKEYX,drawSymbols,"×"+M.strWithInf(copies,infCopies),COPIES_COLOR,COPIES_OUTLINE_COLOR,20,Vector2(size.x/2,-8))
	# symbols
	match starred:
		STAR_STATE.STARRED_UNLOCKED: RenderingServer.canvas_item_add_texture_rect(drawSymbols,Rect2(Vector2(size.x/2-12,size.y-12),Vector2(24,24)),STARRED_SYMBOL_ON)
		STAR_STATE.STARRED_LOCKED: RenderingServer.canvas_item_add_texture_rect(drawSymbols,Rect2(Vector2(size.x/2-12,size.y-12),Vector2(24,24)),STARRED_SYMBOL_OFF)

static func drawDoor(doorDrawScaled:RID,doorDrawAuraBreaker:RID,doorDrawGlitch:RID,doorDrawMain:RID,
	doorSize:Vector2,
	doorBaseColor:C.olors, doorGlitchColor:C.olors,
	doorType:TYPE,
	doorGateAlpha:float,
	negative:bool=false, doorDrawComplex:bool=false, drawFill:bool=true
) -> void:
	var rect:Rect2 = Rect2(Vector2.ZERO, doorSize)
	# fill
	if doorType == TYPE.GATE:
		RenderingServer.canvas_item_add_texture_rect(doorDrawMain,rect,GATE_FILL,true,Color(Color.WHITE,lerp(0.35,1.0,doorGateAlpha)))
		#outline
		RenderingServer.canvas_item_add_rect(doorDrawMain,Rect2(Vector2(0,-1),Vector2(doorSize.x,1)),Color.BLACK.blend(Color(Color.WHITE,doorGateAlpha)))
		RenderingServer.canvas_item_add_rect(doorDrawMain,Rect2(Vector2(0,doorSize.y),Vector2(doorSize.x,1)),Color.BLACK.blend(Color(Color.WHITE,doorGateAlpha)))
		RenderingServer.canvas_item_add_rect(doorDrawMain,Rect2(Vector2(-1,0),Vector2(1,doorSize.y)),Color.BLACK.blend(Color(Color.WHITE,doorGateAlpha)))
		RenderingServer.canvas_item_add_rect(doorDrawMain,Rect2(Vector2(doorSize.x,0),Vector2(1,doorSize.y)),Color.BLACK.blend(Color(Color.WHITE,doorGateAlpha)))
	else:
		if drawFill:
			if Colors.getDef(doorBaseColor).doorTexture:
				var tileTexture:bool = Colors.getDef(doorBaseColor).doorTextureTile
				RenderingServer.canvas_item_add_texture_rect(doorDrawScaled,rect,Game.COLOR_TEXTURES.current([doorBaseColor]),tileTexture)
			elif doorBaseColor == C.olors.GLITCH:
				RenderingServer.canvas_item_add_nine_patch(doorDrawGlitch,rect,TEXTURE_RECT,SPEND_HIGH,CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,Game.highTone[C.olors.GLITCH])
				RenderingServer.canvas_item_add_nine_patch(doorDrawGlitch,rect,TEXTURE_RECT,SPEND_MAIN,CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,Game.mainTone[C.olors.GLITCH])
				RenderingServer.canvas_item_add_nine_patch(doorDrawGlitch,rect,TEXTURE_RECT,SPEND_DARK,CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,Game.darkTone[C.olors.GLITCH])
				if doorGlitchColor != C.olors.GLITCH:
					if Colors.getDef(doorGlitchColor).doorTexture:
						RenderingServer.canvas_item_add_nine_patch(doorDrawMain,rect,TEXTURE_RECT,GLITCH.current([doorGlitchColor]),GLITCH_CORNER_SIZE,GLITCH_CORNER_SIZE,TILE,TILE)
					else:
						RenderingServer.canvas_item_add_nine_patch(doorDrawMain,rect,TEXTURE_RECT,GLITCH_HIGH,GLITCH_CORNER_SIZE,GLITCH_CORNER_SIZE,TILE,TILE,true,Game.highTone[doorGlitchColor])
						RenderingServer.canvas_item_add_nine_patch(doorDrawMain,rect,TEXTURE_RECT,GLITCH_MAIN,GLITCH_CORNER_SIZE,GLITCH_CORNER_SIZE,TILE,TILE,true,Game.mainTone[doorGlitchColor])
						RenderingServer.canvas_item_add_nine_patch(doorDrawMain,rect,TEXTURE_RECT,GLITCH_DARK,GLITCH_CORNER_SIZE,GLITCH_CORNER_SIZE,TILE,TILE,true,Game.darkTone[doorGlitchColor])
			elif doorBaseColor in [C.olors.ICE, C.olors.MUD, C.olors.GRAFFITI]:
				RenderingServer.canvas_item_set_material(doorDrawScaled,Game.NO_MATERIAL.get_rid())
				RenderingServer.canvas_item_add_nine_patch(doorDrawScaled,rect,TEXTURE_RECT,SPEND_HIGH,CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,Game.highTone[doorBaseColor])
				RenderingServer.canvas_item_add_nine_patch(doorDrawScaled,rect,TEXTURE_RECT,SPEND_MAIN,CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,Game.mainTone[doorBaseColor])
				RenderingServer.canvas_item_add_nine_patch(doorDrawScaled,rect,TEXTURE_RECT,SPEND_DARK,CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,Game.darkTone[doorBaseColor])
				drawAuras(doorDrawAuraBreaker,doorDrawAuraBreaker,doorDrawAuraBreaker,doorBaseColor==C.olors.ICE,doorBaseColor==C.olors.MUD,doorBaseColor==C.olors.GRAFFITI,rect)
			else:
				RenderingServer.canvas_item_add_nine_patch(doorDrawMain,rect,TEXTURE_RECT,SPEND_HIGH,CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,Game.highTone[doorBaseColor])
				RenderingServer.canvas_item_add_nine_patch(doorDrawMain,rect,TEXTURE_RECT,SPEND_MAIN,CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,Game.mainTone[doorBaseColor])
				RenderingServer.canvas_item_add_nine_patch(doorDrawMain,rect,TEXTURE_RECT,SPEND_DARK,CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,Game.darkTone[doorBaseColor])
		# frame
		if doorDrawComplex:
			RenderingServer.canvas_item_add_nine_patch(doorDrawMain,rect,TEXTURE_RECT,FRAME_HIGH,CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,Color.from_hsv(Game.complexViewHue,0.4901960784,1))
			RenderingServer.canvas_item_add_nine_patch(doorDrawMain,rect,TEXTURE_RECT,FRAME_MAIN,CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,Color.from_hsv(Game.complexViewHue,0.7058823529,0.9019607843))
			RenderingServer.canvas_item_add_nine_patch(doorDrawMain,rect,TEXTURE_RECT,FRAME_DARK,CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,Color.from_hsv(Game.complexViewHue,1,0.7450980392))
		elif negative: RenderingServer.canvas_item_add_nine_patch(doorDrawMain,rect,TEXTURE_RECT,FRAME_NEGATIVE,CORNER_SIZE,CORNER_SIZE)
		else: RenderingServer.canvas_item_add_nine_patch(doorDrawMain,rect,TEXTURE_RECT,FRAME,CORNER_SIZE,CORNER_SIZE)

static func drawAuras(objectDrawCrumbled:RID,objectDrawPainted:RID,objectDrawFrozen:RID,objectFrozen:bool,objectCrumbled:bool,objectPainted:bool,rect:Rect2) -> void:
	var variableSize:bool = false
	if objectCrumbled:
		if rect.size == Vector2(32,32): RenderingServer.canvas_item_add_texture_rect(objectDrawCrumbled,rect,CRUMBLED_1X1)
		elif rect.size == Vector2(32,64): RenderingServer.canvas_item_add_texture_rect(objectDrawCrumbled,rect,CRUMBLED_1X2)
		elif rect.size == Vector2(64,64): RenderingServer.canvas_item_add_texture_rect(objectDrawCrumbled,rect,CRUMBLED_2X2)
		else: variableSize = true
		if variableSize:
			RenderingServer.canvas_item_set_material(objectDrawCrumbled,CRUMBLED_MATERIAL.get_rid())
			RenderingServer.canvas_item_set_instance_shader_parameter(objectDrawCrumbled, &"size", rect.size)
			RenderingServer.canvas_item_add_rect(objectDrawCrumbled,rect,Color.WHITE)
		else: RenderingServer.canvas_item_set_material(objectDrawCrumbled,Game.NO_MATERIAL.get_rid())
	if objectPainted:
		if rect.size == Vector2(32,32): RenderingServer.canvas_item_add_texture_rect(objectDrawPainted,rect,PAINTED_1X1)
		elif rect.size == Vector2(32,64): RenderingServer.canvas_item_add_texture_rect(objectDrawPainted,rect,PAINTED_1X2)
		elif rect.size == Vector2(64,64): RenderingServer.canvas_item_add_texture_rect(objectDrawPainted,rect,PAINTED_2X2)
		else: variableSize = true
		if variableSize:
			RenderingServer.canvas_item_set_material(objectDrawPainted,PAINTED_MATERIAL.get_rid())
			RenderingServer.canvas_item_set_instance_shader_parameter(objectDrawPainted, &"scale", rect.size/128)
			RenderingServer.canvas_item_add_texture_rect(objectDrawPainted,rect,PAINTED_BASE,true)
		else: RenderingServer.canvas_item_set_material(objectDrawPainted,Game.ADDITIVE_MATERIAL.get_rid())
	if objectFrozen:
		if rect.size == Vector2(32,32): RenderingServer.canvas_item_add_texture_rect(objectDrawFrozen,rect,FROZEN_1X1)
		elif rect.size == Vector2(32,64): RenderingServer.canvas_item_add_texture_rect(objectDrawFrozen,rect,FROZEN_1X2)
		elif rect.size == Vector2(64,64): RenderingServer.canvas_item_add_texture_rect(objectDrawFrozen,rect,FROZEN_2X2)
		elif rect.size == Vector2(96,64): RenderingServer.canvas_item_add_texture_rect(objectDrawFrozen,rect,FROZEN_3X2)
		else: variableSize = true
		if variableSize:
			RenderingServer.canvas_item_set_material(objectDrawFrozen,FROZEN_MATERIAL.get_rid())
			RenderingServer.canvas_item_set_instance_shader_parameter(objectDrawFrozen, &"size", rect.size)
			RenderingServer.canvas_item_add_rect(objectDrawFrozen,rect,Color.WHITE)
		else: RenderingServer.canvas_item_set_material(objectDrawFrozen,Game.NO_MATERIAL.get_rid())

func receiveMouseInput(event:InputEventMouse) -> bool:
	# resizing
	if !editor.edgeResizing or editor.componentDragged: return false
	var dragCornerSize:Vector2 = Vector2(8,8)/editor.cameraZoom
	var diffSign:Vector2 = Editor.rectSign(Rect2(position+dragCornerSize,size-dragCornerSize*2), editor.mouseWorldPosition)
	if !diffSign: return false
	elif !diffSign.x: editor.mouse_default_cursor_shape = Control.CURSOR_VSIZE
	elif !diffSign.y: editor.mouse_default_cursor_shape = Control.CURSOR_HSIZE
	elif (diffSign.x > 0) == (diffSign.y > 0): editor.mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
	else: editor.mouse_default_cursor_shape = Control.CURSOR_BDIAGSIZE
	if Editor.isLeftClick(event):
		editor.startSizeDrag(self, diffSign)
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
				if !Mods.active(&"MoreLockSizes"):
					for lock in locks: lock._coerceSize()
			TYPE.GATE:
				if !Mods.active(&"MoreLockSizes"):
					for lock in locks: lock._coerceSize()
				Changes.addChange(Changes.PropertyChange.new(self,&"colorSpend",C.olors.WHITE))
				Changes.addChange(Changes.PropertyChange.new(self,&"copies",M.ONE))
				Changes.addChange(Changes.PropertyChange.new(self,&"frozen",false))
				Changes.addChange(Changes.PropertyChange.new(self,&"crumbled",false))
				Changes.addChange(Changes.PropertyChange.new(self,&"painted",false))
	if property == &"size" and type == TYPE.SIMPLE and len(locks) > 0: locks[0]._simpleDoorUpdate() # ghhghghhh TODO: figure this out
	if property in [&"copies", &"infCopies"] and M.neq(M.across(M.cabs(copies), infCopies), infCopies):
		if M.ex(M.r(infCopies)) and M.nex(M.r(copies)): Changes.addChange(Changes.PropertyChange.new(self,&"copies", M.Ncn(M.saxis(M.r(copies)), M.ir(copies))))
		if M.ex(M.i(infCopies)) and M.nex(M.i(copies)): Changes.addChange(Changes.PropertyChange.new(self,&"copies",M.Ncn(M.r(copies), M.saxis(M.ir(copies)))))

func propertyChangedDo(property:StringName) -> void:
	super(property)
	if editor and property == &"type" and editor.findProblems:
		for lock in locks: editor.findProblems.findProblems(lock)
	if property == &"type":
		z_index = 7 if type == TYPE.GATE else 0
	if property in [&"size", &"type"]:
		%shape.shape.size = size
		%shape.position = size/2
		%interactShape.shape.size = size
		%interactShape.position = size/2
		if type == TYPE.COMBO: %interactShape.shape.size += Vector2(2,2)
		elif type == TYPE.SIMPLE: %shape.shape.size -= Vector2(2,2)
	if property in [&"size", &"position"]:
		for remoteLock in remoteLocks: remoteLock.queue_redraw()

func addLock() -> void:
	Changes.addChange(Changes.CreateComponentChange.new(Lock,{&"position":getFirstFreePosition(),&"parentId":id}))
	if len(locks) == 1 and type != Door.TYPE.GATE: Changes.addChange(Changes.PropertyChange.new(self,&"type",TYPE.SIMPLE))
	elif type == Door.TYPE.SIMPLE: Changes.addChange(Changes.PropertyChange.new(self,&"type",TYPE.COMBO))
	Changes.bufferSave()

func duplicateLock(lock:Lock) -> void:
	var newLock:Lock = Changes.addChange(Changes.CreateComponentChange.new(Lock,{&"position":getFirstFreePosition(lock.getOffset(), lock.size),&"parentId":id})).result
	Changes.addChange(Changes.PropertyChange.new(self,&"type",TYPE.COMBO))
	for property in Lock.PROPERTIES:
		if property not in Lock.CREATE_PARAMETERS and property != &"id":
			Changes.addChange(Changes.PropertyChange.new(newLock,property,Changes.copy(lock.get(property))))
	Changes.bufferSave()

func getFirstFreePosition(lockOffset:Vector2=Vector2(7,7), lockSize:Vector2=Vector2(18,18)) -> Vector2:
	for y in floor(size.y/32):
		for x in floor(size.x/32):
			var rect:Rect2 = Rect2(Vector2(32*x,32*y)-lockOffset, lockSize)
			var overlaps:bool = false
			for lock in locks:
				if Rect2(lock.position-lock.getOffset(), lock.size).intersects(rect):
					overlaps = true
					break
			if overlaps: continue
			return Vector2(32*x,32*y)
	return Vector2.ZERO

func removeLock(index:int) -> void:
	Changes.addChange(Changes.DeleteComponentChange.new(locks[index]))
	if type == Door.TYPE.SIMPLE: Changes.addChange(Changes.PropertyChange.new(self,&"type",TYPE.COMBO))
	Changes.bufferSave()

func deletedInit() -> void:
	for remoteLock in remoteLocks:
		Changes.addChange(Changes.ComponentArrayPopAtChange.new(remoteLock,&"doors",remoteLock.doors.find(self)))

func reindexLocks() -> void:
	var iter:int = 0
	var nonArmamentIter:int = 0
	var armamentIter:int = 0
	for lock in locks:
		lock.index = iter
		if lock.armament:
			lock.displayIndex = armamentIter
			if lock.get_parent() != %armamentLocksParent:
				lock.get_parent().remove_child(lock)
				%armamentLocksParent.add_child(lock)
				%armamentLocksParent.move_child(lock,armamentIter)
			armamentIter += 1
		else:
			lock.displayIndex = nonArmamentIter
			if lock.get_parent() != %locksParent:
				lock.get_parent().remove_child(lock)
				%locksParent.add_child(lock)
				%locksParent.move_child(lock,armamentIter)
			nonArmamentIter += 1
		iter += 1

# ==== PLAY ==== #
var gameCopies:PackedInt64Array = M.ONE
var gameFrozen:bool = false
var gameCrumbled:bool = false
var gamePainted:bool = false
var cursed:bool = false
var curseColor:C.olors
var glitchMimic:C.olors = C.olors.GLITCH
var errorMimic:C.olors = C.olors.ERROR
var curseMimic:C.olors = C.olors.GLITCH

enum STAR_STATE {UNSTARRED, STARRED_UNLOCKED, STARRED_LOCKED}
var starred:STAR_STATE = STAR_STATE.UNSTARRED
var starredColor:C.olors = C.olors.WHITE 
var starredSpendKey:PackedInt64Array = M.ZERO
var starredSpendGlisten:PackedInt64Array = M.ZERO

enum ANIM_STATE {IDLE, ADD_COPY, RELOCK}
var animState:ANIM_STATE = ANIM_STATE.IDLE
var animTimer:float = 0
var animAlpha:float = 0
var addCopySound:AudioStreamPlayer
var animPart:int = 0
var gateAlpha:float = 1
var gateOpen:bool = false
var gateBufferCheck:bool = false
var curseTimer:float = 0
var drawComplex:bool = false

var justOpened:bool = false # for player jumped off door check

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
			var animLength:float = lerp(50,10,Game.fastAnimSpeed)
			animAlpha = 1 - animTimer/animLength
			if animTimer >= animLength: animState = ANIM_STATE.IDLE
			queue_redraw()
		ANIM_STATE.RELOCK:
			animTimer += delta*60
			var animLength:float = lerp(60,12,Game.fastAnimSpeed)
			match animPart:
				0: if animTimer >= lerp(25,5,Game.fastAnimSpeed):
					AudioManager.play(preload("res://resources/sounds/door/relock.wav"))
					animPart += 1
				1: if animTimer >= lerp(40,8,Game.fastAnimSpeed):
					AudioManager.play(preload("res://resources/sounds/door/masterNegative.wav"))
					animAlpha = 1
					animPart += 1
				2: if animTimer >= lerp(50,10,Game.fastAnimSpeed):
					animPart += 1
					for lock in locks: lock.queue_redraw()
				3:
					animAlpha -= delta*6 # 0.1 per frame, 60fps
			if animTimer >= animLength:
				animState = ANIM_STATE.IDLE
			queue_redraw()
	if type == TYPE.GATE:
		if gateBufferCheck and !overlappingPlayer() and !Game.player.overlapping(%interact):
			GameChanges.addChange(GameChanges.PropertyChange.new(self,&"gateBufferCheck",false))
			gateCheck(Game.player, false)
			GameChanges.bufferSave()
		if !gateOpen and gateAlpha < 1:
			gateAlpha = min(gateAlpha+delta*6, 1)
			queue_redraw()
		elif gateOpen and gateAlpha > 0:
			gateAlpha = max(gateAlpha-delta*6, 0)
			queue_redraw()
	if drawComplex or (Game.playState == Game.PLAY_STATE.EDIT and M.nex(copies)): queue_redraw()

func start() -> void:
	gameCopies = copies
	gameFrozen = frozen
	gameCrumbled = crumbled
	gamePainted = painted
	animState = ANIM_STATE.IDLE
	animTimer = 0
	animAlpha = 0
	animPart = 0
	complexCheck()
	if type == TYPE.GATE:
		if overlappingPlayer():
			gateOpen = true
			gateBufferCheck = true
		else: gateCheck(Game.player, true)
	propertyGameChangedDo(&"gateOpen")
	super()

# avoids 1 frame delay
func overlappingPlayer() -> bool: return Rect2(Game.player.position - Vector2(6,12), Vector2(12,21)).intersects(Rect2(position, size))

func stop() -> void:
	cursed = false
	curseTimer = 0
	gateAlpha = 1
	gateOpen = false
	gateBufferCheck = false
	drawComplex = false
	glitchMimic = C.olors.GLITCH
	errorMimic = C.olors.ERROR
	curseMimic = C.olors.GLITCH
	justOpened = false
	starred = STAR_STATE.UNSTARRED
	starredSpendGlisten = M.ZERO
	starredSpendKey = M.ZERO
	starredColor = C.olors.WHITE
	super()

func tryOpen(player:Player) -> void:
	if type == TYPE.GATE: return
	if animState != ANIM_STATE.IDLE: return
	if gameFrozen or gameCrumbled or gamePainted:
		var gateArmamentImmunities:Array[C.olors] = player.getArmamentImmunities()
		if hasEffectiveColor(C.olors.PURE): return
		if int(gameFrozen) + int(gameCrumbled) + int(gamePainted) > 1: return
		if gameFrozen and (M.nex(player.key[C.olors.ICE]) or C.olors.ICE in gateArmamentImmunities): return
		if gameCrumbled and (M.nex(player.key[C.olors.MUD]) or C.olors.MUD in gateArmamentImmunities): return
		if gamePainted and (M.nex(player.key[C.olors.GRAFFITI]) or C.olors.GRAFFITI in gateArmamentImmunities): return
	else:
		if player.explodey and tryDynamiteOpen(player): return
		if player.masterCycle == 1 and tryMasterOpen(player): return
		if player.masterCycle == 2 and tryQuicksilverOpen(player): return
		if player.masterCycle == 3 and tryCosmicOpen(player): return
	match starred:
		STAR_STATE.STARRED_LOCKED: return
		STAR_STATE.STARRED_UNLOCKED:
			if M.nex(gameCopies) or checkCanOpen(player, false, true):
				player.changeGlisten(starredColor, M.sub(player.glisten[starredColor], M.add(starredSpendGlisten, calculateCosts(player, ipow(), true, false, true))))
				player.changeKeys(starredColor, M.sub(player.key[starredColor],M.add(starredSpendKey, calculateCosts(player, ipow(), false, false, true))))
			else: return
		STAR_STATE.UNSTARRED:
			if M.nex(gameCopies) or checkCanOpen(player):
				var spendColor:C.olors = getColor(COLOR_STEP.FINAL)
				player.changeGlisten(spendColor, M.sub(player.glisten[spendColor], calculateCosts(player, ipow(), true)))
				player.changeKeys(spendColor, M.sub(player.key[spendColor], calculateCosts(player)))
			else: return
	
	GameChanges.addChange(GameChanges.PropertyChange.new(self, &"gameCopies", M.sub(gameCopies, M.across(ipow(), M.sub(M.allAxes(), infCopies)))))
	
	if gameFrozen or gameCrumbled or gamePainted: AudioManager.play(preload("res://resources/sounds/door/deaura.wav"))
	else:
		match type:
			TYPE.SIMPLE:
				if locks[0].type == Lock.TYPE.BLAST: AudioManager.play(preload("res://resources/sounds/door/blast.wav"))
				elif getColor(COLOR_STEP.FINAL) == C.olors.MASTER and locks[0].getColor(Lock.COLOR_STEP.FINAL) == C.olors.MASTER: AudioManager.play(preload("res://resources/sounds/door/master.wav"))
				else: AudioManager.play(preload("res://resources/sounds/door/simple.wav"))
			TYPE.COMBO: AudioManager.play(preload("res://resources/sounds/door/combo.wav"))
		Game.setMimic(C.olors.GLITCH, getColor(COLOR_STEP.EFFECTIVE))

	if M.nex(gameCopies): destroy()
	else: relockAnimation()
	player.bufferCheckKeys()
	GameChanges.bufferSave()

func tryMasterOpen(player:Player) -> bool:
	if hasEffectiveColor(C.olors.MASTER): return false
	if hasEffectiveColor(C.olors.PURE): return false

	var openedForwards:bool = M.positive(M.sign(M.across(gameCopies, player.masterMode)))
	GameChanges.addChange(GameChanges.PropertyChange.new(self, &"gameCopies", M.sub(gameCopies, M.across(player.masterMode, M.sub(M.allAxes(), infCopies)))))
	player.changeKeys(C.olors.MASTER, M.sub(player.key[C.olors.MASTER], player.masterMode))
	
	if openedForwards:
		AudioManager.play(preload("res://resources/sounds/door/master.wav"))
		if M.nex(gameCopies): destroy()
		else: relockAnimation()
	else:
		AudioManager.play(preload("res://resources/sounds/door/masterNegative.wav"))
		addCopyAnimation()

	player.dropMaster()
	player.bufferCheckKeys()
	GameChanges.bufferSave()
	return true

func tryQuicksilverOpen(player:Player) -> bool:
	if hasEffectiveColor(C.olors.QUICKSILVER): return false
	if hasEffectiveColor(C.olors.PURE): return false

	player.changeKeys(C.olors.QUICKSILVER, M.sub(player.key[C.olors.QUICKSILVER], player.masterMode))
	var spendColor:C.olors = getColor(COLOR_STEP.FINAL)
	if starred != 0:
		player.changeGlisten(starredColor, M.sub(player.glisten[starredColor], M.add(starredSpendGlisten, calculateCosts(player, player.masterMode, true, false))))
		player.changeKeys(starredColor, M.sub(player.key[starredColor],M.add(starredSpendKey, calculateCosts(player, player.masterMode, false, false))))
	else:
		player.changeGlisten(spendColor, M.sub(player.glisten[spendColor], calculateCosts(player, player.masterMode, true)))
		player.changeKeys(spendColor, M.sub(player.key[spendColor],calculateCosts(player, player.masterMode)))

	AudioManager.play(preload("res://resources/sounds/door/master.wav"))
	relockAnimation()

	Game.setMimic(C.olors.GLITCH, getColor(COLOR_STEP.EFFECTIVE))

	player.dropMaster()
	player.bufferCheckKeys()
	GameChanges.bufferSave()

	return true

func tryDynamiteOpen(player:Player) -> bool:
	if hasEffectiveColor(C.olors.DYNAMITE): return false
	if hasEffectiveColor(C.olors.PURE): return false

	var openedForwards:bool
	var openedBackwards:bool

	if M.simplies(gameCopies, player.key[C.olors.DYNAMITE]) and M.nonNegative(M.sub(M.along(player.key[C.olors.DYNAMITE], gameCopies), M.cabs(gameCopies))) and M.nex(infCopies):
		# if the door can open, open it
		player.changeKeys(C.olors.DYNAMITE, M.sub(player.key[C.olors.DYNAMITE], gameCopies))
		GameChanges.addChange(GameChanges.PropertyChange.new(self, &"gameCopies", M.ZERO))
		
		openedForwards = true
	else:
		openedForwards = M.hasPositive(M.along(player.key[C.olors.DYNAMITE], gameCopies))
		openedBackwards = M.hasNonPositive(M.along(player.key[C.olors.DYNAMITE], gameCopies))

		GameChanges.addChange(GameChanges.PropertyChange.new(self, &"gameCopies", M.sub(gameCopies, M.across(player.key[C.olors.DYNAMITE], M.sub(M.allAxes(),infCopies)))))
		player.changeKeys(C.olors.DYNAMITE, M.ZERO)

	if openedForwards:
		AudioManager.play(preload("res://resources/sounds/door/explode.wav"))
		if M.nex(gameCopies): destroy()
		else: relockAnimation()
		add_child(ExplosionParticle.new(size/2,1))
	if openedBackwards:
		AudioManager.play(preload("res://resources/sounds/door/explodeNegative.wav"))
		if !openedForwards:
			addCopyAnimation()
			add_child(ExplosionParticle.new(size/2,-1))

	Game.player.bufferCheckKeys()
	GameChanges.bufferSave()
	return true

func tryCosmicOpen(player:Player) -> bool:
	if hasEffectiveColor(C.olors.COSMIC): return false
	if hasEffectiveColor(C.olors.PURE): return false
	if starred == STAR_STATE.UNSTARRED and player.masterMode == M.ONE:
		player.changeKeys(C.olors.COSMIC, M.sub(player.key[C.olors.COSMIC], player.masterMode))
		if checkCanOpen(player, true, false): GameChanges.addChange(GameChanges.PropertyChange.new(self, &"starred", STAR_STATE.STARRED_UNLOCKED))
		else: GameChanges.addChange(GameChanges.PropertyChange.new(self, &"starred", STAR_STATE.STARRED_LOCKED))
		GameChanges.addChange(GameChanges.PropertyChange.new(self, &"starredSpendKey", calculateCosts(player, ipow(), false, true, false)))
		GameChanges.addChange(GameChanges.PropertyChange.new(self, &"starredSpendGlisten", calculateCosts(player, ipow(), true, false, true)))
		GameChanges.addChange(GameChanges.PropertyChange.new(self, &"starredColor", getColor(COLOR_STEP.FINAL)))
		GameChanges.addChange(GameChanges.PropertyChange.new(self, &"starredipow", ipow()))
	elif starred != STAR_STATE.UNSTARRED and player.masterMode == M.nONE:
		player.changeKeys(C.olors.COSMIC, M.sub(player.key[C.olors.COSMIC], player.masterMode))
		GameChanges.addChange(GameChanges.PropertyChange.new(self, &"starred", STAR_STATE.UNSTARRED))
	else: return false
	relockAnimation()
	player.dropMaster()
	player.bufferCheckKeys()
	GameChanges.bufferSave()
	return true

func checkCanOpen(player:Player, checkNonarmamentLocks:bool=true, checkArmamentLocks:bool=true, checkCrash:bool=true) -> bool:
	var willCrash:bool = false
	var canOpen:bool = true
	if M.ex(gameCopies): # although nothing (yet) can make a door 0 copy without destroying it
		for lock in locks:
			if !lock.canOpen(player):
				if lock.getColor(Lock.COLOR_STEP.EFFECTIVE) == C.olors.NONE and checkCrash: willCrash = true
				elif checkArmamentLocks if lock.armament else checkNonarmamentLocks: canOpen = false
			elif lock.getColor(Lock.COLOR_STEP.EFFECTIVE) == C.olors.NONE: canOpen = false
		for lock in remoteLocks:
			if !lock.satisfied and (checkArmamentLocks if lock.armament else checkNonarmamentLocks): canOpen = false
		if willCrash: Game.crash(); return false
	return canOpen

func calculateCosts(player:Player, costIpow:PackedInt64Array=ipow(), forGlisten:bool=false, checkNonarmamentLocks:bool=true, checkArmamentLocks:bool=true) -> PackedInt64Array:
	var cost:PackedInt64Array = M.ZERO
	for lock in locks: if ((lock.type == Lock.TYPE.GLISTENING) == forGlisten) and (checkArmamentLocks if lock.armament else checkNonarmamentLocks): cost = M.add(cost, lock.getCost(player, costIpow))
	for lock in remoteLocks: if ((lock.type == Lock.TYPE.GLISTENING) == forGlisten) and (checkArmamentLocks if lock.armament else checkNonarmamentLocks): cost = M.add(cost, lock.cost)
	return cost

func hasEffectiveColor(color:C.olors) -> bool:
	if getColor(COLOR_STEP.EFFECTIVE) == color: return true
	for lock in locks: if lock.getColor(Lock.COLOR_STEP.EFFECTIVE) == color: return true
	return false

func hasInitialColor(color:C.olors) -> bool:
	if colorSpend == color: return true
	for lock in locks: if lock.color == color: return true
	return false

func destroy() -> void:
	GameChanges.addChange(GameChanges.PropertyChange.new(self, &"active", false))
	var color:C.olors = getColor(COLOR_STEP.BASE)
	if type == TYPE.SIMPLE: color = locks[0].getColor(Lock.COLOR_STEP.BASE)
	makeDebris(Debris, color)
	justOpened = true

func addCopyAnimation() -> void:
	animState = ANIM_STATE.ADD_COPY
	animTimer = 0
	animAlpha = 0
	animPart = 0
	Game.fasterAnims()
	addCopySound = AudioManager.play(preload("res://resources/sounds/door/addCopy.wav"))
	var color:C.olors = getColor(COLOR_STEP.BASE)
	if type == TYPE.SIMPLE: color = locks[0].getColor(Lock.COLOR_STEP.BASE)
	makeDebris(AddCopyDebris, color)

func relockAnimation() -> void:
	animState = ANIM_STATE.RELOCK
	animTimer = 0
	animAlpha = 0
	animPart = 0
	Game.fasterAnims()
	for lock in locks: lock.queue_redraw()
	var color:C.olors = getColor(COLOR_STEP.BASE)
	if type == TYPE.SIMPLE: color = locks[0].getColor(Lock.COLOR_STEP.BASE)
	makeDebris(RelockDebris, color)

func makeDebris(debrisType:GDScript, debrisColor:C.olors) -> void:
	for y in floor(size.y/16):
		for x in floor(size.x/16):
			%particlesParent.add_child(debrisType.new(debrisColor,Vector2(x*16,y*16)))

func propertyGameChangedDo(property:StringName) -> void:
	if property == &"active":
		%collision.process_mode = PROCESS_MODE_INHERIT if active else PROCESS_MODE_DISABLED
		%interact.process_mode = PROCESS_MODE_INHERIT if active else PROCESS_MODE_DISABLED
		for remoteLock in remoteLocks: remoteLock.checkDoors()
	if property == &"gateOpen" and type == TYPE.GATE:
		%collision.process_mode = PROCESS_MODE_DISABLED if gateOpen else PROCESS_MODE_INHERIT
	if property == &"gameCopies": complexCheck()

func gateCheck(player:Player, starting:bool=false) -> void:
	if player.overlapping(%interact):
		GameChanges.addChange(GameChanges.PropertyChange.new(self,&"gateBufferCheck",true))
		return
	var shouldOpen:bool = true
	var willCrash:bool = false
	for lock in locks:
		if !lock.canOpen(player):
			if lock.getColor(Lock.COLOR_STEP.EFFECTIVE) == C.olors.NONE: willCrash = true
			else: shouldOpen = false
		elif lock.getColor(Lock.COLOR_STEP.EFFECTIVE) == C.olors.NONE: shouldOpen = false
	for lock in remoteLocks:
		if !lock.satisfied: shouldOpen = false
	if shouldOpen and willCrash: Game.crash(); return
	if gateOpen and !shouldOpen:
		GameChanges.addChange(GameChanges.PropertyChange.new(self,&"gateOpen",false))
	elif !gateOpen and shouldOpen:
		if starting: gateOpen = true
		else: GameChanges.addChange(GameChanges.PropertyChange.new(self,&"gateOpen",true))

func auraCheck(player:Player) -> void:
	if type == TYPE.GATE: return
	if animState != ANIM_STATE.IDLE: return
	if starred != STAR_STATE.UNSTARRED: return
	var deAuraed:bool = false
	if player.auraRed and gameFrozen and !hasEffectiveColor(C.olors.MAROON):
		GameChanges.addChange(GameChanges.PropertyChange.new(self,&"gameFrozen",false))
		makeDebris(Debris, C.olors.WHITE)
		deAuraed = true
	if player.auraGreen and gameCrumbled and !hasEffectiveColor(C.olors.FOREST):
		GameChanges.addChange(GameChanges.PropertyChange.new(self,&"gameCrumbled",false))
		makeDebris(Debris, C.olors.BROWN)
		deAuraed = true
	if player.auraBlue and gamePainted and !hasEffectiveColor(C.olors.NAVY):
		GameChanges.addChange(GameChanges.PropertyChange.new(self,&"gamePainted",false))
		makeDebris(Debris, C.olors.ORANGE)
		deAuraed = true
	var auraed:bool = false
	if player.auraMaroon and !gameFrozen and !hasEffectiveColor(C.olors.RED) and !isAllInitialColor(C.olors.ICE):
		GameChanges.addChange(GameChanges.PropertyChange.new(self,&"gameFrozen",true))
		makeDebris(Debris, C.olors.WHITE)
		auraed = true
	if player.auraForest and !gameCrumbled and !hasEffectiveColor(C.olors.GREEN) and !isAllInitialColor(C.olors.MUD):
		GameChanges.addChange(GameChanges.PropertyChange.new(self,&"gameCrumbled",true))
		makeDebris(Debris, C.olors.BROWN)
		auraed = true
	if player.auraNavy and !gamePainted and !hasEffectiveColor(C.olors.BLUE) and !isAllInitialColor(C.olors.GRAFFITI):
		GameChanges.addChange(GameChanges.PropertyChange.new(self,&"gamePainted",true))
		makeDebris(Debris, C.olors.ORANGE)
		auraed = true
	if deAuraed or auraed:
		AudioManager.play(preload("res://resources/sounds/door/deaura.wav"))
		GameChanges.bufferSave()

func isAllInitialColor(color:C.olors) -> bool:
	if getColor(COLOR_STEP.INITIAL) != color: return false
	for lock in locks: if lock.color != color: return false
	return true

func isAllBaseColor(color:C.olors) -> bool:
	if getColor(COLOR_STEP.BASE) != color: return false
	for lock in locks: if lock.getColor(Lock.COLOR_STEP.BASE) != color: return false
	return true

func curseCheck(player:Player) -> void:
	if type == TYPE.GATE: return
	if starred != STAR_STATE.UNSTARRED: return
	if animState != ANIM_STATE.IDLE: return
	if hasEffectiveColor(C.olors.PURE): return
	var willCurse:bool = player.curseMode > 0 and (!cursed or (curseColor != player.curseColor and curseColor != C.olors.PURE))
	var willCurseRedundant:bool = willCurse and isAllInitialColor(player.curseColor)
	if willCurse and !willCurseRedundant:
		GameChanges.addChange(GameChanges.PropertyChange.new(self,&"cursed",true))
		GameChanges.addChange(GameChanges.PropertyChange.new(self,&"curseColor",player.curseColor))
		if player.curseColor in [C.olors.GLITCH, C.olors.ERROR]:
			GameChanges.addChange(GameChanges.PropertyChange.new(self,&"curseMimic",player.curseColor))
		makeCurseParticles(curseColor, 1, 0.2, 0.5)
		AudioManager.play(preload("res://resources/sounds/door/curse.wav"))
		GameChanges.bufferSave()
	elif cursed and (willCurseRedundant or (player.curseMode < 0 and curseColor == player.curseColor)):
		GameChanges.addChange(GameChanges.PropertyChange.new(self,&"cursed",false))
		if willCurseRedundant:
			makeCurseParticles(player.curseColor, 1, 0.2, 0.5)
			AudioManager.play(preload("res://resources/sounds/door/curse.wav"))
		else:
			makeCurseParticles(C.olors.BROWN, -1, 0.2, 0.5)
			AudioManager.play(preload("res://resources/sounds/door/decurse.wav"))
		GameChanges.bufferSave()

func makeCurseParticles(color:C.olors, mode:int, scaleMin:float=1,scaleMax:float=1) -> void:
	for y in floor(size.y/16):
		for x in floor(size.x/16):
			%particlesParent.add_child(CurseParticle.Temporary.new(color, mode, Vector2(x,y)*16+Vector2.ONE*randf_range(4,12), randf_range(scaleMin,scaleMax)))

enum COLOR_STEP {INITIAL, Curse, BASE, Error, DRAW_BASE, Glitch, EFFECTIVE, AuraBreaker, FINAL}

func getColor(step:COLOR_STEP) -> C.olors:
	var resultColor:C.olors = colorSpend

	if step < COLOR_STEP.Curse: return resultColor
	var curseAffected:bool = cursed and curseColor != C.olors.PURE
	if curseAffected: resultColor = curseColor
	
	# BASE
	# redundancy checks go here, like cant freeze if all ice

	if step < COLOR_STEP.Error: return resultColor
	var checkColor:C.olors = resultColor # error and glitch act independently
	if checkColor == C.olors.ERROR: resultColor = curseMimic if curseAffected else errorMimic

	# DRAW_BASE
	# the step used for drawing

	if step < COLOR_STEP.Glitch: return resultColor
	if checkColor == C.olors.GLITCH: resultColor = curseMimic if curseAffected else glitchMimic

	# EFFECTIVE
	# the step used for normal immunities, and what glitch gets set to when the door is opened

	if step < COLOR_STEP.AuraBreaker: return resultColor
	if gameFrozen: resultColor = C.olors.ICE
	if gameCrumbled: resultColor = C.olors.MUD
	if gamePainted: resultColor = C.olors.GRAFFITI

	# FINAL
	# the step used for spending
	return resultColor

func ipow() -> PackedInt64Array: # for complex view
	if Game.playState == Game.PLAY_STATE.EDIT: return M.ONE
	# if extant, return current
	if M.ex(M.across(gameCopies, Game.player.complexMode)): return M.saxis(M.across(gameCopies, Game.player.complexMode))
	# return the other axis
	return M.saxis(M.across(gameCopies, M.axibs(M.rotate(Game.player.complexMode))))

func complexCheck() -> void:
	drawComplex = Game.playState != Game.PLAY_STATE.EDIT and M.nex(M.across(ipow(), Game.player.complexMode))
	queue_redraw()

func setMimic(mimicType:C.olors, setColor:C.olors) -> void:
	var property:StringName
	match mimicType:
		C.olors.GLITCH: property = &"glitchMimic"
		C.olors.ERROR: property = &"errorMimic"
	if starred == STAR_STATE.UNSTARRED:
		if curseUnaffected():
			if hasInitialColor(mimicType): GameChanges.addChange(GameChanges.PropertyChange.new(self, property, setColor))
		elif curseColor == mimicType: GameChanges.addChange(GameChanges.PropertyChange.new(self, &"curseMimic", setColor))
	for lock in locks:
		if ((curseUnaffected() and starred == STAR_STATE.UNSTARRED) or lock.armament) and lock.color == mimicType: GameChanges.addChange(GameChanges.PropertyChange.new(lock, property, setColor))
		lock.queue_redraw()
	queue_redraw()
	if type == TYPE.GATE:
		gateCheck(Game.player)
		Game.player.bufferCheckKeys() # if armaments

func curseUnaffected() -> bool: return !cursed or curseColor == C.olors.PURE

func armamentColors() -> Array[C.olors]:
	var colors:Array[C.olors]
	for lock in locks:
		if lock.armament and lock.getColor(Lock.COLOR_STEP.EFFECTIVE) not in colors: colors.append(lock.getColor(Lock.COLOR_STEP.EFFECTIVE))
	return colors

func hasArmamentLocks() -> bool:
	for lock in locks: if lock.armament: return true
	return false

class Debris extends Node2D:
	const FRAME:Texture2D = preload("res://assets/game/door/debris/frame.png")
	const HIGH:Texture2D = preload("res://assets/game/door/debris/high.png")
	const MAIN:Texture2D = preload("res://assets/game/door/debris/main.png")
	const DARK:Texture2D = preload("res://assets/game/door/debris/dark.png")

	var color:C.olors
	var opacity:float = 1
	var velocity:Vector2 = Vector2.ZERO
	var acceleration:Vector2 = Vector2.ZERO
	var fadeSpeed:float

	const FPS:float = 60

	func _init(_color:C.olors,_position) -> void:
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
	var part:int = 0 # part of the anim
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
				if timer >= lerp(25,5, Game.fastAnimSpeed): part += 1; timer = 0
			1:
				position += (startPosition - position) * 0.3
				if position.distance_squared_to(startPosition) < 1: position = startPosition
				whiteAmt = min(whiteAmt+0.0666666667, 1)
				queue_redraw()
				if timer >= lerp(26,5, Game.fastAnimSpeed): queue_free()
		timer += 1

	func _draw() -> void:
		var rect:Rect2 = Rect2(Vector2.ZERO,Vector2(16,16))
		RenderingServer.canvas_item_add_texture_rect(get_canvas_item(),rect,FRAME)
		RenderingServer.canvas_item_add_texture_rect(get_canvas_item(),rect,HIGH,false,Game.highTone[color])
		RenderingServer.canvas_item_add_texture_rect(get_canvas_item(),rect,MAIN,false,Game.mainTone[color])
		RenderingServer.canvas_item_add_texture_rect(get_canvas_item(),rect,DARK,false,Game.darkTone[color])
		RenderingServer.canvas_item_add_rect(get_canvas_item(),rect,Color(Color.WHITE,whiteAmt))
