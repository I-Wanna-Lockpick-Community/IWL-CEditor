extends GameObject
class_name KeyBulk
const SCENE:PackedScene = preload("res://scenes/objects/keyBulk.tscn")

const MULTITYPEOFFSET = 3 # no magic numbers

const TYPES:int = 6
enum TYPE {NORMAL, EXACT, STAR, ROTOR, CURSE, OPERATOR}

const OPERATIONS:int = 6
enum OPERATION {SET, ADD, SUBTRACT, MULTIPLY, DIVIDE, MODULO}
const OPERATION_NAMES:Array[String] = ["Set", "Add", "Subtract", "Multiply", "Divide", "Modulo"]

const BOOL_TYPES = 3
enum BOOL_TYPE {ENABLE, DISABLE, TOGGLE}

# colors that use textures
const TEXTURE_COLORS:Array[C.olors] = [C.olors.MASTER, C.olors.PURE, C.olors.STONE, C.olors.DYNAMITE, C.olors.QUICKSILVER, C.olors.ICE, C.olors.MUD, C.olors.GRAFFITI, C.olors.ERROR, C.olors.COSMIC]

static var FILL:KeyTextureLoader = KeyTextureLoader.new("res://assets/game/key/$t/fill.png")
static var FRAME:KeyTextureLoader = KeyTextureLoader.new("res://assets/game/key/$t/frame.png")
static var FILL_GLITCH:KeyTextureLoader = KeyTextureLoader.new("res://assets/game/key/$t/fillGlitch.png")
static var FRAME_GLITCH:KeyTextureLoader = KeyTextureLoader.new("res://assets/game/key/$t/frameGlitch.png")
static var OUTLINE_MASK:KeyTextureLoader = KeyTextureLoader.new("res://assets/game/key/$t/outlineMask.png")
static var QUICKSILVER_OUTLINE_MASK:KeyTextureLoader = KeyTextureLoader.new("res://assets/game/key/quicksilver/outlineMask$t.png", true)
static var ERROR_FX:IndexTextureLoader = IndexTextureLoader.new("res://assets/game/key/error/fx.png", 3)

# for the additional little thing in the operator key
static var OPERATOR_FRAME:OperatorTextureLoader = OperatorTextureLoader.new("res://assets/game/key/operator/frame/$t.png")
static var OPERATOR_FILL:OperatorTextureLoader = OperatorTextureLoader.new("res://assets/game/key/operator/fill/$t.png")
static var OPERATOR_FRAME_GLITCH:OperatorTextureLoader = OperatorTextureLoader.new("res://assets/game/key/operator/frameGlitch/$t.png")
static var OPERATOR_FILL_GLITCH:OperatorTextureLoader = OperatorTextureLoader.new("res://assets/game/key/operator/fillGlitch/$t.png") 
static var OPERATOR_OUTLINE_MASK:OperatorTextureLoader = OperatorTextureLoader.new("res://assets/game/key/operator/outlineMask/$t.png") 

const CURSE_FILL_DARK:Texture2D = preload("res://assets/game/key/curse/fillDark.png")

const NULL_ROTOR_SYMBOL:Texture2D = preload("res://assets/game/key/symbols/null.png")
const SIGNFLIP_SYMBOL:Texture2D = preload("res://assets/game/key/symbols/signflip.png")
const POSROTOR_SYMBOL:Texture2D = preload("res://assets/game/key/symbols/posrotor.png")
const NEGROTOR_SYMBOL:Texture2D = preload("res://assets/game/key/symbols/negrotor.png")
const INFINITE_SYMBOL:Texture2D = preload("res://assets/game/key/symbols/infinite.png")
const RECIPROCAL__SYMBOL:Texture2D = preload("res://assets/game/key/symbols/reci.png")
const RECIPROCAL_FLIP_SYMBOL:Texture2D = preload("res://assets/game/key/symbols/reciflip.png")
const RECIPROCAL_POS_SYMBOL:Texture2D = preload("res://assets/game/key/symbols/recipos.png")
const RECIPROCAL_NEG_SYMBOL:Texture2D = preload("res://assets/game/key/symbols/recineg.png")
const GLISTENING_SYMBOL:Texture2D = preload("res://assets/game/key/symbols/glistening.png")

