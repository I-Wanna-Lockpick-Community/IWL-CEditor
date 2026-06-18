extends GameObject
class_name RemoteLock
const SCENE:PackedScene = preload("res://scenes/objects/remoteLock.tscn")

const SEARCH_ICON:Texture2D = preload("res://assets/ui/modes/remoteLock.png")
const SEARCH_NAME:String = "Remote Lock"
const SEARCH_KEYWORDS:Array[String] = []

func getOffset() -> Vector2: return Lock.offsetFromType(sizeType)

func getAvailableConfigurations() -> Array[Array]: return Lock.availableConfigurations(count, type)

const CREATE_PARAMETERS:Array[StringName] = [
	&"position"
]
const PROPERTIES:Array[StringName] = [
	&"id", &"position", &"size",
	&"color", &"type", &"configuration", &"sizeType", &"count", &"zeroI", &"isPartial", &"denominator", &"negated", &"armament",
	&"frozen", &"crumbled", &"painted"
]
static var ARRAYS:Dictionary[StringName,Variant] = {
	&"doors":RemoteLock
}

var color:C.olors = C.olors.WHITE
var type:Lock.TYPE = Lock.TYPE.NORMAL
var configuration:Lock.CONFIGURATION = Lock.CONFIGURATION.spr1A
var sizeType:Lock.SIZE_TYPE = Lock.SIZE_TYPE.AnyS
var count:PackedInt64Array = M.ONE
var zeroI:bool = false
var isPartial:bool = false # for partial blast
var denominator:PackedInt64Array = M.ONE # for partial blast
var negated:bool = false
var armament:bool = false
var frozen:bool = false
var crumbled:bool = false
var painted:bool = false

func getColors() -> Array[C.olors]: return [color]

var doors:Array[Door] = []

var drawDropShadow:RID
var drawConnections:RID
var drawGlitch:RID
var drawScaled:RID
var drawAuraBreaker:RID
var drawMain:RID
var drawError:RID
var drawConfiguration:RID
var drawCrumbled:RID
var drawPainted:RID
var drawFrozen:RID

func _init() -> void: size = Vector2(18,18)

func _ready() -> void:
	drawDropShadow = RenderingServer.canvas_item_create()
	drawConnections = RenderingServer.canvas_item_create()
	drawScaled = RenderingServer.canvas_item_create()
	drawAuraBreaker = RenderingServer.canvas_item_create()
	drawGlitch = RenderingServer.canvas_item_create()
	drawMain = RenderingServer.canvas_item_create()
	drawError = RenderingServer.canvas_item_create()
	drawConfiguration = RenderingServer.canvas_item_create()
	drawCrumbled = RenderingServer.canvas_item_create()
	drawPainted = RenderingServer.canvas_item_create()
	drawFrozen = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_z_index(drawDropShadow,-2)
	RenderingServer.canvas_item_set_z_index(drawConnections,-2)
	RenderingServer.canvas_item_set_parent(drawDropShadow,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawConnections,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawScaled,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawAuraBreaker,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawGlitch,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawMain,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawConfiguration,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawCrumbled,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawPainted,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawFrozen,get_canvas_item())
	RenderingServer.canvas_item_set_self_modulate(drawError, "#ffffffaa")
	RenderingServer.canvas_item_set_material(drawError,Game.ADDITIVE_MATERIAL)
	Game.connect(&"goldIndexChanged",func(): if Colors.getDef(getColor(Lock.COLOR_STEP.DRAW_BASE)).doorTextureFrames > 1: queue_redraw())

func _freed() -> void:
	RenderingServer.free_rid(drawDropShadow)
	RenderingServer.free_rid(drawConnections)
	RenderingServer.free_rid(drawGlitch)
	RenderingServer.free_rid(drawScaled)
	RenderingServer.free_rid(drawAuraBreaker)
	RenderingServer.free_rid(drawMain)
	RenderingServer.free_rid(drawError)
	RenderingServer.free_rid(drawConfiguration)
	RenderingServer.free_rid(drawCrumbled)
	RenderingServer.free_rid(drawPainted)
	RenderingServer.free_rid(drawFrozen)

