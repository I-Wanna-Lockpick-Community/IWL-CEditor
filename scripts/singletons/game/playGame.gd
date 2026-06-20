extends PanelContainer
class_name PlayGame

const SCREEN_RECT:Rect2 = Rect2(Vector2.ZERO,Vector2(800,608))
const DESCRIPTION_BOX:Texture2D = preload("res://assets/game/gameUI/description.png")

const WARP_ERROR:Texture2D = preload("res://assets/game/gameUI/warpError.png")

const TEXT_BREAK_FLAGS:int = TextServer.LineBreakFlag.BREAK_MANDATORY|TextServer.LineBreakFlag.BREAK_WORD_BOUND|TextServer.LineBreakFlag.BREAK_ADAPTIVE

@onready var world:World = %world
@onready var gameViewport:SubViewport = %gameViewport
@onready var playCamera:Camera2D = %playCamera

var configFile:ConfigFile = ConfigFile.new()

var paused:bool = false

var drawDescription:RID
var drawMain:RID
var drawAutoRunGradient:RID

enum ROOM_TRANSITION_TYPE {ENTER_LEVEL, WIN_LEVEL, WIN_OMEGA, CRASH}
var roomTransitionType:ROOM_TRANSITION_TYPE = ROOM_TRANSITION_TYPE.ENTER_LEVEL
var roomTransitionPhase:int = -2
var roomTransitionTimer:float = 0
var roomTransitionColor:Color = Color("#5a96c8")
var textWiggleAngle:float = 0
var textOffsetAngle:float = 0 # in degrees!!
var pauseAnimPhase:int = -1
var pauseAnimTimer:float = 0
var autoRunTimer:float = 2

var hideDescription:bool = false
var descriptionOffset:float = 0

func _ready() -> void:
	drawDescription = RenderingServer.canvas_item_create()
	drawMain = RenderingServer.canvas_item_create()
	drawAutoRunGradient = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_material(drawAutoRunGradient, Game.TEXT_GRADIENT_MATERIAL)
	RenderingServer.canvas_item_set_parent(drawDescription, %worldViewportCont.get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawMain, %drawParent.get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawAutoRunGradient, %drawParent.get_canvas_item())
	Game.camera = playCamera

