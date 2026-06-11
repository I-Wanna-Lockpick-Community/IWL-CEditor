extends Node

static var COMPONENTS:Array[GDScript] = [Lock, KeyCounterElement, KeyBulk, Door, Goal, KeyCounter, PlayerSpawn, FloatingTile, RemoteLock, PlaceholderObject, PlayerPlaceholderObject]
static var NON_OBJECT_COMPONENTS:Array[GDScript] = [Lock, KeyCounterElement]
# for outline draw; if not in this then provide an outlineTex() function
static var RECTANGLE_COMPONENTS:Array[GDScript] = [Door, Lock, KeyCounter, RemoteLock, PlaceholderObject, FloatingTile]
static var RESIZABLE_COMPONENTS:Array[GDScript] = [Door, Lock, KeyCounter, RemoteLock, PlaceholderObject, FloatingTile]

enum COLOR_STEP {Initial, CURSE, ERROR, DrawBase, GLITCH, AURA_BREAKER, Calculate}

const DROP_SHADOW_COLOR:Color = Color(Color.BLACK, 0.35)

static var COLOR_TEXTURES:ColorsTextureLoader = ColorsTextureLoader.new("res://assets/game/colorTexture/$c.png")

const EMPTY:Texture2D = preload("res://assets/empty.png")
const FILLED:Texture2D = preload("res://assets/filled.png")

var highTone:Array[Color] = DEFAULT_HIGH.duplicate()
const DEFAULT_HIGH:Array[Color] = [
	Color("#e7bf98"),
	Color("#edeae7"), Color("#e7bf98"), Color("#bfa4db"),
	Color("#c83737"), Color("#70cf88"), Color("#8795b8"),
	Color("#e4afca"), Color("#8acaca"), Color("#554b40"),
	Color("#aa6015"),
	Color("#edeae7"),
	Color("#78be00"),
	Color("#96a0a5"),
	Color("#d18866"), Color("#ffffff"),
	Color("#6d4040"), Color("#3f5c3f"), Color("#49496b"),
	Color("#d1ffff"), Color("#b57ea7"), Color("#f2e380"),
	Color("#00000000"),
	Color("#fff"),
	Color("#240a44")
]
const BRIGHT_HIGH:Array[Color] = [
	Color("#e7bf98"),
	Color("#edeae7"), Color("#e7bf98"), Color("#bfa4db"),
	Color("#eb3737"), Color("#70cf88"), Color("#8795b8"),
	Color("#e4afca"), Color("#8acaf8"), Color("#554b40"),
	Color("#aa6015"),
	Color("#edeae7"),
	Color("#78be00"),
	Color("#96a0a5"),
	Color("#d18866"), Color("#ffffff"),
	Color("#6d4040"), Color("#3f5c3f"), Color("#49496b"),
	Color("#d1ffff"), Color("#b57ea7"), Color("#f2e380"),
	Color("#00000000"),
	Color("#fff"),
	Color("#340e62")
]

var mainTone:Array[Color] = DEFAULT_MAIN.duplicate()
const DEFAULT_MAIN:Array[Color] = [
	Color("#d68f49"),
	Color("#d6cfc9"), Color("#d68f49"), Color("#8f5fc0"),
	Color("#8f1b1b"), Color("#359f50"), Color("#5f71a0"),
	Color("#cf709f"), Color("#50afaf"), Color("#363029"),
	Color("#704010"),
	Color("#d6cfc9"),
	Color("#b49600"),
	Color("#647378"),
	Color("#d34728"), Color("#b8b8b8"),
	Color("#583232"), Color("#2c3b2c"), Color("#333352"),
	Color("#82f0ff"), Color("#966489"), Color("#e2c961"),
	Color("#00000000"),
	Color("#006dff"),
	Color("#19072f")
	
]
const BRIGHT_MAIN:Array[Color] = [
	Color("#d68f49"),
	Color("#d6cfc9"), Color("#d68f49"), Color("#8f5fc0"),
	Color("#a11b1b"), Color("#359f50"), Color("#5f71a0"),
	Color("#cf709f"), Color("#50afd1"), Color("#363029"),
	Color("#704010"),
	Color("#d6cfc9"),
	Color("#b49600"),
	Color("#647378"),
	Color("#d34728"), Color("#b8b8b8"),
	Color("#583232"), Color("#2c3b2c"), Color("#333352"),
	Color("#82f0ff"), Color("#966489"), Color("#e2c961"),
	Color("#00000000"),
	Color("#006dff"),
	Color("#240a44")
]