func convertNumbers(from:M.SYSTEM) -> void:
	Changes.addChange(Changes.ComponentConvertNumberChange.new(self, from, &"count"))
	Changes.addChange(Changes.ComponentConvertNumberChange.new(self, from, &"denominator"))
	Changes.addChange(Changes.ComponentConvertNumberChange.new(self, from, &"cost"))

func _draw() -> void:
	RenderingServer.canvas_item_clear(drawDropShadow)
	RenderingServer.canvas_item_clear(drawConnections)
	RenderingServer.canvas_item_clear(drawScaled)
	RenderingServer.canvas_item_clear(drawAuraBreaker)
	RenderingServer.canvas_item_clear(drawGlitch)
	RenderingServer.canvas_item_clear(drawMain)
	RenderingServer.canvas_item_clear(drawError)
	RenderingServer.canvas_item_clear(drawConfiguration)
	RenderingServer.canvas_item_clear(drawCrumbled)
	RenderingServer.canvas_item_clear(drawPainted)
	RenderingServer.canvas_item_clear(drawFrozen)
	if !active and Game.playState == Game.PLAY_STATE.PLAY: return
	RenderingServer.canvas_item_add_rect(drawDropShadow,Rect2(Vector2(3,3)-getOffset(),size),Game.DROP_SHADOW_COLOR)
	Lock.drawLock(drawScaled,drawAuraBreaker,drawGlitch,drawMain,drawConfiguration,
		size,getColor(Lock.COLOR_STEP.DRAW_BASE),getColor(Lock.COLOR_STEP.Glitch),type,configuration,sizeType,count,zeroI,isPartial,denominator,negated,armament,
		Lock.getFrameHighColor(isNegative(), negated).blend(Color(animColor,animAlpha)),
		Lock.getFrameMainColor(isNegative(), negated).blend(Color(animColor,animAlpha)),
		Lock.getFrameDarkColor(isNegative(), negated).blend(Color(animColor,animAlpha)),
		isNegative()
	)
	var from:Vector2 = size/2-getOffset()
	var index:int = 0
	for door in doors:
		if !door.active and Game.playState == Game.PLAY_STATE.PLAY: continue
		var to:Vector2 = door.position+door.size/2 - position
		if editor and self == editor.focusDialog.focused and index == editor.focusDialog.doorDialog.doorsHandler.selected:
			RenderingServer.canvas_item_add_line(drawConnections,from,to,Color("#00a2ff"),4+4/editor.cameraZoom)
		RenderingServer.canvas_item_add_line(drawConnections,from,to,Color.WHITE if satisfied or Game.playState == Game.PLAY_STATE.EDIT else Color.BLACK,4)
		RenderingServer.canvas_item_add_line(drawConnections,from,to,Game.mainTone[color] if satisfied or Game.playState == Game.PLAY_STATE.EDIT else Color.BLACK,2)
		index += 1
	if editor and self == editor.connectionSource:
		var to:Vector2 = editor.mouseWorldPosition - position
		RenderingServer.canvas_item_add_line(drawConnections,from,to,Color.WHITE if satisfied or Game.playState == Game.PLAY_STATE.EDIT else Color.BLACK,4)
		RenderingServer.canvas_item_add_line(drawConnections,from,to,Game.mainTone[color] if satisfied or Game.playState == Game.PLAY_STATE.EDIT else Color.BLACK,2)
	# auras
	Door.drawAuras(drawCrumbled,drawPainted,drawFrozen,
		frozen if Game.playState == Game.PLAY_STATE.EDIT else gameFrozen,
		crumbled if Game.playState == Game.PLAY_STATE.EDIT else gameCrumbled,
		painted if Game.playState == Game.PLAY_STATE.EDIT else gamePainted,
		Rect2(-getOffset(),size))
	if getColor(Lock.COLOR_STEP.BASE) == C.olors.ERROR:
		RenderingServer.canvas_item_add_texture_rect(drawError,Rect2(-Lock.offsetFromType(sizeType), size),Lock.ERROR_FX.current([randi_range(0,2)]))

func getDrawPosition() -> Vector2: return position - getOffset()

func propertyChangedInit(property:StringName) -> void:
	if property == &"size": _setSizeType()
	if property in [&"count", &"sizeType", &"type"]: _setAutoConfiguration()
	if property == &"armament" and armament:
		if frozen: Changes.addChange(Changes.PropertyChange.new(self,&"frozen",false))
		if crumbled: Changes.addChange(Changes.PropertyChange.new(self,&"crumbled",false))
		if painted: Changes.addChange(Changes.PropertyChange.new(self,&"painted",false))

	Lock.lockPropertyChangedInit(self, property)