const OVERLAY_STAR:Texture2D = preload("res://assets/game/key/overlay/starry.png")
const OVERLAY_WEAK:Texture2D = preload("res://assets/game/key/overlay/weak.png")
const OVERLAY_FORCEFUL:Texture2D = preload("res://assets/game/key/overlay/forceful.png")

static var TEXTURE:KeyColorsTextureLoader = KeyColorsTextureLoader.new("res://assets/game/key/$c/$t.png", true, false, {capitalised=false})
static var GLITCH:KeyColorsTextureLoader = KeyColorsTextureLoader.new("res://assets/game/key/$c/glitch$t.png", false, false, {capitalised=true})

static var OPERATION_TEXTURE:OperatorColorsTextureLoader = OperatorColorsTextureLoader.new("res://assets/game/key/$c/operand/$t.png", true, false, {capitalised=false})
static var OPERATION_GLITCH:OperatorColorsTextureLoader = OperatorColorsTextureLoader.new("res://assets/game/key/$c/operand/glitch$t.png", false, false, {capitalised=true})

const FKEYBULK:Font = preload("res://resources/fonts/fKeyBulk.fnt")

const CREATE_PARAMETERS:Array[StringName] = [
	&"position"
]

@export_group("SavedProperties")
@export var collectType:Player.KEYCHANGE_TYPE = Player.KEYCHANGE_TYPE.NORMAL
@export var color:C.olors = C.olors.WHITE
@export var type:TYPE = TYPE.NORMAL
@export var count:PackedInt64Array = M.ONE()
@export var infinite:int = 0
@export var glistening:bool = false # whether the key affects glistening count or not
@export var altColor:C.olors = C.olors.WHITE
@export var operation:OPERATION = OPERATION.SET
@export var boolType:BOOL_TYPE = BOOL_TYPE.ENABLE # whether a star or curse key is an unstar or uncurse key
@export var reciprocal:bool = false # whether a rotor key is reciprocal or not

func getColors() -> Array[C.olors]:
	if type == TYPE.OPERATOR: return [color, altColor]
	return [color]

var drawDropShadow:RID
var drawGlitch:RID
var drawMain:RID
var drawSymbol:RID
var drawError:RID
var drawAdditionalGlitch:RID
var drawAdditional:RID
var drawOverlay:RID
var textDrawer:TextDrawer
func _init() -> void: size = Vector2(32,32)

func _ready() -> void:
	drawDropShadow = RenderingServer.canvas_item_create()
	drawGlitch = RenderingServer.canvas_item_create()
	drawMain = RenderingServer.canvas_item_create()
	drawSymbol = RenderingServer.canvas_item_create()
	drawError = RenderingServer.canvas_item_create()
	drawAdditionalGlitch = RenderingServer.canvas_item_create()
	drawAdditional = RenderingServer.canvas_item_create()
	drawOverlay = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_material(drawGlitch,Game.GLITCH_MATERIAL.get_rid())
	RenderingServer.canvas_item_set_material(drawAdditionalGlitch,Game.GLITCH_MATERIAL.get_rid())
	RenderingServer.canvas_item_set_z_index(drawDropShadow,-3)
	RenderingServer.canvas_item_set_parent(drawDropShadow,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawGlitch,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawMain,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawSymbol,get_canvas_item())
	textDrawer = TextDrawer.new(self, TextDrawer.SETTING.FKEYBULK)
	textDrawer.position = Vector2(1,30)
	RenderingServer.canvas_item_set_parent(drawError,get_canvas_item())
	RenderingServer.canvas_item_set_self_modulate(drawError, "#ffffffaa")
	RenderingServer.canvas_item_set_material(drawError,Game.ADDITIVE_MATERIAL)
	RenderingServer.canvas_item_set_parent(drawAdditionalGlitch,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawAdditional,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawOverlay,get_canvas_item())
	RenderingServer.canvas_item_set_z_index(drawOverlay,2)
	Game.connect(&"goldIndexChanged",func():if hasAnimatedColor(): queue_redraw())