func _process(delta:float) -> void:
	textWiggleAngle += 5.8643062867*delta # 5.6 degrees per frame, 60fps
	textWiggleAngle = fmod(textWiggleAngle,TAU)
	if roomTransitionPhase != -2:
		roomTransitionTimer += delta
		match roomTransitionPhase:
			-1:
				var nextPhase:float
				match roomTransitionType:
					ROOM_TRANSITION_TYPE.CRASH: nextPhase = 1.25
				if roomTransitionTimer >= nextPhase:
					roomTransitionTimer = 0
					roomTransitionPhase += 1
			0:
				var nextPhase:float
				match roomTransitionType:
					ROOM_TRANSITION_TYPE.ENTER_LEVEL: nextPhase = 0.5833333333
					ROOM_TRANSITION_TYPE.WIN_LEVEL, ROOM_TRANSITION_TYPE.WIN_OMEGA,\
					ROOM_TRANSITION_TYPE.CRASH: nextPhase = 1; textOffsetAngle = min(textOffsetAngle + 67.5*delta, 90)
				roomTransitionColor.a = roomTransitionTimer/nextPhase
				queue_redraw()
				if roomTransitionTimer >= nextPhase:
					roomTransitionTimer = 0
					roomTransitionPhase += 1
			1:
				var nextPhase:float
				match roomTransitionType:
					ROOM_TRANSITION_TYPE.ENTER_LEVEL: nextPhase = 2.5; textOffsetAngle = min(textOffsetAngle + 135*delta,90)
					ROOM_TRANSITION_TYPE.WIN_LEVEL, ROOM_TRANSITION_TYPE.WIN_OMEGA,\
					ROOM_TRANSITION_TYPE.CRASH: nextPhase = 1.6666666667; textOffsetAngle = min(textOffsetAngle + 67.5*delta, 90)
				roomTransitionColor.a = 1
				queue_redraw()
				if roomTransitionTimer >= nextPhase:
					roomTransitionTimer = 0
					roomTransitionPhase += 1
			2:
				if roomTransitionType == ROOM_TRANSITION_TYPE.ENTER_LEVEL:
					roomTransitionColor.a = 1 - roomTransitionTimer/0.5833333333
					textOffsetAngle = 90+roomTransitionTimer*154.2857142857
					if roomTransitionTimer >= 0.4166666667:
						roomTransitionPhase = -2
				else:
					%winMenu.visible = true
					if Input.is_action_just_pressed(&"gameRestart"):
						restart()
				queue_redraw()
	if pauseAnimPhase != -1:
		pauseAnimTimer += delta
		%gameViewportCont.get_material().set_shader_parameter(&"pauseAnimTimer", pauseAnimTimer)
		queue_redraw()
		match pauseAnimPhase:
			0:
				if pauseAnimTimer >= 0.4166666667:
					pauseAnimPhase += 1
					paused = !paused
					%pauseMenu.visible = paused
					%gameViewportCont.get_material().set_shader_parameter(&"darken", !paused)
			1:
				if pauseAnimTimer >= 0.75:
					pauseAnimPhase = -1
					%mouseBlocker.mouse_filter = MOUSE_FILTER_IGNORE
					%gameViewportCont.get_material().set_shader_parameter(&"pauseAnimTimer", 0)
					%gameViewportCont.get_material().set_shader_parameter(&"darken", false)
	if autoRunTimer < 2:
		autoRunTimer += delta
		queue_redraw()
		if autoRunTimer >= 2: autoRunTimer = 2
	if Game.player.cameraAnimVal > 0: queue_redraw()
	if hideDescription and descriptionOffset < 132:
		descriptionOffset += 480*delta
		if descriptionOffset >= 132: descriptionOffset = 132
		queue_redraw()
	elif !hideDescription and descriptionOffset > 0:
		descriptionOffset -= 480*delta
		if descriptionOffset < 0: descriptionOffset = 0
		queue_redraw()
	if !paused: Game.playTime += delta
	var objectsHovered:Array[GameObject] = []
	var mouseWorldPosition = %world.get_local_mouse_position()
	for object in Game.objects.values():
		if object.active and Rect2(object.getDrawPosition(),object.size).has_point(mouseWorldPosition): objectsHovered.append(object)
	%mouseover.describe(objectsHovered, %gameViewportCont.get_local_mouse_position()*Vector2(800,608)/%gameViewportCont.size,Vector2(800,608))