func propertyChangedDo(property:StringName) -> void:
	super(property)
	if property == &"size":
		%shape.shape.size = size
		%shape.position = size/2 - getOffset()

func receiveMouseInput(event:InputEventMouse) -> bool:
	# resizing
	if !editor.edgeResizing or editor.componentDragged: return false
	var dragCornerSize:Vector2 = Vector2(8,8)/editor.cameraZoom
	var diffSign:Vector2 = Editor.rectSign(Rect2(position-getOffset()+dragCornerSize,size-dragCornerSize*2), editor.mouseWorldPosition)
	if !diffSign: return false
	elif !diffSign.x: editor.mouse_default_cursor_shape = Control.CURSOR_VSIZE
	elif !diffSign.y: editor.mouse_default_cursor_shape = Control.CURSOR_HSIZE
	elif (diffSign.x > 0) == (diffSign.y > 0): editor.mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
	else: editor.mouse_default_cursor_shape = Control.CURSOR_BDIAGSIZE
	if Editor.isLeftClick(event):
		editor.startSizeDrag(self, diffSign)
		return true
	return false

func _setAutoConfiguration() -> void: Changes.addChange(Changes.PropertyChange.new(self,&"configuration",Lock.getAutoConfiguration(self)))

func _setSizeType() -> void:
	var match:int = Lock.SIZES.find(size)
	var newSizeType:Lock.SIZE_TYPE = Lock.SIZE_TYPE.ANY if match == -1 else match as Lock.SIZE_TYPE
	Changes.addChange(Changes.PropertyChange.new(self,&"sizeType",newSizeType))
	queue_redraw()

func _connectTo(door:Door) -> void:
	Changes.addChange(Changes.ComponentArrayAppendChange.new(self,&"doors",door))
	Changes.addChange(Changes.ComponentArrayAppendChange.new(door,&"remoteLocks",self))

func _disconnectTo(door:Door) -> void:
	Changes.addChange(Changes.ComponentArrayPopAtChange.new(self,&"doors",doors.find(door)))
	Changes.addChange(Changes.ComponentArrayPopAtChange.new(door,&"remoteLocks",door.remoteLocks.find(self)))

func deletedInit() -> void:
	for door in doors:
		Changes.addChange(Changes.ComponentArrayPopAtChange.new(door,&"remoteLocks",door.remoteLocks.find(self)))

# ==== PLAY ==== #
var cursed:bool = false
var curseColor:C.olors
var glitchMimic:C.olors = C.olors.GLITCH
var errorMimic:C.olors = C.olors.ERROR
var curseMimic:C.olors = C.olors.GLITCH
var satisfied:bool = false
var cost:PackedInt64Array = M.ZERO
var gameFrozen:bool = false
var gameCrumbled:bool = false
var gamePainted:bool = false

var animColor:Color
var animAlpha:float = 0
var curseTimer:float = 0

func _process(delta:float) -> void:
	if editor and self == editor.connectionSource: queue_redraw()
	if cursed and active:
		curseTimer += delta
		if curseTimer >= 2:
			curseTimer -= 2
			makeCurseParticles(curseColor,1,0.2,0.3)
	if animAlpha > 0:
		animAlpha -= delta*3
		queue_redraw()
		if animAlpha <= 0: animAlpha = 0

func start() -> void:
	animAlpha = 0
	gameFrozen = frozen
	gameCrumbled = crumbled
	gamePainted = painted
	cost = getCost(Game.player, true)

func stop() -> void:
	cursed = false
	glitchMimic = C.olors.GLITCH
	curseMimic = C.olors.GLITCH
	errorMimic = C.olors.ERROR
	curseMimic = C.olors.ERROR
	satisfied = false
	cost = M.ZERO
	curseTimer = 0