func hasAnimatedColor() -> bool:
	if getColor(COLOR_STEP.DRAW_BASE) == C.olors.ERROR or getAltColor(COLOR_STEP.DRAW_BASE) == C.olors.ERROR: return true
	if Colors.getDef(getColor(COLOR_STEP.DRAW_BASE)).keyTextureFrames > 1: return true
	if type == TYPE.OPERATOR and Colors.getDef(getAltColor(COLOR_STEP.DRAW_BASE)).keyTextureFrames > 1: return true
	return false

func _freed() -> void:
	RenderingServer.free_rid(drawDropShadow)
	RenderingServer.free_rid(drawGlitch)
	RenderingServer.free_rid(drawMain)
	RenderingServer.free_rid(drawSymbol)
	RenderingServer.free_rid(drawError)
	RenderingServer.free_rid(drawAdditionalGlitch)
	RenderingServer.free_rid(drawAdditional)
	RenderingServer.free_rid(drawOverlay)

func convertNumbers(from:M.SYSTEM) -> void:
	Changes.addChange(Changes.ComponentConvertNumberChange.new(self, from, &"count"))

func outlineTex() -> Texture2D: return getOutlineTexture(color, type, boolType, operation)

static func getOutlineTexture(keyColor:C.olors, keyType:TYPE=TYPE.NORMAL, keyBoolType:BOOL_TYPE=BOOL_TYPE.ENABLE, keyOperation:OPERATION=OPERATION.SET) -> Texture2D:
	var textureType:KeyTextureLoader.TYPE = keyTextureType(keyType,keyBoolType)
	match keyColor:
		C.olors.MASTER:
			match textureType:
				KeyTextureLoader.TYPE.NORMAL: return preload("res://assets/game/key/master/outlineMask.png")
				KeyTextureLoader.TYPE.EXACT: return preload("res://assets/game/key/master/outlineMaskExact.png")
		C.olors.QUICKSILVER:
			return QUICKSILVER_OUTLINE_MASK.current([textureType])
		C.olors.DYNAMITE:
			if textureType == KeyTextureLoader.TYPE.NORMAL: return preload("res://assets/game/key/dynamite/outlineMask.png")
	if textureType == KeyTextureLoader.TYPE.OPERATOR: return OPERATOR_OUTLINE_MASK.current([keyOperation])
	return OUTLINE_MASK.current([textureType])