func _draw() -> void:
	RenderingServer.canvas_item_clear(drawDescription)
	RenderingServer.canvas_item_clear(drawMain)
	RenderingServer.canvas_item_clear(drawAutoRunGradient)
	RenderingServer.canvas_item_set_transform(drawDescription, Transform2D(0, Vector2(0,descriptionOffset)))
	# description box
	if Game.level.description:
		drawLevelDescription(drawDescription)
	# room transition
	if roomTransitionPhase > -1:
		var textOffset = Vector2(0,500*sin(deg_to_rad(textOffsetAngle))-500)
		var textWiggle:Vector2 = Vector2(sin(textWiggleAngle),cos(textWiggleAngle))*3
		var textWiggle2:Vector2 = Vector2(sin(textWiggleAngle+0.8726646260),cos(textWiggleAngle+0.8726646260))*6
		RenderingServer.canvas_item_add_rect(drawMain,SCREEN_RECT,roomTransitionColor)
		match roomTransitionType:
			ROOM_TRANSITION_TYPE.ENTER_LEVEL:
				TextDraw.outlinedCentered2(Game.FLEVELID,drawMain,Game.level.number,Color.WHITE,Color.BLACK,24,Vector2(400,216)+textWiggle+textOffset)
				TextDraw.outlinedCentered2(Game.FLEVELNAME,drawMain,Game.level.name,Color.WHITE,Color.BLACK,36,Vector2(400,280)+textWiggle2+textOffset)
				TextDraw.outlinedCentered2(Game.FLEVELNAME,drawMain,Game.level.author,Color.BLACK,Color.WHITE,36,Vector2(400,376)+textWiggle+textOffset)
			ROOM_TRANSITION_TYPE.WIN_LEVEL: TextDraw.outlinedCentered2(Game.FLEVELNAME,drawMain,"Congratulations!",Color.WHITE,Color.BLACK,36,Vector2(400,280)+textWiggle2+textOffset)
			ROOM_TRANSITION_TYPE.WIN_OMEGA: TextDraw.outlinedCentered2(Game.FLEVELNAME,drawMain,"YOWZA!",Color.WHITE,Color.BLACK,36,Vector2(400,280)+textWiggle2+textOffset)
			ROOM_TRANSITION_TYPE.CRASH:
				TextDraw.outlinedCentered2(Game.FLEVELNAME,drawMain,"NONE ERROR: None colored lock check failed!",Color.WHITE,Color.RED,36,Vector2(400,216)+textWiggle2+textOffset)
				RenderingServer.canvas_item_add_texture_rect(drawMain,Rect2(Vector2(368,368)+textOffset,Vector2(64,64)),WARP_ERROR)
	var autoRunAlpha:float = abs(sin(autoRunTimer*PI))
	if autoRunAlpha > 0:
		TextDraw.outlinedGradient(Game.FMINIID,drawMain,drawAutoRunGradient,
			"[%s] Auto-Run is " % Explainer.hotkeyMap(&"gameAutoRun") + ("on" if Game.autoRun else "off"),
			Color(Color("#e6ffe6") if Game.autoRun else Color("#dcffe6"),autoRunAlpha),
			Color(Color("#e6c896") if Game.autoRun else Color("#64dc8c"),autoRunAlpha),
			Color(Color.BLACK,autoRunAlpha),12,Vector2(4,20)
		)
	if Game.player.cameraAnimVal > 0:
		var topLeft:Vector2 = - Vector2(8,8) + Vector2(16,16)*Game.player.cameraAnimVal
		var bottomRight:Vector2 = Vector2(808,616) - Vector2(16,16)*Game.player.cameraAnimVal
		RenderingServer.canvas_item_add_polyline(drawMain, [
			topLeft, Vector2(bottomRight.x, topLeft.y), bottomRight, Vector2(topLeft.x, bottomRight.y), topLeft, topLeft+Vector2(1,0)
		], [Color.BLACK,Color.BLACK,Color.BLACK,Color.BLACK,Color.BLACK])
		topLeft -= Vector2(4,4)
		bottomRight += Vector2(4,4)
		RenderingServer.canvas_item_add_polyline(drawMain, [
			topLeft, Vector2(bottomRight.x, topLeft.y), bottomRight, Vector2(topLeft.x, bottomRight.y), topLeft, topLeft+Vector2(1,0)
		], [Color.BLACK,Color.BLACK,Color.BLACK,Color.BLACK,Color.BLACK])
		TextDraw.outlined(Game.FPRESENTS, drawMain, "[%s] to zoom" % Explainer.hotkeyMap(&"gameAction"),Color(Color.WHITE,Game.player.cameraAnimVal),Color(Color.BLACK,Game.player.cameraAnimVal),14,Vector2(11,592))
		TextDraw.outlined(Game.FPRESENTS, drawMain, "[%s] to exit" % Explainer.hotkeyMap(&"gameCamera"),Color(Color.WHITE,Game.player.cameraAnimVal),Color(Color.BLACK,Game.player.cameraAnimVal),14,Vector2(692,592))

static func drawLevelDescription(drawer:RID, pos:Vector2=Vector2.ZERO) -> void:
	if Game.levelBounds.size != Vector2i(800,608): return
	RenderingServer.canvas_item_add_texture_rect(drawer,Rect2(pos+Vector2(11,519),Vector2(784,80)),DESCRIPTION_BOX,false,Color(Color.BLACK,0.35))
	RenderingServer.canvas_item_add_texture_rect(drawer,Rect2(pos+Vector2(8,516),Vector2(784,80)),DESCRIPTION_BOX)
	Game.FTALK.draw_multiline_string(drawer,pos+Vector2(16,540),Game.level.description,HORIZONTAL_ALIGNMENT_LEFT,666,12,4,Color("#200020"),TEXT_BREAK_FLAGS)
	TextDraw.outlinedCentered(Game.FROOMNUM,drawer,"PUZZLE",Color("#d6cfc9"),Color("#3e2d1c"),20,pos+Vector2(732,539))
	TextDraw.outlinedCentered(Game.FROOMNUM,drawer,Game.level.shortNumber,Color("#8c50c8"),Color("#140064"),20,pos+Vector2(733,569))