func check(player:Player) -> void:
	if gameFrozen or gameCrumbled or gamePainted:
		var gateArmamentImmunities:Array[C.olors] = player.getArmamentImmunities()
		if getColor(Lock.COLOR_STEP.EFFECTIVE) == C.olors.PURE: return
		if int(gameFrozen) + int(gameCrumbled) + int(gamePainted) > 1: return
		if gameFrozen and (M.nex(player.key[C.olors.ICE]) or C.olors.ICE in gateArmamentImmunities): return
		if gameCrumbled and (M.nex(player.key[C.olors.MUD]) or C.olors.MUD in gateArmamentImmunities): return
		if gamePainted and (M.nex(player.key[C.olors.GRAFFITI]) or C.olors.GRAFFITI in gateArmamentImmunities): return
	var satisfiedBefore:bool = satisfied
	var costBefore:PackedInt64Array = cost
	GameChanges.addChange(GameChanges.PropertyChange.new(self,&"satisfied",canOpen(player)))
	GameChanges.addChange(GameChanges.PropertyChange.new(self,&"cost",getCost(player, true)))
	if getColor(Lock.COLOR_STEP.EFFECTIVE) == C.olors.NONE and !satisfied: Game.crash(); return
	if !(satisfiedBefore == satisfied and M.eq(costBefore, cost)):
		if satisfied: AudioManager.play(preload("res://resources/sounds/remoteLock/success.wav"))
		else: AudioManager.play(preload("res://resources/sounds/remoteLock/fail.wav"))
		for door in doors: if door.type == Door.TYPE.GATE: door.gateCheck(player)
		blinkAnim()
		GameChanges.bufferSave()

func blinkAnim() -> void:
	animAlpha = 1
	animColor = Color("#00ff66") if satisfied else Color("#ff0066")

func canOpen(player:Player, checkColor:C.olors=getColor(Lock.COLOR_STEP.FINAL)) -> bool: return Lock.getLockCanOpen(self, player, checkColor)

func getCost(player:Player, airEffect:bool) -> PackedInt64Array: return Lock.getLockCost(self,airEffect,player,M.ONE)

func getColor(step:Lock.COLOR_STEP) -> C.olors:
	var resultColor:C.olors = color

	if step < Lock.COLOR_STEP.Curse: return resultColor
	var curseAffected:bool = cursed and curseColor != C.olors.PURE and !armament
	if curseAffected: resultColor = curseColor
	
	# BASE
	# redundancy checks go here, like cant freeze if all ice

	if step < Lock.COLOR_STEP.Error: return resultColor
	var checkColor:C.olors = resultColor # error and glitch act independently
	if checkColor == C.olors.ERROR: resultColor = curseMimic if curseAffected else errorMimic

	# DRAW_BASE
	# the step used for drawing

	if step < Lock.COLOR_STEP.Glitch: return resultColor
	if checkColor == C.olors.GLITCH: resultColor = curseMimic if curseAffected else glitchMimic

	# EFFECTIVE
	# the step used for normal immunities

	if step < Lock.COLOR_STEP.AuraBreaker: return resultColor
	if gameFrozen: resultColor = C.olors.ICE
	if gameCrumbled: resultColor = C.olors.MUD
	if gamePainted: resultColor = C.olors.GRAFFITI

	# FINAL
	# the step used for check and cost
	return resultColor

func isNegative() -> bool:
	if type in [Lock.TYPE.BLAST, Lock.TYPE.ALL]:
		if M.isComplex(count) or M.isComplex(denominator): return false
		return M.negative(M.sign(effectiveDenominator()))
	return M.negative(M.sign(effectiveCount()))

func effectiveCount(_ipow:PackedInt64Array=M.ONE) -> PackedInt64Array: return count
func effectiveDenominator(_ipow:PackedInt64Array=M.ONE) -> PackedInt64Array: return denominator
func effectiveZeroI() -> bool: return zeroI

func checkDoors() -> void:
	var any:bool = false
	for door in doors:
		if door.active: any = true
	GameChanges.addChange(GameChanges.PropertyChange.new(self,&"active",any))
	queue_redraw()

func setMimic(mimicType:C.olors, setColor:C.olors) -> void:
	var property:StringName
	match mimicType:
		C.olors.GLITCH: property = &"glitchMimic"
		C.olors.ERROR: property = &"errorMimic"
	if curseUnaffected():
		if color == mimicType: GameChanges.addChange(GameChanges.PropertyChange.new(self, property, setColor))
	elif curseColor == mimicType: GameChanges.addChange(GameChanges.PropertyChange.new(self, &"curseMimic", setColor))
	queue_redraw()