func _draw() -> void:
	RenderingServer.canvas_item_clear(drawDropShadow)
	RenderingServer.canvas_item_clear(drawGlitch)
	RenderingServer.canvas_item_clear(drawMain)
	RenderingServer.canvas_item_clear(drawSymbol)
	RenderingServer.canvas_item_clear(drawError)
	RenderingServer.canvas_item_clear(drawAdditionalGlitch)
	RenderingServer.canvas_item_clear(drawAdditional)
	textDrawer.setMixedFractions(Game.mixedFractions)
	if !active and Game.playState == Game.PLAY_STATE.PLAY:
		textDrawer.evaluate()
		return
	var rect:Rect2 = Rect2(Vector2.ZERO, size)
	RenderingServer.canvas_item_add_texture_rect(drawDropShadow,Rect2(Vector2(3,3),size),getOutlineTexture(color,type,boolType,operation),false,Game.DROP_SHADOW_COLOR)
	drawKey(drawGlitch,drawMain,Vector2.ZERO,getColor(COLOR_STEP.DRAW_BASE),type,boolType,glitchMimic,partialInfiniteAlpha)
	if color == C.olors.ERROR:
		var errorrect:Rect2 = Rect2(Vector2(randi_range(-5,5),randi_range(-5,5)),size)
		RenderingServer.canvas_item_add_texture_rect(drawError,errorrect,ERROR_FX.current([randi_range(0,2)]))
	if animState == ANIM_STATE.FLASH: RenderingServer.canvas_item_add_texture_rect(drawSymbol,rect,outlineTex(),false,Color(Color.WHITE,animAlpha))
	match type:
		KeyBulk.TYPE.NORMAL, KeyBulk.TYPE.EXACT:
			if !M.eq(count, M.ONE()): textDrawer.addNumber(count, keycountColor(), keycountOutlineColor())
		KeyBulk.TYPE.ROTOR:
			if reciprocal:
				if M.eq(count, M.nONE()): RenderingServer.canvas_item_add_texture_rect(drawSymbol,rect,RECIPROCAL_FLIP_SYMBOL)
				elif M.eq(count, M.I()): RenderingServer.canvas_item_add_texture_rect(drawSymbol,rect,RECIPROCAL_POS_SYMBOL)
				elif M.eq(count, M.nI()): RenderingServer.canvas_item_add_texture_rect(drawSymbol,rect,RECIPROCAL_NEG_SYMBOL)
				elif M.eq(count, M.ONE()): RenderingServer.canvas_item_add_texture_rect(drawSymbol,rect, RECIPROCAL__SYMBOL)
			else:
				if M.eq(count, M.nONE()) or M.eq(count,M.ONE()): RenderingServer.canvas_item_add_texture_rect(drawSymbol,rect,SIGNFLIP_SYMBOL)
				elif M.eq(count, M.I()): RenderingServer.canvas_item_add_texture_rect(drawSymbol,rect,POSROTOR_SYMBOL)
				elif M.eq(count, M.nI()): RenderingServer.canvas_item_add_texture_rect(drawSymbol,rect,NEGROTOR_SYMBOL)
		KeyBulk.TYPE.CURSE, KeyBulk.TYPE.STAR: #placeholder
			if boolType == BOOL_TYPE.TOGGLE: RenderingServer.canvas_item_add_texture_rect(drawSymbol,rect,SIGNFLIP_SYMBOL)
		KeyBulk.TYPE.OPERATOR:
			drawOperationSymbol(drawAdditional,drawAdditionalGlitch,Vector2.ZERO,getAltColor(COLOR_STEP.DRAW_BASE),operation,glitchMimic)
	if infinite:
		if glistening:
			RenderingServer.canvas_item_add_texture_rect(drawSymbol,Rect2(Vector2(MULTITYPEOFFSET,-MULTITYPEOFFSET), size),INFINITE_SYMBOL)
		else:
			RenderingServer.canvas_item_add_texture_rect(drawSymbol,rect,INFINITE_SYMBOL)
		if infinite > 1:
			var string:String = ""
			if partialInfiniteCount: string = str(infinite-partialInfiniteCount)
			string += "/%s" % infinite
			TextDraw.outlined2(FKEYBULK,drawSymbol,string,Color("#ebe3dd"),Color("#363029"),14,Vector2(28,8))
	if glistening:
		if infinite:
			RenderingServer.canvas_item_add_texture_rect(drawSymbol,Rect2(Vector2(-MULTITYPEOFFSET,MULTITYPEOFFSET), size),GLISTENING_SYMBOL)
		else:
			RenderingServer.canvas_item_add_texture_rect(drawSymbol,rect,GLISTENING_SYMBOL)
	match collectType:
		Player.KEYCHANGE_TYPE.NONE: RenderingServer.canvas_item_add_texture_rect(drawSymbol,rect,OVERLAY_WEAK, false, Color(Colors.getDarkTone(getColor(COLOR_STEP.FINAL)),0.6))
		Player.KEYCHANGE_TYPE.ALL: RenderingServer.canvas_item_add_texture_rect(drawSymbol,rect,OVERLAY_FORCEFUL, false, Color(Colors.getDarkTone(getColor(COLOR_STEP.FINAL)),0.6))
		Player.KEYCHANGE_TYPE.STAR: RenderingServer.canvas_item_add_texture_rect(drawSymbol,rect,OVERLAY_STAR, false, Color(Colors.getDarkTone(getColor(COLOR_STEP.FINAL)),0.6))
	textDrawer.evaluate()