func _input(event:InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		if !event.is_echo():
			if event.keycode == KEY_F5: queue_redraw()
			var skipTransitionThreshold:float
			match roomTransitionType:
				ROOM_TRANSITION_TYPE.ENTER_LEVEL: skipTransitionThreshold = 0.6666666667
				ROOM_TRANSITION_TYPE.WIN_LEVEL: skipTransitionThreshold = 0.3333333333
			if roomTransitionType == ROOM_TRANSITION_TYPE.CRASH and abs(roomTransitionPhase) < 2:
				roomTransitionPhase = 2
				roomTransitionTimer = 0
				roomTransitionColor.a = 1
				textOffsetAngle = 90
			elif roomTransitionPhase == 1 and roomTransitionTimer >= skipTransitionThreshold:
				if event.keycode == KEY_SPACE:
					roomTransitionPhase += 1
					roomTransitionTimer = 0
			if !inAnimation():
				if event.keycode == KEY_ESCAPE: pause()
		if !paused and !inAnimation():
			if !Game.player.cameraMode and event.is_action_pressed(&"gameAutoRun"): autoRun()
			Game.player.receiveKey(event)

func startLevel() -> void:
	start()
	roomTransitionType = ROOM_TRANSITION_TYPE.ENTER_LEVEL
	roomTransitionPhase = 1
	roomTransitionTimer = 0
	textOffsetAngle = 0

func start() -> void:
	Game.player = preload("res://scenes/player.tscn").instantiate()
	world.add_child(Game.player)
	assert(Game.levelStart)
	Game.player.position = Game.levelStart.position + Vector2(16, 23)
	Game.goldIndexFloat = 0
	GameChanges.start()
	for object in Game.objects.values():
		object.start()
		object.queue_redraw()
	for component in Game.components.values():
		component.start()
		component.queue_redraw()
	Game.camera.position = Game.player.position
	Game.camera.reset_smoothing()

func restart() -> void:
	Game.won = false
	Game.crashState = Game.CRASH_STATE.NONE
	%winMenu.visible = false
	roomTransitionPhase = -2
	queue_redraw()
	Game.player.pauseFrame = true
	Game.player.queue_free()
	for object in Game.objects.values():
		object.stop()
		object.queue_redraw()
	for component in Game.components.values():
		component.stop()
		component.queue_redraw()
	for particle in Game.particlesParent.get_children(): particle.queue_free()
	await get_tree().process_frame
	start()

func inAnimation() -> bool:
	if roomTransitionPhase == 0 or roomTransitionPhase == 1: return true
	if roomTransitionPhase == 2 and roomTransitionTimer < 0.1: return true
	if pauseAnimPhase != -1: return true
	return false

func pause() -> void:
	if inAnimation(): return
	pauseAnimPhase = 0
	pauseAnimTimer = 0
	%gameViewportCont.get_material().set_shader_parameter(&"darken", !paused)
	%mouseBlocker.mouse_filter = MOUSE_FILTER_STOP
	AudioManager.play(preload("res://resources/sounds/pause.wav"), 0.85, 0.6)
	if paused: saveSettings()
	else: loadSettings()

func quit() -> void:
	saveSettings()
	get_tree().quit()

func editLevel() -> void:
	saveSettings()
	await get_tree().process_frame
	Game.edit()

func loadSettings() -> void:
	configFile.load("user://config.ini")
	%gameSettings.playGame = self
	%gameSettings.opened(configFile)

func saveSettings() -> void:
	%gameSettings.closed(configFile)
	configFile.save("user://config.ini")

func autoRun() -> void:
	Game.autoRun = !Game.autoRun
	AudioManager.play(preload("res://resources/sounds/autoRun.wav"),1 , 1.0 if Game.autoRun else 0.7)
	autoRunTimer = 0
	saveSettings()

func win(goal:Goal) -> void:
	if goal.type == Goal.TYPE.OMEGA: roomTransitionType = ROOM_TRANSITION_TYPE.WIN_OMEGA
	else: roomTransitionType = ROOM_TRANSITION_TYPE.WIN_LEVEL
	roomTransitionPhase = 0
	roomTransitionTimer = 0
	textOffsetAngle = 0

func crash() -> void:
	roomTransitionType = ROOM_TRANSITION_TYPE.CRASH
	roomTransitionPhase = -1
	roomTransitionTimer = 0
	textOffsetAngle = 0

func toggleDescription() -> void:
	hideDescription = !hideDescription
	AudioManager.play(preload("res://resources/sounds/sndDrop.wav"))
