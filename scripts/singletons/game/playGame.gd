extends PanelContainer
class_name PlayGame

const SCREEN_RECT:Rect2 = Rect2(Vector2.ZERO,Vector2(800,608))
const DESCRIPTION_BOX:Texture2D = preload("res://assets/game/gameUI/description.png")

const WARP_ERROR:Texture2D = preload("res://assets/game/gameUI/warpError.png")

const TEXT_BREAK_FLAGS:int = TextServer.LineBreakFlag.BREAK_MANDATORY|TextServer.LineBreakFlag.BREAK_WORD_BOUND|TextServer.LineBreakFlag.BREAK_ADAPTIVE

@onready var world:World = %world
@onready var gameViewport:SubViewport = %gameViewport
@onready var worldViewportCont:SubViewportContainer = %worldViewportCont
@onready var playCamera:Camera2D = %playCamera
@onready var pda:PDA = %PDA
@onready var playGameDialog:PlayGameDialog = %playGameDialog

var configFile:ConfigFile = ConfigFile.new()

var paused:bool = false

var drawDescription:RID
var drawMain:RID

enum ROOM_TRANSITION_TYPE {ENTER_LEVEL, WIN_LEVEL, WIN_OMEGA, CRASH}
var roomTransitionType:ROOM_TRANSITION_TYPE = ROOM_TRANSITION_TYPE.ENTER_LEVEL
var roomTransitionPhase:int = -2
var roomTransitionTimer:float = 0
var roomTransitionColor:Color = Color("#5a96c8")
var textWiggleAngle:float = 0
var textOffsetAngle:float = 0 # in degrees!!
var pauseAnimPhase:int = -1
var pauseAnimTimer:float = 0

var hideDescription:bool = false
var descriptionOffset:float = 0

var mouseWorldPosition:Vector2
var hoveredNote:GameNote
var draggedNote:GameNote

var numberEdits:Array[NumberEdit] = []

func _ready() -> void:
	drawDescription = RenderingServer.canvas_item_create()
	drawMain = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(drawDescription, %worldViewportCont.get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawMain, %drawParent.get_canvas_item())
	Game.camera = playCamera
	Game.pda = %PDA
	pda.screenSize = Vector2(800, 608)
	pda.reset()
	%quickSwitcher.gameSettings = %gameSettings
	%quickSwitcher.configFile = configFile

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
	if draggedNote: continuePositionDrag()
	mouseWorldPosition = %world.get_local_mouse_position()
	for object in Game.objects.values():
		if object.active and Rect2(object.getDrawPosition(),object.size).has_point(mouseWorldPosition): objectsHovered.append(object)
	hoveredNote = null
	for note in Game.notes.values():
		if note.active and Rect2(note.getDrawPosition(),note.size).has_point(mouseWorldPosition): hoveredNote = note
	if playGameDialog.focused: %mouseover.visible = false
	else: %mouseover.describe(objectsHovered, %gameViewportCont.get_local_mouse_position()*Vector2(800,608)/%gameViewportCont.size,Vector2(800,608))

func _draw() -> void:
	RenderingServer.canvas_item_clear(drawDescription)
	RenderingServer.canvas_item_clear(drawMain)
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

func _gui_input(event:InputEvent) -> void:
	if !paused and !inAnimation():
		if Editor.isLeftClick(event):
			if hoveredNote:
				playGameDialog.focus(hoveredNote)
				startPositionDrag(hoveredNote)
			elif playGameDialog.focused: playGameDialog.defocus()
			else:
				var pencilmark:Pencilmark = createNote(Pencilmark, mouseWorldPosition-Vector2(16,16))
				AudioManager.play(preload("res://resources/sounds/sndAddMark.wav"), 0.7, 1)
				playGameDialog.focus(pencilmark)
				startPositionDrag(pencilmark)
		elif Editor.isLeftUnclick(event):
			if draggedNote:
				stopPositionDrag()
		elif event is InputEventMouse and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			if hoveredNote:
				AudioManager.play(preload("res://resources/sounds/player/camera.wav"),0.55,1.5)
				deleteNote(hoveredNote)

func _input(event:InputEvent) -> void:
	if event is InputEventMouseMotion and !paused: Game.mouseMoveTimer = 0
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
		if Editor.isTextInput(%gameViewport.gui_get_focus_owner()):
			match event.keycode:
				KEY_ESCAPE: grab_focus()
		elif !paused and !inAnimation():
			if !Game.player.cameraMode:
				if event.is_action_pressed(&"gameAutoRun"): %quickSwitcher.toggleAutoRun()
				elif event.is_action_pressed(&"gameMixedFractionsSwitch") and Mods.active(&"Fractions"): %quickSwitcher.toggleMixedFractions()
			if playGameDialog.interacted and playGameDialog.interacted.receiveKey(event): return
			elif playGameDialog.interacted and playGameDialog.interacted.receiveUnhandledKey(event): return
			else: Game.player.receiveKey(event)

func startPositionDrag(note:GameNote) -> void:
	draggedNote = note

func continuePositionDrag() -> void:
	var difference:Vector2 = %world.get_local_mouse_position() - mouseWorldPosition
	draggedNote.position += difference

func stopPositionDrag() -> void:
	draggedNote = null

func createNote(type:GDScript, pos:Vector2) -> GameNote:
	var note:GameNote = type.SCENE.instantiate()
	note.fromEditor = false
	note.id = Game.noteIdIter
	Game.noteIdIter += 1
	Game.notes[note.id] = note
	Game.notesParent.add_child(note)
	note.position = pos
	return note

func deleteNote(note:GameNote) -> void:
	print(note)
	if note == playGameDialog.focused: playGameDialog.defocus()
	Game.notes.erase(note.id)
	if note == hoveredNote: hoveredNote = null
	if note == draggedNote: draggedNote = null
	note.queue_free()

func startLevel() -> void:
	start()
	roomTransitionType = ROOM_TRANSITION_TYPE.ENTER_LEVEL
	roomTransitionPhase = 1
	roomTransitionTimer = 0
	textOffsetAngle = 0

func start() -> void:
	Game.player = Game.PLAYER.instantiate()
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
	for note in Game.notes.values():
		note.start()
		note.queue_redraw()
	Game.camera.position = Game.player.position
	Game.camera.reset_smoothing()

func restart() -> void:
	Game.won = false
	Game.crashState = Game.CRASH_STATE.NONE
	%winMenu.visible = false
	roomTransitionPhase = -2
	queue_redraw()
	Game.player.pauseFrame = true
	pda.close()
	Game.player.queue_free()
	for object in Game.objects.values():
		object.stop()
		object.queue_redraw()
	for component in Game.components.values():
		component.stop()
		component.queue_redraw()
	for note in Game.notes.values():
		note.stop()
		note.queue_redraw()
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
	playGameDialog.defocus()
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

func worldspaceToScreenspace(vector:Vector2) -> Vector2:
	return (vector - playCamera.get_screen_center_position()+Vector2(400,304))*playCamera.zoom