func keycountColor() -> Color: return Color("#363029") if M.negative(M.sign(count)) else Color("#ebe3dd")
func keycountOutlineColor() -> Color: return Color("#d6cfc9") if M.negative(M.sign(count)) else Color("#363029")

static func keyTextureType(keyType:TYPE, keyBoolType:BOOL_TYPE) -> KeyTextureLoader.TYPE:
	match keyType:
		TYPE.EXACT: return KeyTextureLoader.TYPE.EXACT
		TYPE.STAR: return KeyTextureLoader.TYPE.UNSTAR if keyBoolType == BOOL_TYPE.DISABLE else KeyTextureLoader.TYPE.STAR
		TYPE.CURSE: return KeyTextureLoader.TYPE.UNCURSE if keyBoolType == BOOL_TYPE.DISABLE else KeyTextureLoader.TYPE.CURSE
		TYPE.OPERATOR: return KeyTextureLoader.TYPE.OPERATOR
		_: return KeyTextureLoader.TYPE.NORMAL

static func drawKey(keyDrawGlitch:RID,keyDrawMain:RID, keyOffset:Vector2,keyColor:C.olors,keyType:TYPE=TYPE.NORMAL,keyBoolType:BOOL_TYPE=BOOL_TYPE.ENABLE,keyGlitchMimic:C.olors=C.olors.GLITCH,keyPartialInfiniteAlpha:float=1) -> void:
	var rect:Rect2 = Rect2(keyOffset, Vector2(32,32))
	var textureType:KeyTextureLoader.TYPE = keyTextureType(keyType, keyBoolType)
	RenderingServer.canvas_item_set_modulate(keyDrawMain, Color(Color.WHITE, keyPartialInfiniteAlpha))
	RenderingServer.canvas_item_set_modulate(keyDrawGlitch, Color(Color.WHITE, keyPartialInfiniteAlpha))
	if keyColor in TEXTURE_COLORS:
		RenderingServer.canvas_item_add_texture_rect(keyDrawMain,rect,TEXTURE.current([keyColor,textureType]))
	elif keyColor == C.olors.GLITCH:
		RenderingServer.canvas_item_add_texture_rect(keyDrawGlitch,rect,FRAME_GLITCH.current([textureType]))
		RenderingServer.canvas_item_add_texture_rect(keyDrawGlitch,rect,FILL.current([textureType]),false,Colors.getMainTone(keyColor))
		if textureType == TYPE.CURSE: RenderingServer.canvas_item_add_texture_rect(keyDrawGlitch,rect,CURSE_FILL_DARK,false,Colors.getDarkTone(keyColor))
		if keyGlitchMimic != C.olors.GLITCH:
			if keyGlitchMimic in TEXTURE_COLORS: RenderingServer.canvas_item_add_texture_rect(keyDrawMain,rect,GLITCH.current([keyGlitchMimic,textureType]))
			else: RenderingServer.canvas_item_add_texture_rect(keyDrawMain,rect,FILL_GLITCH.current([textureType]),false,Colors.getMainTone(keyGlitchMimic))
	else:
		RenderingServer.canvas_item_add_texture_rect(keyDrawMain,rect,FRAME.current([textureType]))
		RenderingServer.canvas_item_add_texture_rect(keyDrawMain,rect,FILL.current([textureType]),false,Colors.getMainTone(keyColor))
		if keyType == TYPE.CURSE and not keyBoolType == BOOL_TYPE.DISABLE: RenderingServer.canvas_item_add_texture_rect(keyDrawMain,rect,CURSE_FILL_DARK,false,Colors.getDarkTone(keyColor))