var darkTone:Array[Color] = DEFAULT_DARK.duplicate()
const DEFAULT_DARK:Array[Color] = [
	Color("#9c6023"),
	Color("#bbaea4"), Color("#9c6023"), Color("#603689"),
	Color("#480d0d"), Color("#1b5028"), Color("#3a4665"),
	Color("#af3a75"), Color("#357575"), Color("#181512"),
	Color("#382007"),
	Color("#bbaea4"),
	Color("#dc6e00"),
	Color("#3c4b50"),
	Color("#7a3117"), Color("#818181"),
	Color("#3b1f1f"), Color("#1d2b1d"), Color("#262633"),
	Color("#62b6c1"), Color("#7f4972"), Color("#c6af51"),
	Color("#00000000"),
	Color("#006dff"),
	Color("#110521")

]
const BRIGHT_DARK:Array[Color] = [
	Color("#9c6023"),
	Color("#bbaea4"), Color("#9c6023"), Color("#603689"),
	Color("#6b0d0d"), Color("#1b5028"), Color("#3a4665"),
	Color("#af3a75"), Color("#357592"), Color("#181512"),
	Color("#382007"),
	Color("#bbaea4"),
	Color("#dc6e00"),
	Color("#3c4b50"),
	Color("#7a3117"), Color("#818181"),
	Color("#3b1f1f"), Color("#1d2b1d"), Color("#262633"),
	Color("#62b6c1"), Color("#7f4972"), Color("#c6af51"),
	Color("#00000000"),
	Color("#006dff"),
	Color("#19072f")
]

@onready var editor:Editor = get_node("/root/editor")
var playGame:PlayGame
var world:World
var tiles:TileMapLayer
var tilesDropShadow:TileMapLayer
var objectsParent:Node2D
var particlesParent:Node2D

var level:Level = Level.new()
var anyChanges:bool = false:
	set(value):
		anyChanges = value
		updateWindowName()

var objectIdIter:int = 0 # for creating objects
var componentIdIter:int = 0 # for creating components
var goldIndex:int = 0 # youve seen this before
var goldIndexFloat:float = 0
signal goldIndexChanged

var objects:Dictionary[int,GameObject] = {}
var components:Dictionary[int,GameComponent] = {}

var levelBounds:Rect2i = Rect2i(0,0,800,608):
	set(value):
		levelBounds = value
		RenderingServer.global_shader_parameter_set(&"LEVEL_POS", levelBounds.position)
		RenderingServer.global_shader_parameter_set(&"LEVEL_SIZE", levelBounds.size)
		if camera:
			camera.limit_left = levelBounds.position.x
			camera.limit_top = levelBounds.position.y
			camera.limit_right = levelBounds.end.x
			camera.limit_bottom = levelBounds.end.y
		if editor:
			editor.levelBoundsObject.position = levelBounds.position
			editor.levelBoundsObject.size = levelBounds.size
			if editor.settingsOpen: editor.settingsMenu.updateLevelSettingsPosition()

const NO_MATERIAL:CanvasItemMaterial = preload("res://resources/materials/noMaterial.tres")
const GLITCH_MATERIAL:ShaderMaterial = preload("res://resources/materials/glitchDrawMaterial.tres")
const ADDITIVE_MATERIAL:CanvasItemMaterial = preload("res://resources/materials/additiveMaterial.tres")
const ADDITIVE_FLAT_COLOR_MATERIAL:ShaderMaterial = preload("res://resources/materials/additiveFlatColorMaterial.tres")
const SUBTRACTIVE_MATERIAL:CanvasItemMaterial = preload("res://resources/materials/subtractiveMaterial.tres")
const NEGATIVE_MATERIAL:ShaderMaterial = preload("res://resources/materials/negativeMaterial.tres")
const TEXT_GRADIENT_MATERIAL:ShaderMaterial = preload("res://resources/materials/textGradientMaterial.tres")