func curseUnaffected() -> bool:
	return !cursed or curseColor == C.olors.PURE

func curseCheck(player:Player) -> void:
	if getColor(Lock.COLOR_STEP.EFFECTIVE) == C.olors.PURE or armament: return
	var willCurse:bool = player.curseMode > 0 and (!cursed or (curseColor != player.curseColor and curseColor != C.olors.PURE))
	var willCurseRedundant:bool = willCurse and color == player.curseColor
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
		if curseColor == C.olors.GLITCH:
			GameChanges.addChange(GameChanges.PropertyChange.new(self,&"curseMimic",C.olors.GLITCH))
		if curseColor == C.olors.ERROR:
			GameChanges.addChange(GameChanges.PropertyChange.new(self,&"curseMimic",C.olors.ERROR))
		if willCurseRedundant:
			makeCurseParticles(player.curseColor, 1, 0.2, 0.5)
			AudioManager.play(preload("res://resources/sounds/door/curse.wav"))
		else:
			makeCurseParticles(C.olors.BROWN, -1, 0.2, 0.5)
			AudioManager.play(preload("res://resources/sounds/door/decurse.wav"))
		GameChanges.bufferSave()

func makeCurseParticles(particleColor:C.olors, mode:int, scaleMin:float=1,scaleMax:float=1) -> void:
	for y in floor((size.y)/16):
		for x in floor((size.x)/16):
			%particlesParent.add_child(CurseParticle.Temporary.new(particleColor, mode, Vector2(x,y)*16-getOffset()+Vector2.ONE*randf_range(4,12), randf_range(scaleMin,scaleMax)))

func auraCheck(player:Player) -> void:
	var deAuraed:bool = false
	if player.auraRed and gameFrozen and getColor(Lock.COLOR_STEP.EFFECTIVE) != C.olors.MAROON:
		GameChanges.addChange(GameChanges.PropertyChange.new(self,&"gameFrozen",false))
		makeDebris(Door.Debris, C.olors.WHITE)
		deAuraed = true
	if player.auraGreen and gameCrumbled and getColor(Lock.COLOR_STEP.EFFECTIVE) != C.olors.FOREST:
		GameChanges.addChange(GameChanges.PropertyChange.new(self,&"gameCrumbled",false))
		makeDebris(Door.Debris, C.olors.BROWN)
		deAuraed = true
	if player.auraBlue and gamePainted and getColor(Lock.COLOR_STEP.EFFECTIVE) != C.olors.NAVY:
		GameChanges.addChange(GameChanges.PropertyChange.new(self,&"gamePainted",false))
		makeDebris(Door.Debris, C.olors.ORANGE)
		deAuraed = true
	if armament: return
	var auraed:bool = false
	if player.auraMaroon and !gameFrozen and getColor(Lock.COLOR_STEP.EFFECTIVE) != C.olors.RED:
		GameChanges.addChange(GameChanges.PropertyChange.new(self,&"gameFrozen",true))
		makeDebris(Door.Debris, C.olors.WHITE)
		auraed = true
	if player.auraForest and !gameCrumbled and getColor(Lock.COLOR_STEP.EFFECTIVE) != C.olors.GREEN:
		GameChanges.addChange(GameChanges.PropertyChange.new(self,&"gameCrumbled",true))
		makeDebris(Door.Debris, C.olors.BROWN)
		auraed = true
	if player.auraNavy and !gamePainted and getColor(Lock.COLOR_STEP.EFFECTIVE) != C.olors.BLUE:
		GameChanges.addChange(GameChanges.PropertyChange.new(self,&"gamePainted",true))
		makeDebris(Door.Debris, C.olors.ORANGE)
		auraed = true
	
	if deAuraed or auraed:
		AudioManager.play(preload("res://resources/sounds/door/deaura.wav"))
		GameChanges.bufferSave()

func makeDebris(debrisType:GDScript, debrisColor:C.olors) -> void:
	for y in floor(size.y/16):
		for x in floor(size.x/16):
			%particlesParent.add_child(debrisType.new(debrisColor,Vector2(x*16,y*16)))

func propertyGameChangedDo(property:StringName) -> void:
	if property == &"active":
		%interact.process_mode = PROCESS_MODE_INHERIT if active else PROCESS_MODE_DISABLED