static func drawOperationSymbol(keyDrawAdditonal:RID, keyDrawGlitch:RID, keyOffset:Vector2, partColor:C.olors, keyMode:OPERATION=OPERATION.SET,keyGlitchMimic:C.olors=C.olors.GLITCH):
	var rect:Rect2 = Rect2(keyOffset, Vector2(32,32))
	if partColor in TEXTURE_COLORS:
		RenderingServer.canvas_item_add_texture_rect(keyDrawAdditonal,rect,OPERATION_TEXTURE.current([partColor,keyMode]))
	elif partColor == C.olors.GLITCH:
		RenderingServer.canvas_item_add_texture_rect(keyDrawGlitch,rect,OPERATOR_FRAME_GLITCH.current([keyMode]))
		RenderingServer.canvas_item_add_texture_rect(keyDrawGlitch,rect,OPERATOR_FILL.current([keyMode]),false,Colors.getMainTone(partColor))
		if keyGlitchMimic != C.olors.GLITCH:
			if keyGlitchMimic in TEXTURE_COLORS: RenderingServer.canvas_item_add_texture_rect(keyDrawAdditonal,rect,OPERATION_GLITCH.current([keyGlitchMimic,keyMode]))
			else: 
				RenderingServer.canvas_item_add_texture_rect(keyDrawAdditonal,rect,OPERATOR_FILL_GLITCH.current([keyMode]),false,Colors.getMainTone(keyGlitchMimic))
	else:
		RenderingServer.canvas_item_add_texture_rect(keyDrawAdditonal,rect,OPERATOR_FRAME.current([keyMode]))
		RenderingServer.canvas_item_add_texture_rect(keyDrawAdditonal,rect,OPERATOR_FILL.current([keyMode]),false,Colors.getMainTone(partColor))

func propertyChangedInit(property:StringName) -> void:
	if property == &"type":
		if type not in [TYPE.NORMAL, TYPE.EXACT] and M.neq(count, M.ONE()): Changes.addChange(Changes.PropertyChange.new(self,&"count",M.ONE()))
		if type not in [TYPE.STAR, TYPE.CURSE] and boolType != BOOL_TYPE.ENABLE: Changes.addChange(Changes.PropertyChange.new(self,&"boolType",BOOL_TYPE.ENABLE))
		if type in [TYPE.STAR, TYPE.CURSE] and collectType != Player.KEYCHANGE_TYPE.NORMAL: Changes.addChange(Changes.PropertyChange.new(self,&"collectType",Player.KEYCHANGE_TYPE.NORMAL))
		if type != TYPE.ROTOR: Changes.addChange(Changes.PropertyChange.new(self,&"reciprocal",false))
		Changes.addChange(Changes.PropertyChange.new(self,&"altColor",color))
	if property == &"reciprocal":
		if reciprocal and M.eq(count, M.nONE()): Changes.addChange(Changes.PropertyChange.new(self,&"count",M.ONE()))
		if !reciprocal and M.eq(count, M.ONE()): Changes.addChange(Changes.PropertyChange.new(self,&"count",M.nONE()))

# ==== PLAY ==== #
var glitchMimic:C.olors = C.olors.GLITCH
var errorMimic:C.olors = C.olors.ERROR
var partialInfiniteCount:int = 0

enum ANIM_STATE {IDLE, FLASH}
var animState:ANIM_STATE = ANIM_STATE.IDLE
var animAlpha:float = 0
var partialInfiniteAlpha:float = 1