const ROBOTO_MONO:Font = preload("res://resources/fonts/RobotoMono-SemiBold.ttf")
const FKEYX:Font = preload("res://resources/fonts/fKeyX.fnt")
const FKEYNUM:Font = preload("res://resources/fonts/fKeyNum.fnt")
const FTALK:Font = preload("res://resources/fonts/fTalk.fnt")
const FLEVELID:Font = preload("res://resources/fonts/fLevelID.fnt")
const FLEVELNAME:Font = preload("res://resources/fonts/fLevelName.fnt")
const FROOMNUM:Font = preload("res://resources/fonts/fRoomNum.fnt")
const FMINIID:Font = preload("res://resources/fonts/fMiniId.fnt")
const FPRESENTS:Font = preload("res://resources/fonts/fPresents.fnt")

var latestSpawn:PlayerSpawn
var levelStart:PlayerSpawn
var player:Player
enum PLAY_STATE {EDIT, PLAY, PAUSED}
var playState:PLAY_STATE = PLAY_STATE.EDIT:
	set(value):
		playState = value
		if editor:
			editor.topBar._updateButtons()
			editor.editorCamera.enabled = playState != PLAY_STATE.PLAY
			editor.playtestCamera.enabled = playState == PLAY_STATE.PLAY
		fastAnimSpeed = 0
		fastAnimTimer = 0
		complexViewHue = 0

var camera:Camera2D

var fastAnimSpeed:float = 0 # 0: slowest, 1: fastest
var fastAnimTimer:float = 0 # speed resets when this counts down to 0
var bufferedGateCheck:bool = false
var complexViewHue:float = 0

var editorWindowSize:Vector2
var editorWindowMode:Window.Mode
var logUiScale:float = 0
var uiScale:float = 1:
	set(value):
		uiScale = value
		if editor:
			get_window().content_scale_factor = uiScale
			editor._gameViewportDisplayResized()

var simpleLocks:bool = false:
	set(value):
		simpleLocks = value
		for component in components.values():
			if component is Lock: component.queue_redraw()
var hideTimer:bool = false:
	set(value):
		hideTimer = value
		updateWindowName()
var playTime:float
var autoRun:bool = true
var fullJumps:bool = false
var fastAnimations:bool = false

var won:bool = false
enum CRASH_STATE {NONE, NONE_COLOR}
var crashState = CRASH_STATE.NONE # focal point, none color

var windowName:String

func setWorld(_world:World) -> void:
	world = _world
	tiles = world.tiles
	tilesDropShadow = world.tilesDropShadow
	objectsParent = world.objectsParent
	particlesParent = world.particlesParent
	level.activate()
	updateWindowName()

func _process(delta:float) -> void:
	goldIndexFloat += delta*6 # 0.1 per frame, 60fps
	if goldIndexFloat > 12: goldIndexFloat -= 12
	if goldIndex != int(goldIndexFloat):
		goldIndex = int(goldIndexFloat)
		goldIndexChanged.emit()
	# fast anims
	if fastAnimTimer > 0:
		fastAnimTimer -= delta
		# counted down; reset
		if fastAnimTimer <= 0 or !fastAnimations:
			fastAnimTimer = 0
			fastAnimSpeed = 0
	complexViewHue += delta*0.1764705882 # 0.75/255 per frame, 60fps
	if complexViewHue >= 1: complexViewHue -= 1
	if playGame and !hideTimer: updateWindowName()

func bufferGateCheck() -> void: bufferedGateCheck = true