func _process(delta:float) -> void:
	match animState:
		ANIM_STATE.IDLE: animAlpha = 0
		ANIM_STATE.FLASH:
			animAlpha -= delta*6
			if animAlpha <= 0: animState = ANIM_STATE.IDLE
			queue_redraw()
	if infinite > 1:
		if !partialInfiniteCount and partialInfiniteAlpha < 1:
			partialInfiniteAlpha = min(partialInfiniteAlpha+delta*6, 1)
			queue_redraw()
		elif partialInfiniteCount and partialInfiniteAlpha > 0.5:
			partialInfiniteAlpha = max(partialInfiniteAlpha-delta*6, 0.5)
			queue_redraw()

func stop() -> void:
	glitchMimic = C.olors.GLITCH
	errorMimic = C.olors.ERROR
	partialInfiniteCount = 0
	partialInfiniteAlpha = 1
	super()

func collect(player:Player) -> void:
	if partialInfiniteCount: return
	var collectColor:C.olors = getColor(COLOR_STEP.FINAL)
	var collectAltColor:C.olors = getAltColor(COLOR_STEP.FINAL) # for operator
	if glistening:
		match type:
			TYPE.NORMAL: player.changeGlisten(collectColor, M.add(player.glisten[collectColor], count), collectType)
			TYPE.EXACT: player.changeGlisten(collectColor, count, collectType)
			TYPE.ROTOR:
				if reciprocal: player.changeGlisten(collectColor, M.divide(count,player.glisten[collectColor]), collectType)
				else: player.changeGlisten(collectColor, M.times(player.glisten[collectColor], count), collectType)
			TYPE.OPERATOR:
				match operation:
					OPERATION.SET: player.changeGlisten(collectColor, player.glisten[collectAltColor], collectType)
					OPERATION.ADD: player.changeGlisten(collectColor, M.add(player.glisten[collectColor], player.glisten[collectAltColor]), collectType)
					OPERATION.SUBTRACT: player.changeGlisten(collectColor, M.sub(player.glisten[collectColor], player.glisten[collectAltColor]), collectType)
					OPERATION.MULTIPLY: player.changeGlisten(collectColor, M.times(player.glisten[collectColor], player.glisten[collectAltColor]), collectType)
					OPERATION.DIVIDE: player.changeGlisten(collectColor, M.divide(player.glisten[collectColor], player.glisten[collectAltColor]), collectType)
					OPERATION.MODULO: player.changeGlisten(collectColor, M.modulo(player.glisten[collectColor], player.glisten[collectAltColor]), collectType)

	match type:
		TYPE.NORMAL: player.changeKeys(collectColor, M.add(player.key[collectColor], count), collectType)
		TYPE.EXACT: player.changeKeys(collectColor, count, collectType)
		TYPE.ROTOR:
			if reciprocal: player.changeKeys(collectColor, M.divide(count,player.key[collectColor]), collectType)
			else: player.changeKeys(collectColor, M.times(player.key[collectColor], count), collectType)
		TYPE.STAR, TYPE.CURSE:
			var changeType:GameChanges.TYPE = GameChanges.TYPE.StarChange if type == TYPE.STAR else GameChanges.TYPE.CurseChange
			match boolType:
				BOOL_TYPE.ENABLE: GameChanges.applyChange(GameChanges.newColorChange(changeType, collectColor, true))
				BOOL_TYPE.DISABLE: GameChanges.applyChange(GameChanges.newColorChange(changeType, collectColor, false))
				BOOL_TYPE.TOGGLE, _:
					if type == TYPE.STAR: GameChanges.applyChange(GameChanges.newColorChange(changeType, collectColor, !player.star[collectColor]))
					else: GameChanges.applyChange(GameChanges.newColorChange(changeType, collectColor, !player.curse[collectColor]))
		TYPE.OPERATOR:
			match operation:
				OPERATION.SET: player.changeKeys(collectColor, player.key[collectAltColor], collectType)
				OPERATION.ADD: player.changeKeys(collectColor, M.add(player.key[collectColor], player.key[collectAltColor]), collectType)
				OPERATION.SUBTRACT: player.changeKeys(collectColor, M.sub(player.key[collectColor], player.key[collectAltColor]), collectType)
				OPERATION.MULTIPLY: player.changeKeys(collectColor, M.times(player.key[collectColor], player.key[collectAltColor]), collectType)
				OPERATION.DIVIDE: player.changeKeys(collectColor, M.divide(player.key[collectColor], player.key[collectAltColor]), collectType)
				OPERATION.MODULO: player.changeKeys(collectColor, M.modulo(player.key[collectColor], player.key[collectAltColor]), collectType)

	if infinite:
		flashAnimation()
		GameChanges.applyChange(GameChanges.newPropertyChange(self, &"partialInfiniteCount", infinite))
	else: GameChanges.applyChange(GameChanges.newPropertyChange(self, &"active", false))
	for object in Game.objects.values():
		if object is KeyBulk and object.infinite and object.partialInfiniteCount > 0:
			GameChanges.applyChange(GameChanges.newPropertyChange(object, &"partialInfiniteCount", object.partialInfiniteCount - 1))

	if color == C.olors.MASTER: # not effectiveColor; doesnt trigger on glitch master
		AudioManager.play(preload("res://resources/sounds/key/master.wav"))
	else:
		match type:
			TYPE.ROTOR: AudioManager.play(preload("res://resources/sounds/key/signflip.wav"))
			TYPE.STAR:
				if boolType == BOOL_TYPE.DISABLE or (boolType == BOOL_TYPE.TOGGLE and not player.star[color]): AudioManager.play(preload("res://resources/sounds/key/unstar.wav"))
				else: AudioManager.play(preload("res://resources/sounds/key/star.wav"))
			_:
				if M.negative(M.sign(count)): AudioManager.play(preload("res://resources/sounds/key/negative.wav"))
				else: AudioManager.play(preload("res://resources/sounds/key/normal.wav"))
	
	Game.setMimic(C.olors.ERROR, collectColor)
	Game.player.bufferCheckKeys()
	GameChanges.bufferSave()

func setMimic(mimicType:C.olors, setColor:C.olors) -> void:
	var property:StringName
	match mimicType:
		C.olors.GLITCH: property = &"glitchMimic"
		C.olors.ERROR: property = &"errorMimic"
	if hasInitialColor(mimicType): GameChanges.applyChange(GameChanges.newPropertyChange(self, property, setColor))
	queue_redraw()

func flashAnimation() -> void:
	animState = ANIM_STATE.FLASH
	animAlpha = 1

func propertyGameChangedDo(property:StringName) -> void:
	if property == &"active":
		%interact.process_mode = PROCESS_MODE_INHERIT if active else PROCESS_MODE_DISABLED

func hasInitialColor(checkColor:C.olors) -> bool:
	return color == checkColor or (type == TYPE.OPERATOR and altColor == checkColor)

enum COLOR_STEP {INITIAL, Error, DRAW_BASE, Glitch, FINAL}

func getColor(step:COLOR_STEP) -> C.olors:
	var resultColor:C.olors = color

	if step < COLOR_STEP.Error: return resultColor
	if resultColor == C.olors.ERROR: return errorMimic

	# DRAW_BASE
	# the step used for drawing

	if step < COLOR_STEP.Glitch: return resultColor
	if resultColor == C.olors.GLITCH: return glitchMimic

	# FINAL
	# the step used for spending
	return resultColor

func getAltColor(step:COLOR_STEP) -> C.olors:
	var resultColor:C.olors = altColor

	if step < COLOR_STEP.Error: return resultColor
	if resultColor == C.olors.ERROR: return errorMimic

	# DRAW_BASE
	# the step used for drawing

	if step < COLOR_STEP.Glitch: return resultColor
	if resultColor == C.olors.GLITCH: return glitchMimic

	# FINAL
	# the step used for spending
	return resultColor