func updateWindowName() -> void:
	var newWindowName:String
	if editor:
		if anyChanges: newWindowName = level.name + "*" + " - IWLCEditor"
		else: newWindowName = level.name + " - IWLCEditor"
	else:
		if hideTimer: newWindowName = "IWLCEditor"
		else: newWindowName = "IWLCEditor - Time: " + formatTime(playTime)
	if newWindowName != windowName:
		windowName = newWindowName
		get_window().title = newWindowName

func fasterAnims() -> void:
	if !fastAnimations: return
	fastAnimTimer = 1.6666666667 # 100 frames, 60fps
	fastAnimSpeed = min(fastAnimSpeed+0.05, 1)

func playTest(spawn:PlayerSpawn) -> void:
	var starting:bool = false
	
	editor.multiselect.deselect()
	editor.focusDialog.defocusComponent()
	editor.focusDialog.defocus()
	editor.componentDragged = null
	Changes.bufferSave()
	
	if playState == PLAY_STATE.EDIT:
		camera.zoom = Vector2.ONE*uiScale
		starting = true
		player = preload("res://scenes/player.tscn").instantiate()
		world.add_child(player)
		player.position = spawn.position + Vector2(17, 23)
		if spawn != levelStart:
			GameChanges.assignAndFollowStack(spawn.undoStack)
			GameChanges.saveBuffered = spawn.saveBuffered
			player.key.assign(spawn.key.map(func(number): return number.duplicate()))
			player.star.assign(spawn.star)
			player.curse.assign(spawn.curse)
			player.glisten.assign(spawn.glisten.map(func(number): return number.duplicate()))
		else: GameChanges.start()
	playState = PLAY_STATE.PLAY
	latestSpawn = spawn

	goldIndexFloat = 0

	for object in objects.values():
		if starting: object.start()
		object.queue_redraw()
	for component in components.values():
		if starting: component.start()
		component.queue_redraw()
	await get_tree().process_frame
	editor.playtestCamera.reset_smoothing()

func pauseTest() -> void:
	playState = PLAY_STATE.PAUSED
	for object in objects.values(): object.queue_redraw()
	for component in components.values(): component.queue_redraw()
	if !objects.get(-1):
		objects[-1] = editor.playerObject
		objectsParent.add_child(editor.playerObject)
	editor.playerObject.position = player.position - Vector2(6, 12)

func stopTest() -> void:
	playState = PLAY_STATE.EDIT
	GameChanges.saveBuffered = false
	GameChanges.previousSaveBuffered = false
	player.pauseFrame = true
	won = false
	crashState = CRASH_STATE.NONE
	await get_tree().process_frame
	player.queue_free()
	for object in objects.values():
		object.stop()
		object.queue_redraw()
	for component in components.values():
		component.stop()
		component.queue_redraw()
	if objects.get(-1):
		editor.playerObject.deleted(true)

func savestate() -> void:
	var state:PlayerSpawn = Changes.addChange(Changes.CreateComponentChange.new(PlayerSpawn, {&"position":player.position.round()-Vector2(17, 23),&"forceState":true})).result
	Changes.addChange(Changes.PropertyChange.new(state,&"key",player.key.map(func(count): return count.duplicate())))
	Changes.addChange(Changes.PropertyChange.new(state,&"star",player.star))
	Changes.addChange(Changes.PropertyChange.new(state,&"curse",player.curse))
	Changes.addChange(Changes.PropertyChange.new(state,&"glisten",player.glisten.map(func(count): return count.duplicate())))
	Changes.addChange(Changes.PropertyChange.new(state,&"undoStack",GameChanges.undoStack.duplicate()))
	Changes.addChange(Changes.PropertyChange.new(state,&"saveBuffered",GameChanges.saveBuffered))

func restart() -> void:
	if editor:
		stopTest()
		await get_tree().process_frame # to be safe
		if editor: playTest(latestSpawn)
	else: playGame.restart()

func setMimic(mimicType:C.olors, setColor:C.olors) -> void:
	if setColor == C.olors.NONE: return
	for object in objects.values():
		if object.get_script() in [KeyBulk, Door, RemoteLock]:
			object.setMimic(mimicType, setColor)

func play() -> void:
	if !levelStart: return Saving.errorPopup("No level start found,\nCannot play level.", "Play Error")
	Saving.confirmAction = Saving.ACTION.SAVE_FOR_PLAY
	Saving.save()
	playTime = 0

func playSaved(fromOpenWindow:OpenWindow=null) -> void:
	get_window().content_scale_factor = 1
	editorWindowMode = get_window().mode
	editorWindowSize = get_window().size
	if fromOpenWindow: editor.remove_child(fromOpenWindow) # otherwise it gets killed by the scene change
	get_tree().change_scene_to_file("res://scenes/playGame.tscn")
	get_window().mode = Window.MODE_WINDOWED
	if !OS.has_feature("web"): get_window().size = Vector2(800,608) * uiScale
	objects.clear()
	components.clear()
	await get_tree().scene_changed
	setWorld(playGame.world)
	if fromOpenWindow: fromOpenWindow.resolve()
	else: Saving.loadFile(Saving.savePath, true)
	playState = PLAY_STATE.PLAY
	playGame.loadSettings()
	playGame.startLevel()

func edit() -> void:
	get_window().content_scale_factor = uiScale
	won = false
	crashState = CRASH_STATE.NONE
	playState = PLAY_STATE.EDIT
	get_tree().change_scene_to_file("res://scenes/editor.tscn")
	get_window().mode = editorWindowMode
	if !OS.has_feature("web"): get_window().size = editorWindowSize
	objects.clear()
	components.clear()
	await get_tree().scene_changed
	editor = get_node("/root/editor")
	Saving.loadFile(Saving.savePath, true)
	await get_tree().process_frame
	editor.home()

func formatTime(seconds:float) -> String:
	var hours:int = int(seconds/3600)
	seconds -= hours*3600
	var minutes:int = int(seconds/60)
	seconds -= minutes*60
	var string:String = ""
	if hours: string += str(hours) + "h "
	if minutes: string += str(minutes) + "m "
	if seconds: string += str(int(seconds)) + "s "
	return string.trim_suffix(" ")

func win(goal:Goal) -> void:
	won = true
	goal.win()
	if goal.type == Goal.TYPE.OMEGA:
		AudioManager.play(preload("res://resources/sounds/goal/deltaruneShine.wav"), 1.2, 0.8)
		AudioManager.play(preload("res://resources/sounds/goal/winOmega.wav"))
	else: AudioManager.play(preload("res://resources/sounds/goal/win.wav"), 0.9, 1.4)
	if editor:
		await timer(0.5)
		stopTest()
		editor.cameraZoom = camera.zoom.x
		editor.editorCamera.zoom = camera.zoom
		editor.targetCameraZoom = camera.zoom.x
		editor.editorCamera.position = (camera.get_screen_center_position() - editor.gameCont.size/2)
	else:
		playGame.win(goal)

func timer(time:float) -> Signal:
	var t = Timer.new()
	t.one_shot = true
	get_tree().get_root().add_child(t)
	t.timeout.connect(t.queue_free)
	t.start(time)
	return t.timeout

func crash() -> void:
	crashState = CRASH_STATE.NONE_COLOR
	for i in 40: particlesParent.add_child(KeyParticle.new(player.position+Vector2(randf_range(-8,8),randf_range(-8,8)), i, Color.from_hsv(i/40.0,0.7058823529,1), 1))
	for i in 30: particlesParent.add_child(KeyParticle.new(player.position+Vector2(randf_range(-8,8),randf_range(-8,8)), i, Color.from_hsv(i/30.0,0.7058823529,1), 0.6))
	AudioManager.play(preload("res://resources/sounds/sndAwaken.wav"))
	AudioManager.play(preload("res://resources/sounds/sndPop.wav"))
	player.crashAnim()
	if editor:
		await timer(0.6666666667)
		stopTest()
		editor.cameraZoom = 1
		editor.editorCamera.zoom = Vector2.ONE
		editor.home()
	else:
		playGame.crash()
